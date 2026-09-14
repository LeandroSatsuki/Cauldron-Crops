extends Node2D
class_name VillageChest

var inventory: Dictionary = {}
@onready var clickable_area: Area2D = $ClickableArea
var _navigation_obstacle: NavigationObstacle2D = null

func _ready() -> void:
	add_to_group("village_chest")
	_navigation_obstacle = _ensure_navigation_obstacle(42.0)
	if clickable_area and not clickable_area.input_event.is_connected(_on_clickable_area_input_event):
		clickable_area.input_event.connect(_on_clickable_area_input_event)


func _ensure_navigation_obstacle(obstacle_radius: float) -> NavigationObstacle2D:
	var obstacle: NavigationObstacle2D = get_node_or_null("PlayerNavigationObstacle") as NavigationObstacle2D
	if obstacle == null:
		obstacle = NavigationObstacle2D.new()
		obstacle.name = "PlayerNavigationObstacle"
		add_child(obstacle)
	obstacle.radius = obstacle_radius
	obstacle.avoidance_enabled = true
	return obstacle

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

func clear_contents() -> void:
	inventory.clear()

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

func _on_clickable_area_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main: Node = get_tree().current_scene
		if main != null and main.has_method("request_player_interaction"):
			if bool(main.call("request_player_interaction", self, global_position, 52.0, Callable(self, "_open_chest"))):
				viewport.set_input_as_handled()
			return
		_open_chest()
		viewport.set_input_as_handled()


func _open_chest() -> void:
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("abrir_bau_vila"):
		ui.abrir_bau_vila(self)
	else:
		push_warning("VillageChest: UI nao encontrada ou metodo abrir_bau_vila ausente.")
