extends Button

signal slot_clicado(item_id: String, is_right_click: bool, slot_node: Control)

var item_id: String = ""
var quantidade: int = 0
var tween_piscar: Tween

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

func _ready() -> void:
	# A MÁGICA ESTÁ AQUI: Garantir que o destaque visual
	# NUNCA bloqueie os cliques do mouse quando estiver visível.
	if destaque:
		destaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_label:
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if qtd_label:
		qtd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var icone := Database.obter_icone_item(item_id) if item_ativo else ""
	var nome := Database.obter_nome_item(item_id) if item_ativo else ""

	if icon_label:
		icon_label.text = "%s" % icone
		icon_label.tooltip_text = nome
		icon_label.visible = item_ativo
	if qtd_label:
		qtd_label.text = str(quantidade)
		qtd_label.visible = quantidade > 0
	tooltip_text = nome

func configurar_slot(id: String, qtd: int, texto_exibicao: String) -> void:
	item_id = id
	quantidade = qtd
	if icon_label:
		icon_label.text = "%s" % texto_exibicao
	if qtd_label:
		qtd_label.text = str(qtd)
	self.tooltip_text = texto_exibicao
	_atualizar_visual()

func set_destaque(ativo: bool) -> void:
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
