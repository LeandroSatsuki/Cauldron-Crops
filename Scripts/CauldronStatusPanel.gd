extends PanelContainer
const HUDLayoutScript = preload("res://Scripts/HUDLayout.gd")

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
	var ui := get_node_or_null("../../../UI")
	if ui != null:
		for node_name in ["InventoryBackdrop", "ToolBarPanel", "LeftPanel", "InitialObjectivesPanel"]:
			var control: Control = ui.get_node(node_name)
			control.item_rect_changed.connect(_queue_layout)
			control.visibility_changed.connect(_queue_layout)
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
	var scene := get_tree().current_scene
	var ui := scene.get_node_or_null("UI") if scene != null else null
	position = HUDLayoutScript.find_free_panel_position(size, screen_size, HUDLayoutScript.get_occupied_hud_rects(ui))
	_applying_layout = false
