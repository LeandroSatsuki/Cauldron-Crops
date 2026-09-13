extends Node2D

const MOVE_COLOR := Color(0.55, 0.95, 0.72, 0.9)
const INTERACTION_COLOR := Color(1.0, 0.78, 0.34, 0.95)

var _elapsed: float = 0.0
var _is_interaction: bool = false


func _ready() -> void:
	visible = false
	z_as_relative = false
	z_index = 4000
	set_process(true)


func show_destination(world_position: Vector2, interaction: bool) -> void:
	global_position = world_position
	_is_interaction = interaction
	_elapsed = 0.0
	visible = true
	modulate = Color.WHITE
	queue_redraw()


func clear_destination() -> void:
	visible = false
	_elapsed = 0.0


func is_interaction_destination() -> bool:
	return _is_interaction


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	var pulse: float = 1.0 + sin(_elapsed * 7.0) * 0.08
	scale = Vector2.ONE * pulse
	queue_redraw()


func _draw() -> void:
	var color: Color = INTERACTION_COLOR if _is_interaction else MOVE_COLOR
	draw_circle(Vector2.ZERO, 3.0, color)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 32, color, 2.0, true)
	if _is_interaction:
		draw_line(Vector2(0.0, -17.0), Vector2(6.0, -11.0), color, 2.0, true)
		draw_line(Vector2(6.0, -11.0), Vector2(0.0, -5.0), color, 2.0, true)
		draw_line(Vector2(0.0, -5.0), Vector2(-6.0, -11.0), color, 2.0, true)
		draw_line(Vector2(-6.0, -11.0), Vector2(0.0, -17.0), color, 2.0, true)
	else:
		for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			draw_line(direction * 14.0, direction * 18.0, color, 2.0, true)
