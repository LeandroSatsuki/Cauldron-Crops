extends Panel

var item_vinculado: String = ""

func _can_drop_data(_at_position, data):
	# Verifica se o dado é uma string (nome do item)
	return data is String and data != ""

func _drop_data(_at_position, data):
	item_vinculado = data
	var label_node = get_node_or_null("Label") # Procura o nó com segurança
	if label_node:
		label_node.text = data
	else:
		print("ERRO: Nó 'Label' não encontrado dentro de ", name)
	print("Slot do Caldeirão recebeu: ", data)
