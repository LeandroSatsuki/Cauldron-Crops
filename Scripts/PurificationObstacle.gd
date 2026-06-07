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
var purification_progress: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $Visual

func _ready() -> void:
	add_to_group("purification_obstacle")
	input_pickable = true
	_normalizar_progresso()
	_aplicar_estado()
	print("PurificationObstacle: ready. parent=%s global_position=%s visible=%s purificado=%s" % [str(get_parent().get_path() if get_parent() else "null"), str(global_position), str(visible), str(purified_state)])

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if try_handle_global_click(get_global_mouse_position()):
			_viewport.set_input_as_handled()

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

	var ui := _obter_ui()
	if ui != null and ui.has_method("_tem_popup_modal_aberto") and ui.call("_tem_popup_modal_aberto"):
		return false

	var inside: bool = rect.has_point(global_point)
	print("PurificationObstacle: click global=", global_point, " rect=", rect, " inside=", inside, " purificado=", purified_state)
	if not inside:
		return false

	print("PurificationObstacle: clique recebido na area bloqueada.")
	if ui != null and ui.has_method("abrir_painel_purificacao"):
		ui.call("abrir_painel_purificacao", self)
	else:
		_mostrar_feedback(_format_requirements_text())
	return true

func get_obstacle_id() -> String:
	return obstacle_id

func get_purification_requirements() -> Array:
	return purification_requirements.duplicate(true)

func get_delivered_requirements() -> Dictionary:
	_normalizar_progresso()
	var delivered: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		delivered[item_id] = int(purification_progress.get(item_id, 0))

	return delivered

func get_missing_requirements() -> Dictionary:
	_normalizar_progresso()
	var missing: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		var required_quantity: int = int(requirement.get("quantity", 0))
		var delivered_quantity: int = int(purification_progress.get(item_id, 0))
		var missing_quantity: int = required_quantity - delivered_quantity
		if missing_quantity > 0:
			missing[item_id] = missing_quantity

	return missing

func can_purify() -> bool:
	if purified_state:
		return false
	return get_missing_requirements().is_empty()

func deliver_requirement(item_id: String) -> int:
	if purified_state or item_id == "":
		return 0

	var requirement_quantity := _obter_quantidade_requerida(item_id)
	if requirement_quantity <= 0:
		return 0

	_normalizar_progresso()
	var delivered_quantity: int = int(purification_progress.get(item_id, 0))
	var missing_quantity: int = requirement_quantity - delivered_quantity
	if missing_quantity <= 0:
		return 0

	var inventory_quantity: int = int(GlobalInventory.inventario.get(item_id, 0))
	if inventory_quantity <= 0:
		return 0

	var quantity_to_deliver: int = min(missing_quantity, inventory_quantity)
	if quantity_to_deliver <= 0:
		return 0

	if not GlobalInventory.remover_item(item_id, quantity_to_deliver):
		push_warning("PurificationObstacle: falha ao remover %s x%d do inventario." % [item_id, quantity_to_deliver])
		return 0

	purification_progress[item_id] = min(delivered_quantity + quantity_to_deliver, requirement_quantity)
	_notificar_interface_purificacao()
	return quantity_to_deliver

func deliver_all_available() -> Dictionary:
	var delivered: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		var delivered_quantity: int = deliver_requirement(item_id)
		if delivered_quantity > 0:
			delivered[item_id] = delivered_quantity

	return delivered

func finalize_purification() -> bool:
	if not can_purify():
		return false

	_definir_progresso_completo()
	purified_state = true
	print("PurificationObstacle: purificado.")
	_aplicar_estado()
	var ui := _obter_ui()
	if ui != null and ui.has_method("mostrar_feedback_purificacao"):
		ui.call("mostrar_feedback_purificacao", global_position)
	else:
		_mostrar_feedback("Área purificada! Novos lotes foram revelados.")
	_notificar_interface_purificacao()
	if ui != null and ui.has_method("fechar_painel_purificacao"):
		ui.call("fechar_painel_purificacao")
	purified.emit(obstacle_id)
	return true

func _get_item_display_name(item_id: String) -> String:
	if Database != null and Database.has_method("obter_nome_item"):
		var nome: String = str(Database.obter_nome_item(item_id))
		if nome != "":
			return nome
	return item_id

func _obter_quantidade_requerida(item_id: String) -> int:
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		if str(requirement.get("item_id", "")) != item_id:
			continue

		return int(requirement.get("quantity", 0))

	return 0

func _normalizar_progresso() -> void:
	var progresso_normalizado: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		var required_quantity: int = int(requirement.get("quantity", 0))
		var current_quantity: int = int(purification_progress.get(item_id, 0))
		if current_quantity < 0:
			current_quantity = 0
		progresso_normalizado[item_id] = min(current_quantity, required_quantity)

	purification_progress = progresso_normalizado

func _definir_progresso_completo() -> void:
	var completo: Dictionary = {}
	for requirement_variant in purification_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue

		var requirement: Dictionary = requirement_variant
		var item_id: String = str(requirement.get("item_id", ""))
		if item_id == "":
			continue

		completo[item_id] = int(requirement.get("quantity", 0))

	purification_progress = completo

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

func _notificar_interface_purificacao() -> void:
	var ui := _obter_ui()
	if ui == null:
		return

	if ui.has_method("atualizar_painel_purificacao"):
		ui.call_deferred("atualizar_painel_purificacao")
	if ui.has_method("verificar_e_atualizar_inventario"):
		ui.call_deferred("verificar_e_atualizar_inventario")
	if ui.has_method("atualizar_status_jogo"):
		ui.call_deferred("atualizar_status_jogo")

func _atualizar_ui_pos_purificacao() -> void:
	_notificar_interface_purificacao()

func _mostrar_feedback(texto: String) -> void:
	var scene: Node = get_tree().current_scene
	if scene != null:
		var ui: Node = scene.get_node_or_null("UI")
		if ui != null and ui.has_method("criar_texto_flutuante"):
			ui.call("criar_texto_flutuante", texto, global_position, Color(0.8, 0.95, 1.0))
			return

	print(texto)

func _obter_ui() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null

	var scene: Node = tree.current_scene
	if scene == null:
		return null

	return scene.get_node_or_null("UI")

func get_save_data() -> Dictionary:
	return {
		"obstacle_id": obstacle_id,
		"purified": purified_state,
		"purification_progress": get_delivered_requirements()
	}

func load_save_data(data: Dictionary) -> void:
	var estava_purificado := purified_state
	if data.has("obstacle_id"):
		obstacle_id = str(data.get("obstacle_id", obstacle_id))
	if data.has("purified"):
		purified_state = bool(data.get("purified", purified_state))
	if data.has("purification_progress"):
		var progresso_carregado: Dictionary = {}
		var progresso_data_variant: Variant = data.get("purification_progress", {})
		if typeof(progresso_data_variant) == TYPE_DICTIONARY:
			progresso_carregado = progresso_data_variant
		purification_progress = progresso_carregado.duplicate(true)

	_normalizar_progresso()
	if purified_state:
		_definir_progresso_completo()
	_aplicar_estado()
	if purified_state and not estava_purificado:
		purified.emit(obstacle_id)
