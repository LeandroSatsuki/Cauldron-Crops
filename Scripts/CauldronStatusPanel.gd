extends PanelContainer

# Apresentação em coordenadas de tela, sem depender da câmera ou do save.
var _layout_queued := false
var _applying_layout := false

func _enter_tree() -> void:
	_queue_layout()

func _ready() -> void:
	custom_minimum_size = Vector2.ZERO
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263b2c")
	style.border_color = Color("aa9860")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	get_viewport().size_changed.connect(_queue_layout)
	minimum_size_changed.connect(_queue_layout)
	visibility_changed.connect(_queue_layout)
	_queue_layout()

func _queue_layout() -> void:
	if _layout_queued or _applying_layout:
		return
	_layout_queued = true
	_apply_layout.call_deferred()

func _apply_layout() -> void:
	_layout_queued = false
	if not is_inside_tree():
		return
	_applying_layout = true
	var screen_size := get_viewport().get_visible_rect().size
	size.x = minf(400, screen_size.x - 40)
	size.y = get_combined_minimum_size().y
	position = Vector2(screen_size.x - size.x - 20, maxf(20, screen_size.y - size.y - 20))
	_applying_layout = false
