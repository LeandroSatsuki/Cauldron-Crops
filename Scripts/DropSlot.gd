extends Panel

var item_vinculado: String = ""

func _can_drop_data(_at_position, data):
	# Verifica se o dado é uma string (nome do item)
	return data is String and data != ""

func _drop_data(_at_position, data):
	item_vinculado = data
	$Label.text = data # Atualiza o texto do slot
	print("Slot do Caldeirão recebeu: ", data)
