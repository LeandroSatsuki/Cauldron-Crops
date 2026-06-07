extends CharacterBody2D

@export var move_speed_pixels_per_second: float = 128.0
@export var think_interval: float = 1.0
@export var harvest_duration: float = 0.5
@export var deposit_duration: float = 0.3
@export var carry_capacity: int = 1

@onready var crop_sensor_area: Area2D = $CropSensorArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

const PRIORITY_HARVEST_FIRST: int = 0
const PRIORITY_WATER_FIRST: int = 1
const PRIORITY_HARVEST_ONLY: int = 2
const PRIORITY_WATER_ONLY: int = 3
const PRIORITY_PAUSED: int = 4

var state: String = "IDLE"
var carried_rewards: Array = []
var target_plot: Node2D = null
var target_chest: Node2D = null
var work_priority: int = PRIORITY_HARVEST_FIRST
var lotes_maduros_encontrados: int = 0
var lotes_secos_encontrados: int = 0
var ultimo_alvo_detectado: String = "Nenhum"
var ultima_acao: String = "aguardando trabalho"
var _movement_callback: Callable = Callable()
var _think_timer: Timer
var _last_position: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
var _is_avoiding_obstacle: bool = false
var _final_destination: Vector2 = Vector2.ZERO
var _current_avoidance_point: Vector2 = Vector2.ZERO
var _avoidance_attempts: int = 0
var _caldeirao_anchor_path: NodePath = NodePath("CauldronUI/BaseAnchor")

func _ready() -> void:
	_think_timer = Timer.new()
	_think_timer.wait_time = max(think_interval, 0.1)
	_think_timer.autostart = true
	_think_timer.one_shot = false
	_think_timer.timeout.connect(_on_think_timer_timeout)
	add_child(_think_timer)

	if crop_sensor_area and not crop_sensor_area.area_entered.is_connected(_on_crop_sensor_area_area_entered):
		crop_sensor_area.area_entered.connect(_on_crop_sensor_area_area_entered)
	_last_position = global_position

func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 3

func _physics_process(delta: float) -> void:
	var esta_em_movimento: bool = state == "MOVING_TO_PLOT" or state == "MOVING_TO_CHEST"
	if navigation_agent == null:
		if esta_em_movimento:
			var direcao_emergencial: Vector2 = _final_destination - global_position
			if direcao_emergencial.length() > 0.0:
				velocity = direcao_emergencial.normalized() * move_speed_pixels_per_second
			else:
				velocity = Vector2.ZERO
		else:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed_pixels_per_second * 6.0 * delta)
		move_and_slide()
		_monitorar_travamento(delta)
		return

	if not esta_em_movimento:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed_pixels_per_second * 6.0 * delta)
		move_and_slide()
		_last_position = global_position
		_stuck_time = 0.0
		return

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		_concluir_deslocamento()
		_last_position = global_position
		_stuck_time = 0.0
		return

	var proximo_ponto: Vector2 = navigation_agent.get_next_path_position()
	var vetor: Vector2 = proximo_ponto - global_position
	var distancia: float = vetor.length()
	if distancia <= navigation_agent.target_desired_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		_concluir_deslocamento()
		_last_position = global_position
		_stuck_time = 0.0
		return

	if distancia > 0.0:
		velocity = vetor / distancia * move_speed_pixels_per_second
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_monitorar_travamento(delta)

func _on_think_timer_timeout() -> void:
	if state != "IDLE":
		return

	if work_priority == PRIORITY_PAUSED:
		_registrar_acao("pausado")
		return

	if not carried_rewards.is_empty():
		_registrar_acao("indo ao baú")
		_procurar_bau()
		return

	var talento_desbloqueado: bool = _tem_skill_golem_irrigador()
	_recalcular_contadores_lotes()

	match work_priority:
		PRIORITY_HARVEST_ONLY:
			if not _procurar_lote():
				_registrar_acao("sem lote maduro")
		PRIORITY_WATER_ONLY:
			if talento_desbloqueado:
				if not _procurar_lote_para_regar():
					_registrar_acao("sem lote seco")
			else:
				_registrar_acao("rega bloqueada pelo talento")
		PRIORITY_WATER_FIRST:
			if talento_desbloqueado and _procurar_lote_para_regar():
				return
			if _procurar_lote():
				return
			if talento_desbloqueado:
				_registrar_acao("sem lote seco")
			else:
				if lotes_maduros_encontrados > 0:
					_registrar_acao("sem lote maduro")
				else:
					_registrar_acao("rega bloqueada pelo talento")
		_:
			if _procurar_lote():
				return
			if talento_desbloqueado and _procurar_lote_para_regar():
				return
			if lotes_maduros_encontrados > 0:
				_registrar_acao("sem lote maduro")
			elif talento_desbloqueado:
				_registrar_acao("sem lote seco")
			else:
				_registrar_acao("sem lote maduro")

func _tem_skill_golem_irrigador() -> bool:
	return "skill_golem_irrigador" in GlobalInventory.skills_desbloqueadas

func is_golem_active() -> bool:
	return work_priority != PRIORITY_PAUSED

func is_irrigation_skill_unlocked() -> bool:
	return _tem_skill_golem_irrigador()

func get_work_priority() -> int:
	return work_priority

func set_work_priority(nova_prioridade: int) -> bool:
	if nova_prioridade < PRIORITY_HARVEST_FIRST or nova_prioridade > PRIORITY_PAUSED:
		return false

	work_priority = nova_prioridade
	if work_priority == PRIORITY_PAUSED:
		_parar_execucao_atual()
	else:
		if _prioridade_exige_talento_irrigador(work_priority) and not _tem_skill_golem_irrigador():
			ultima_acao = "rega bloqueada pelo talento"
		else:
			ultima_acao = "aguardando trabalho"
	return true

func get_work_priority_label() -> String:
	var bloqueada := _prioridade_exige_talento_irrigador(work_priority) and not _tem_skill_golem_irrigador()
	match work_priority:
		PRIORITY_HARVEST_FIRST:
			return "Colher primeiro"
		PRIORITY_WATER_FIRST:
			return "Regar primeiro" + (" (bloqueado pelo talento)" if bloqueada else "")
		PRIORITY_HARVEST_ONLY:
			return "Só colher"
		PRIORITY_WATER_ONLY:
			return "Só regar" + (" (bloqueado pelo talento)" if bloqueada else "")
		PRIORITY_PAUSED:
			return "Pausado"
		_:
			return "Colher primeiro"

func get_talent_irrigator_label() -> String:
	return "Desbloqueado" if _tem_skill_golem_irrigador() else "Bloqueado"

func get_current_task_label() -> String:
	if work_priority == PRIORITY_PAUSED:
		return "Pausado"

	if _prioridade_exige_talento_irrigador(work_priority) and not _tem_skill_golem_irrigador():
		if work_priority == PRIORITY_WATER_FIRST and lotes_maduros_encontrados > 0:
			return "Procurando colheita"
		return "Rega bloqueada pelo talento"

	if not carried_rewards.is_empty() and state == "IDLE":
		return "Pronto para entregar colheita"

	match state:
		"MOVING_TO_PLOT":
			return "Indo ao lote"
		"HARVESTING":
			return "Colhendo"
		"MOVING_TO_CHEST":
			return "Indo ao baú"
		"DEPOSITING":
			return "Depositando"
		"WATERING":
			return "Irrigando"
		_:
			var prioridade_efetiva: int = _obter_prioridade_efetiva()
			match prioridade_efetiva:
				PRIORITY_WATER_ONLY:
					return "Procurando lote para regar"
				PRIORITY_WATER_FIRST:
					return "Procurando rega ou colheita"
				PRIORITY_HARVEST_ONLY:
					return "Procurando colheita"
				_:
					return "Aguardando trabalho"

func _prioridade_exige_talento_irrigador(prioridade: int) -> bool:
	return prioridade == PRIORITY_WATER_FIRST or prioridade == PRIORITY_WATER_ONLY

func _obter_prioridade_efetiva() -> int:
	if work_priority == PRIORITY_PAUSED:
		return PRIORITY_PAUSED
	if _prioridade_exige_talento_irrigador(work_priority) and not _tem_skill_golem_irrigador():
		if work_priority == PRIORITY_WATER_ONLY:
			return PRIORITY_PAUSED
		return PRIORITY_HARVEST_FIRST
	return work_priority

func get_last_target_label() -> String:
	return ultimo_alvo_detectado if ultimo_alvo_detectado != "" else "Nenhum"

func get_last_action_label() -> String:
	return ultima_acao if ultima_acao != "" else "aguardando trabalho"

func get_mature_plots_found() -> int:
	return lotes_maduros_encontrados

func get_dry_plots_found() -> int:
	return lotes_secos_encontrados

func atualizar_diagnosticos_runtime() -> void:
	_recalcular_contadores_lotes()

func _parar_execucao_atual() -> void:
	velocity = Vector2.ZERO
	_movement_callback = Callable()
	_is_avoiding_obstacle = false
	_current_avoidance_point = Vector2.ZERO
	_stuck_time = 0.0
	_final_destination = global_position
	if navigation_agent:
		navigation_agent.target_position = global_position
	_limpar_alvo_lote()
	target_chest = null
	state = "IDLE"
	ultima_acao = "pausado"

func _recalcular_contadores_lotes() -> void:
	lotes_maduros_encontrados = 0
	lotes_secos_encontrados = 0

	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	for lote in lotes:
		if not is_instance_valid(lote):
			continue
		if lote.has_method("is_expansion_blocked") and bool(lote.call("is_expansion_blocked")):
			continue
		if lote.has_method("get") and lote.get("visible") == false:
			continue

		if bool(lote.get("pronto_para_colher")):
			lotes_maduros_encontrados += 1
		elif lote.has_method("pode_ser_regado_por_golem") and bool(lote.call("pode_ser_regado_por_golem")):
			lotes_secos_encontrados += 1

func _descrever_lote(lote: Node2D) -> String:
	if lote == null or not is_instance_valid(lote):
		return "Nenhum"
	return "%s" % lote.get_path()

func _registrar_acao(texto: String) -> void:
	if texto == "":
		return
	ultima_acao = texto

func _registrar_alvo(lote: Node2D) -> void:
	ultimo_alvo_detectado = _descrever_lote(lote)

func _procurar_lote() -> bool:
	_recalcular_contadores_lotes()
	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	var melhor_lote: Node2D = null
	var melhor_distancia: float = -1.0

	for lote in lotes:
		if not is_instance_valid(lote):
			continue
		if lote.has_method("is_expansion_blocked") and bool(lote.call("is_expansion_blocked")):
			continue
		if lote.has_method("get") and lote.get("visible") == false:
			continue
		if lote.get("pronto_para_colher") != true:
			continue

		var lote_node: Node2D = lote as Node2D
		if lote_node == null:
			continue

		var distancia: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node))
		if melhor_lote == null or distancia < melhor_distancia:
			melhor_lote = lote_node
			melhor_distancia = distancia

	if melhor_lote == null:
		_registrar_acao("sem lote maduro")
		return false

	target_plot = melhor_lote
	_registrar_alvo(target_plot)
	_registrar_acao("indo ao lote")
	state = "MOVING_TO_PLOT"
	_iniciar_deslocamento(_obter_posicao_interacao_lote(target_plot), Callable(self, "_chegar_ao_lote"))
	return true

func _procurar_lote_para_regar() -> bool:
	_recalcular_contadores_lotes()
	if not _tem_skill_golem_irrigador():
		_registrar_acao("rega bloqueada pelo talento")
		return false

	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	var melhor_lote: Node2D = null
	var melhor_distancia: float = -1.0

	for lote in lotes:
		if not is_instance_valid(lote):
			continue
		if not lote.has_method("pode_ser_regado_por_golem"):
			continue
		if not bool(lote.call("pode_ser_regado_por_golem")):
			continue

		var lote_node: Node2D = lote as Node2D
		if lote_node == null:
			continue

		var distancia: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node))
		if melhor_lote == null or distancia < melhor_distancia:
			melhor_lote = lote_node
			melhor_distancia = distancia

	if melhor_lote == null:
		_registrar_acao("sem lote seco")
		return false

	target_plot = melhor_lote
	_registrar_alvo(target_plot)
	_registrar_acao("indo ao lote")
	state = "MOVING_TO_PLOT"
	_iniciar_deslocamento(_obter_posicao_interacao_lote(target_plot), Callable(self, "_chegar_para_regar"))
	return true

func _procurar_bau() -> void:
	target_chest = _encontrar_bau()
	if target_chest == null:
		push_warning("Golem: nenhum Baú da Vila encontrado.")
		state = "IDLE"
		_registrar_acao("indo ao baú")
		return

	ultimo_alvo_detectado = "Baú da Vila"
	_registrar_acao("indo ao baú")
	state = "MOVING_TO_CHEST"
	_iniciar_deslocamento(target_chest.global_position, Callable(self, "_chegar_ao_bau"))

func _encontrar_bau() -> Node2D:
	var baus = get_tree().get_nodes_in_group("village_chest")
	for bau in baus:
		if not is_instance_valid(bau):
			continue
		if bau is Node2D:
			return bau as Node2D
	return null

func _iniciar_deslocamento(destino: Vector2, callback: Callable) -> void:
	_movement_callback = callback
	_final_destination = destino
	_is_avoiding_obstacle = false
	_current_avoidance_point = Vector2.ZERO
	_avoidance_attempts = 0
	_stuck_time = 0.0
	_last_position = global_position
	if navigation_agent:
		navigation_agent.max_speed = move_speed_pixels_per_second
		navigation_agent.target_desired_distance = max(10.0, navigation_agent.target_desired_distance)
		navigation_agent.path_desired_distance = max(10.0, navigation_agent.path_desired_distance)
		navigation_agent.target_position = destino

func _finalizar_deslocamento() -> void:
	var callback: Callable = _movement_callback
	_movement_callback = Callable()
	if callback.is_valid():
		callback.call()

func _concluir_deslocamento() -> void:
	if _is_avoiding_obstacle:
		_retomar_destino_final()
		return
	_finalizar_deslocamento()

func _retomar_destino_final() -> void:
	_is_avoiding_obstacle = false
	_current_avoidance_point = Vector2.ZERO
	_stuck_time = 0.0
	_last_position = global_position
	if navigation_agent:
		navigation_agent.target_position = _final_destination

func _monitorar_travamento(delta: float) -> void:
	var esta_em_movimento: bool = state == "MOVING_TO_PLOT" or state == "MOVING_TO_CHEST"
	if not esta_em_movimento:
		_last_position = global_position
		_stuck_time = 0.0
		return

	var moved_distance: float = global_position.distance_to(_last_position)
	if moved_distance < 1.0:
		_stuck_time += delta
	else:
		_stuck_time = 0.0

	_last_position = global_position

	if _stuck_time >= 0.6:
		_tentar_desvio_caldeirao()

func _tentar_desvio_caldeirao() -> void:
	_stuck_time = 0.0
	_avoidance_attempts += 1

	var centro_caldeirao: Vector2 = _obter_centro_caldeirao()
	if centro_caldeirao == Vector2.ZERO:
		push_warning("Golem: nao foi possivel localizar o caldeirao para criar desvio.")
		if _avoidance_attempts >= 3:
			_abortar_movimento("Golem: travou repetidas vezes sem referencia do caldeirao.")
		return

	var desvio: Vector2 = _calcular_desvio_caldeirao(_final_destination)
	if desvio == Vector2.ZERO:
		push_warning("Golem: nao foi possivel calcular desvio valido ao redor do caldeirao.")
		if _avoidance_attempts >= 3:
			_abortar_movimento("Golem: travou repetidas vezes sem desvio valido.")
		return

	_is_avoiding_obstacle = true
	_current_avoidance_point = desvio
	_last_position = global_position
	if navigation_agent:
		navigation_agent.target_position = desvio

	print("Golem: travado, desviando do caldeirao para %s." % [str(desvio)])

func _abortar_movimento(mensagem: String) -> void:
	push_warning(mensagem)
	velocity = Vector2.ZERO
	_movement_callback = Callable()
	_is_avoiding_obstacle = false
	_current_avoidance_point = Vector2.ZERO
	_stuck_time = 0.0
	_avoidance_attempts = 0
	_final_destination = Vector2.ZERO
	if state == "MOVING_TO_PLOT":
		_limpar_alvo_lote()
	elif state == "MOVING_TO_CHEST":
		target_chest = null
	state = "IDLE"

func _calcular_desvio_caldeirao(destino_final: Vector2) -> Vector2:
	var centro_caldeirao: Vector2 = _obter_centro_caldeirao()
	if centro_caldeirao == Vector2.ZERO:
		return Vector2.ZERO

	var margem: float = 160.0
	var candidatos: Array[Vector2] = [
		centro_caldeirao + Vector2(-margem, 0.0),
		centro_caldeirao + Vector2(margem, 0.0),
		centro_caldeirao + Vector2(0.0, -margem),
		centro_caldeirao + Vector2(0.0, margem)
	]

	var melhor_candidato: Vector2 = Vector2.ZERO
	var melhor_custo: float = -1.0
	var iniciar_em: int = 0
	if _avoidance_attempts > 0:
		iniciar_em = _avoidance_attempts % candidatos.size()

	for i in range(candidatos.size()):
		var indice: int = (iniciar_em + i) % candidatos.size()
		var candidato: Vector2 = candidatos[indice]
		if _current_avoidance_point != Vector2.ZERO and candidato.distance_to(_current_avoidance_point) < 8.0:
			continue
		var custo: float = global_position.distance_to(candidato) + candidato.distance_to(destino_final)
		if melhor_custo < 0.0 or custo < melhor_custo:
			melhor_custo = custo
			melhor_candidato = candidato

	if melhor_candidato != Vector2.ZERO:
		return melhor_candidato

	for j in range(candidatos.size()):
		var candidato_fallback: Vector2 = candidatos[j]
		var custo_fallback: float = global_position.distance_to(candidato_fallback) + candidato_fallback.distance_to(destino_final)
		if melhor_custo < 0.0 or custo_fallback < melhor_custo:
			melhor_custo = custo_fallback
			melhor_candidato = candidato_fallback

	return melhor_candidato

func _obter_centro_caldeirao() -> Vector2:
	if get_tree() == null or get_tree().current_scene == null:
		return Vector2.ZERO

	var base_anchor: Node = get_tree().current_scene.get_node_or_null(_caldeirao_anchor_path)
	if base_anchor and base_anchor is Node2D:
		return (base_anchor as Node2D).global_position

	var cauldron_ui: Node = get_tree().current_scene.get_node_or_null("CauldronUI")
	if cauldron_ui and cauldron_ui is Node2D:
		return (cauldron_ui as Node2D).global_position

	return Vector2.ZERO

func _chegar_ao_lote() -> void:
	if state != "MOVING_TO_PLOT":
		return

	state = "HARVESTING"
	await get_tree().create_timer(harvest_duration).timeout
	if work_priority == PRIORITY_PAUSED or state != "HARVESTING":
		return

	if not is_instance_valid(target_plot) or not target_plot.has_method("harvest_by_golem"):
		push_warning("Golem: lote inválido para colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		_registrar_acao("sem lote maduro")
		return

	var colheita: Array = target_plot.harvest_by_golem()
	if colheita.is_empty():
		push_warning("Golem: o lote não entregou colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		_registrar_acao("sem lote maduro")
		return

	carried_rewards = colheita.duplicate(true)

	_limpar_alvo_lote()

	if carried_rewards.is_empty():
		push_warning("Golem: colheita inválida recebida do lote.")
		state = "IDLE"
		_registrar_acao("sem lote maduro")
		return

	_registrar_acao("colheu")
	_registrar_acao("indo ao baú")
	_procurar_bau()

func _chegar_para_regar() -> void:
	if state != "MOVING_TO_PLOT":
		return

	state = "WATERING"
	await get_tree().create_timer(harvest_duration).timeout
	if work_priority == PRIORITY_PAUSED or state != "WATERING":
		return

	if not is_instance_valid(target_plot) or not target_plot.has_method("regar_por_golem"):
		push_warning("Golem: lote inválido para irrigação.")
		_limpar_alvo_lote()
		state = "IDLE"
		_registrar_acao("sem lote seco")
		return

	if not target_plot.pode_ser_regado_por_golem():
		push_warning("Golem: o lote não aceitou a irrigação.")
		_limpar_alvo_lote()
		state = "IDLE"
		if _tem_skill_golem_irrigador():
			_registrar_acao("sem lote seco")
		else:
			_registrar_acao("rega bloqueada pelo talento")
		return

	if target_plot.regar_por_golem():
		_registrar_acao("regou")
	else:
		_registrar_acao("sem lote seco")

	_limpar_alvo_lote()
	state = "IDLE"

func _chegar_ao_bau() -> void:
	if state != "MOVING_TO_CHEST":
		return

	state = "DEPOSITING"
	await get_tree().create_timer(deposit_duration).timeout
	if work_priority == PRIORITY_PAUSED or state != "DEPOSITING":
		return

	var total_quantidade: int = 0
	if is_instance_valid(target_chest) and target_chest.has_method("deposit_item"):
		for recompensa_variant in carried_rewards:
			if typeof(recompensa_variant) != TYPE_DICTIONARY:
				continue

			var recompensa: Dictionary = recompensa_variant
			var item_id: String = str(recompensa.get("item_id", ""))
			var quantidade: int = int(recompensa.get("quantidade", 0))
			if item_id == "" or quantidade <= 0:
				continue

			target_chest.deposit_item(item_id, quantidade)
			total_quantidade += quantidade
			print("Golem: depositou %s x%d no Baú da Vila." % [item_id, quantidade])
	else:
		push_warning("Golem: baú inválido para depósito.")

	if total_quantidade > 0:
		var ui = get_tree().current_scene.get_node_or_null("UI")
		if ui and ui.has_method("criar_texto_flutuante"):
			ui.criar_texto_flutuante("+%d itens no Baú" % total_quantidade, target_chest.global_position if is_instance_valid(target_chest) else global_position, Color(0.4, 0.9, 1.0))

	carried_rewards = []
	target_chest = null
	state = "IDLE"
	_registrar_acao("indo ao baú")

func _limpar_alvo_lote() -> void:
	target_plot = null

func _obter_posicao_interacao_lote(lote: Node2D) -> Vector2:
	if lote and lote.has_method("get_golem_harvest_position"):
		return lote.get_golem_harvest_position()
	return lote.global_position if lote else global_position

func _on_crop_sensor_area_area_entered(area: Area2D) -> void:
	if area and area.has_method("rustle_from_golem"):
		area.rustle_from_golem()
