extends Control

signal items_transferred
signal close_requested

const PANEL_COLOR := Color("252d27")
const BORDER_COLOR := Color("9f9163")

var quantity_picker: SpinBox
var move_button: Button
var move_all_button: Button
var transfer_popup: PanelContainer
var inventory_grid: GridContainer
var chest_grid: GridContainer
var feedback: Label
var inventory_capacity_label: Label
var _shield: Control
var _item_icon: TextureRect
var _item_fallback: Label
var _item_name: Label
var _available_label: Label
var _direction_label: Label
var _chest: VillageChest
var _personal_snapshot: Dictionary = {}
var _storage_snapshot: Dictionary = {}
var _selected_item: String = ""
var _from_chest: bool = false


func _ready() -> void:
	_build_interface()
	visibility_changed.connect(_on_visibility_changed)
	close_requested.connect(get_parent().fechar_bau_vila)
	refresh_items(true)


func bind_chest(chest: VillageChest) -> void:
	_chest = chest
	_close_transfer()
	feedback.text = ""
	position = (get_viewport_rect().size - size) / 2.0
	refresh_items(true)


func refresh_items(force: bool = false) -> void:
	var personal: Dictionary = _chest.get_depositable_personal_items() if is_instance_valid(_chest) else {}
	var storage: Dictionary = _chest.get_contents() if is_instance_valid(_chest) else {}
	if force or personal != _personal_snapshot:
		_personal_snapshot = personal.duplicate()
		_fill_grid(inventory_grid, personal, false)
	if force or storage != _storage_snapshot:
		_storage_snapshot = storage.duplicate()
		_fill_grid(chest_grid, storage, true)
	if transfer_popup.visible:
		var available := _get_available()
		_available_label.text = "Total do item: %d" % available
		quantity_picker.max_value = maxi(1, available)
		if available <= 0:
			_close_transfer()
			feedback.text = "Este item não está mais disponível."


func is_editing_quantity() -> bool:
	return is_visible_in_tree() and transfer_popup.visible


func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if transfer_popup.visible:
			_close_transfer()
		else:
			close_requested.emit()
		get_viewport().set_input_as_handled()


func _open_transfer(item_id: String, from_chest: bool) -> void:
	if not is_visible_in_tree() or not is_instance_valid(_chest):
		return
	_selected_item = item_id
	_from_chest = from_chest
	var available := _get_available()
	if available <= 0:
		_close_transfer()
		return
	_item_name.text = Database.obter_nome_item(item_id)
	_item_icon.texture = Database.obter_textura_item(item_id)
	_item_icon.visible = _item_icon.texture != null
	_item_fallback.text = Database.obter_icone_item(item_id)
	_item_fallback.visible = _item_icon.texture == null
	_direction_label.text = "Baú → Mochila" if from_chest else "Mochila → Baú"
	_available_label.text = "Total do item: %d" % available
	quantity_picker.max_value = available
	quantity_picker.value = 1
	quantity_picker.get_line_edit().text = "1"
	feedback.text = "Sementes precisam estar na mochila para plantar." if item_id.begins_with("semente_") and not from_chest else ""
	_shield.show()
	transfer_popup.show()
	quantity_picker.get_line_edit().grab_focus()
	quantity_picker.get_line_edit().select_all()


func _get_available() -> int:
	if not is_instance_valid(_chest):
		return 0
	if _from_chest:
		return _chest.get_item_quantity(_selected_item)
	return int(_chest.get_depositable_personal_items().get(_selected_item, 0))


func _open_transfer_from_slot(item_id: String, from_chest: bool, slot: Button) -> void:
	var grid: GridContainer = chest_grid if from_chest else inventory_grid
	# Uma grade reconstruida invalida seus botoes antigos, mesmo se o item
	# ainda existir em outra pilha. Nenhum callback destacado pode abrir modal.
	if not is_instance_valid(slot) or slot.get_parent() != grid:
		return
	_open_transfer(item_id, from_chest)


func _move_selected(move_all: bool) -> void:
	if not is_visible_in_tree() or not transfer_popup.visible or not is_instance_valid(_chest):
		return
	quantity_picker.apply()
	var quantity := _get_available() if move_all else int(quantity_picker.value)
	var success := _chest.withdraw_to_personal_inventory(_selected_item, quantity) if _from_chest else _chest.deposit_from_personal_inventory(_selected_item, quantity)
	if not success:
		if _from_chest and int(GlobalInventory.get_acceptance(_selected_item, quantity).get("accepted", 0)) < quantity:
			feedback.text = "A Mochila não tem espaço para esta quantidade."
		else:
			feedback.text = "A quantidade mudou. Confira o valor e tente novamente."
		refresh_items(true)
		return
	feedback.text = "%s × %d → %s" % [Database.obter_nome_item(_selected_item), quantity, "Mochila" if _from_chest else "Baú"]
	_close_transfer()
	refresh_items(true)
	items_transferred.emit()


func _close_transfer() -> void:
	_selected_item = ""
	quantity_picker.get_line_edit().release_focus()
	transfer_popup.hide()
	_shield.hide()


func _on_visibility_changed() -> void:
	if is_node_ready() and not visible:
		_close_transfer()


func _build_interface() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panels := HBoxContainer.new()
	panels.name = "Panels"
	panels.add_theme_constant_override("separation", 16)
	add_child(panels)
	panels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chest_grid = _build_inventory(panels, "Chest", "Baú da Vila", "Recursos guardados na vila")
	inventory_grid = _build_inventory(panels, "Backpack", "Mochila", "Itens que você carrega · água no poço")
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.custom_minimum_size = Vector2(0, 44)
	get_node("Panels/Chest/Margin/Content").add_child(feedback)
	var footer_space := Control.new()
	footer_space.custom_minimum_size.y = 44
	get_node("Panels/Backpack/Margin/Content").add_child(footer_space)
	_shield = Control.new()
	_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shield)
	_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shield.hide()
	transfer_popup = PanelContainer.new()
	transfer_popup.name = "TransferPopup"
	transfer_popup.add_theme_stylebox_override("panel", _style(PANEL_COLOR, BORDER_COLOR))
	transfer_popup.custom_minimum_size = Vector2(360, 300)
	add_child(transfer_popup)
	transfer_popup.position = Vector2((size.x - 360) / 2, 70)
	var body := _panel_body(transfer_popup)
	_direction_label = _label(body, "", 22)
	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(0, 72)
	body.add_child(icon_holder)
	_item_icon = TextureRect.new()
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_holder.add_child(_item_icon)
	_item_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_item_fallback = Label.new()
	_item_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_item_fallback.add_theme_font_size_override("font_size", 36)
	icon_holder.add_child(_item_fallback)
	_item_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_item_name = _label(body, "", 22)
	_available_label = _label(body, "", 18)
	var row := HBoxContainer.new()
	body.add_child(row)
	_label(row, "Quantidade", 18)
	quantity_picker = SpinBox.new()
	quantity_picker.min_value = 1
	quantity_picker.value = 1
	quantity_picker.rounded = true
	quantity_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(quantity_picker)
	quantity_picker.get_line_edit().add_theme_stylebox_override("normal", _style(Color("19231e"), BORDER_COLOR))
	quantity_picker.get_line_edit().text_submitted.connect(func(_text: String): _move_selected(false))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	move_button = _button(buttons, "Mover", func(): _move_selected(false))
	move_all_button = _button(buttons, "Mover tudo", func(): _move_selected(true))
	move_all_button.tooltip_text = "Move todas as unidades deste tipo de item, incluindo suas outras pilhas."
	_button(body, "Cancelar", _close_transfer)
	transfer_popup.hide()


func _build_inventory(parent: HBoxContainer, node_name: String, title: String, subtitle: String) -> GridContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = 400
	panel.add_theme_stylebox_override("panel", _style(PANEL_COLOR, BORDER_COLOR))
	parent.add_child(panel)
	var content := _panel_body(panel)
	var heading := _label(content, title, 25)
	heading.name = "Title"
	_label(content, subtitle, 16)
	if node_name == "Backpack":
		inventory_capacity_label = _label(content, "", 16)
		inventory_capacity_label.name = "Capacity"
		inventory_capacity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4 if node_name == "Backpack" else 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	_label(content, "Clique em um item para mover" if node_name == "Chest" else "Clique numa pilha para mover", 16)
	_button(content, "Fechar", func(): close_requested.emit())
	return grid


func _panel_body(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	return content


func _fill_grid(grid: GridContainer, items: Dictionary, from_chest: bool) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var entries: Array[Dictionary] = []
	if from_chest:
		var ids: Array = items.keys()
		ids.sort()
		for id_variant in ids:
			var quantity := int(items[id_variant])
			if quantity > 0:
				entries.append({"item_id": str(id_variant), "quantity": quantity})
	else:
		# Mesma ordem, divisao e stack_maximo da barra; nao recontar por tipo.
		for entry in GlobalInventory.get_personal_slot_entries():
			if items.has(entry["item_id"]):
				entries.append(entry)
		var capacity: int = GlobalInventory.get_slot_capacity()
		var overflow := entries.size() > capacity
		inventory_capacity_label.text = "%d/%d slots" % [entries.size(), capacity]
		if overflow:
			inventory_capacity_label.text += " · excesso legado"
		inventory_capacity_label.modulate = Color("ffc078") if overflow else Color("e8dfc7")
		inventory_capacity_label.tooltip_text = "Deposite no baú para reduzir o excesso. Todos os itens foram preservados." if overflow else "Água fica no poço. Pilhas padrão de 99 unidades."
	for entry in entries:
		var item_id := str(entry["item_id"])
		var quantity := int(entry["quantity"])
		var slot := _button(grid, "", Callable())
		slot.pressed.connect(_open_transfer_from_slot.bind(item_id, from_chest, slot))
		slot.set_meta("item_id", item_id)
		slot.set_meta("quantity", quantity)
		slot.tooltip_text = "%s × %d" % [Database.obter_nome_item(item_id), quantity]
		if not from_chest:
			slot.tooltip_text += "\nPilha %d/%d · total do item: %d" % [int(entry["stack_index"]) + 1, int(entry["stack_count"]), int(items[item_id])]
		slot.custom_minimum_size = Vector2(66, 66)
		var texture: Texture2D = Database.obter_textura_item(item_id)
		if texture != null:
			var icon := TextureRect.new()
			icon.texture = texture
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)
			icon.position = Vector2(9, 5)
			icon.size = Vector2(48, 44)
		else:
			slot.text = Database.obter_icone_item(item_id)
		var amount := Label.new()
		amount.text = str(quantity)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(amount)
		amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		amount.offset_right = -5
		amount.offset_bottom = -3
	var minimum_slots: int = 20 if from_chest else GlobalInventory.get_slot_capacity()
	for index in range(maxi(0, minimum_slots - entries.size())):
		var empty := Panel.new()
		empty.custom_minimum_size = Vector2(66, 66)
		empty.add_theme_stylebox_override("panel", _style(Color("202922"), Color("475044")))
		grid.add_child(empty)


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _style(Color("344137"), Color("686b4e")))
	button.add_theme_stylebox_override("hover", _style(Color("475640"), BORDER_COLOR))
	button.add_theme_stylebox_override("pressed", _style(Color("20291f"), BORDER_COLOR))
	if action.is_valid():
		button.pressed.connect(action)
	parent.add_child(button)
	return button


func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8dfc7"))
	parent.add_child(label)
	return label


func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
