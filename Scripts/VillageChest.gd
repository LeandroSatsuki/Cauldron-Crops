extends Node2D
class_name VillageChest

var inventory: Dictionary = {}

func _ready() -> void:
	add_to_group("village_chest")

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
	return inventory.duplicate()
