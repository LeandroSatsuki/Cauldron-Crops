extends Area2D

signal purified(obstacle_id: String)

@export var obstacle_id: String = "first_obstacle"
@export var purified_state: bool = false
@export var interaction_size: Vector2 = Vector2(360, 240)
@export var interaction_offset: Vector2 = Vector2.ZERO

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
	if GlobalInventory.inventario.get("pocao_purificadora_fraca", 0) < 1:
		_mostrar_feedback("Precisa de Poção Purificadora Fraca.")
		return

	print("PurificationObstacle: poção encontrada.")
	if not GlobalInventory.remover_item("pocao_purificadora_fraca", 1):
		_mostrar_feedback("Precisa de Poção Purificadora Fraca.")
		return

	purified_state = true
	print("PurificationObstacle: purificado.")
	_aplicar_estado()
	_atualizar_ui_pos_purificacao()
	_mostrar_feedback("Área purificada. Novos lotes foram revelados.")
	purified.emit(obstacle_id)

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
