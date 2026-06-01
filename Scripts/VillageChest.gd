extends Node2D
class_name VillageChest

var inventory: Dictionary = {}
@onready var clickable_area: Area2D = $ClickableArea

func _ready() -> void:
	add_to_group("village_chest")
	if clickable_area and not clickable_area.input_event.is_connected(_on_clickable_area_input_event):
		clickable_area.input_event.connect(_on_clickable_area_input_event)

func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 15

func deposit_item(item_id: String, quantidade: int = 1) -> void:
	if item_id == "" or quantidade <= 0:
		return

	inventory[item_id] = int(inventory.get(item_id, 0)) + quantidade
	print("VillageChest: recebeu %s x%d. Total: %d" % [
		item_id,
		quantidade,
		int(inventory[item_id])
	])

func get_contents() -> Dictionary:
	return inventory.duplicate(true)

func set_contents(data: Dictionary) -> void:
	inventory = data.duplicate(true)

func withdraw_all_to_global_inventory() -> Dictionary:
	if inventory.is_empty():
		print("VillageChest: baú vazio, nada para retirar.")
		return {}

	var retirado: Dictionary = inventory.duplicate()
	for item_id in retirado.keys():
		var quantidade: int = int(retirado[item_id])
		if quantidade <= 0:
			continue
		GlobalInventory.adicionar_item(str(item_id), quantidade)
		print("VillageChest: retirado %s x%d para o inventário global." % [str(item_id), quantidade])

	inventory.clear()
	return retirado

func _on_clickable_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ui = get_tree().current_scene.get_node_or_null("UI")
		if ui and ui.has_method("abrir_bau_vila"):
			ui.abrir_bau_vila(self)
		else:
			push_warning("VillageChest: UI nao encontrada ou metodo abrir_bau_vila ausente.")
