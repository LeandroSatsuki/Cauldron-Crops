extends CharacterBody2D

@export var move_speed_pixels_per_second: float = 128.0
@export var think_interval: float = 1.0
@export var harvest_duration: float = 0.5
@export var deposit_duration: float = 0.3
@export var carry_capacity: int = 1
@export var idle_look_duration: float = 1.5
@export var rest_duration: float = 3.0
@export var react_duration: float = 1.0

@onready var crop_sensor_area: Area2D = $CropSensorArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

const PRIORITY_HARVEST_FIRST: int = 0
const PRIORITY_WATER_FIRST: int = 1
const PRIORITY_HARVEST_ONLY: int = 2
const PRIORITY_WATER_ONLY: int = 3
const PRIORITY_PAUSED: int = 4

var state: String = "IDLE"
var carried_rewards: Array = []
var seed_cargo := GolemSeedCargo.new()
var seeding_enabled := false
var _task_generation := 0
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
var life_state: String = "IDLE"
var life_action: String = "aguardando trabalho"
var _life_timer: Timer
var _home_position: Vector2 = Vector2.ZERO
var _idle_cycle_count: int = 0
var _rest_point: Node2D = null
const SEED_MOVEMENT_STATES := ["MOVING_TO_SEED_CHEST", "MOVING_TO_SEED_PLOT", "MOVING_TO_SEED_RETURN"]
const SEED_ARRIVAL_DISTANCE := 14.0
var _seed_target_cell := Vector2i(-1, -1)
var _seed_route_elapsed := 0.0
var _seed_cargo_visual: Sprite2D

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
	_home_position = global_position
	life_state = "IDLE"
	life_action = "aguardando trabalho"
	_rest_point = _encontrar_ponto_descanso()
	_life_timer = Timer.new()
	_life_timer.one_shot = true
	_life_timer.timeout.connect(_on_life_timer_timeout)
	add_child(_life_timer)
	_configure_player_collision_exception.call_deferred()
	_seed_cargo_visual = Sprite2D.new()
	_seed_cargo_visual.name = "SeedCargoVisual"
	_seed_cargo_visual.texture = preload("res://Assets/Tools/tool_seed.png")
	_seed_cargo_visual.scale = Vector2.ONE
	_seed_cargo_visual.position = Vector2(17, -25)
	_seed_cargo_visual.z_index = 2
	_seed_cargo_visual.visible = false
	add_child(_seed_cargo_visual)


func _configure_player_collision_exception() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for player_variant in tree.get_nodes_in_group("player_avatar"):
		var player_body: PhysicsBody2D = player_variant as PhysicsBody2D
		if player_body == null or not is_instance_valid(player_body):
			continue
		add_collision_exception_with(player_body)
		player_body.add_collision_exception_with(self)

func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 3
	_atualizar_visual_vida()
	if _seed_cargo_visual:
		_seed_cargo_visual.visible = seed_cargo.has_seed()

func _physics_process(delta: float) -> void:
	if state in SEED_MOVEMENT_STATES:
		_process_seed_movement(delta)
		return
	var esta_em_movimento: bool = _esta_em_movimento()
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
	if life_state != "IDLE":
		return

	if work_priority == PRIORITY_PAUSED:
		_registrar_acao("pausado")
		return
	if seed_cargo.has_seed():
		_resume_seed_cargo()
		return

	if not carried_rewards.is_empty():
		_cancelar_vida_ociosa()
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
	if work_priority in [PRIORITY_HARVEST_FIRST, PRIORITY_WATER_FIRST] and _start_seeding():
		return
	_iniciar_vida_ociosa()

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
	_cancelar_vida_ociosa()
	if work_priority == PRIORITY_PAUSED:
		_parar_execucao_atual()
	else:
		if (seed_cargo.has_seed() or state in SEED_MOVEMENT_STATES or state == "PLANTING_SEED") and work_priority in [PRIORITY_HARVEST_ONLY, PRIORITY_WATER_ONLY]:
			seed_cargo.mark_return_pending()
			_parar_execucao_atual()
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
	if life_state == "LOOKING":
		return "Olhando ao redor"
	if life_state == "GOING_TO_REST":
		return "Indo descansar"
	if life_state == "RESTING":
		return "Descansando"
	if life_state == "REACTING":
		return "Reagindo à chuva"
	# A falta do talento de rega não bloqueia o plantio dos modos mistos.
	if seed_cargo.has_seed() or state == "MOVING_TO_SEED_CHEST":
		return str(get_seeding_status()["text"])

	if _prioridade_exige_talento_irrigador(work_priority) and not _tem_skill_golem_irrigador():
		if work_priority == PRIORITY_WATER_FIRST and lotes_maduros_encontrados > 0:
			return "Procurando colheita"
		return "Rega bloqueada pelo talento"

	if not carried_rewards.is_empty() and state == "IDLE":
		return "Pronto para entregar colheita"
	if seed_cargo.has_seed():
		return "Devolvendo semente" if seed_cargo.is_return_pending() else "Transportando semente"

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
		"MOVING_TO_SEED_CHEST":
			return "Indo buscar semente"
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
	if life_state != "IDLE":
		return life_action
	return ultima_acao if ultima_acao != "" else "aguardando trabalho"

func get_mature_plots_found() -> int:
	return lotes_maduros_encontrados

func get_dry_plots_found() -> int:
	return lotes_secos_encontrados

func atualizar_diagnosticos_runtime() -> void:
	_recalcular_contadores_lotes()

func _parar_execucao_atual() -> void:
	_task_generation += 1
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
	_cancelar_vida_ociosa()
	state = "IDLE"
	ultima_acao = "pausado"

func _exit_tree() -> void:
	_parar_execucao_atual()

func get_work_save_data() -> Dictionary:
	var harvest: Variant = GolemWorkState.harvest_totals(carried_rewards)
	if harvest == null:
		return {} # O preflight de gravação recusa carga runtime inválida.
	return {"version": GolemWorkState.VERSION, "seeding_enabled": seeding_enabled,
		"work_priority": work_priority, "harvest_cargo": harvest,
		"seed_cargo": seed_cargo.get_save_data()}

func load_work_save_data(data: Dictionary, grove_restored: bool) -> bool:
	if not GolemWorkState.is_valid(data, grove_restored):
		return false
	_parar_execucao_atual()
	work_priority = int(data["work_priority"])
	seeding_enabled = data["seeding_enabled"]
	carried_rewards = GolemWorkState.harvest_rewards(data["harvest_cargo"])
	seed_cargo = GolemSeedCargo.new()
	seed_cargo.apply_save_data(data["seed_cargo"])
	ultima_acao = "pausado" if work_priority == PRIORITY_PAUSED else "aguardando trabalho"
	return true

func _dispatch_work_callback(callback: Callable, generation: int) -> void:
	if _task_is_current(generation) and callback.is_valid():
		callback.call()

func _task_is_current(generation: int) -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and generation == _task_generation

func _receive_harvest_cargo(rewards: Array) -> void:
	carried_rewards = rewards.duplicate(true)

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

func _obter_farm_grid_manager_da_cena() -> FarmGridManager:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return null

	var scene: Node = tree.current_scene
	if not scene.has_method("obter_farm_grid_manager"):
		return null

	var grid_manager_variant: Variant = scene.call("obter_farm_grid_manager")
	if grid_manager_variant is FarmGridManager:
		return grid_manager_variant
	return null

func _obter_farm_plot_por_grid_position(grid_position: Vector2i) -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return null

	var scene: Node = tree.current_scene
	if not scene.has_method("obter_farm_plot_por_grid_position"):
		return null

	var plot_variant: Variant = scene.call("obter_farm_plot_por_grid_position", grid_position)
	if plot_variant is Node2D and is_instance_valid(plot_variant):
		return plot_variant
	return null

func _procurar_lote() -> bool:
	_recalcular_contadores_lotes()

	var melhor_lote: Node2D = null
	var melhor_distancia: float = -1.0
	var grid_manager: FarmGridManager = _obter_farm_grid_manager_da_cena()
	if grid_manager != null:
		for tile_variant in grid_manager.get_all_tiles():
			if tile_variant is not FarmTileData:
				continue

			var tile: FarmTileData = tile_variant
			if tile.crop_id == "" or tile.remaining_growth_time > 0.0:
				continue

			var lote_node: Node2D = _obter_farm_plot_por_grid_position(tile.grid_position)
			if lote_node == null:
				continue
			if lote_node.has_method("is_expansion_blocked") and bool(lote_node.call("is_expansion_blocked")):
				continue
			if lote_node.has_method("get") and lote_node.get("visible") == false:
				continue

			var distancia: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node))
			if melhor_lote == null or distancia < melhor_distancia:
				melhor_lote = lote_node
				melhor_distancia = distancia

	if melhor_lote == null:
		var lotes = get_tree().get_nodes_in_group("lotes_terra")
		for lote in lotes:
			if not is_instance_valid(lote):
				continue
			if lote.has_method("is_expansion_blocked") and bool(lote.call("is_expansion_blocked")):
				continue
			if lote.has_method("get") and lote.get("visible") == false:
				continue
			if lote.get("pronto_para_colher") != true:
				continue

			var lote_node_legacy: Node2D = lote as Node2D
			if lote_node_legacy == null:
				continue

			var distancia_legacy: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node_legacy))
			if melhor_lote == null or distancia_legacy < melhor_distancia:
				melhor_lote = lote_node_legacy
				melhor_distancia = distancia_legacy

	if melhor_lote == null:
		_registrar_acao("sem lote maduro")
		return false

	target_plot = melhor_lote
	_cancelar_vida_ociosa()
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

	var melhor_lote: Node2D = null
	var melhor_distancia: float = -1.0
	var grid_manager: FarmGridManager = _obter_farm_grid_manager_da_cena()
	if grid_manager != null:
		for tile_variant in grid_manager.get_all_tiles():
			if tile_variant is not FarmTileData:
				continue

			var tile: FarmTileData = tile_variant
			if tile.crop_id == "" or tile.remaining_growth_time <= 0.0 or tile.is_watered:
				continue

			var lote_node: Node2D = _obter_farm_plot_por_grid_position(tile.grid_position)
			if lote_node == null:
				continue
			if lote_node.has_method("pode_ser_regado_por_golem") and not bool(lote_node.call("pode_ser_regado_por_golem")):
				continue

			var distancia: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node))
			if melhor_lote == null or distancia < melhor_distancia:
				melhor_lote = lote_node
				melhor_distancia = distancia

	if melhor_lote == null:
		var lotes = get_tree().get_nodes_in_group("lotes_terra")
		for lote in lotes:
			if not is_instance_valid(lote):
				continue
			if not lote.has_method("pode_ser_regado_por_golem"):
				continue
			if not bool(lote.call("pode_ser_regado_por_golem")):
				continue

			var lote_node_legacy: Node2D = lote as Node2D
			if lote_node_legacy == null:
				continue

			var distancia_legacy: float = global_position.distance_to(_obter_posicao_interacao_lote(lote_node_legacy))
			if melhor_lote == null or distancia_legacy < melhor_distancia:
				melhor_lote = lote_node_legacy
				melhor_distancia = distancia_legacy

	if melhor_lote == null:
		_registrar_acao("sem lote seco")
		return false

	target_plot = melhor_lote
	_cancelar_vida_ociosa()
	_registrar_alvo(target_plot)
	_registrar_acao("indo ao lote")
	state = "MOVING_TO_PLOT"
	_iniciar_deslocamento(_obter_posicao_interacao_lote(target_plot), Callable(self, "_chegar_para_regar"))
	return true

func _procurar_bau() -> void:
	_cancelar_vida_ociosa()
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
	_task_generation += 1
	_movement_callback = Callable(self, "_dispatch_work_callback").bind(callback, _task_generation)
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
	var esta_em_movimento: bool = _esta_em_movimento()
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
	_task_generation += 1
	push_warning(mensagem)
	velocity = Vector2.ZERO
	_movement_callback = Callable()
	_is_avoiding_obstacle = false
	_current_avoidance_point = Vector2.ZERO
	_stuck_time = 0.0
	_avoidance_attempts = 0
	_final_destination = Vector2.ZERO
	if state in SEED_MOVEMENT_STATES:
		_limpar_alvo_lote()
		target_chest = null
		_registrar_acao("semente aguardando caminho" if seed_cargo.has_seed() else "plantio aguardando caminho")
	elif state == "MOVING_TO_PLOT":
		_limpar_alvo_lote()
	elif state == "MOVING_TO_CHEST":
		target_chest = null
		if not carried_rewards.is_empty():
			_registrar_acao("entrega aguardando caminho")
	elif state == "MOVING_TO_REST":
		life_state = "IDLE"
		life_action = "descanso indisponivel"
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

func _esta_em_movimento() -> bool:
	return state in SEED_MOVEMENT_STATES or state == "MOVING_TO_PLOT" or state == "MOVING_TO_CHEST" or state == "MOVING_TO_REST"

func get_life_state() -> String:
	return life_state

func get_life_action_label() -> String:
	return life_action

func get_rest_point_position() -> Vector2:
	var point := _encontrar_ponto_descanso()
	return point.global_position if point != null else _home_position

func reagir_a_chuva() -> bool:
	if state != "IDLE" or work_priority == PRIORITY_PAUSED:
		return false
	_cancelar_vida_ociosa()
	life_state = "REACTING"
	life_action = "reagindo a chuva"
	if _life_timer:
		_life_timer.start(max(0.1, react_duration))
	return true

func notify_weather_reaction(weather_id: String) -> bool:
	if weather_id.strip_edges().to_lower() in ["rain", "chuva"]:
		return reagir_a_chuva()
	return false

func _iniciar_vida_ociosa() -> void:
	if state != "IDLE" or work_priority == PRIORITY_PAUSED or seed_cargo.has_seed() or not carried_rewards.is_empty() or life_state != "IDLE":
		return
	_idle_cycle_count += 1
	if _idle_cycle_count % 3 == 0:
		_ir_para_descanso()
	else:
		life_state = "LOOKING"
		life_action = "olhando ao redor"
		if _life_timer:
			_life_timer.start(max(0.1, idle_look_duration))

func _ir_para_descanso() -> void:
	_rest_point = _encontrar_ponto_descanso()
	var destination := get_rest_point_position()
	life_state = "GOING_TO_REST"
	life_action = "procurando descanso"
	if global_position.distance_to(destination) <= 10.0:
		_chegar_ao_descanso()
		return
	state = "MOVING_TO_REST"
	_iniciar_deslocamento(destination, Callable(self, "_chegar_ao_descanso"))

func _chegar_ao_descanso() -> void:
	if state != "MOVING_TO_REST" and life_state != "GOING_TO_REST":
		return
	state = "IDLE"
	life_state = "RESTING"
	life_action = "descansando"
	if _life_timer:
		_life_timer.start(max(0.1, rest_duration))

func _on_life_timer_timeout() -> void:
	if life_state == "LOOKING" or life_state == "RESTING" or life_state == "REACTING":
		life_state = "IDLE"
		life_action = "aguardando trabalho"

func _cancelar_vida_ociosa() -> void:
	if _life_timer:
		_life_timer.stop()
	life_state = "IDLE"
	life_action = "aguardando trabalho"

func _encontrar_ponto_descanso() -> Node2D:
	if get_tree() == null:
		return null
	for node in get_tree().get_nodes_in_group("golem_rest_point"):
		if node is Node2D and is_instance_valid(node):
			return node as Node2D
	return null

func _atualizar_visual_vida() -> void:
	var visual := get_node_or_null("ColorRect") as Control
	if visual == null:
		return

	var pulso := sin(float(Time.get_ticks_msec()) * 0.004) * 0.025
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	visual.modulate = Color.WHITE
	match life_state:
		"LOOKING":
			visual.rotation = pulso
			visual.modulate = Color(1.0, 1.0, 0.78, 1.0)
		"RESTING":
			visual.scale = Vector2(1.08, 0.82)
			visual.modulate = Color(0.72, 0.9, 1.0, 1.0)
		"REACTING":
			visual.rotation = pulso * 2.0
			visual.modulate = Color(0.72, 0.9, 1.0, 1.0)

func _chegar_ao_lote() -> void:
	if state != "MOVING_TO_PLOT":
		return

	state = "HARVESTING"
	var generation := _task_generation
	await get_tree().create_timer(harvest_duration).timeout
	if not _task_is_current(generation) or work_priority == PRIORITY_PAUSED or state != "HARVESTING":
		return

	if not is_instance_valid(target_plot) or not target_plot.has_method("harvest_by_golem"):
		push_warning("Golem: lote inválido para colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		_registrar_acao("sem lote maduro")
		return

	var colheita: Array = target_plot.harvest_by_golem(Callable(self, "_receive_harvest_cargo"))
	if not _task_is_current(generation):
		return
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
	var generation := _task_generation
	await get_tree().create_timer(harvest_duration).timeout
	if not _task_is_current(generation) or work_priority == PRIORITY_PAUSED or state != "WATERING":
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

	var watered: bool = target_plot.regar_por_golem()
	if not _task_is_current(generation):
		return
	if watered:
		_registrar_acao("regou")
	else:
		_registrar_acao("sem lote seco")

	_limpar_alvo_lote()
	state = "IDLE"

func _chegar_ao_bau() -> void:
	if state != "MOVING_TO_CHEST":
		return

	state = "DEPOSITING"
	var generation := _task_generation
	await get_tree().create_timer(deposit_duration).timeout
	if not _task_is_current(generation) or work_priority == PRIORITY_PAUSED or state != "DEPOSITING":
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
		target_chest = null
		state = "IDLE"
		_registrar_acao("entrega aguardando baú")
		return

	var feedback_position := target_chest.global_position
	carried_rewards = []
	target_chest = null
	state = "IDLE"
	_registrar_acao("indo ao baú")
	if total_quantidade > 0:
		var ui = get_tree().current_scene.get_node_or_null("UI")
		if ui and ui.has_method("criar_texto_flutuante"):
			ui.criar_texto_flutuante("+%d itens no Baú" % total_quantidade, feedback_position, Color(0.4, 0.9, 1.0))

func _limpar_alvo_lote() -> void:
	target_plot = null

func _obter_posicao_interacao_lote(lote: Node2D) -> Vector2:
	if lote and lote.has_method("get_golem_harvest_position"):
		return lote.get_golem_harvest_position()
	return lote.global_position if lote else global_position

func _on_crop_sensor_area_area_entered(area: Area2D) -> void:
	if area and area.has_method("rustle_from_golem"):
		area.rustle_from_golem()


# Piloto físico: nenhum consumidor agregado/Mochila e nenhuma reserva em trânsito.
func set_seeding_enabled(enabled: bool) -> bool:
	if enabled and not GroveExpedition.restored:
		return false
	seeding_enabled = enabled
	if not enabled:
		seed_cargo.mark_return_pending()
		if state in SEED_MOVEMENT_STATES or state == "PLANTING_SEED":
			_parar_execucao_atual()
	_cancelar_vida_ociosa()
	return true


func get_seeding_status() -> Dictionary:
	# Consulta de apresentação: não liga habilidade, muda prioridade ou reserva itens.
	var result := {"unlocked": GroveExpedition.restored, "enabled": seeding_enabled, "code": "off", "text": "Desligado. Ative quando quiser."}
	if not is_inside_tree():
		return _seed_status(result, "inactive", "Vila ausente. O trabalho físico está suspenso.")
	if not GroveExpedition.restored:
		return _seed_status(result, "locked", "Restaure a Clareira do Bosque para liberar.")
	if seed_cargo.has_seed():
		if work_priority == PRIORITY_PAUSED:
			return _seed_status(result, "paused_cargo", "Pausado com 1 semente preservada" + (" para devolver." if seed_cargo.is_return_pending() else "."))
		if seed_cargo.is_return_pending():
			if state in ["MOVING_TO_SEED_RETURN", "RETURNING_SEED"]:
				return _seed_status(result, "returning", "Devolvendo 1 semente ao Baú da Vila.")
			return _seed_status(result, "return_pending", "Devolução pendente. A semente permanece com o golem.")
		if state == "PLANTING_SEED":
			return _seed_status(result, "planting", "Plantando trigo no canteiro inicial.")
		if state == "MOVING_TO_SEED_PLOT":
			return _seed_status(result, "transporting", "Transportando 1 semente de trigo.")
		return _seed_status(result, "cargo_waiting", "Transporte aguardando caminho. Semente preservada.")
	if not seeding_enabled:
		return result
	if work_priority == PRIORITY_PAUSED:
		return _seed_status(result, "paused", "Pausado. Retome uma prioridade mista para semear.")
	if work_priority in [PRIORITY_HARVEST_ONLY, PRIORITY_WATER_ONLY]:
		return _seed_status(result, "exclusive", "Use Colher primeiro ou Regar primeiro para semear.")
	if not carried_rewards.is_empty() or state in ["MOVING_TO_PLOT", "HARVESTING", "WATERING", "MOVING_TO_CHEST", "DEPOSITING"]:
		return _seed_status(result, "other_work", "Colheita e rega têm prioridade; semeia depois.")
	if state == "MOVING_TO_SEED_CHEST":
		return _seed_status(result, "fetching", "Indo buscar 1 semente no Baú da Vila.")
	var prepared := 0
	var reasons: Dictionary = {}
	for cell in GolemSeedCargo.PILOT_CELLS:
		var plot := _obter_farm_plot_por_grid_position(cell)
		if not is_instance_valid(plot):
			continue
		var validation: Dictionary = plot.call("validate_seed_planting", GolemSeedCargo.SEED_ITEM_ID)
		if validation["success"]:
			prepared += 1
		else:
			reasons[validation["reason"]] = true
	if prepared == 0:
		if reasons.has("wrong_season"):
			return _seed_status(result, "season", "Trigo só é semeado na Primavera.")
		if reasons.has("untilled"):
			return _seed_status(result, "soil", "Are um dos 4 lotes iniciais para preparar o canteiro.")
		if reasons.has("occupied"):
			return _seed_status(result, "occupied", "Nenhum lote vazio disponível no canteiro inicial.")
		return _seed_status(result, "unavailable", "Canteiro inicial bloqueado ou indisponível.")
	var chest := _encontrar_bau() as VillageChest
	if not is_instance_valid(chest) or chest.is_queued_for_deletion():
		return _seed_status(result, "no_chest", "Baú da Vila indisponível. Nenhuma semente retirada.")
	var stock := chest.get_item_quantity(GolemSeedCargo.SEED_ITEM_ID)
	if stock < 1:
		return _seed_status(result, "no_seeds", "Deposite sementes de trigo no Baú da Vila; não usa a Mochila.")
	return _seed_status(result, "ready", "Pronto · %d lote(s) · %d semente(s) no baú." % [prepared, stock])


func _seed_status(result: Dictionary, code: String, text: String) -> Dictionary:
	result["code"] = code
	result["text"] = text
	return result


func _can_seed_now() -> bool:
	return seeding_enabled and GroveExpedition.restored and work_priority in [PRIORITY_HARVEST_FIRST, PRIORITY_WATER_FIRST] and carried_rewards.is_empty()


func _valid_seed_plot(plot: Node2D) -> bool:
	return is_instance_valid(plot) and plot.is_inside_tree() and not plot.is_queued_for_deletion() and plot.has_method("validate_seed_planting") and bool(plot.call("validate_seed_planting", GolemSeedCargo.SEED_ITEM_ID)["success"])


func _start_seeding() -> bool:
	if not _can_seed_now() or seed_cargo.has_seed():
		return false
	var chest := _encontrar_bau() as VillageChest
	if chest == null or chest.get_item_quantity(GolemSeedCargo.SEED_ITEM_ID) < 1:
		_registrar_acao("sem sementes no baú")
		return false
	var nearest: Node2D = null
	var distance := INF
	for cell in GolemSeedCargo.PILOT_CELLS:
		var plot := _obter_farm_plot_por_grid_position(cell)
		if not _valid_seed_plot(plot):
			continue
		var candidate_distance := global_position.distance_to(_obter_posicao_interacao_lote(plot))
		if candidate_distance < distance:
			nearest = plot
			distance = candidate_distance
			_seed_target_cell = cell
	if nearest == null:
		_registrar_acao("sem lote preparado para trigo")
		return false
	target_plot = nearest
	target_chest = chest
	_cancelar_vida_ociosa()
	state = "MOVING_TO_SEED_CHEST"
	_registrar_acao("indo buscar semente")
	_start_seed_route(_seed_chest_position(chest), Callable(self, "_arrive_seed_chest"))
	return true


func _seed_chest_position(chest: Node2D) -> Vector2:
	# Aproximação sul, fora do corpo/obstáculo do baú; nunca mirar seu centro.
	return chest.global_position + Vector2(0, 48)


func _seed_chest_in_reach() -> bool:
	return is_instance_valid(target_chest) and target_chest.is_inside_tree() and not target_chest.is_queued_for_deletion() and target_chest is VillageChest and global_position.distance_to(_seed_chest_position(target_chest)) <= SEED_ARRIVAL_DISTANCE


func _seed_plot_in_reach() -> bool:
	return is_instance_valid(target_plot) and global_position.distance_to(_obter_posicao_interacao_lote(target_plot)) <= SEED_ARRIVAL_DISTANCE


func _start_seed_route(destination: Vector2, callback: Callable) -> void:
	_seed_route_elapsed = 0.0
	_iniciar_deslocamento(destination, callback)


func _process_seed_movement(delta: float) -> void:
	_seed_route_elapsed += delta
	if _seed_route_elapsed > 30.0:
		_abortar_movimento("Golem: trajeto de semente indisponível; custódia preservada.")
		return
	var destination := _current_avoidance_point if _is_avoiding_obstacle else _final_destination
	if global_position.distance_to(destination) <= SEED_ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
		_concluir_deslocamento()
		return
	if navigation_agent == null:
		_abortar_movimento("Golem: navegação de semente indisponível.")
		return
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return # Mapa recém-inserido (inclusive retorno da vila cacheada).
	var next := navigation_agent.get_next_path_position()
	if navigation_agent.get_current_navigation_path().is_empty() or navigation_agent.is_navigation_finished():
		if _seed_route_elapsed < 0.2:
			velocity = Vector2.ZERO
			return # NavigationAgent pode entregar caminho vazio no primeiro tick.
		_abortar_movimento("Golem: caminho terminou longe do destino; semente preservada.")
		return
	var direction := next - global_position
	velocity = direction.normalized() * minf(move_speed_pixels_per_second, direction.length() / maxf(delta, 0.001))
	move_and_slide()
	_monitorar_travamento(delta)


func _arrive_seed_chest() -> void:
	if state != "MOVING_TO_SEED_CHEST":
		return
	var live := _obter_farm_plot_por_grid_position(_seed_target_cell)
	if not _can_seed_now() or not _seed_chest_in_reach() or live != target_plot or not _valid_seed_plot(live):
		_finish_seed_job("retirada recusada; estoque preservado")
		return
	if not seed_cargo.take_from_chest(target_chest as VillageChest, _seed_target_cell):
		_finish_seed_job("sem sementes no baú")
		return
	_resume_seed_cargo()


func _resume_seed_cargo() -> void:
	if not seed_cargo.has_seed() or work_priority == PRIORITY_PAUSED:
		return
	_cancelar_vida_ociosa()
	var cell := seed_cargo.get_target_cell()
	var plot := _obter_farm_plot_por_grid_position(cell)
	if not _can_seed_now() or not _valid_seed_plot(plot):
		seed_cargo.mark_return_pending()
	if seed_cargo.is_return_pending():
		target_plot = null
		target_chest = _encontrar_bau()
		if not is_instance_valid(target_chest):
			_finish_seed_job("devolução aguardando baú")
			return
		state = "MOVING_TO_SEED_RETURN"
		_registrar_acao("devolvendo semente")
		_start_seed_route(_seed_chest_position(target_chest), Callable(self, "_arrive_seed_return"))
	else:
		target_plot = plot
		target_chest = null
		_registrar_alvo(plot)
		state = "MOVING_TO_SEED_PLOT"
		_registrar_acao("transportando semente")
		_start_seed_route(_obter_posicao_interacao_lote(plot), Callable(self, "_arrive_seed_plot"))


func _arrive_seed_plot() -> void:
	if state != "MOVING_TO_SEED_PLOT":
		return
	if not _seed_plot_in_reach():
		_finish_seed_job("semente aguardando caminho")
		return
	state = "PLANTING_SEED"
	var generation := _task_generation
	await get_tree().create_timer(harvest_duration).timeout
	if not _task_is_current(generation) or state != "PLANTING_SEED" or work_priority == PRIORITY_PAUSED:
		return
	var live := _obter_farm_plot_por_grid_position(seed_cargo.get_target_cell())
	if not _can_seed_now() or live != target_plot or not _valid_seed_plot(live) or not _seed_plot_in_reach():
		seed_cargo.mark_return_pending()
		_resume_seed_cargo()
		return
	var result: Dictionary = live.call("try_plant_from_golem_cargo", seed_cargo)
	# O sinal do lote pode carregar outro snapshot: não tocar a nova tarefa.
	if not _task_is_current(generation):
		return
	if result["success"]:
		_finish_seed_job("plantou trigo")
	else:
		seed_cargo.mark_return_pending()
		_resume_seed_cargo()


func _arrive_seed_return() -> void:
	if state != "MOVING_TO_SEED_RETURN":
		return
	if not _seed_chest_in_reach():
		_finish_seed_job("devolução aguardando caminho")
		return
	state = "RETURNING_SEED"
	var generation := _task_generation
	await get_tree().create_timer(deposit_duration).timeout
	if not _task_is_current(generation) or state != "RETURNING_SEED" or work_priority == PRIORITY_PAUSED:
		return
	if _seed_chest_in_reach() and seed_cargo.return_to_chest(target_chest as VillageChest):
		_finish_seed_job("semente devolvida")
	else:
		_finish_seed_job("devolução aguardando baú/caminho")


func _finish_seed_job(message: String) -> void:
	velocity = Vector2.ZERO
	target_plot = null
	target_chest = null
	state = "IDLE"
	_registrar_acao(message)
