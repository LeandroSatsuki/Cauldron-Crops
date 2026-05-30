extends Area2D

func is_pixel_opaque(pos_in_parent: Vector2) -> bool:
	# A colisão está no centro do Area2D, então a distância da posição recebida (coordenada local do pai)
	# até a posição deste Area2D deve ser menor ou igual ao raio da colisão (35 pixels).
	return pos_in_parent.distance_to(position) <= 35.0
