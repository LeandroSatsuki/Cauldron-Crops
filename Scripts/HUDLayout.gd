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


static func get_occupied_hud_rects(ui: Node) -> Array[Rect2]:
	var rectangles: Array[Rect2] = []
	if ui == null:
		return rectangles
	for node_name in ["InventoryBackdrop", "ToolBarPanel", "LeftPanel", "InitialObjectivesPanel"]:
		var control := ui.get_node_or_null(node_name) as Control
		if control != null and control.is_visible_in_tree():
			if node_name == "LeftPanel":
				# O VBox legado conserva altura vazia das lojas removidas.
				for child in control.get_children():
					if child is Control and child.is_visible_in_tree():
						rectangles.append(child.get_global_rect())
			else:
				rectangles.append(control.get_global_rect())
	var toggle: Control = ui.get("initial_objectives_toggle_button")
	if toggle != null and toggle.is_visible_in_tree():
		rectangles.append(toggle.get_global_rect())
	return rectangles


static func get_protected_hud_rects(ui: Node) -> Array[Rect2]:
	var rectangles: Array[Rect2] = []
	if ui == null:
		return rectangles
	for control in ui.find_children("*", "BaseButton", true, false):
		if control.is_visible_in_tree() and not control.disabled:
			rectangles.append(control.get_global_rect())
	# Slots são painéis interativos, não BaseButton.
	var inventory := ui.get_node_or_null("InventoryBackdrop") as Control
	if inventory != null and inventory.is_visible_in_tree():
		rectangles.append(inventory.get_global_rect())
	return rectangles

static func find_free_panel_position(panel_size: Vector2, screen: Vector2, occupied: Array[Rect2], protected: Array[Rect2] = []) -> Vector2:
	# Apresentação apenas: objetivos arrastados não são movidos por esta busca.
	var preferred := screen - panel_size - Vector2(20, 20)
	var xs: Array[float] = [preferred.x, 20.0]
	var ys: Array[float] = [preferred.y, 20.0]
	for rectangle in occupied + protected:
		xs.append(rectangle.position.x - panel_size.x - 12.0)
		xs.append(rectangle.end.x + 12.0)
		ys.append(rectangle.position.y - panel_size.y - 12.0)
		ys.append(rectangle.end.y + 12.0)
	var best := Vector2(maxf(20, preferred.x), maxf(20, preferred.y))
	var distance := INF
	var fallback := best
	var fallback_protected_overlap := INF
	var fallback_score := INF
	var fallback_distance := INF
	for x in xs:
		for y in ys:
			var bounded := Vector2(clampf(x, 12.0, maxf(12.0, screen.x - panel_size.x - 12.0)), clampf(y, 12.0, maxf(12.0, screen.y - panel_size.y - 12.0)))
			var candidate := Rect2(bounded, panel_size)
			if not Rect2(Vector2(12, 12), screen - Vector2(24, 24)).encloses(candidate):
				continue
			var blocked := false
			var overlap := 0.0
			for rectangle in occupied:
				if candidate.intersects(rectangle.grow(6.0)):
					blocked = true
					overlap += candidate.intersection(rectangle.grow(6.0)).get_area()
			var protected_overlap := 0.0
			for rectangle in protected:
				protected_overlap += candidate.intersection(rectangle.grow(6.0)).get_area()
			if protected_overlap > 0.0:
				blocked = true
			var candidate_distance := candidate.position.distance_squared_to(preferred)
			# Controles têm prioridade sobre a área de conteúdo inevitavelmente coberta.
			var same_priority := is_equal_approx(protected_overlap, fallback_protected_overlap)
			if protected_overlap < fallback_protected_overlap or (same_priority and (overlap < fallback_score or (is_equal_approx(overlap, fallback_score) and candidate_distance < fallback_distance))):
				fallback = candidate.position
				fallback_protected_overlap = protected_overlap
				fallback_score = overlap
				fallback_distance = candidate_distance
			if not blocked and candidate_distance < distance:
				best = candidate.position
				distance = candidate_distance
	return best if distance < INF else fallback
