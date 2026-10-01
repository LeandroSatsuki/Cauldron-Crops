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


func get_item_quantity(item_id: String) -> int:
	if item_id == "":
		return 0
	return maxi(int(inventory.get(item_id, 0)), 0)


func get_depositable_personal_items() -> Dictionary:
	var items: Dictionary = {}
	for item_variant in GlobalInventory.inventario:
		var item_id := str(item_variant)
		var quantity := int(GlobalInventory.inventario[item_variant])
		# Agua pertence a reserva regeneravel do poco, fora dos slots da Mochila.
		if item_id != "" and item_id != "agua" and quantity > 0:
			items[item_id] = quantity
	return items


func deposit_from_personal_inventory(item_id: String, quantity: int) -> bool:
	if quantity <= 0 or int(get_depositable_personal_items().get(item_id, 0)) < quantity:
		return false
	# Operacao sincrona: o destino atual nao possui capacidade nem pode recusar.
	if not GlobalInventory.remover_item(item_id, quantity):
		return false
	deposit_item(item_id, quantity)
	if GlobalInventory.semente_selecionada == item_id and int(GlobalInventory.inventario.get(item_id, 0)) == 0:
		GlobalInventory.semente_selecionada = ""
	return true


func withdraw_item(item_id: String, quantidade: int = 1) -> bool:
	if item_id == "" or quantidade <= 0:
		return false
	var current_quantity: int = get_item_quantity(item_id)
	if current_quantity < quantidade:
		return false
	var remaining_quantity: int = current_quantity - quantidade
	if remaining_quantity > 0:
		inventory[item_id] = remaining_quantity
	else:
		inventory.erase(item_id)
	print("VillageChest: retirou %s x%d. Restam: %d" % [
		item_id,
		quantidade,
		remaining_quantity,
	])
	return true

func withdraw_to_personal_inventory(item_id: String, quantity: int) -> bool:
	if item_id == "" or quantity <= 0 or get_item_quantity(item_id) < quantity:
		return false
	var acceptance: Dictionary = GlobalInventory.get_acceptance(item_id, quantity)
	if int(acceptance.get("accepted", 0)) != quantity:
		return false
	if not withdraw_item(item_id, quantity):
		return false
	var insertion: Dictionary = GlobalInventory.try_add_item(item_id, quantity)
	if int(insertion.get("accepted", 0)) != quantity:
		# Defesa transacional: se o destino mudar inesperadamente entre consulta e
		# insercao, desfaz qualquer parte aceita e restaura a origem completa.
		var accepted := int(insertion.get("accepted", 0))
		if accepted > 0:
			GlobalInventory.remover_item(item_id, accepted)
		deposit_item(item_id, quantity)
		return false
	return true


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

	var snapshot: Dictionary = inventory.duplicate()
	var retirado: Dictionary = {}
	for item_id in snapshot.keys():
		var quantidade: int = int(snapshot[item_id])
		if quantidade <= 0:
			continue
		if withdraw_to_personal_inventory(str(item_id), quantidade):
			retirado[item_id] = quantidade
			print("VillageChest: retirado %s x%d para a Mochila." % [str(item_id), quantidade])
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
