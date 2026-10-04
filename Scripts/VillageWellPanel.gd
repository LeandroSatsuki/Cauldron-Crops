extends PanelContainer

const RESOURCE_ACCESS := preload("res://Scripts/VillageResourceAccess.gd")
var well: VillageWell
var title: Label
var water_label: Label
var water_bar: ProgressBar
var status_label: Label
var cost_box: VBoxContainer
var improve_button: Button
var feedback: Label
var _amount_labels: Dictionary = {}
var _drag := UIDragHelper.new()
var _positioned := false

func _ready() -> void:
	theme = preload("res://Themes/pixel_ui_theme.tres")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263326")
	style.border_color = Color("a59b70")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	title = _label("Poço da Vila", box)
	title.add_theme_font_size_override("font_size", 18)
	_drag.attach(self, title)
	water_label = _label("", box)
	water_bar = ProgressBar.new()
	water_bar.custom_minimum_size.y = 14
	water_bar.show_percentage = false
	box.add_child(water_bar)
	_label("A água se regenera e abastece a fazenda.\nNão ocupa espaço na Mochila.", box)
	status_label = _label("", box)
	cost_box = VBoxContainer.new()
	box.add_child(cost_box)
	for id in VillageWellState.PROJECT_REQUIREMENTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		cost_box.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Database.obter_textura_item(id)
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		_amount_labels[id] = _label("", row)
	_label("Materiais: Baú da Vila primeiro,\nMochila para completar.", cost_box)
	feedback = _label("", box)
	feedback.hide()
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	improve_button = Button.new()
	improve_button.text = "Melhorar · capacidade 20"
	improve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	improve_button.custom_minimum_size.y = 38
	improve_button.pressed.connect(_on_improve)
	buttons.add_child(improve_button)
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(func(): well.close_panel())
	buttons.add_child(close)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func bind_well(value: VillageWell) -> void:
	well = value

func open() -> void:
	feedback.hide()
	refresh()
	_center_after_layout.call_deferred()

func _center_after_layout() -> void:
	# Labels com quebra precisam de uma passagem dos containers antes de centrar.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or not is_visible_in_tree():
		return
	_positioned = false
	_layout()

func _process(_delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(well):
		refresh()

func refresh() -> void:
	var water := GlobalInventory.get_item_quantity("agua")
	water_label.text = "Água  %d / %d" % [water, EconomyManager.poco_capacidade_maxima]
	water_bar.max_value = EconomyManager.poco_capacidade_maxima
	water_bar.value = water
	var status := EconomyManager.get_well_project_status()
	var code: String = status["code"]
	status_label.text = {
		"locked": "Melhoria disponível após restaurar a Clareira.",
		"missing": "Amplie a reserva para 20 de água.\nFaltam materiais para a melhoria.",
		"ready": "Amplie a reserva para 20 de água.\nNão altera a velocidade de regeneração.",
		"completed": "Reserva ampliada. Benefício já obtido.",
		"home_unavailable": "Retorne à vila para melhorar o Poço.",
	}.get(code, "Melhoria indisponível.")
	improve_button.disabled = code != "ready"
	improve_button.visible = code != "completed"
	cost_box.visible = code != "completed"
	var storage := well.get_parent().get_node_or_null("VillageChest")
	var access := RESOURCE_ACCESS.new(storage)
	for id in _amount_labels:
		var required: int = VillageWellState.PROJECT_REQUIREMENTS[id]
		var available: int = access.get_available(id)
		_amount_labels[id].text = "%s  %d / %d" % [Database.obter_nome_item(id), available, required]
		_amount_labels[id].modulate = Color("e1ddb8") if available >= required else Color("ddb793")
	_layout()

func _on_improve() -> void:
	if not is_instance_valid(well) or not well.is_panel_open():
		return
	if EconomyManager.is_well_improved():
		refresh()
		return
	var success := well.try_improve_from_panel()
	feedback.text = "Poço melhorado! A reserva agora comporta 20.\nA água se recupera no ritmo habitual." if success else "Não foi possível melhorar. Confira os materiais."
	feedback.show()
	refresh()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		well.close_panel()
		get_viewport().set_input_as_handled()

func _layout() -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	var width := minf(420, maxf(300, screen.x - 32))
	custom_minimum_size.x = width
	size = Vector2(width, get_combined_minimum_size().y)
	if not _positioned:
		position = (screen - size) / 2
		_positioned = true
	position = Vector2(clampf(position.x, 0, maxf(0, screen.x - size.x)), clampf(position.y, 0, maxf(0, screen.y - size.y)))

func _label(text_value: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label
