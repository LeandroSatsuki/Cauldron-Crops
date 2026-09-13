extends CharacterBody2D
class_name PlayerAvatar

signal destination_requested(destination: Vector2)
signal destination_reached(destination: Vector2)

@export var move_speed_pixels_per_second: float = 180.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var _requested_destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false


func _ready() -> void:
	add_to_group("player_avatar")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_requested_destination = global_position
	if navigation_agent:
		navigation_agent.max_speed = move_speed_pixels_per_second
		if not navigation_agent.velocity_computed.is_connected(_on_navigation_velocity_computed):
			navigation_agent.velocity_computed.connect(_on_navigation_velocity_computed)


func _physics_process(_delta: float) -> void:
	z_index = int(global_position.y) + 6
	if not _has_active_destination():
		_apply_velocity(Vector2.ZERO)
		return

	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_position)
	var desired_velocity: Vector2 = direction * move_speed_pixels_per_second
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		_apply_velocity(desired_velocity)


func _on_navigation_velocity_computed(safe_velocity: Vector2) -> void:
	if not _has_destination:
		return
	_apply_velocity(safe_velocity)


func _apply_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
	move_and_slide()


func request_move(destination: Vector2) -> bool:
	if navigation_agent == null or not is_inside_tree():
		return false

	_requested_destination = destination
	_has_destination = true
	navigation_agent.target_position = destination
	destination_requested.emit(destination)
	return true


func stop_moving() -> void:
	_has_destination = false
	_requested_destination = global_position
	velocity = Vector2.ZERO
	if navigation_agent:
		navigation_agent.target_position = global_position


func has_active_destination() -> bool:
	return _has_destination


func get_requested_destination() -> Vector2:
	return _requested_destination


func _has_active_destination() -> bool:
	if not _has_destination or navigation_agent == null:
		return false
	if not navigation_agent.is_navigation_finished():
		return true

	_has_destination = false
	velocity = Vector2.ZERO
	destination_reached.emit(_requested_destination)
	return false
