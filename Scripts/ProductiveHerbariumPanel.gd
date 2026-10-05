extends PanelContainer

const RESOURCE_ACCESS := preload("res://Scripts/VillageResourceAccess.gd")
var site: Node2D
var status_label: Label
var cost_box: VBoxContainer
var feedback: Label
var action_button: Button
var scroll: ScrollContainer
var _amount_labels: Dictionary = {}
var _drag := UIDragHelper.new()
var _positioned := false

func bind_site(value: Node2D) -> void:
	site = value

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
	var title := _label("Herbário produtivo", box)
	title.add_theme_font_size_override("font_size", 18)
	_drag.attach(self, title)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_label("Uma Raiz Gélida por coleta, na Mochila.\nRenova em 90 segundos de sessão aberta.\nGuarda no máximo uma coleta pronta.", content)
	status_label = _label("", content)
	cost_box = VBoxContainer.new()
	content.add_child(cost_box)
	for id in HerbariumProduction.PROJECT_REQUIREMENTS:
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
	_label("Investimento único. Baú da Vila primeiro;\nMochila para completar. Abrir não gasta.", cost_box)
	feedback = _label("", content)
	feedback.hide()
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	action_button = Button.new()
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.custom_minimum_size.y = 38
	action_button.pressed.connect(_on_action)
	buttons.add_child(action_button)
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(func(): site.close_panel())
	buttons.add_child(close)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func open() -> void:
	feedback.hide()
	_positioned = false
	refresh()
	_center_after_layout.call_deferred()

func _center_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and is_visible_in_tree():
		_positioned = false
		_layout()

func _process(_delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(site):
		refresh()

func refresh() -> void:
	var status: Dictionary = HerbariumProduction.get_status(site)
	var code: String = status["code"]
	status_label.text = {
		"locked": "Restaure o Herbário e a Clareira para liberar esta melhoria opcional.",
		"missing": "Faltam materiais para ativar a produção.",
		"ready": "Materiais completos. A primeira coleta ficará pronta no ponto.",
		"available": "Uma Raiz Gélida pronta para coletar.",
		"renewing": "Próxima coleta em %d s. O tempo continua no Bosque." % ceili(float(status["renewal_remaining"])),
		"home_unavailable": "Retorne à vila para interagir.",
	}.get(code, "Indisponível.")
	cost_box.visible = not bool(status["activated"])
	action_button.text = "Coletar · 1 Raiz" if bool(status["activated"]) else "Ativar produção"
	action_button.disabled = code not in ["ready", "available"]
	var access := RESOURCE_ACCESS.new(site.get_parent().get_node_or_null("VillageChest"))
	for id in _amount_labels:
		_amount_labels[id].text = "%s  %d / %d" % [Database.obter_nome_item(id), access.get_available(id), HerbariumProduction.PROJECT_REQUIREMENTS[id]]
	_layout()

func _on_action() -> void:
	if not is_instance_valid(site) or not site.is_panel_open():
		return
	var was_active := HerbariumProduction.activated
	var success: bool = site.try_collect_from_panel() if was_active else site.try_activate_from_panel()
	feedback.text = ("Raiz Gélida guardada na Mochila." if was_active else "Produção ativada. Primeira coleta disponível.") if success else ("Nada coletado. Confira espaço na Mochila e alcance." if was_active else "Nada gasto. Confira marcos, materiais e alcance.")
	feedback.show()
	refresh()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		site.close_panel()
		get_viewport().set_input_as_handled()

func _layout() -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	var width := minf(420, maxf(240, screen.x - 32))
	custom_minimum_size.x = width
	var content := scroll.get_child(0) as Control
	scroll.custom_minimum_size.y = minf(maxf(80, content.get_combined_minimum_size().y), minf(310, maxf(80, screen.y - 150)))
	reset_size()
	size.x = width
	if not _positioned:
		position = (screen - size) / 2
		_positioned = true
	position = Vector2(clampf(position.x, 0, maxf(0, screen.x - size.x)), clampf(position.y, 0, maxf(0, screen.y - size.y)))

func _label(value: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label
