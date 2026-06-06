extends Area2D

signal purified(obstacle_id: String)

@export var obstacle_id: String = "first_obstacle"
@export var purified_state: bool = false
@export var interaction_size: Vector2 = Vector2(360, 240)
@export var interaction_offset: Vector2 = Vector2.ZERO
var purification_requirements: Array[Dictionary] = [
	{"item_id": "pocao_purificadora_fraca", "quantity": 1},
	{"item_id": "escama_brilhante", "quantity": 1},
	{"item_id": "trigo", "quantity": 3}
]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $Visual

func _ready() -> void:
	add_to_group("purification_obstacle")
	input_pickable = true
	set_process_input(true)
	set_process_unhandled_input(true)
	print("PurificationObstacle: ready. parent=%s global_position=%s visible=%s purificado=%s" % [str(get_parent().get_path() if get_parent() else "null"), str(global_position), str(visible), str(purified_state)])
	_aplicar_estado()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if try_handle_global_click(get_global_mouse_position()):
			_viewport.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		return

	var click_position: Vector2 = get_global_mouse_position()
	if try_handle_global_click(click_position):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_event.pressed:
		return

	var click_position: Vector2 = get_global_mouse_position()
	if try_handle_global_click(click_position):
		get_viewport().set_input_as_handled()

func _get_interaction_rect() -> Rect2:
	var center: Vector2 = global_position + interaction_offset
	return Rect2(center - interaction_size * 0.5, interaction_size)

func _is_click_inside_purification_area(global_point: Vector2) -> bool:
	return _get_interaction_rect().has_point(global_point)

func try_handle_global_click(global_point: Vector2) -> bool:
	var rect: Rect2 = _get_interaction_rect()
	if purified_state:
		print("PurificationObstacle: clique ignorado, ja purificado. click global=", global_point, " rect=", rect, " purificado=", purified_state)
		return false

	var inside: bool = rect.has_point(global_point)
	print("PurificationObstacle: click global=", global_point, " rect=", rect, " inside=", inside, " purificado=", purified_state)
	if not inside:
		return false

	print("PurificationObstacle: clique recebido na area bloqueada.")
	_tentar_purificar()
	return true

func _tentar_purificar() -> void:
	if purified_state:
		return

	print("PurificationObstacle: tentando purificar %s." % obstacle_id)
	var missing: Dictionary = _get_missing_requirements()
	if not missing.is_empty():
		_mostrar_feedback(_format_missing_requirements_text(missing))
		return

	if not _consume_requirements():
		_mostrar_feedback("Falha ao consumir requisitos de purificação.")
		return

	purified_state = true
	print("PurificationObstacle: purificado.")
	_aplicar_estado()
	_atualizar_ui_pos_purificacao()
	_mostrar_feedback("Área purificada. Novos lotes foram revelados.")
	purified.emit(obstacle_id)

func _get_inventory_quantity(item_id: String) -> int:
	return int(GlobalInventory.inventario.get(item_id, 0))

func _get_item_display_name(item_id: String) -> String:
	if Database != null and Database.has_method("obter_nome_item"):
		var nome: String = str(Database.obter_nome_item(item_id))
		if nome != "":
			return nome
	return item_id

func _get_missing_requirements() -> Dictionary:
	var missing: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		var required_quantity: int = int(requirement.get("quantity", 0))
		var current_quantity: int = _get_inventory_quantity(item_id)
		var missing_quantity: int = required_quantity - current_quantity
		if missing_quantity > 0:
			missing[item_id] = missing_quantity

	return missing

func _has_all_requirements() -> bool:
	return _get_missing_requirements().is_empty()

func _consume_requirements() -> bool:
	if not _has_all_requirements():
		return false

	var consumidos: Array[Dictionary] = []
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		var quantity: int = int(requirement.get("quantity", 0))
		if quantity <= 0:
			continue

		if not GlobalInventory.remover_item(item_id, quantity):
			push_error("PurificationObstacle: falha inesperada ao consumir %s x%d." % [item_id, quantity])
			for consumed_variant in consumidos:
				if typeof(consumed_variant) != TYPE_DICTIONARY:
					continue
				var consumed: Dictionary = consumed_variant
				var consumed_item_id: String = str(consumed.get("item_id", ""))
				var consumed_quantity: int = int(consumed.get("quantity", 0))
				if consumed_item_id != "" and consumed_quantity > 0:
					GlobalInventory.adicionar_item(consumed_item_id, consumed_quantity)
			return false

		consumidos.append({"item_id": item_id, "quantity": quantity})

	return true

func _format_requirements_text() -> String:
	var partes: Array[String] = []
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		var quantity: int = int(requirement.get("quantity", 0))
		if item_id == "" or quantity <= 0:
			continue

		partes.append("%s x%d" % [_get_item_display_name(item_id), quantity])

	if partes.is_empty():
		return "Requer: nenhum requisito definido."
	return "Requer: %s." % ", ".join(partes)

func _format_missing_requirements_text(missing: Dictionary) -> String:
	var partes: Array[String] = []
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "" or not missing.has(item_id):
			continue

		var missing_quantity: int = int(missing.get(item_id, 0))
		if missing_quantity <= 0:
			continue

		partes.append("%s x%d" % [_get_item_display_name(item_id), missing_quantity])

	if partes.is_empty():
		return _format_requirements_text()
	return "Faltam: %s." % ", ".join(partes)


func _aplicar_estado() -> void:
	if collision_shape:
		collision_shape.disabled = purified_state
	if visual_root:
		visual_root.visible = not purified_state
	input_pickable = not purified_state
	visible = not purified_state
	modulate = Color(1, 1, 1, 1.0)

func _atualizar_ui_pos_purificacao() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var ui: Node = scene.get_node_or_null("UI")
	if ui == null:
		return

	if ui.has_method("verificar_e_atualizar_inventario"):
		ui.call("verificar_e_atualizar_inventario")
	if ui.has_method("atualizar_status_jogo"):
		ui.call("atualizar_status_jogo")

func _mostrar_feedback(texto: String) -> void:
	var scene: Node = get_tree().current_scene
	if scene != null:
		var ui: Node = scene.get_node_or_null("UI")
		if ui != null and ui.has_method("criar_texto_flutuante"):
			ui.call("criar_texto_flutuante", texto, global_position, Color(0.8, 0.95, 1.0))
			return

	print(texto)

func get_save_data() -> Dictionary:
	return {
		"obstacle_id": obstacle_id,
		"purified": purified_state
	}

func load_save_data(data: Dictionary) -> void:
	var estava_purificado := purified_state
	if data.has("obstacle_id"):
		obstacle_id = str(data.get("obstacle_id", obstacle_id))
	if data.has("purified"):
		purified_state = bool(data.get("purified", purified_state))
	_aplicar_estado()
	if purified_state and not estava_purificado:
		purified.emit(obstacle_id)
