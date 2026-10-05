extends Control

# Interface transitória; não é armazenamento, ferramenta ou estado de save.
var item_id: String = ""
var pending_item: String = ""
var card: PanelContainer
var application_bar: PanelContainer
var title_label: Label
var description_label: Label
var quantity_label: Label
var icon: TextureRect
var icon_label: Label
var apply_button: Button
var feedback_label: Label
var _last_size := Vector2.ZERO

func _ready() -> void:
	theme = preload("res://Themes/pixel_ui_theme.tres")
	name = "ItemUsePanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 300
	card = _panel("ItemCard")
	var body := _body(card)
	var header := HBoxContainer.new()
	body.add_child(header)
	icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	icon_label = Label.new()
	header.add_child(icon_label)
	title_label = _label(header)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_label = _label(body)
	description_label = _label(body)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	apply_button = Button.new()
	apply_button.text = "Aplicar"
	apply_button.pressed.connect(_apply_pressed)
	actions.add_child(apply_button)
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(close_card)
	actions.add_child(close)
	application_bar = _panel("ApplicationBar")
	var row := HBoxContainer.new()
	_body(application_bar).add_child(row)
	feedback_label = _label(row)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(cancel_application)
	row.add_child(cancel)
	card.hide()
	application_bar.hide()

func _panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	# Mesmo vocabulário provisório do jogo, fundo explicitamente opaco.
	style.bg_color = Color(0.12, 0.16, 0.10, 1.0)
	style.border_color = Color(0.53, 0.61, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _body(panel: PanelContainer) -> VBoxContainer:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	return body

func _label(parent: Node) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _main() -> Node:
	return get_parent().get_parent() if get_parent() != null else null

func show_item(id: String, defer_until_release: bool = false) -> void:
	cancel_application()
	close_card()
	if id == "" or (GlobalInventory.get_item_quantity(id) <= 0 and not (id == "pocao_crescimento" and GlobalInventory.cargas_crescimento > 0)):
		return
	if defer_until_release:
		pending_item = id
		return
	_open_card(id)

func _open_card(id: String) -> void:
	var ui := get_parent()
	if ui.has_method("_tem_popup_modal_aberto") and ui._tem_popup_modal_aberto():
		return
	item_id = id
	_refresh_card()
	card.show()
	_layout()
	ui._atualizar_modal_blocker()

func close_card() -> void:
	pending_item = ""
	item_id = ""
	if card != null:
		card.hide()
	var ui := get_parent()
	if ui != null and ui.is_inside_tree() and ui.has_method("_atualizar_modal_blocker"):
		ui._atualizar_modal_blocker()

func is_card_open() -> bool:
	return card != null and card.is_visible_in_tree()

func cancel_application() -> void:
	var main := _main()
	if main != null and main.has_method("cancel_consumable_application"):
		main.cancel_consumable_application()
	if application_bar != null:
		application_bar.hide()

func _refresh_card() -> void:
	title_label.text = Database.obter_nome_item(item_id)
	icon.texture = Database.obter_textura_item(item_id)
	icon.visible = icon.texture != null
	icon_label.text = Database.obter_icone_item(item_id)
	icon_label.visible = icon.texture == null
	quantity_label.text = "Mochila: %d" % GlobalInventory.get_item_quantity(item_id)
	if item_id == "pocao_crescimento":
		quantity_label.text += " · Doses disponíveis: %d" % GlobalInventory.cargas_crescimento
		description_label.text = "Reduz pela metade o tempo restante de uma planta crescendo. Cada frasco rende 3 doses. O frasco só é aberto na primeira aplicação válida."
	elif item_id == "preparo_solo_vivo":
		description_label.text = "Trata permanentemente o lote marcado, vazio e arado. Após regar e colher trigo, conserva umidade para o próximo trigo. Aplicar não rega."
	elif item_id == "adubo_flamejante":
		description_label.text = "Aplicar num tomate crescendo ou maduro acrescenta +2 tomates à próxima colheita. Uma aplicação por planta, antes de a colheita ser calculada. Não rega nem evita morte; se a planta morrer, o adubo é perdido."
	elif item_id == "mistura_restauradora":
		description_label.text = "Ingrediente para receitas e projetos de restauração. Use pelo caldeirão ou pelo painel do projeto; não é aplicado livremente no cenário."
	elif item_id == "pocao_purificadora_fraca":
		description_label.text = "Reagente de purificação. Clique num obstáculo corrompido e entregue pelo painel."
	elif item_id == "pocao_aceleradora":
		description_label.text = "Use pelo painel Golem. Preparar não gasta agora: um frasco da Mochila será usado ao iniciar a próxima nova entrega de colheita, com deslocamento +50%. Não altera uma entrega já iniciada."
	else:
		description_label.text = Database.obter_descricao_item(item_id)
		if description_label.text == "":
			description_label.text = "Consulte as receitas e projetos conhecidos para encontrar usos deste item."
	apply_button.visible = item_id in ["pocao_crescimento", "preparo_solo_vivo", "adubo_flamejante"]
	apply_button.disabled = GlobalInventory.get_item_quantity(item_id) <= 0 and not (item_id == "pocao_crescimento" and GlobalInventory.cargas_crescimento > 0)

func _apply_pressed() -> void:
	var id := item_id
	close_card()
	var main := _main()
	if main != null and main.has_method("begin_consumable_application"):
		main.begin_consumable_application(id)
	var ui := get_parent()
	ui.atualizar_destaques()
	ui.atualizar_status_jogo()

func _process(_delta: float) -> void:
	if get_viewport().gui_is_dragging():
		cancel_application()
		pending_item = ""
		if is_card_open():
			close_card()
	elif pending_item != "" and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var id := pending_item
		pending_item = ""
		_open_card(id)
	if is_card_open():
		if get_parent()._tem_popup_modal_aberto(false):
			close_card()
		else:
			_refresh_card()
	var main := _main()
	if main != null and main.has_method("begin_consumable_application"):
		var selected := str(main.selected_consumable)
		application_bar.visible = selected != ""
		if selected != "":
			var count := "%d doses · %d frascos" % [GlobalInventory.cargas_crescimento, GlobalInventory.get_item_quantity(selected)] if selected == "pocao_crescimento" else "%d na Mochila" % GlobalInventory.get_item_quantity(selected)
			feedback_label.text = "%s · %s\n%s" % [Database.obter_nome_item(selected), count, main.consumable_feedback]
	if _last_size != get_viewport_rect().size:
		_layout()
	# Containers podem mudar de altura após reflow/resize; manter no viewport.
	for panel in [card, application_bar]:
		# O primeiro reflow pode inflar a altura antes de a largura ser conhecida.
		# Recuperar o mínimo atual permite encolher novamente sem recortar texto.
		panel.reset_size()
		panel.position.x = clampf(panel.position.x, 12.0, maxf(12.0, _last_size.x - panel.size.x - 12.0))
		panel.position.y = clampf(panel.position.y, 12.0, maxf(12.0, _last_size.y - panel.size.y - 12.0))

func _layout() -> void:
	_last_size = get_viewport_rect().size
	var card_width := minf(340.0, _last_size.x - 24.0)
	card.custom_minimum_size.x = card_width
	card.size = Vector2(card_width, 0)
	card.position = Vector2((_last_size.x - card_width) / 2.0, maxf(100.0, (_last_size.y - card.size.y) / 2.0))
	var bar_width := minf(520.0, _last_size.x - 24.0)
	application_bar.custom_minimum_size.x = bar_width
	application_bar.size = Vector2(bar_width, 0)
	application_bar.position = Vector2((_last_size.x - bar_width) / 2.0, maxf(12.0, _last_size.y - application_bar.size.y - 16.0))

func handle_cancel_input(event: InputEvent) -> bool:
	var main := _main()
	var armed: bool = main != null and main.has_method("begin_consumable_application") and main.selected_consumable != ""
	if not is_card_open() and not armed:
		return false
	var cancel: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	cancel = cancel or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)
	if cancel:
		close_card()
		cancel_application()
	return cancel
