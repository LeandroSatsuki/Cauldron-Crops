extends Node2D


signal region_transition_requested(request: Dictionary)


const NAVIGATION_BOUNDS := Rect2(0.0, 0.0, 1920.0, 1080.0)


@onready var world_region: WorldRegion = $RegionContext
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var player_avatar: CharacterBody2D = $PlayerAvatar
@onready var destination_marker: Node2D = $PlayerDestinationMarker
@onready var main_camera: Camera2D = $MainCamera


var _pending_player_interaction: Dictionary = {}


func _ready() -> void:
	_configure_navigation()
	if not world_region.transition_requested.is_connected(_on_region_transition_requested):
		world_region.transition_requested.connect(_on_region_transition_requested)
	enter_region_at(world_region.default_entry_id)
	_register_with_travel_coordinator.call_deferred()


func _process(delta: float) -> void:
	if not _pending_player_interaction.is_empty():
		_process_pending_player_interaction()
	elif not player_avatar.has_active_destination():
		_clear_destination_marker()
	main_camera.position = main_camera.position.lerp(player_avatar.global_position, clampf(delta * 7.0, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var click_position: Vector2 = get_global_mouse_position()
	if try_move_player_to(click_position):
		get_viewport().set_input_as_handled()


func _configure_navigation() -> void:
	var vertices := PackedVector2Array([
		NAVIGATION_BOUNDS.position,
		Vector2(NAVIGATION_BOUNDS.position.x, NAVIGATION_BOUNDS.end.y),
		NAVIGATION_BOUNDS.end,
		Vector2(NAVIGATION_BOUNDS.end.x, NAVIGATION_BOUNDS.position.y),
	])
	var polygon := NavigationPolygon.new()
	polygon.vertices = vertices
	polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	navigation_region.navigation_polygon = polygon


func get_current_region_identity() -> Dictionary:
	return world_region.get_identity()


func resolve_region_entry(entry_id: StringName = &"") -> Dictionary:
	return world_region.resolve_entry(entry_id)


func enter_region_at(entry_id: StringName = &"") -> bool:
	world_region.refresh_entry_points()
	var entry: Dictionary = world_region.resolve_entry(entry_id)
	if not bool(entry.get("found", false)):
		return false
	_pending_player_interaction.clear()
	player_avatar.global_position = entry.get("global_position", player_avatar.global_position)
	player_avatar.stop_moving()
	_clear_destination_marker()
	main_camera.make_current()
	main_camera.global_position = player_avatar.global_position
	return true


func request_region_transition(
	target_region_id: StringName,
	target_entry_id: StringName,
	source_exit_id: StringName = &""
) -> bool:
	return world_region.request_transition(target_region_id, target_entry_id, source_exit_id)


func peek_pending_region_transition() -> Dictionary:
	return world_region.peek_pending_transition()


func consume_pending_region_transition() -> Dictionary:
	return world_region.consume_pending_transition()


func _on_region_transition_requested(request: Dictionary) -> void:
	region_transition_requested.emit(request.duplicate(true))


func _register_with_travel_coordinator() -> void:
	var coordinator: Node = get_tree().root.get_node_or_null("RegionTravelCoordinator")
	if coordinator != null and coordinator.has_method("register_region_scene"):
		coordinator.call("register_region_scene", self)


func can_issue_player_move(world_position: Vector2, check_interaction_colliders: bool = true) -> bool:
	if player_avatar == null or not is_instance_valid(player_avatar):
		return false
	if ToolManager.get_active_tool() != ToolManager.ToolType.NONE or GlobalInventory.semente_selecionada != "":
		return false
	if not NAVIGATION_BOUNDS.grow(-28.0).has_point(world_position):
		return false
	if check_interaction_colliders and _world_position_has_interaction_collider(world_position):
		return false
	return true


func try_move_player_to(world_position: Vector2, check_interaction_colliders: bool = true) -> bool:
	if not can_issue_player_move(world_position, check_interaction_colliders):
		return false
	_pending_player_interaction.clear()
	var move_requested: bool = bool(player_avatar.request_move(world_position))
	if move_requested:
		destination_marker.call("show_destination", world_position, false)
	return move_requested


func request_player_interaction(target: Node, target_position: Vector2, interaction_distance: float, callback: Callable) -> bool:
	if target == null or not is_instance_valid(target) or not callback.is_valid():
		return false
	var safe_distance: float = maxf(interaction_distance, 24.0)
	_pending_player_interaction.clear()
	if player_avatar.global_position.distance_to(target_position) <= safe_distance:
		player_avatar.stop_moving()
		_clear_destination_marker()
		callback.call()
		return true

	var direction_from_target: Vector2 = target_position.direction_to(player_avatar.global_position)
	if direction_from_target.is_zero_approx():
		direction_from_target = Vector2.RIGHT
	var approach_position: Vector2 = target_position + direction_from_target * maxf(safe_distance - 8.0, 16.0)
	_pending_player_interaction = {
		"target_ref": weakref(target),
		"target_position": target_position,
		"interaction_distance": safe_distance,
		"callback": callback,
		"action_signature": _get_player_action_signature(),
	}
	if not player_avatar.request_move(approach_position):
		_pending_player_interaction.clear()
		return false
	destination_marker.call("show_destination", target_position, true)
	return true


func _process_pending_player_interaction() -> void:
	if str(_pending_player_interaction.get("action_signature", "")) != _get_player_action_signature():
		_cancel_pending_interaction()
		return
	var target_ref: WeakRef = _pending_player_interaction.get("target_ref") as WeakRef
	var target: Object = target_ref.get_ref() if target_ref != null else null
	var callback: Callable = _pending_player_interaction.get("callback", Callable())
	if target == null or not is_instance_valid(target) or not callback.is_valid():
		_cancel_pending_interaction()
		return
	var target_position: Vector2 = _pending_player_interaction.get("target_position", player_avatar.global_position)
	var interaction_distance: float = float(_pending_player_interaction.get("interaction_distance", 48.0))
	if player_avatar.global_position.distance_to(target_position) <= interaction_distance:
		_pending_player_interaction.clear()
		player_avatar.stop_moving()
		_clear_destination_marker()
		callback.call()
	elif not player_avatar.has_active_destination():
		_cancel_pending_interaction()


func _cancel_pending_interaction() -> void:
	_pending_player_interaction.clear()
	player_avatar.stop_moving()
	_clear_destination_marker()


func _clear_destination_marker() -> void:
	if destination_marker != null and destination_marker.visible:
		destination_marker.call("clear_destination")


func _get_player_action_signature() -> String:
	return "%d|%s" % [ToolManager.get_active_tool(), GlobalInventory.semente_selecionada]


func _world_position_has_interaction_collider(world_position: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF
	for hit in get_world_2d().direct_space_state.intersect_point(query, 16):
		var collider: Object = hit.get("collider")
		if collider == null or not is_instance_valid(collider) or collider == player_avatar:
			continue
		if collider is Node and player_avatar.is_ancestor_of(collider as Node):
			continue
		return true
	return false
