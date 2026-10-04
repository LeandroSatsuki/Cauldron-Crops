extends Node2D
class_name VillageWell

const PANEL := preload("res://Scripts/VillageWellPanel.gd")
const INTERACTION_DISTANCE := 52.0
var panel: PanelContainer
var popup_root: Control
var _improved := false
var _hovered := false

func _ready() -> void:
	add_to_group("village_well")
	z_as_relative = false
	z_index = int(global_position.y) + 15
	$ClickableArea.input_event.connect(_on_input_event)
	$ClickableArea.mouse_entered.connect(func(): _hovered = true; queue_redraw())
	$ClickableArea.mouse_exited.connect(func(): _hovered = false; queue_redraw())
	var layer := CanvasLayer.new()
	layer.name = "WellPanelLayer"
	layer.layer = 12
	add_child(layer)
	popup_root = Control.new()
	popup_root.name = "PopupRoot"
	popup_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_root.hide()
	layer.add_child(popup_root)
	panel = PANEL.new()
	panel.name = "WellPanel"
	popup_root.add_child(panel)
	panel.bind_well(self)
	EconomyManager.well_improvement_changed.connect(_refresh_visual)
	RegionTravelCoordinator.transition_started.connect(_on_transition_started)
	tree_exiting.connect(close_panel)
	_refresh_visual()

func _on_transition_started(_request: Dictionary) -> void:
	close_panel()

func _refresh_visual() -> void:
	_improved = EconomyManager.is_well_improved()
	queue_redraw()

func _on_input_event(viewport: Viewport, event: InputEvent, _shape: int) -> void:
	if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var world := get_parent()
	if world == get_tree().current_scene and world.has_method("request_player_interaction"):
		if world.call("request_player_interaction", self, global_position, INTERACTION_DISTANCE, Callable(self, "open_panel")):
			viewport.set_input_as_handled()

func can_interact_now() -> bool:
	if not is_inside_tree() or get_tree().current_scene != get_parent() or RegionTravelCoordinator.is_transition_in_progress() or SaveManager.is_applying_snapshot():
		return false
	var player: Node2D = get_parent().get_node_or_null("PlayerAvatar")
	if player == null:
		return false
	var distance: float = get_parent().call("_resolve_safe_interaction_distance", self, global_position, INTERACTION_DISTANCE)
	return player.global_position.distance_to(global_position) <= distance

func open_panel() -> void:
	if not can_interact_now():
		return
	popup_root.show()
	panel.open()

func close_panel() -> void:
	if is_instance_valid(popup_root):
		popup_root.hide()

func is_panel_open() -> bool:
	return is_instance_valid(popup_root) and popup_root.is_visible_in_tree()

func try_improve_from_panel() -> bool:
	return is_panel_open() and can_interact_now() and EconomyManager.try_improve_village_well()

func _process(_delta: float) -> void:
	if is_panel_open() and not can_interact_now():
		close_panel()
	if _improved != EconomyManager.is_well_improved():
		_refresh_visual()

func _draw() -> void:
	# Formas nativas seguem o baú/paisagem existentes; não dependem de arte local.
	_oval(Vector2(0, 15), Vector2(41, 15), Color("243729", 0.35))
	draw_rect(Rect2(-29, -8, 58, 27), Color("626b62"))
	_oval(Vector2(0, 16), Vector2(29, 10), Color("777f70"))
	_oval(Vector2.ZERO, Vector2(33, 17), Color("9ca18a"))
	_oval(Vector2(0, -2), Vector2(24, 11), Color("304d51"))
	_oval(Vector2(0, -1), Vector2(20, 8), Color("5a9fa9") if _improved else Color("417f8e"))
	draw_line(Vector2(-12, -2), Vector2(5, -2), Color("97c5c4"), 2)
	for x in [-34, 28]:
		draw_rect(Rect2(x, -52, 6, 65), Color("795c3d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-43, -48), Vector2(0, -69), Vector2(43, -48), Vector2(0, -36)]), Color("637348") if _improved else Color("755e45"))
	draw_line(Vector2(0, -38), Vector2(0, -8), Color("c8b389"), 2)
	if _improved:
		draw_line(Vector2(-29, 10), Vector2(29, 10), Color("c0b57a"), 4)
		for point in [Vector2(-34, 20), Vector2(34, 19)]:
			draw_line(point, point + Vector2(0, -7), Color("78914e"), 2)
			draw_circle(point + Vector2(0, -9), 3, Color("e0d8a1"))
	if _hovered:
		draw_string(ThemeDB.fallback_font, Vector2(-45, -78), "Poço da Vila", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("eee3bd"))

func _oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
