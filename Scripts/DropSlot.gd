extends Panel

var item_vinculado: String = ""

func _can_drop_data(at_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_STRING

func _drop_data(at_pos: Vector2, data: Variant) -> void:
	item_vinculado = data
	var label = get_node_or_null("Label")
	if label:
		label.text = data
