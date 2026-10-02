extends Node2D


signal region_transition_requested(request: Dictionary)



var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")

const FISHING_SPOT_SCENE_PATH: String = "res://Scenes/FishingSpot.tscn"

const FISHING_SPOT_SCRIPT_PATH: String = "res://Scripts/FishingSpot.gd"
const RESTORATION_PROJECT_SCENE_PATH: String = "res://Scenes/RestorationProject.tscn"

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var main_camera: Camera2D = get_node_or_null("MainCamera") as Camera2D
@onready var player_avatar: CharacterBody2D = get_node_or_null("PlayerAvatar") as CharacterBody2D
@onready var player_destination_marker: Node2D = get_node_or_null("PlayerDestinationMarker") as Node2D
@onready var world_region: WorldRegion = get_node_or_null("RegionContext") as WorldRegion



const BASE_FARM_COLUMNS: int = 4

const BASE_FARM_ROWS: int = 4

const EXTRA_FARM_COLUMNS_RIGHT: int = 2

const EXTRA_FARM_ROWS_BOTTOM: int = 1

const FARM_SPACING: int = 80

const BASE_FARM_PIXEL_SIZE: int = 320

const FISHING_SPOT_POSITION: Vector2 = Vector2(1288, 172)

const FISHING_SPOT_Z_INDEX: int = 20

const EXPANSION_POCKET_COLUMNS: int = 2

const EXPANSION_POCKET_ROWS: int = 2

const EXPANSION_POCKET_START_COLUMN: int = BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT

const EXPANSION_POCKET_START_ROW: int = 0

const EXPANSION_V0_OBSTACLE_ID: String = "first_obstacle"

# Referência legada das funções de blockout. Elas não são mais chamadas no runtime.
const BLOCKOUT_FARM_Z_INDEX: int = 40

const FREE_FARMING_PILOT_Z_INDEX: int = 35
const FREE_FARMING_REASON_OUTSIDE_PILOT: String = "outside_free_farming_pilot"
const FREE_FARMING_REASON_HOE_REQUIRED: String = "hoe_required"
const FREE_FARMING_REASON_PREPARATION_FAILED: String = "preparation_failed"
const WORLD_NAVIGATION_BOUNDS: Rect2 = Rect2(-512.0, -384.0, 3072.0, 2304.0)
const INTERACTION_CLEARANCE_MARGIN: float = 16.0
const INTERACTION_APPROACH_INSET: float = 8.0


@export var cultivable_grid_bounds: Rect2i = Rect2i(Vector2i(-8, -5), Vector2i(24, 14))
@export var reserved_cultivation_grid_areas: Array[Rect2i] = []
@export var free_farming_pilot_bounds: Rect2i = Rect2i(Vector2i(4, 5), Vector2i(6, 2))
@export var show_free_farming_pilot_marker: bool = false
@export var camera_follow_speed: float = 7.0



var expansion_area_configs: Dictionary = {}

var expansion_area_order: Array[String] = []

var expansion_area_visuals: Dictionary = {}

var expansion_area_plots: Dictionary = {}

var lore_discoveries: Dictionary = {}
var restoration_projects: Dictionary = {}

var farm_plot_registry: Dictionary = {}
var farm_grid_manager: FarmGridManager = null

var farm_origin: Vector2 = Vector2.ZERO

var _camera_dragging: bool = false
var _camera_follow_enabled: bool = true
var _pending_player_interaction: Dictionary = {}
var _region_being_cached: bool = false

func _ready() -> void:
	_configurar_contexto_regiao()

	_configurar_regiao_navegacao()



	var screen_size = get_viewport_rect().size

	var start_x: float = (screen_size.x - BASE_FARM_PIXEL_SIZE) / 2.0 - 40.0

	var start_y: float = (screen_size.y - BASE_FARM_PIXEL_SIZE) / 2.0

	farm_origin = Vector2(start_x, start_y)



	_criar_farm_plot_base(start_x, start_y)

	_criar_farm_plot_extras_direita(start_x, start_y)

	_criar_farm_plot_extras_inferiores(start_x, start_y)

	_garantir_lago_da_fazenda()

	_registrar_area_expansao_v0(start_x, start_y)

	_garantir_areas_expansao(start_x, start_y)

	_conectar_obstaculos_purificacao()

	_sincronizar_areas_expansao()
	_garantir_primeira_descoberta_lore()
	_garantir_primeiro_projeto_restauracao()
	_reconstruir_farm_grid_manager()

	_criar_marcador_agricultura_livre()
	_configurar_camera_inicial(start_x, start_y)
	_register_with_travel_coordinator.call_deferred()


func _configurar_contexto_regiao() -> void:
	if world_region == null:
		return
	if not world_region.transition_requested.is_connected(_on_region_transition_requested):
		world_region.transition_requested.connect(_on_region_transition_requested)

	var entry: Dictionary = world_region.resolve_entry()
	if player_avatar != null and bool(entry.get("found", false)):
		player_avatar.global_position = entry.get("global_position", player_avatar.global_position)


func enter_region_at(entry_id: StringName = &"") -> bool:
	if world_region == null or player_avatar == null or not is_instance_valid(player_avatar):
		return false
	world_region.refresh_entry_points()
	var entry: Dictionary = world_region.resolve_entry(entry_id)
	if not bool(entry.get("found", false)):
		return false
	_cancel_pending_player_interaction(true)
	player_avatar.global_position = entry.get("global_position", player_avatar.global_position)
	player_avatar.call("stop_moving")
	if main_camera != null:
		main_camera.make_current()
		main_camera.global_position = player_avatar.global_position
	_camera_follow_enabled = true
	_region_being_cached = false
	return true


func on_region_became_inactive() -> void:
	_region_being_cached = true
	_cancel_pending_player_interaction(true)


func on_region_became_active() -> void:
	_region_being_cached = false


func advance_inactive_time(elapsed_seconds: float) -> Dictionary:
	var safe_elapsed: float = maxf(elapsed_seconds, 0.0)
	var advanced_plots: int = 0
	if safe_elapsed > 0.0:
		for plot_variant in farm_plot_registry.values():
			var plot: Node = plot_variant as Node
			if plot != null and is_instance_valid(plot) and plot.has_method("advance_inactive_time"):
				if bool(plot.call("advance_inactive_time", safe_elapsed)):
					advanced_plots += 1
		var cauldron: Node = get_node_or_null("CauldronUI")
		if cauldron != null and cauldron.has_method("advance_inactive_time"):
			cauldron.call("advance_inactive_time", safe_elapsed)
		_reconstruir_farm_grid_manager()
	return {
		"elapsed_seconds": safe_elapsed,
		"advanced_plots": advanced_plots,
	}


func _register_with_travel_coordinator() -> void:
	var coordinator: Node = get_tree().root.get_node_or_null("RegionTravelCoordinator")
	if coordinator != null and coordinator.has_method("register_region_scene"):
		coordinator.call("register_region_scene", self)


func get_current_region_identity() -> Dictionary:
	if world_region == null:
		return {}
	return world_region.get_identity()


func resolve_region_entry(entry_id: StringName = &"") -> Dictionary:
	if world_region == null:
		return {"found": false, "entry_id": String(entry_id)}
	return world_region.resolve_entry(entry_id)


func request_region_transition(
	target_region_id: StringName,
	target_entry_id: StringName,
	source_exit_id: StringName = &""
) -> bool:
	if world_region == null:
		return false
	return world_region.request_transition(target_region_id, target_entry_id, source_exit_id)


func peek_pending_region_transition() -> Dictionary:
	if world_region == null:
		return {}
	return world_region.peek_pending_transition()


func consume_pending_region_transition() -> Dictionary:
	if world_region == null:
		return {}
	return world_region.consume_pending_transition()


func _on_region_transition_requested(request: Dictionary) -> void:
	# A troca de cena pertence a uma camada futura; o mapa apenas publica o contrato.
	region_transition_requested.emit(request.duplicate(true))


func _process(delta: float) -> void:
	if player_avatar == null or not is_instance_valid(player_avatar):
		return
	_process_camera_follow(delta)
	if not _pending_player_interaction.is_empty():
		_process_pending_player_interaction()
		return
	if not player_avatar.has_method("has_active_destination") or not bool(player_avatar.call("has_active_destination")):
		_clear_player_destination_marker()
		return
	if _player_movement_is_blocked_by_mode() and player_avatar.has_method("stop_moving"):
		player_avatar.call("stop_moving")



func _configurar_regiao_navegacao() -> void:

	if navigation_region == null:

		return



	var vertices := PackedVector2Array([
		WORLD_NAVIGATION_BOUNDS.position,
		Vector2(WORLD_NAVIGATION_BOUNDS.position.x, WORLD_NAVIGATION_BOUNDS.end.y),
		WORLD_NAVIGATION_BOUNDS.end,
		Vector2(WORLD_NAVIGATION_BOUNDS.end.x, WORLD_NAVIGATION_BOUNDS.position.y)
	])

	var polygon := NavigationPolygon.new()
	polygon.vertices = vertices
	polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))

	navigation_region.navigation_polygon = polygon


func _configurar_camera_inicial(start_x: float, start_y: float) -> void:

	if main_camera == null:

		return

	main_camera.make_current()
	main_camera.zoom = Vector2.ONE
	if player_avatar != null and is_instance_valid(player_avatar):
		main_camera.position = player_avatar.global_position
	else:
		main_camera.position = Vector2(start_x + (2.8 * FARM_SPACING), start_y + (1.6 * FARM_SPACING))
	main_camera.limit_left = -512
	main_camera.limit_top = -384
	main_camera.limit_right = 2560
	main_camera.limit_bottom = 1920


func _garantir_farm_grid_manager() -> void:
	if farm_grid_manager == null:
		farm_grid_manager = FarmGridManager.new()


func _reconstruir_farm_grid_manager() -> void:
	_garantir_farm_grid_manager()
	if farm_grid_manager == null:
		return

	farm_grid_manager.clear()

	for key_variant in farm_plot_registry.keys():
		if typeof(key_variant) != TYPE_VECTOR2I:
			continue

		var plot_variant: Variant = farm_plot_registry.get(key_variant)
		if plot_variant is not Node2D or not is_instance_valid(plot_variant):
			continue

		var plot: Node2D = plot_variant
		var plot_position: Vector2i = key_variant
		_sincronizar_farm_grid_manager_com_plot(plot_position, plot)


func _sincronizar_farm_grid_manager_com_plot(grid_position: Vector2i, plot: Node2D) -> void:
	if grid_position == Vector2i(-1, -1) or plot == null or not is_instance_valid(plot):
		return

	_garantir_farm_grid_manager()
	if farm_grid_manager == null:
		return

	var tile: FarmTileData = _converter_farm_plot_para_tile_data(grid_position, plot)
	if tile == null:
		return

	farm_grid_manager.set_tile(grid_position, tile)


func _converter_farm_plot_para_tile_data(grid_position: Vector2i, plot: Node2D) -> FarmTileData:
	var tile: FarmTileData = FarmTileData.new()
	tile.grid_position = grid_position
	if plot == null or not is_instance_valid(plot):
		return tile

	if plot.has_method("is_expansion_blocked") and bool(plot.call("is_expansion_blocked")):
		tile.tile_state = FarmTileData.TileState.BLOQUEADO
		return tile

	var save_data: Dictionary = {}
	if plot.has_method("get_save_data"):
		var save_data_variant: Variant = plot.call("get_save_data")
		if typeof(save_data_variant) == TYPE_DICTIONARY:
			save_data = save_data_variant

	var arado: bool = bool(save_data.get("arado", false))
	var regado: bool = bool(save_data.get("regado", false))
	var semente_id: String = str(save_data.get("semente_id_plantada", ""))
	tile.is_watered = regado
	tile.crop_id = semente_id
	tile.remaining_growth_time = maxf(float(save_data.get("tempo_restante", 0.0)), 0.0)
	tile.total_growth_time = maxf(float(save_data.get("tempo_total_crescimento", 0.0)), 0.0)
	tile.pending_harvest_rewards = save_data.get("pending_harvest_rewards", {}).duplicate(true)

	if semente_id != "":
		tile.tile_state = FarmTileData.TileState.MOLHADO if regado else FarmTileData.TileState.PLANTADO
	elif arado:
		tile.tile_state = FarmTileData.TileState.MOLHADO if regado else FarmTileData.TileState.ARADO
	else:
		tile.tile_state = FarmTileData.TileState.GRAMA

	return tile


func _esta_modal_aberto() -> bool:

	var ui_node: Node = get_node_or_null("UI")
	if ui_node != null and ui_node.has_method("_tem_popup_modal_aberto"):

		return bool(ui_node.call("_tem_popup_modal_aberto"))

	return false


func can_issue_player_move(world_position: Vector2, check_interaction_colliders: bool = true) -> bool:
	if player_avatar == null or not is_instance_valid(player_avatar):
		return false
	if _player_movement_is_blocked_by_mode():
		return false
	if check_interaction_colliders and _world_position_has_interaction_collider(world_position):
		return false
	return true


func _player_movement_is_blocked_by_mode() -> bool:
	if _player_movement_is_blocked_by_context():
		return true

	var tool_manager: Node = get_tree().root.get_node_or_null("ToolManager")
	if tool_manager != null and tool_manager.has_method("get_active_tool"):
		if int(tool_manager.call("get_active_tool")) != int(ToolManager.ToolType.NONE):
			return true
	if GlobalInventory.semente_selecionada != "":
		return true
	return false


func _player_movement_is_blocked_by_context() -> bool:
	return _esta_modal_aberto() or _camera_dragging


func try_move_player_to(world_position: Vector2, check_interaction_colliders: bool = true) -> bool:
	if not can_issue_player_move(world_position, check_interaction_colliders):
		return false
	_cancel_pending_player_interaction(false)
	set_camera_follow_enabled(true)
	var move_requested: bool = bool(player_avatar.request_move(world_position))
	if move_requested:
		_show_player_destination_marker(world_position, false)
	return move_requested


func request_player_interaction(target: Node, target_position: Vector2, interaction_distance: float, callback: Callable) -> bool:
	if player_avatar == null or not is_instance_valid(player_avatar):
		return false
	if target == null or not is_instance_valid(target) or not callback.is_valid():
		return false
	if _player_movement_is_blocked_by_context():
		return false

	_cancel_pending_player_interaction(false)
	set_camera_follow_enabled(true)
	var safe_distance: float = _resolve_safe_interaction_distance(target, target_position, interaction_distance)
	if player_avatar.global_position.distance_to(target_position) <= safe_distance:
		if player_avatar.has_method("stop_moving"):
			player_avatar.call("stop_moving")
		_clear_player_destination_marker()
		callback.call()
		return true

	var direction_from_target: Vector2 = target_position.direction_to(player_avatar.global_position)
	if direction_from_target.is_zero_approx():
		direction_from_target = Vector2.DOWN
	var approach_position: Vector2 = target_position + direction_from_target * maxf(
		safe_distance - INTERACTION_APPROACH_INSET,
		16.0
	)
	_pending_player_interaction = {
		"target_ref": weakref(target),
		"target_position": target_position,
		"interaction_distance": safe_distance,
		"callback": callback,
		"action_signature": _get_player_action_signature(),
	}
	if not bool(player_avatar.request_move(approach_position)):
		_pending_player_interaction.clear()
		return false
	_show_player_destination_marker(approach_position, true)
	return true


func _resolve_safe_interaction_distance(target: Node, target_position: Vector2, requested_distance: float) -> float:
	var safe_distance: float = maxf(requested_distance, 24.0)
	var player_radius: float = 13.0
	if player_avatar != null and is_instance_valid(player_avatar):
		var agent: NavigationAgent2D = player_avatar.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
		if agent != null:
			player_radius = maxf(agent.radius, player_radius)
	var obstacles: Array[Node] = []
	if target is NavigationObstacle2D:
		obstacles.append(target)
	if target != null and is_instance_valid(target):
		obstacles.append_array(target.find_children("*", "NavigationObstacle2D", true, false))
	for obstacle_variant: Node in obstacles:
		var obstacle: NavigationObstacle2D = obstacle_variant as NavigationObstacle2D
		if obstacle == null or not obstacle.avoidance_enabled:
			continue
		var required_clearance: float = target_position.distance_to(obstacle.global_position) \
			+ obstacle.radius + player_radius + INTERACTION_CLEARANCE_MARGIN
		safe_distance = maxf(safe_distance, required_clearance)
	return safe_distance


func has_pending_player_interaction() -> bool:
	return not _pending_player_interaction.is_empty()


func set_camera_follow_enabled(enabled: bool, snap_to_player: bool = false) -> void:
	_camera_follow_enabled = enabled
	if enabled and snap_to_player and main_camera != null and player_avatar != null and is_instance_valid(player_avatar):
		main_camera.position = player_avatar.global_position


func is_camera_follow_enabled() -> bool:
	return _camera_follow_enabled


func _process_camera_follow(delta: float) -> void:
	if not _camera_follow_enabled or main_camera == null or player_avatar == null or not is_instance_valid(player_avatar):
		return
	var weight: float = clampf(maxf(camera_follow_speed, 0.1) * delta, 0.0, 1.0)
	main_camera.position = main_camera.position.lerp(player_avatar.global_position, weight)


func _process_pending_player_interaction() -> void:
	if _player_movement_is_blocked_by_context():
		_cancel_pending_player_interaction(true)
		return
	if str(_pending_player_interaction.get("action_signature", "")) != _get_player_action_signature():
		_cancel_pending_player_interaction(true)
		return

	var target_ref: WeakRef = _pending_player_interaction.get("target_ref") as WeakRef
	var target: Object = target_ref.get_ref() if target_ref != null else null
	var callback: Callable = _pending_player_interaction.get("callback", Callable())
	if target == null or not is_instance_valid(target) or not callback.is_valid():
		_cancel_pending_player_interaction(true)
		return

	var target_position: Vector2 = _pending_player_interaction.get("target_position", player_avatar.global_position)
	var interaction_distance: float = float(_pending_player_interaction.get("interaction_distance", 48.0))
	if player_avatar.global_position.distance_to(target_position) <= interaction_distance:
		_pending_player_interaction.clear()
		if player_avatar.has_method("stop_moving"):
			player_avatar.call("stop_moving")
		_clear_player_destination_marker()
		callback.call()
		return

	if player_avatar.has_method("has_active_destination") and not bool(player_avatar.call("has_active_destination")):
		_cancel_pending_player_interaction(false)


func _cancel_pending_player_interaction(stop_player: bool) -> void:
	_pending_player_interaction.clear()
	_clear_player_destination_marker()
	if stop_player and player_avatar != null and is_instance_valid(player_avatar) and player_avatar.has_method("stop_moving"):
		player_avatar.call("stop_moving")


func _show_player_destination_marker(world_position: Vector2, interaction: bool) -> void:
	if player_destination_marker != null and player_destination_marker.has_method("show_destination"):
		player_destination_marker.call("show_destination", world_position, interaction)


func _clear_player_destination_marker() -> void:
	if player_destination_marker != null and player_destination_marker.visible and player_destination_marker.has_method("clear_destination"):
		player_destination_marker.call("clear_destination")


func _get_player_action_signature() -> String:
	var active_tool: int = int(ToolManager.ToolType.NONE)
	var tool_manager: Node = get_tree().root.get_node_or_null("ToolManager")
	if tool_manager != null and tool_manager.has_method("get_active_tool"):
		active_tool = int(tool_manager.call("get_active_tool"))
	return "%d|%s" % [active_tool, GlobalInventory.semente_selecionada]


func _world_position_has_interaction_collider(world_position: Vector2) -> bool:
	if not is_inside_tree() or get_world_2d() == null:
		return false

	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_point(query, 16)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or not is_instance_valid(collider):
			continue
		if collider == player_avatar:
			continue
		if collider is Node and player_avatar.is_ancestor_of(collider as Node):
			continue
		return true
	return false




func _criar_farm_plot_base(start_x: float, start_y: float) -> void:

	for x in range(BASE_FARM_COLUMNS):

		for y in range(BASE_FARM_ROWS):

			_instanciar_farm_plot(x, y, start_x, start_y)



func _criar_farm_plot_extras_direita(start_x: float, start_y: float) -> void:

	for x in range(BASE_FARM_COLUMNS, BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT):

		for y in range(BASE_FARM_ROWS):

			_instanciar_farm_plot(x, y, start_x, start_y)



func _criar_farm_plot_extras_inferiores(start_x: float, start_y: float) -> void:

	for x in range(BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT):

		for y in range(BASE_FARM_ROWS, BASE_FARM_ROWS + EXTRA_FARM_ROWS_BOTTOM):

			_instanciar_farm_plot(x, y, start_x, start_y)



func _instanciar_farm_plot(grid_x: int, grid_y: int, start_x: float, start_y: float) -> Node2D:
	var plot_existente: Node2D = _obter_farm_plot_registrado(grid_x, grid_y)
	if plot_existente != null:
		return plot_existente

	var plot: Node2D = farm_plot_scene.instantiate()

	plot.position = Vector2(start_x + (grid_x * FARM_SPACING), start_y + (grid_y * FARM_SPACING))

	plot.name = "FarmPlot_%d_%d" % [grid_x, grid_y]

	add_child(plot)

	_registrar_farm_plot(grid_x, grid_y, plot)

	return plot


func _farm_plot_key(grid_x: int, grid_y: int) -> Vector2i:

	return Vector2i(grid_x, grid_y)


func _registrar_farm_plot(grid_x: int, grid_y: int, plot: Node2D) -> bool:

	if plot == null or not is_instance_valid(plot):
		return false

	var key: Vector2i = _farm_plot_key(grid_x, grid_y)
	var plot_existente: Node2D = _obter_farm_plot_registrado(grid_x, grid_y)
	if plot_existente != null and plot_existente != plot:
		push_error(
			"Main: coordenada agricola %s ja pertence ao plot %s; registro duplicado de %s recusado."
			% [key, plot_existente.name, plot.name]
		)
		return false

	for registered_key_variant in farm_plot_registry.keys():
		if typeof(registered_key_variant) != TYPE_VECTOR2I:
			continue
		var registered_key: Vector2i = registered_key_variant
		if registered_key == key:
			continue
		if farm_plot_registry.get(registered_key_variant) == plot:
			push_error(
				"Main: plot %s ja esta registrado na coordenada agricola %s; novo registro em %s recusado."
				% [plot.name, registered_key, key]
			)
			return false

	farm_plot_registry[key] = plot
	if plot.has_signal("estado_alterado"):
		var callback := Callable(self, "_on_farm_plot_estado_alterado")
		if not plot.is_connected("estado_alterado", callback):
			plot.connect("estado_alterado", callback)

	var tree_exiting_callback := Callable(self, "_on_farm_plot_tree_exiting").bind(grid_x, grid_y, plot)
	if not plot.tree_exiting.is_connected(tree_exiting_callback):
		plot.tree_exiting.connect(tree_exiting_callback)
	return true


func _on_farm_plot_estado_alterado() -> void:
	_reconstruir_farm_grid_manager()


func _on_farm_plot_tree_exiting(grid_x: int, grid_y: int, plot: Node2D) -> void:
	if _region_being_cached:
		return
	_desregistrar_farm_plot(grid_x, grid_y, plot)


func _desregistrar_farm_plot(grid_x: int, grid_y: int, plot: Node2D) -> bool:
	var key: Vector2i = _farm_plot_key(grid_x, grid_y)
	if not farm_plot_registry.has(key):
		return false

	if farm_plot_registry.get(key) != plot:
		return false

	farm_plot_registry.erase(key)
	if farm_grid_manager != null:
		farm_grid_manager.remove_tile(Vector2i(grid_x, grid_y))
	return true


func _obter_farm_plot_registrado(grid_x: int, grid_y: int) -> Node2D:

	var key: Vector2i = _farm_plot_key(grid_x, grid_y)

	if not farm_plot_registry.has(key):
		return null


	var plot_variant: Variant = farm_plot_registry.get(key)

	if plot_variant is Node2D and is_instance_valid(plot_variant):
		return plot_variant

	farm_plot_registry.erase(key)
	return null


func _obter_ou_criar_farm_plot(grid_x: int, grid_y: int, start_x: float, start_y: float) -> Node2D:

	var plot: Node2D = _obter_farm_plot_registrado(grid_x, grid_y)

	if plot != null:
		return plot

	plot = farm_plot_scene.instantiate()
	plot.position = Vector2(start_x + (grid_x * FARM_SPACING), start_y + (grid_y * FARM_SPACING))
	plot.name = "FarmPlot_%d_%d" % [grid_x, grid_y]
	add_child(plot)
	_registrar_farm_plot(grid_x, grid_y, plot)
	_sincronizar_farm_grid_manager_com_plot(Vector2i(grid_x, grid_y), plot)
	return plot


func _tile_grid_esta_bloqueado(grid_position: Vector2i) -> bool:
	if grid_position == Vector2i(-1, -1):
		return false

	_garantir_farm_grid_manager()
	var manager: FarmGridManager = farm_grid_manager
	if manager == null or not manager.has_tile(grid_position):
		return false

	var tile: FarmTileData = manager.get_tile(grid_position)
	if tile == null:
		return false

	return tile.tile_state == FarmTileData.TileState.BLOQUEADO


func obter_farm_grid_manager() -> FarmGridManager:
	return obter_farm_grid_snapshot()


func obter_farm_grid_snapshot() -> FarmGridManager:
	_garantir_farm_grid_manager()
	var snapshot := FarmGridManager.new()
	if farm_grid_manager != null:
		snapshot.load_save_data(farm_grid_manager.to_save_data())
	return snapshot


func obter_farm_grid_save_data() -> Dictionary:
	_garantir_farm_grid_manager()
	if farm_grid_manager == null:
		return {}
	return farm_grid_manager.to_save_data()


func obter_farm_plot_por_grid_position(grid_position: Vector2i) -> Node2D:
	return _obter_farm_plot_registrado(grid_position.x, grid_position.y)


func garantir_farm_plot_por_grid_position(grid_position: Vector2i) -> Node2D:
	if farm_origin == Vector2.ZERO:
		return null

	return _obter_ou_criar_farm_plot(
		grid_position.x,
		grid_position.y,
		farm_origin.x,
		farm_origin.y
	)



func _converter_posicao_global_em_grid(global_position: Vector2) -> Vector2i:

	if farm_origin == Vector2.ZERO:
		return Vector2i(-1, -1)

	var relative_position: Vector2 = global_position - farm_origin
	var grid_x: int = int(round(relative_position.x / float(FARM_SPACING)))
	var grid_y: int = int(round(relative_position.y / float(FARM_SPACING)))
	return Vector2i(grid_x, grid_y)


func _converter_grid_em_posicao_global(grid_position: Vector2i) -> Vector2:
	return farm_origin + Vector2(grid_position) * float(FARM_SPACING)


func avaliar_solo_para_arar(global_position: Vector2) -> Dictionary:
	if farm_origin == Vector2.ZERO:
		return SoilValidityPolicy.evaluate(Vector2i.ZERO, {"farm_ready": false})

	return avaliar_grid_para_arar(_converter_posicao_global_em_grid(global_position))


func avaliar_grid_para_arar(grid_position: Vector2i) -> Dictionary:
	var existing_plot: Node2D = _obter_farm_plot_registrado(grid_position.x, grid_position.y)
	var tile_is_blocked: bool = _tile_grid_esta_bloqueado(grid_position)
	var blockers: Dictionary = {
		"water": false,
		"building": false,
		"obstacle": false,
		"corruption": false,
	}
	if existing_plot == null:
		blockers = _obter_bloqueios_solo_na_celula(grid_position)

	return SoilValidityPolicy.evaluate(grid_position, {
		"farm_ready": farm_origin != Vector2.ZERO,
		"has_existing_plot": existing_plot != null,
		"inside_cultivable_bounds": cultivable_grid_bounds.has_point(grid_position),
		"is_corrupted": tile_is_blocked or bool(blockers.get("corruption", false)),
		"requires_purification": bool(blockers.get("corruption", false)),
		"is_area_purified": not bool(blockers.get("corruption", false)),
		"has_water": bool(blockers.get("water", false)),
		"has_building": bool(blockers.get("building", false)),
		"has_obstacle": bool(blockers.get("obstacle", false)),
		"is_reserved_zone": _grid_esta_em_zona_cultivo_reservada(grid_position),
	})


func pode_arar_em_posicao_global(global_position: Vector2) -> bool:
	return bool(avaliar_solo_para_arar(global_position).get("valid", false))


func avaliar_agricultura_livre(global_position: Vector2) -> Dictionary:
	var evaluation: Dictionary = avaliar_solo_para_arar(global_position)
	if not bool(evaluation.get("valid", false)):
		return evaluation

	var grid_position: Vector2i = evaluation.get("grid_position", Vector2i.ZERO)
	if _obter_farm_plot_registrado(grid_position.x, grid_position.y) != null:
		return evaluation
	if free_farming_pilot_bounds.has_point(grid_position):
		return evaluation

	evaluation["valid"] = false
	evaluation["reason"] = FREE_FARMING_REASON_OUTSIDE_PILOT
	return evaluation


func tentar_arar_agricultura_livre(global_position: Vector2, show_feedback: bool = true) -> Dictionary:
	var evaluation: Dictionary = avaliar_agricultura_livre(global_position)
	evaluation["created"] = false
	evaluation["prepared"] = false

	if not _enxada_esta_ativa():
		evaluation["valid"] = false
		evaluation["reason"] = FREE_FARMING_REASON_HOE_REQUIRED
		if show_feedback:
			_mostrar_feedback_agricultura_livre(evaluation, global_position)
		return evaluation

	if not bool(evaluation.get("valid", false)):
		if show_feedback:
			_mostrar_feedback_agricultura_livre(evaluation, global_position)
		return evaluation

	var grid_position: Vector2i = evaluation.get("grid_position", Vector2i.ZERO)
	var plot: Node2D = _obter_farm_plot_registrado(grid_position.x, grid_position.y)
	var created: bool = plot == null
	if plot == null:
		plot = _obter_ou_criar_farm_plot(grid_position.x, grid_position.y, farm_origin.x, farm_origin.y)

	if plot == null or not plot.has_method("tentar_arar"):
		evaluation["valid"] = false
		evaluation["reason"] = FREE_FARMING_REASON_PREPARATION_FAILED
		if show_feedback:
			_mostrar_feedback_agricultura_livre(evaluation, global_position)
		return evaluation

	var prepared: bool = bool(plot.call("tentar_arar", show_feedback))
	evaluation["created"] = created
	evaluation["prepared"] = prepared
	evaluation["plot"] = plot
	_reconstruir_farm_grid_manager()
	return evaluation


func handle_hoe_world_click(global_position: Vector2) -> Dictionary:
	var grid_position: Vector2i = _converter_posicao_global_em_grid(global_position)
	var existing_plot: Node2D = _obter_farm_plot_registrado(grid_position.x, grid_position.y)
	if existing_plot != null:
		var accepted: bool = request_player_interaction(
			existing_plot,
			existing_plot.global_position,
			46.0,
			Callable(existing_plot, "_on_plot_clicked")
		)
		return {
			"handled": accepted,
			"existing_plot": true,
			"grid_position": grid_position,
			"plot": existing_plot,
		}
	var evaluation: Dictionary = tentar_arar_agricultura_livre(global_position)
	evaluation["handled"] = true
	evaluation["existing_plot"] = false
	return evaluation


func _enxada_esta_ativa() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var tool_manager: Node = tree.root.get_node_or_null("ToolManager")
	if tool_manager == null or not tool_manager.has_method("get_active_tool"):
		return false
	return int(tool_manager.call("get_active_tool")) == int(ToolManager.ToolType.HOE)


func _mostrar_feedback_agricultura_livre(evaluation: Dictionary, global_position: Vector2) -> void:
	var reason: String = str(evaluation.get("reason", ""))
	var message: String = "Nao e possivel arar aqui."
	match reason:
		FREE_FARMING_REASON_OUTSIDE_PILOT:
			message = "Cultivo livre disponivel no terreno ao sul dos lotes."
		FREE_FARMING_REASON_HOE_REQUIRED:
			message = "Selecione a Enxada."
		SoilValidityPolicy.REASON_OUTSIDE_CULTIVABLE_BOUNDS:
			message = "Este terreno nao e cultivavel."
		SoilValidityPolicy.REASON_CORRUPTED:
			message = "Purifique esta area antes de cultivar."
		SoilValidityPolicy.REASON_WATER:
			message = "Nao e possivel arar a agua."
		SoilValidityPolicy.REASON_BUILDING:
			message = "Ha uma construcao neste espaco."
		SoilValidityPolicy.REASON_OBSTACLE:
			message = "Ha um obstaculo neste espaco."
		SoilValidityPolicy.REASON_RESERVED_ZONE:
			message = "Esta area esta reservada."

	var ui: Node = get_node_or_null("UI")
	if ui != null and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", message, global_position + Vector2(0.0, -28.0), Color(1.0, 0.78, 0.48, 1.0))
	else:
		print(message)


func _grid_esta_em_zona_cultivo_reservada(grid_position: Vector2i) -> bool:
	for reserved_area in reserved_cultivation_grid_areas:
		if reserved_area.has_point(grid_position):
			return true
	return false


func _obter_bloqueios_solo_na_celula(grid_position: Vector2i) -> Dictionary:
	var blockers: Dictionary = {
		"water": false,
		"building": false,
		"obstacle": false,
		"corruption": false,
	}

	var world_2d: World2D = get_world_2d()
	if world_2d == null:
		return blockers

	var space_state: PhysicsDirectSpaceState2D = world_2d.direct_space_state
	if space_state == null:
		return blockers

	var cell_shape := RectangleShape2D.new()
	cell_shape.size = Vector2.ONE * (float(FARM_SPACING) * 0.8)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = cell_shape
	query.transform = Transform2D(0.0, _converter_grid_em_posicao_global(grid_position))
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
	for result in results:
		var collider_variant: Variant = result.get("collider")
		if collider_variant is not Node:
			continue
		var collider: Node = collider_variant
		if _node_ou_ancestral_no_grupo(collider, "lotes_terra") or _node_ou_ancestral_eh_personagem(collider):
			continue
		if _node_ou_ancestral_no_grupo(collider, "fishing_spot"):
			blockers["water"] = true
		elif _node_ou_ancestral_no_grupo(collider, "purification_obstacle"):
			blockers["corruption"] = true
		elif _node_ou_ancestral_no_grupo(collider, "cauldrons") or _node_ou_ancestral_no_grupo(collider, "village_chest"):
			blockers["building"] = true
		else:
			blockers["obstacle"] = true

	return blockers


func _node_ou_ancestral_no_grupo(node: Node, group_name: StringName) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		if current == self:
			break
		current = current.get_parent()
	return false


func _node_ou_ancestral_eh_personagem(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is CharacterBody2D:
			return true
		if current == self:
			break
		current = current.get_parent()
	return false



func _registrar_area_expansao_v0(start_x: float, start_y: float) -> void:

	if expansion_area_configs.has(EXPANSION_V0_OBSTACLE_ID):

		return



	expansion_area_order.append(EXPANSION_V0_OBSTACLE_ID)

	expansion_area_configs[EXPANSION_V0_OBSTACLE_ID] = {

		"obstacle_id": EXPANSION_V0_OBSTACLE_ID,

		"visual_name": "BlockedAreaVisual",

		"visual_position": Vector2(

			start_x + ((EXPANSION_POCKET_START_COLUMN + 0.5) * float(FARM_SPACING)),

			start_y + ((EXPANSION_POCKET_START_ROW + 0.7) * float(FARM_SPACING))

		),

		"pocket_start_column": EXPANSION_POCKET_START_COLUMN,

		"pocket_start_row": EXPANSION_POCKET_START_ROW,

		"pocket_columns": EXPANSION_POCKET_COLUMNS,

		"pocket_rows": EXPANSION_POCKET_ROWS

	}



func _garantir_areas_expansao(start_x: float, start_y: float) -> void:

	for obstacle_id in expansion_area_order:

		_garantir_area_expansao(obstacle_id, start_x, start_y)



func _garantir_area_expansao(obstacle_id: String, start_x: float, start_y: float) -> void:

	var area_config: Dictionary = _obter_config_area_expansao(obstacle_id)

	if area_config.is_empty():

		return



	if not expansion_area_visuals.has(obstacle_id):

		var visual: Node2D = _criar_area_bloqueada_visual()

		if visual != null:

			visual.name = str(area_config.get("visual_name", "BlockedAreaVisual"))

			visual.position = area_config.get("visual_position", Vector2.ZERO)

			expansion_area_visuals[obstacle_id] = visual

			add_child(visual)



	if not expansion_area_plots.has(obstacle_id):

		var area_plots: Array = _criar_pocket_expansao(obstacle_id, start_x, start_y)

		expansion_area_plots[obstacle_id] = area_plots



func _criar_pocket_expansao(obstacle_id: String, start_x: float, start_y: float) -> Array:

	var area_config: Dictionary = _obter_config_area_expansao(obstacle_id)

	var area_plots: Array = []

	if area_config.is_empty():

		return area_plots



	var pocket_start_column: int = int(area_config.get("pocket_start_column", 0))

	var pocket_start_row: int = int(area_config.get("pocket_start_row", 0))

	var pocket_columns: int = int(area_config.get("pocket_columns", 0))

	var pocket_rows: int = int(area_config.get("pocket_rows", 0))



	for x in range(pocket_columns):

		for y in range(pocket_rows):

			var grid_x: int = pocket_start_column + x

			var grid_y: int = pocket_start_row + y

			var plot: Node2D = _obter_farm_plot_registrado(grid_x, grid_y)
			if plot == null:
				plot = farm_plot_scene.instantiate()
				plot.position = Vector2(start_x + (grid_x * FARM_SPACING), start_y + (grid_y * FARM_SPACING))
				plot.name = "FarmPlot_%d_%d" % [grid_x, grid_y]
				add_child(plot)
				if not _registrar_farm_plot(grid_x, grid_y, plot):
					plot.queue_free()
					continue

			if plot.has_method("set_expansion_blocked"):

				plot.call("set_expansion_blocked", true)

			plot.visible = false

			area_plots.append(plot)



	return area_plots



func _obter_config_area_expansao(obstacle_id: String) -> Dictionary:

	if not expansion_area_configs.has(obstacle_id):

		return {}

	var area_config_variant: Variant = expansion_area_configs.get(obstacle_id, {})

	if typeof(area_config_variant) != TYPE_DICTIONARY:

		return {}

	return area_config_variant



func _criar_area_bloqueada_visual() -> Node2D:

	var bloqueio := Node2D.new()

	bloqueio.z_index = 36



	var sombra := Polygon2D.new()

	sombra.name = "BlockedAreaShadow"

	sombra.z_index = 0

	sombra.color = Color(0.160784, 0.054902, 0.2, 0.58)

	sombra.polygon = PackedVector2Array([

		Vector2(-98, -46),

		Vector2(-68, -90),

		Vector2(28, -96),

		Vector2(94, -48),

		Vector2(108, 10),

		Vector2(74, 66),

		Vector2(6, 96),

		Vector2(-78, 80),

		Vector2(-110, 26)

	])

	bloqueio.add_child(sombra)



	var raiz := Polygon2D.new()

	raiz.name = "BlockedAreaRoot"

	raiz.z_index = 1

	raiz.color = Color(0.317647, 0.133333, 0.4, 0.92)

	raiz.polygon = PackedVector2Array([

		Vector2(-74, -30),

		Vector2(-38, -68),

		Vector2(20, -74),

		Vector2(70, -36),

		Vector2(82, 14),

		Vector2(52, 58),

		Vector2(-6, 70),

		Vector2(-64, 44)

	])

	bloqueio.add_child(raiz)



	var cristal := Polygon2D.new()

	cristal.name = "BlockedAreaCrystal"

	cristal.position = Vector2(18, -8)

	cristal.z_index = 2

	cristal.color = Color(0.780392, 0.27451, 0.905882, 0.88)

	cristal.polygon = PackedVector2Array([

		Vector2(0, -32),

		Vector2(18, -14),

		Vector2(28, 0),

		Vector2(18, 16),

		Vector2(0, 32),

		Vector2(-18, 16),

		Vector2(-28, 0),

		Vector2(-18, -14)

	])

	bloqueio.add_child(cristal)



	var anel := Line2D.new()

	anel.name = "BlockedAreaRing"

	anel.z_index = 3

	anel.width = 7.0

	anel.default_color = Color(0.941176, 0.768627, 1.0, 0.85)

	anel.antialiased = true

	anel.closed = true

	anel.points = PackedVector2Array([

		Vector2(0, -52),

		Vector2(36, -34),

		Vector2(54, 0),

		Vector2(38, 38),

		Vector2(0, 54),

		Vector2(-38, 38),

		Vector2(-54, 0),

		Vector2(-36, -34)

	])

	bloqueio.add_child(anel)



	return bloqueio



func _criar_marcador_agricultura_livre() -> void:
	if not show_free_farming_pilot_marker or has_node("FreeFarmingPilotArea"):
		return

	var marker := Node2D.new()
	marker.name = "FreeFarmingPilotArea"
	marker.z_index = FREE_FARMING_PILOT_Z_INDEX
	marker.z_as_relative = false

	var area_size: Vector2 = Vector2(free_farming_pilot_bounds.size) * float(FARM_SPACING)
	var first_cell_center: Vector2 = _converter_grid_em_posicao_global(free_farming_pilot_bounds.position)
	marker.position = first_cell_center + (area_size - Vector2.ONE * float(FARM_SPACING)) * 0.5

	var fill := Polygon2D.new()
	fill.name = "Fill"
	fill.color = Color(0.27451, 0.619608, 0.321569, 0.10)
	fill.polygon = _criar_poligono_retangular(area_size - Vector2(8.0, 8.0))
	marker.add_child(fill)

	var outline := Line2D.new()
	outline.name = "Outline"
	outline.width = 3.0
	outline.default_color = Color(0.643137, 0.905882, 0.52549, 0.78)
	outline.antialiased = true
	outline.closed = true
	outline.points = _criar_pontos_retangulo(area_size - Vector2(8.0, 8.0))
	marker.add_child(outline)

	var label := Label.new()
	label.name = "Label"
	label.text = "Area de cultivo livre"
	label.position = Vector2(-area_size.x * 0.5, -area_size.y * 0.5 - 32.0)
	label.size = Vector2(area_size.x, 26.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = Color(0.811765, 0.968627, 0.709804, 0.92)
	marker.add_child(label)

	add_child(marker)


func _criar_blockout_fazenda_v0(start_x: float, start_y: float) -> void:

	if has_node("FarmBlockoutV0"):

		return



	var blockout_root := Node2D.new()

	blockout_root.name = "FarmBlockoutV0"

	blockout_root.z_index = BLOCKOUT_FARM_Z_INDEX

	blockout_root.z_as_relative = false
	add_child(blockout_root)
	blockout_root.add_child(_criar_envelope_macro_fazenda(Vector2(start_x + (2.6 * FARM_SPACING), start_y + (2.5 * FARM_SPACING)), Vector2(2400, 1600)))

	var zonas: Array = [
			{
				"id": "initial_hub",
				"title": "Área inicial",
				"subtitle": "Caldeirão central / praça aberta",
				"center": Vector2(start_x + (2.8 * FARM_SPACING), start_y + (1.6 * FARM_SPACING)),
				"size": Vector2(340, 220),
				"fill": Color(0.431373, 0.329412, 0.172549, 0.3),
				"outline": Color(0.972549, 0.898039, 0.694118, 0.78)
			},
			{
				"id": "initial_logistics_side",
				"title": "Baú / logística",
				"subtitle": "Lado de apoio do núcleo inicial",
				"center": Vector2(start_x - (5.8 * FARM_SPACING), start_y + (4.8 * FARM_SPACING)),
				"size": Vector2(210, 140),
				"fill": Color(0.439216, 0.278431, 0.133333, 0.28),
				"outline": Color(0.988235, 0.815686, 0.619608, 0.72)
			},
			{
				"id": "initial_arrival_side",
				"title": "Abrigo / chegada",
				"subtitle": "Marco cenográfico da vila",
				"center": Vector2(start_x + (8.1 * FARM_SPACING), start_y + (0.2 * FARM_SPACING)),
				"size": Vector2(220, 146),
				"fill": Color(0.219608, 0.309804, 0.372549, 0.26),
				"outline": Color(0.74902, 0.858824, 0.941176, 0.72)
			},
			{
				"id": "fishing_lake",
				"title": "Lago / pesca",
				"subtitle": "Ponto especial de pesca",
				"center": Vector2(start_x + (6.6 * FARM_SPACING), start_y - (2.6 * FARM_SPACING)),
				"size": Vector2(280, 180),
				"fill": Color(0.109804, 0.529412, 0.752941, 0.28),
				"outline": Color(0.843137, 0.960784, 1.0, 0.78)
			},
			{
				"id": "creatures_animals_future",
				"title": "Criaturas mágicas",
				"subtitle": "Animais e aliados encantados",
				"center": Vector2(start_x + (10.4 * FARM_SPACING), start_y - (1.4 * FARM_SPACING)),
				"size": Vector2(220, 140),
				"fill": Color(0.160784, 0.356863, 0.258824, 0.3),
				"outline": Color(0.690196, 0.882353, 0.741176, 0.68)
			},
			{
				"id": "helpers_golems_future",
				"title": "Golems / ajudantes",
				"subtitle": "Área de apoio da fazenda",
				"center": Vector2(start_x - (1.9 * FARM_SPACING), start_y + (5.2 * FARM_SPACING)),
				"size": Vector2(190, 128),
				"fill": Color(0.294118, 0.184314, 0.454902, 0.28),
				"outline": Color(0.843137, 0.713726, 0.976471, 0.68)
			},
			{
				"id": "foraging_resources_future",
				"title": "Recursos / forrageamento",
				"subtitle": "Área de coleta natural",
				"center": Vector2(start_x + (11.1 * FARM_SPACING), start_y + (5.2 * FARM_SPACING)),
				"size": Vector2(230, 146),
				"fill": Color(0.486275, 0.333333, 0.113725, 0.28),
				"outline": Color(0.988235, 0.878431, 0.619608, 0.68)
			},
			{
				"id": "blocked_area_future",
				"title": "Corrupção futura",
				"subtitle": "Segunda área corrompida",
				"center": Vector2(start_x + (11.8 * FARM_SPACING), start_y + (1.4 * FARM_SPACING)),
				"size": Vector2(220, 140),
				"fill": Color(0.337255, 0.121569, 0.454902, 0.32),
				"outline": Color(0.94902, 0.760784, 1.0, 0.72)
			},
			{
				"id": "ruin_mystery_future",
				"title": "Ruína / mistério",
				"subtitle": "Zona de enigma futuro",
				"center": Vector2(start_x + (12.9 * FARM_SPACING), start_y + (6.3 * FARM_SPACING)),
				"size": Vector2(230, 146),
				"fill": Color(0.184314, 0.184314, 0.227451, 0.26),
				"outline": Color(0.823529, 0.831373, 0.87451, 0.64)
			}

	]



	for zona in zonas:

		var marcador: Node2D = _criar_marcador_zona(

			str(zona.get("id", "zona_futura")),

			str(zona.get("title", "Zona futura")),

			str(zona.get("subtitle", "")),

			zona.get("center", Vector2.ZERO),

			zona.get("size", Vector2(200, 120)),

			zona.get("fill", Color(1, 1, 1, 0.35)),

			zona.get("outline", Color(1, 1, 1, 0.85))

		)

		blockout_root.add_child(marcador)



func _criar_marcador_zona(zona_id: String, titulo: String, subtitulo: String, centro: Vector2, tamanho: Vector2, fill_color: Color, outline_color: Color) -> Node2D:

	var marcador := Node2D.new()

	marcador.name = "Blockout_%s" % zona_id

	marcador.position = centro

	marcador.z_index = BLOCKOUT_FARM_Z_INDEX

	marcador.z_as_relative = false



	var sombra := Polygon2D.new()

	sombra.name = "Sombra"

	sombra.color = Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * 0.32)

	sombra.polygon = _criar_poligono_retangular(tamanho + Vector2(30, 24))

	sombra.position = Vector2(8, 10)

	marcador.add_child(sombra)



	var corpo := Polygon2D.new()

	corpo.name = "Corpo"

	corpo.color = fill_color

	corpo.polygon = _criar_poligono_retangular(tamanho)

	marcador.add_child(corpo)



	var contorno := Line2D.new()

	contorno.name = "Contorno"

	contorno.width = 3.0

	contorno.default_color = outline_color

	contorno.closed = true

	contorno.antialiased = true

	contorno.points = _criar_pontos_retangulo(tamanho)

	marcador.add_child(contorno)



	var detalhe_horizontal := Line2D.new()

	detalhe_horizontal.name = "DetalheHorizontal"

	detalhe_horizontal.width = 1.5

	detalhe_horizontal.default_color = Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.42)

	detalhe_horizontal.points = PackedVector2Array([

		Vector2(-tamanho.x * 0.35, 0),

		Vector2(tamanho.x * 0.35, 0)

	])

	marcador.add_child(detalhe_horizontal)



	var detalhe_vertical := Line2D.new()

	detalhe_vertical.name = "DetalheVertical"

	detalhe_vertical.width = 1.5

	detalhe_vertical.default_color = Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.34)

	detalhe_vertical.points = PackedVector2Array([

		Vector2(0, -tamanho.y * 0.32),

		Vector2(0, tamanho.y * 0.32)

	])

	marcador.add_child(detalhe_vertical)



	var etiqueta := Label.new()

	etiqueta.name = "Etiqueta"

	etiqueta.text = titulo + "\n" + subtitulo

	etiqueta.position = Vector2(-tamanho.x * 0.5, -tamanho.y * 0.5 - 48)

	etiqueta.size = Vector2(tamanho.x, 70)

	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	etiqueta.add_theme_font_size_override("font_size", 15)

	etiqueta.add_theme_color_override("font_color", outline_color)

	etiqueta.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))

	etiqueta.add_theme_constant_override("shadow_offset_x", 2)

	etiqueta.add_theme_constant_override("shadow_offset_y", 2)

	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	marcador.add_child(etiqueta)



	return marcador


func _criar_envelope_macro_fazenda(centro: Vector2, tamanho: Vector2) -> Node2D:

	var envelope := Node2D.new()

	envelope.name = "FarmEnvelopeMacro"
	envelope.position = centro
	envelope.z_index = BLOCKOUT_FARM_Z_INDEX - 1
	envelope.z_as_relative = false

	var sombra := Polygon2D.new()
	sombra.name = "Sombra"
	sombra.color = Color(0.160784, 0.168627, 0.152941, 0.04)
	sombra.polygon = _criar_poligono_retangular(tamanho + Vector2(36, 28))
	sombra.position = Vector2(10, 12)
	envelope.add_child(sombra)

	var corpo := Polygon2D.new()
	corpo.name = "Corpo"
	corpo.color = Color(0.160784, 0.168627, 0.152941, 0.05)
	corpo.polygon = _criar_poligono_retangular(tamanho)
	envelope.add_child(corpo)

	var contorno := Line2D.new()
	contorno.name = "Contorno"
	contorno.width = 5.0
	contorno.default_color = Color(0.611765, 0.682353, 0.588235, 0.26)
	contorno.closed = true
	contorno.antialiased = true
	contorno.points = _criar_pontos_retangulo(tamanho)
	envelope.add_child(contorno)

	return envelope


func _criar_poligono_retangular(tamanho: Vector2) -> PackedVector2Array:

	var meio_x: float = tamanho.x * 0.5

	var meio_y: float = tamanho.y * 0.5

	return PackedVector2Array([

		Vector2(-meio_x, -meio_y),

		Vector2(meio_x, -meio_y),

		Vector2(meio_x, meio_y),

		Vector2(-meio_x, meio_y)

	])



func _criar_pontos_retangulo(tamanho: Vector2) -> PackedVector2Array:

	var pontos := _criar_poligono_retangular(tamanho)

	pontos.append(pontos[0])

	return pontos



func _conectar_obstaculos_purificacao() -> void:

	var tree: SceneTree = get_tree()

	if tree == null:

		return



	var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

	for obstaculo_variant in obstaculos:

		var obstaculo: Node = obstaculo_variant

		if obstaculo == null or not is_instance_valid(obstaculo):

			continue

		if not obstaculo.has_signal("purified"):

			continue

		if not obstaculo.is_connected("purified", Callable(self, "_on_obstaculo_purificado")):

			obstaculo.connect("purified", Callable(self, "_on_obstaculo_purificado"))



func _obter_estado_purificacao_obstaculo(obstacle_id: String) -> bool:

	var obstaculo: Node = _obter_obstaculo_purificacao_por_id(obstacle_id)

	if obstaculo == null or not obstaculo.has_method("get_save_data"):

		return false



	var obstacle_data_variant: Variant = obstaculo.call("get_save_data")

	if typeof(obstacle_data_variant) != TYPE_DICTIONARY:

		return false



	return bool((obstacle_data_variant as Dictionary).get("purified", false))



func _obter_obstaculo_purificacao_por_id(obstacle_id: String) -> Node:

	if obstacle_id == "":

		return null



	var tree: SceneTree = get_tree()

	if tree == null:

		return null



	var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

	for obstaculo_variant in obstaculos:

		var obstaculo: Node = obstaculo_variant

		if obstaculo == null or not is_instance_valid(obstaculo):

			continue

		if obstaculo.has_method("get_obstacle_id"):

			if str(obstaculo.call("get_obstacle_id")) == obstacle_id:

				return obstaculo

		elif obstaculo.name == obstacle_id:

			return obstaculo



	return null



func _aplicar_estado_area_expansao(obstacle_id: String, purificado: bool) -> void:

	if obstacle_id == "":

		return



	if expansion_area_visuals.has(obstacle_id):

		var visual: Node = expansion_area_visuals[obstacle_id]

		if visual != null and is_instance_valid(visual):

			visual.visible = not purificado



	if expansion_area_plots.has(obstacle_id):

		var area_plots: Array = expansion_area_plots[obstacle_id]

		for plot_variant in area_plots:

			var plot: Node = plot_variant

			if plot == null or not is_instance_valid(plot):

				continue

			if plot.has_method("set_expansion_blocked"):

				plot.call("set_expansion_blocked", not purificado)

	if lore_discoveries.has(obstacle_id):
		var lore_discovery: Node = lore_discoveries[obstacle_id]
		if lore_discovery != null and is_instance_valid(lore_discovery) and lore_discovery.has_method("set_area_purified"):
			lore_discovery.call("set_area_purified", purificado)

	if restoration_projects.has(obstacle_id):
		var restoration_project: Node = restoration_projects[obstacle_id]
		if restoration_project != null and is_instance_valid(restoration_project) and restoration_project.has_method("set_area_purified"):
			restoration_project.call("set_area_purified", purificado)

	_reconstruir_farm_grid_manager()



func _sincronizar_areas_expansao() -> void:

	for obstacle_id in expansion_area_order:

		_aplicar_estado_area_expansao(obstacle_id, _obter_estado_purificacao_obstaculo(obstacle_id))



func sincronizar_area_bloqueada_v0() -> void:

	_sincronizar_areas_expansao()



func _on_obstaculo_purificado(obstacle_id: String) -> void:

	if obstacle_id == "":

		return

	_aplicar_estado_area_expansao(obstacle_id, true)

func _garantir_primeira_descoberta_lore() -> void:
	if lore_discoveries.has(EXPANSION_V0_OBSTACLE_ID):
		return
	var lore_scene := load("res://Scenes/LoreDiscovery.tscn") as PackedScene
	if lore_scene == null:
		push_warning("Main: cena de descoberta de lore nao foi encontrada.")
		return
	var discovery := lore_scene.instantiate() as Area2D
	if discovery == null:
		return
	var area_config := _obter_config_area_expansao(EXPANSION_V0_OBSTACLE_ID)
	discovery.name = "LoreDiscovery_FirstPurifiedArea"
	discovery.position = Vector2(area_config.get("visual_position", Vector2.ZERO)) + Vector2(54.0, -36.0)
	add_child(discovery)
	lore_discoveries[EXPANSION_V0_OBSTACLE_ID] = discovery
	discovery.call("set_area_purified", _obter_estado_purificacao_obstaculo(EXPANSION_V0_OBSTACLE_ID))


func _garantir_primeiro_projeto_restauracao() -> void:
	if restoration_projects.has(EXPANSION_V0_OBSTACLE_ID):
		return
	var restoration_scene := load(RESTORATION_PROJECT_SCENE_PATH) as PackedScene
	if restoration_scene == null:
		push_warning("Main: cena do projeto de restauracao nao foi encontrada.")
		return
	var project := restoration_scene.instantiate() as Area2D
	if project == null:
		return
	var area_config := _obter_config_area_expansao(EXPANSION_V0_OBSTACLE_ID)
	project.name = "RestorationProject_FirstHerbarium"
	# Fica ao lado do pocket 2x2: projeto e lotes nunca disputam o mesmo clique.
	project.position = Vector2(area_config.get("visual_position", Vector2.ZERO)) + Vector2(180.0, 110.0)
	add_child(project)
	restoration_projects[EXPANSION_V0_OBSTACLE_ID] = project
	project.call("set_area_purified", _obter_estado_purificacao_obstaculo(EXPANSION_V0_OBSTACLE_ID))

func _garantir_lago_da_fazenda() -> void:

	var fishing_spot_node: Node = get_node_or_null("FishingSpot")

	var fishing_spot: Node2D = null



	if fishing_spot_node != null:

		fishing_spot = fishing_spot_node as Node2D

	else:

		var fishing_spot_scene: Resource = load(FISHING_SPOT_SCENE_PATH)

		if fishing_spot_scene is PackedScene:

			fishing_spot = (fishing_spot_scene as PackedScene).instantiate() as Node2D

		if fishing_spot == null:

			push_warning("Main: FishingSpot.tscn nao carregou; usando fallback em runtime.")

			fishing_spot = _criar_lago_da_fazenda_fallback()

		if fishing_spot == null:

			push_warning("Main: nao foi possivel criar o lago da fazenda.")

			return

		fishing_spot.name = "FishingSpot"

		add_child(fishing_spot)



	if fishing_spot == null:

		push_warning("Main: FishingSpot nao eh um Node2D valido.")

		return



	fishing_spot.position = FISHING_SPOT_POSITION

	fishing_spot.visible = true

	fishing_spot.z_index = FISHING_SPOT_Z_INDEX



func _criar_lago_da_fazenda_fallback() -> Node2D:

	var fishing_spot := Area2D.new()

	var fishing_spot_script: Script = load(FISHING_SPOT_SCRIPT_PATH) as Script

	if fishing_spot_script != null:

		fishing_spot.set_script(fishing_spot_script)



	fishing_spot.input_pickable = true

	fishing_spot.z_index = FISHING_SPOT_Z_INDEX



	var lake_glow := Polygon2D.new()

	lake_glow.name = "LakeGlow"

	lake_glow.z_index = 19

	lake_glow.color = Color(0.0862745, 0.509804, 0.784314, 0.45)

	lake_glow.polygon = PackedVector2Array([

		Vector2(-170, -45),

		Vector2(-125, -105),

		Vector2(80, -110),

		Vector2(165, -35),

		Vector2(150, 55),

		Vector2(60, 110),

		Vector2(-70, 110),

		Vector2(-170, 45)

	])

	fishing_spot.add_child(lake_glow)



	var lake_visual := Polygon2D.new()

	lake_visual.name = "LakeVisual"

	lake_visual.z_index = 20

	lake_visual.color = Color(0.12549, 0.705882, 0.921569, 0.96)

	lake_visual.polygon = PackedVector2Array([

		Vector2(-150, -35),

		Vector2(-110, -95),

		Vector2(60, -100),

		Vector2(145, -30),

		Vector2(130, 50),

		Vector2(50, 100),

		Vector2(-60, 100),

		Vector2(-150, 35)

	])

	fishing_spot.add_child(lake_visual)



	var moving_area := Node2D.new()

	moving_area.name = "MovingFishingArea"

	moving_area.visible = true

	moving_area.position = Vector2(44.0, -10.0)

	moving_area.z_index = 25

	fishing_spot.add_child(moving_area)



	var moving_area_glow := Polygon2D.new()

	moving_area_glow.name = "MovingFishingAreaGlow"

	moving_area_glow.z_index = 26

	moving_area_glow.color = Color(0.27451, 0.984314, 1.0, 0.52)

	moving_area_glow.polygon = PackedVector2Array([

		Vector2(-58, -12),

		Vector2(-34, -42),

		Vector2(18, -48),

		Vector2(54, -24),

		Vector2(58, 12),

		Vector2(30, 44),

		Vector2(-18, 48),

		Vector2(-56, 22)

	])

	moving_area.add_child(moving_area_glow)



	var moving_area_core := Polygon2D.new()

	moving_area_core.name = "MovingFishingAreaCore"

	moving_area_core.z_index = 27

	moving_area_core.color = Color(0.337255, 0.976471, 0.960784, 0.76)

	moving_area_core.polygon = PackedVector2Array([

		Vector2(-44, -8),

		Vector2(-24, -26),

		Vector2(14, -30),

		Vector2(40, -14),

		Vector2(44, 8),

		Vector2(22, 26),

		Vector2(-12, 30),

		Vector2(-40, 14)

	])

	moving_area.add_child(moving_area_core)



	var moving_area_ring := Line2D.new()

	moving_area_ring.name = "MovingFishingAreaRing"

	moving_area_ring.z_index = 28

	moving_area_ring.width = 8.0

	moving_area_ring.default_color = Color(0.760784, 0.996078, 1.0, 0.92)

	moving_area_ring.antialiased = true

	moving_area_ring.closed = true

	moving_area_ring.points = PackedVector2Array([

		Vector2(0, -40),

		Vector2(30, -28),

		Vector2(42, 0),

		Vector2(28, 30),

		Vector2(0, 40),

		Vector2(-30, 28),

		Vector2(-42, 0),

		Vector2(-28, -30)

	])

	moving_area.add_child(moving_area_ring)



	var moving_area_sparkle := Polygon2D.new()

	moving_area_sparkle.name = "MovingFishingAreaSparkle"

	moving_area_sparkle.position = Vector2(20, -16)

	moving_area_sparkle.z_index = 29

	moving_area_sparkle.color = Color(0.980392, 1.0, 1.0, 0.92)

	moving_area_sparkle.polygon = PackedVector2Array([

		Vector2(0, -5),

		Vector2(3, -2),

		Vector2(5, 0),

		Vector2(3, 2),

		Vector2(0, 5),

		Vector2(-3, 2),

		Vector2(-5, 0),

		Vector2(-3, -2)

	])

	moving_area.add_child(moving_area_sparkle)



	var bobber := Node2D.new()

	bobber.name = "Bobber"

	bobber.visible = false

	bobber.z_index = 30

	bobber.add_child(_criar_bobber_corpo())

	bobber.add_child(_criar_bobber_destaque())

	fishing_spot.add_child(bobber)



	var fishing_bite_timer := Timer.new()

	fishing_bite_timer.name = "FishingBiteTimer"

	fishing_bite_timer.wait_time = 3.0

	fishing_bite_timer.one_shot = true

	fishing_spot.add_child(fishing_bite_timer)



	var collision_shape := CollisionShape2D.new()

	collision_shape.name = "CollisionShape2D"

	var rectangle_shape := RectangleShape2D.new()

	rectangle_shape.size = Vector2(340, 220)

	collision_shape.shape = rectangle_shape

	fishing_spot.add_child(collision_shape)



	return fishing_spot



func _criar_bobber_corpo() -> Polygon2D:

	var body := Polygon2D.new()

	body.name = "Body"

	body.color = Color(0.909804, 0.258824, 0.258824, 1)

	body.polygon = PackedVector2Array([

		Vector2(0, -7),

		Vector2(5, -5),

		Vector2(7, 0),

		Vector2(5, 5),

		Vector2(0, 7),

		Vector2(-5, 5),

		Vector2(-7, 0),

		Vector2(-5, -5)

	])

	return body



func _criar_bobber_destaque() -> Polygon2D:

	var highlight := Polygon2D.new()

	highlight.name = "Highlight"

	highlight.color = Color(0.976471, 0.976471, 0.976471, 0.9)

	highlight.polygon = PackedVector2Array([

		Vector2(-2, -6),

		Vector2(1, -6),

		Vector2(2, -3),

		Vector2(-1, -3)

	])

	return highlight



func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if _esta_modal_aberto():
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		var tree: SceneTree = get_tree()

		if tree == null:

			return



		var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

		for obstaculo_variant in obstaculos:

			var obstaculo: Node = obstaculo_variant

			if obstaculo == null or not is_instance_valid(obstaculo):

				continue

			if not obstaculo.has_method("try_handle_global_click"):

				continue

			if obstaculo.call("try_handle_global_click", get_global_mouse_position()):

				get_viewport().set_input_as_handled()

				return



func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed and not _esta_modal_aberto():
				_camera_dragging = true
				set_camera_follow_enabled(false)
				_cancel_pending_player_interaction(true)
				get_viewport().set_input_as_handled()
			elif not event.pressed:
				_camera_dragging = false
				get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _esta_modal_aberto():
				return

			var tool_manager: Node = get_tree().root.get_node_or_null("ToolManager")
			var click_position: Vector2 = get_global_mouse_position()
			if tool_manager != null and tool_manager.has_method("get_active_tool"):
				var active_tool: int = int(tool_manager.call("get_active_tool"))
				if active_tool == int(ToolManager.ToolType.HOE):
					handle_hoe_world_click(click_position)
					get_viewport().set_input_as_handled()
					return
				if active_tool != int(ToolManager.ToolType.NONE):
					return

			if try_move_player_to(click_position):
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseMotion and _camera_dragging and main_camera != null:
		main_camera.position -= event.relative * main_camera.zoom
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_F5:

			SaveManager.save_game()

			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_F9:

			if SaveManager.load_game():

				var ui_node := get_node_or_null("UI")

				if ui_node and ui_node.has_method("reiniciar_objetivos_iniciais_apos_load"):

					ui_node.call("reiniciar_objetivos_iniciais_apos_load")

				_reconstruir_farm_grid_manager()

				get_viewport().set_input_as_handled()
