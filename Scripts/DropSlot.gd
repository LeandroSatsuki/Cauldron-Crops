extends Panel

var _item_vinculado: String = ""
var item_vinculado: String:
	get:
		return _item_vinculado
	set(value):
		_item_vinculado = str(value)
		if is_node_ready():
			_atualizar_visual()

@onready var icon_rect: TextureRect = $ItemIcon
var item_text_label: Label = null

func _carregar_textura_item(id_item: String) -> Texture2D:
	var caminhos := [
		"res://Assets/Items/%s.png" % id_item,
		"res://Assets/%s.png" % id_item
	]

	for caminho in caminhos:
		if ResourceLoader.exists(caminho):
			return load(caminho)

	return null

func _criar_preview_drag(item_id_preview: String) -> Control:
	var conteudo := PanelContainer.new()
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.custom_minimum_size = Vector2(160, 56)

	var margem := MarginContainer.new()
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_theme_constant_override("margin_left", 10)
	margem.add_theme_constant_override("margin_top", 6)
	margem.add_theme_constant_override("margin_right", 10)
	margem.add_theme_constant_override("margin_bottom", 6)
	conteudo.add_child(margem)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = "%s %s" % [Database.obter_icone_item(item_id_preview), Database.obter_nome_item(item_id_preview)]
	margem.add_child(label)

	return conteudo

func _garantir_item_label() -> void:
	item_text_label = get_node_or_null("ItemIconLabel") as Label
	if item_text_label == null:
		item_text_label = Label.new()
		item_text_label.name = "ItemIconLabel"
		item_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_text_label.add_theme_font_size_override("font_size", 30)
		item_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(item_text_label)
		move_child(item_text_label, get_child_count() - 1)

func _atualizar_visual() -> void:
	if icon_rect:
		icon_rect.visible = false
		icon_rect.texture = null

	var item_ativo := _item_vinculado != ""
	var icone := Database.obter_icone_item(_item_vinculado) if item_ativo else ""
	var nome := Database.obter_nome_item(_item_vinculado) if item_ativo else ""

	if item_text_label:
		item_text_label.visible = item_ativo
		item_text_label.text = icone
		item_text_label.tooltip_text = nome
	tooltip_text = nome

func _ready() -> void:
	# Garantir que este painel capture cliques e eventos de drop
	mouse_filter = Control.MOUSE_FILTER_STOP
	if icon_rect:
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.visible = false
	_garantir_item_label()
	_atualizar_visual()

func _can_drop_data(_at_position, data) -> bool:
	# Verifica se o dado é uma string (nome do item) e não está vazio
	return data is String and data != ""

func _drop_data(_at_position, data) -> void:
	item_vinculado = str(data)
	_atualizar_visual()
	print("Slot do Caldeirão recebeu: ", data)

# Adicionado para depuração visual:
# Isso ajuda a saber se o sistema de Drag & Drop está vendo o slot
func _get_drag_data(_at_position):
	if item_vinculado != "":
		set_drag_preview(_criar_preview_drag(item_vinculado))
		return item_vinculado
	return null
