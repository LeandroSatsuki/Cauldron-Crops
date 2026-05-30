extends Panel

var item_vinculado: String = ""

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_STRING # Aceita qualquer item arrastado

func _drop_data(_at_position, data):
	item_vinculado = data
	$Label.text = data # Atualiza o visual
