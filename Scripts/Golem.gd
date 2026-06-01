extends CharacterBody2D

@export var move_speed_pixels_per_second: float = 128.0
@export var think_interval: float = 1.0
@export var harvest_duration: float = 0.5
@export var deposit_duration: float = 0.3
@export var carry_capacity: int = 1

@onready var crop_sensor_area: Area2D = $CropSensorArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var state: String = "IDLE"
var carried_rewards: Array = []
var target_plot: Node2D = null
var target_chest: Node2D = null
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

	if not carried_rewards.is_empty():
		_procurar_bau()
	else:
		_procurar_lote()

func _procurar_lote() -> void:
	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	for lote in lotes:
		if not is_instance_valid(lote):
			continue
		if lote.get("pronto_para_colher") == true:
			target_plot = lote as Node2D
			if target_plot == null:
				continue
			state = "MOVING_TO_PLOT"
			_iniciar_deslocamento(_obter_posicao_interacao_lote(target_plot), Callable(self, "_chegar_ao_lote"))
			return

func _procurar_bau() -> void:
	target_chest = _encontrar_bau()
	if target_chest == null:
		push_warning("Golem: nenhum Baú da Vila encontrado.")
		state = "IDLE"
		return

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

	if not is_instance_valid(target_plot) or not target_plot.has_method("harvest_by_golem"):
		push_warning("Golem: lote inválido para colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		return

	var colheita: Array = target_plot.harvest_by_golem()
	if colheita.is_empty():
		push_warning("Golem: o lote não entregou colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		return

	carried_rewards = colheita.duplicate(true)

	_limpar_alvo_lote()

	if carried_rewards.is_empty():
		push_warning("Golem: colheita inválida recebida do lote.")
		state = "IDLE"
		return

	_procurar_bau()

func _chegar_ao_bau() -> void:
	if state != "MOVING_TO_CHEST":
		return

	state = "DEPOSITING"
	await get_tree().create_timer(deposit_duration).timeout

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

func _limpar_alvo_lote() -> void:
	target_plot = null

func _obter_posicao_interacao_lote(lote: Node2D) -> Vector2:
	if lote and lote.has_method("get_golem_harvest_position"):
		return lote.get_golem_harvest_position()
	return lote.global_position if lote else global_position

func _on_crop_sensor_area_area_entered(area: Area2D) -> void:
	if area and area.has_method("rustle_from_golem"):
		area.rustle_from_golem()
