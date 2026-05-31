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

@onready var icon_label: Label = $ItemIconLabel
@onready var qtd_label: Label = $QuantidadeLabel
@onready var destaque: ReferenceRect = $Destaque

func _carregar_textura_item(id_item: String) -> Texture2D:
	var caminhos := [
		"res://Assets/Items/%s.png" % id_item,
		"res://Assets/%s.png" % id_item
	]

	for caminho in caminhos:
		if ResourceLoader.exists(caminho):
			return load(caminho)

	return null

func _ready() -> void:
	# A MÁGICA ESTÁ AQUI: Garantir que o destaque visual 
	# NUNCA bloqueie os cliques do mouse quando estiver visível.
	if destaque:
		destaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_label:
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if qtd_label:
		qtd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func configurar_slot(id: String, qtd: int, texto_exibicao: String) -> void:
	item_id = id
	quantidade = qtd
	if icon_label:
		icon_label.text = texto_exibicao
	if qtd_label:
		qtd_label.text = str(qtd)
	self.tooltip_text = texto_exibicao

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
func _get_drag_data(at_position):
	if item_id == "":
		return null
	
	var preview = TextureRect.new()
	var textura_item = _carregar_textura_item(item_id)

	if textura_item:
		preview.texture = textura_item
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(40, 40)
		
		# Centralizador
		var control = Control.new()
		preview.position = -preview.custom_minimum_size / 2
		control.add_child(preview)
		set_drag_preview(control)
	else:
		# Fallback de segurança se a imagem não existir
		var text_preview = Label.new()
		text_preview.text = item_id
		set_drag_preview(text_preview)
		
	return item_id
