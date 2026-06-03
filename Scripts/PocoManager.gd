extends Node

var tempo_acumulado: float = 0.0

func _process(delta: float) -> void:
	if _is_current_scene_dev_scene():
		return

	tempo_acumulado += delta
	if tempo_acumulado >= 1.0:
		tempo_acumulado -= 1.0
		var agua_atual = GlobalInventory.inventario.get("agua", 0)
		if agua_atual < EconomyManager.poco_capacidade_maxima:
			GlobalInventory.adicionar_item("agua", 1)

func _is_current_scene_dev_scene() -> bool:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return false

	var scene_file_path: String = current_scene.scene_file_path
	return scene_file_path.begins_with("res://Scenes/dev/")
