extends Node2D

const PANEL := preload("res://Scripts/ProductiveHerbariumPanel.gd")
var panel: PanelContainer
var popup_root: Control
var _hovered := false
var _open_token := 0

func _ready() -> void:
	add_to_group("herbarium_production_site")
	z_as_relative = false
	z_index = int(global_position.y) + 15
	var area := Area2D.new()
	area.name = "ClickableArea"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(func(): _hovered = true; queue_redraw())
	area.mouse_exited.connect(func(): _hovered = false; queue_redraw())
	var layer := CanvasLayer.new()
	layer.name = "HerbariumPanelLayer"
	layer.layer = 12
	add_child(layer)
	popup_root = Control.new()
	popup_root.name = "PopupRoot"
	popup_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_root.hide()
	layer.add_child(popup_root)
	panel = PANEL.new()
	panel.name = "HerbariumPanel"
	panel.bind_site(self)
	popup_root.add_child(panel)
	HerbariumProduction.progress_changed.connect(queue_redraw)
	RegionTravelCoordinator.transition_started.connect(func(_request: Dictionary): close_panel())
	tree_exiting.connect(close_panel)

func _on_input_event(viewport: Viewport, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if request_open():
			viewport.set_input_as_handled()

func request_open() -> bool:
	if not _context_valid() or get_parent().call("_esta_modal_aberto"):
		return false
	get_parent().call("_cancel_pending_player_interaction", true)
	_open_token += 1
	return bool(get_parent().call("request_player_interaction", self, global_position,
		HerbariumProduction.INTERACTION_DISTANCE, Callable(self, "_open_if_current").bind(HerbariumProduction.get_generation(), _open_token)))

func _open_if_current(generation: int, token: int) -> void:
	if token == _open_token and generation == HerbariumProduction.get_generation() and can_interact_now():
		_open_token += 1
		open_panel()

func cancel_pending_open() -> void:
	_open_token += 1

func _context_valid() -> bool:
	return is_inside_tree() and get_tree().current_scene == get_parent() \
		and not bool(get_parent().get("_region_being_cached")) \
		and not SaveManager.is_applying_snapshot() and not RegionTravelCoordinator.is_transition_in_progress() \
		and get_parent().get_node_or_null("ProductiveHerbarium") == self

func can_interact_now() -> bool:
	if not _context_valid():
		return false
	var player := get_parent().get_node_or_null("PlayerAvatar") as Node2D
	if player == null:
		return false
	var distance: float = get_parent().call("_resolve_safe_interaction_distance", self, global_position, HerbariumProduction.INTERACTION_DISTANCE)
	return player.global_position.distance_to(global_position) <= distance

func open_panel() -> void:
	if can_interact_now():
		popup_root.show()
		panel.open()

func close_panel() -> void:
	cancel_pending_open()
	if is_instance_valid(popup_root):
		popup_root.hide()

func is_panel_open() -> bool:
	return is_instance_valid(popup_root) and popup_root.is_visible_in_tree()

func try_activate_from_panel() -> bool:
	return is_panel_open() and can_interact_now() and HerbariumProduction.try_activate(self)

func try_collect_from_panel() -> bool:
	return is_panel_open() and can_interact_now() and HerbariumProduction.try_collect(self)

func _process(_delta: float) -> void:
	if is_panel_open() and not can_interact_now():
		close_panel()

func _draw() -> void:
	# Marcador técnico mínimo. A representação final pertence ao Antigravity.
	draw_rect(Rect2(-22, -20, 44, 40), Color("263326"))
	draw_rect(Rect2(-22, -20, 44, 40), Color("a59b70"), false, 2)
	var texture: Texture2D = Database.obter_textura_item("raiz_gelida")
	if texture != null:
		draw_texture_rect(texture, Rect2(-14, -14, 28, 28), false)
	if HerbariumProduction.activated and HerbariumProduction.renewal_remaining <= 0.0:
		draw_circle(Vector2(20, -20), 4, Color("e1ddb8"))
	if _hovered:
		draw_string(ThemeDB.fallback_font, Vector2(-62, -32), "Herbário produtivo", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("eee3bd"))
