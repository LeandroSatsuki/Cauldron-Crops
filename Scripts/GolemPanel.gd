extends PanelContainer

# Layout local: conserva os caminhos/controles existentes e a posição arrastada.
var _queued := false
var _laying_out := false
var _positioned := false

func _enter_tree() -> void:
	_queue_layout()

func _ready() -> void:
	get_viewport().size_changed.connect(_queue_layout)
	minimum_size_changed.connect(_queue_layout)
	visibility_changed.connect(_queue_layout)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("263826")
	background.border_color = Color("9da773")
	background.set_border_width_all(2)
	background.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", background)
	_queue_layout()

func _queue_layout() -> void:
	if _queued or _laying_out:
		return
	_queued = true
	_apply_layout.call_deferred()

func _apply_layout() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_laying_out = true
	var screen := get_viewport_rect().size
	var width := minf(440.0, maxf(300.0, screen.x - 32.0))
	var previous_position := position
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	custom_minimum_size = Vector2(width, 0)
	size = Vector2(width, get_combined_minimum_size().y)
	if not _positioned:
		position = (screen - size) * 0.5
		_positioned = true
	else:
		position = previous_position
	position = Vector2(clampf(position.x, 0, maxf(0, screen.x - size.x)), clampf(position.y, 0, maxf(0, screen.y - size.y)))
	_laying_out = false
