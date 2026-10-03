extends Node

# Layout de apresentação: não altera capacidade, itens, seleção ou save.
const MAX_INVENTORY_WIDTH := 882.0
const OBJECTIVES_RESERVED_WIDTH := 339.0 # Painel 295, margem 20, intervalo 24.
const SLOT_WIDTH := 60.0
const SLOT_GAP := 10.0

var _ui: Node
var _layout_queued := false
var _updating_objectives := false
var _objectives_sync_queued := false
var _tools_full_width := 0.0


func _enter_tree() -> void:
	# HOME volta do cache sem repetir _ready; considerar resize feito no Bosque.
	_queue_layout()


func _ready() -> void:
	_ui = get_parent()
	get_viewport().size_changed.connect(_queue_layout)
	var bar: HBoxContainer = _ui.get_node("InventoryBar")
	bar.child_entered_tree.connect(_on_slots_changed)
	bar.child_exiting_tree.connect(_on_slots_changed)
	_ui.get_node("InitialObjectivesPanel").item_rect_changed.connect(_queue_objectives_sync)
	_ui.get_node("InitialObjectivesPanel").minimum_size_changed.connect(_queue_objectives_sync)
	_queue_layout()


func _on_slots_changed(_child: Node) -> void:
	_queue_layout()


func _queue_layout() -> void:
	if _layout_queued:
		return
	_layout_queued = true
	_apply_layout.call_deferred()


func _apply_layout() -> void:
	_layout_queued = false
	if not is_inside_tree():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var stacked := viewport_size.x < 960.0
	var left := 20.0 if stacked else 255.0
	var top := 140.0 if stacked else 3.0
	var width := minf(MAX_INVENTORY_WIDTH, maxf(300.0, viewport_size.x - left - OBJECTIVES_RESERVED_WIDTH))
	var page_size := clampi(floori((width - 52.0 + SLOT_GAP) / (SLOT_WIDTH + SLOT_GAP)), 1, 12)
	_ui.call("set_inventory_page_size", page_size)
	_set_rect("InventoryBackdrop", Rect2(left, top, width, 101.0))
	_set_rect("InventoryTitle", Rect2(left + 16.0, top + 13.0, 100.0, 20.0))
	_set_rect("InventoryCapacityLabel", Rect2(left + width - 82.0, top + 13.0, 64.0, 20.0))
	_set_rect("InventoryPreviousButton", Rect2(left + width - 230.0, top + 5.0, 36.0, 28.0))
	_set_rect("InventoryPageLabel", Rect2(left + width - 194.0, top + 5.0, 60.0, 28.0))
	_set_rect("InventoryNextButton", Rect2(left + width - 134.0, top + 5.0, 36.0, 28.0))
	_set_rect("InventoryBar", Rect2(left + 32.0, top + 37.0, width - 52.0, 60.0))
	var tools: HBoxContainer = _ui.get_node("ToolBarPanel")
	_ui.call("set_toolbar_compact", false)
	# Consultar os filhos: o mínimo do HBox pode estar atrasado neste frame.
	_tools_full_width = tools.get_theme_constant("separation") * (tools.get_child_count() - 1)
	for index in range(tools.get_child_count()):
		var button: Button = tools.get_child(index)
		_tools_full_width += button.get_combined_minimum_size().x
	var tools_width := width - 32.0
	var compact := tools_width < _tools_full_width
	_ui.call("set_toolbar_compact", compact)
	_set_rect("ToolBarPanel", Rect2(left + 16.0, top + 105.0, tools_width, 52.0))
	var actions: Control = _ui.get_node("LeftPanel")
	actions.position.y = maxf(200.0, top + 190.0) if stacked else 200.0
	_sync_objectives_toggle()


func _set_rect(node_name: String, rectangle: Rect2) -> void:
	var control: Control = _ui.get_node(node_name)
	control.position = rectangle.position
	control.size = rectangle.size


func _sync_objectives_toggle() -> void:
	_objectives_sync_queued = false
	if _updating_objectives or not is_inside_tree():
		return
	var toggle: Button = _ui.get("initial_objectives_toggle_button")
	if toggle == null:
		return
	_updating_objectives = true
	var panel: Control = _ui.get_node("InitialObjectivesPanel")
	var viewport_size := get_viewport().get_visible_rect().size
	# Autowrap pode calcular altura transitória enquanto Containers se acomodam.
	panel.size.y = panel.get_combined_minimum_size().y
	panel.position = Vector2(
		clampf(panel.position.x, 0.0, maxf(0.0, viewport_size.x - panel.size.x)),
		clampf(panel.position.y, 0.0, viewport_size.y - panel.size.y) if panel.size.y <= viewport_size.y else panel.position.y
	)
	toggle.global_position = panel.get_global_rect().position + Vector2(panel.size.x - 34.0, 4.0)
	toggle.size = Vector2(28.0, 28.0)
	_updating_objectives = false


func _queue_objectives_sync() -> void:
	if _updating_objectives or _objectives_sync_queued:
		return
	_objectives_sync_queued = true
	_sync_objectives_toggle.call_deferred()
