extends Panel

# Este script age como um "buraco negro" para qualquer input que
# caia nas áreas vazias do popup (entre os DropSlots).
# Garante que NENHUM clique ou drop vaze para a plantação (Area2D) abaixo.

func _can_drop_data(_at_position, data) -> bool:
	# Retorna true para QUALQUER dado.
	# Isso faz a UI capturar o item e impede o Godot de
	# passar o drop para o mundo 2D/plantação abaixo.
	return true

func _drop_data(_at_position, data) -> void:
	# Não faz absolutamente nada.
	# O item apenas "cai no fundo" com segurança.
	print("DEBUG: Item interceptado pelo fundo do Popup e descartado com segurança.")
