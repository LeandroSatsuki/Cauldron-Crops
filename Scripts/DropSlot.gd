extends Panel

# Variável para armazenar o ID do item
var item_vinculado: String = ""
@onready var icon_rect: TextureRect = $ItemIcon

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
	# Garantir que este painel capture cliques e eventos de drop
	mouse_filter = Control.MOUSE_FILTER_STOP

func _can_drop_data(_at_position, data) -> bool:
	# Verifica se o dado é uma string (nome do item) e não está vazio
	return data is String and data != ""

func _drop_data(_at_position, data) -> void:
	item_vinculado = data
	
	var label_node = get_node_or_null("Label")
	if label_node:
		label_node.text = "" # Limpa o texto "Soltar item"
		label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var textura_item = _carregar_textura_item(data)
	if textura_item and icon_rect:
		icon_rect.texture = textura_item
	else:
		print("AVISO: Nenhuma imagem encontrada para o item '%s' em res://Assets/Items/ ou res://Assets/." % data)
	
	print("Slot do Caldeirão recebeu: ", data)

# Adicionado para depuração visual: 
# Isso ajuda a saber se o sistema de Drag & Drop está vendo o slot
func _get_drag_data(_at_position):
	if item_vinculado != "":
		var preview = Label.new()
		preview.text = item_vinculado
		set_drag_preview(preview)
		return item_vinculado
	return null
