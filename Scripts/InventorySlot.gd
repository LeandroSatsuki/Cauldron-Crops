extends Button

signal slot_clicado(item_id: String, is_right_click: bool, slot_node: Control)

var item_id: String = ""
var quantidade: int = 0
var tween_piscar: Tween
var item_texture_rect: TextureRect

var item_vinculado: String:
	get:
		return item_id
	set(value):
		item_id = value
		if is_node_ready():
			_atualizar_visual()

@onready var icon_label: Label = $ItemIconLabel
@onready var qtd_label: Label = $QuantidadeLabel
@onready var destaque: ReferenceRect = $Destaque

func _garantir_item_texture_rect() -> void:
	if item_texture_rect != null:
		return

	item_texture_rect = get_node_or_null("ItemTexture") as TextureRect
	if item_texture_rect == null:
		item_texture_rect = TextureRect.new()
		item_texture_rect.name = "ItemTexture"
		item_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		item_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(item_texture_rect)
		move_child(item_texture_rect, 0)

	item_texture_rect.visible = false
	item_texture_rect.texture = null

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	# A MÁGICA ESTÁ AQUI: Garantir que o destaque visual
	# NUNCA bloqueie os cliques do mouse quando estiver visível.
	if destaque:
		destaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_label:
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if qtd_label:
		qtd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_garantir_item_texture_rect()
	_atualizar_visual()

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

func _atualizar_visual() -> void:
	var item_ativo := item_id != ""
	var icone: String = str(Database.obter_icone_item(item_id)) if item_ativo else ""
	var nome: String = str(Database.obter_nome_item(item_id)) if item_ativo else ""
	var orientation := nome
	if item_id == "semente_verao":
		orientation += "\n" + Database.obter_descricao_item(item_id)
	var textura_item: Texture2D = Database.obter_textura_item(item_id) if item_ativo else null

	if item_texture_rect:
		item_texture_rect.texture = textura_item
		item_texture_rect.visible = textura_item != null

	if icon_label:
		icon_label.text = "%s" % icone
		icon_label.visible = item_ativo and textura_item == null
		icon_label.tooltip_text = orientation
	if qtd_label:
		qtd_label.text = str(quantidade)
		qtd_label.visible = quantidade > 0
	tooltip_text = orientation

func configurar_slot(id: String, qtd: int, texto_exibicao: String) -> void:
	item_id = id
	quantidade = qtd
	disabled = item_id == ""
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	if icon_label:
		icon_label.text = "%s" % texto_exibicao
	if item_texture_rect:
		item_texture_rect.texture = Database.obter_textura_item(id)
	if qtd_label:
		qtd_label.text = str(qtd)
	self.tooltip_text = texto_exibicao
	_atualizar_visual()

func set_destaque(ativo: bool) -> void:
	# Nenhuma selecao (ID vazio) nao representa um slot vazio selecionado.
	ativo = ativo and item_id != "" and quantidade > 0
	if not destaque:
		destaque = $Destaque
		
	if ativo:
		destaque.visible = true
		if tween_piscar:
			tween_piscar.kill()
		destaque.modulate.a = 1.0
		tween_piscar = create_tween().set_loops()
		tween_piscar.tween_property(destaque, "modulate:a", 0.3, 0.8)
		tween_piscar.tween_property(destaque, "modulate:a", 1.0, 0.8)
	else:
		if destaque:
			destaque.visible = false
		if tween_piscar:
			tween_piscar.kill()

# Dispara a seleção normalmente ao clicar (Sinal restaurado)
func _gui_input(event):
	if item_id == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("slot_clicado", item_id, false, self)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			emit_signal("slot_clicado", item_id, true, self)

# O arrasto funciona independentemente da seleção
func _get_drag_data(_at_position):
	if item_id == "":
		return null

	set_drag_preview(_criar_preview_drag(item_id))
	return item_id
