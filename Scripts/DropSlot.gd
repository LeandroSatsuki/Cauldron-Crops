extends Panel

# Variável para armazenar o ID do item
var item_vinculado: String = ""

func _ready() -> void:
	# Garantir que este painel capture cliques e eventos de drop
	mouse_filter = Control.MOUSE_FILTER_STOP

func _can_drop_data(_at_position, data) -> bool:
	# Verifica se o dado é uma string (nome do item) e não está vazio
	return data is String and data != ""

func _drop_data(_at_position, data) -> void:
	item_vinculado = data
	
	# Atualiza o label apenas se ele existir, sem travar o jogo
	var label_node = get_node_or_null("Label")
	if label_node:
		label_node.text = data
		# Opcional: Garante que o Label não bloqueie novos drops
		label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
