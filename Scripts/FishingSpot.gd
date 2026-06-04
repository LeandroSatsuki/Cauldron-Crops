extends Area2D

const FEEDBACK_OFFSET: Vector2 = Vector2(0.0, -60.0)
const FEEDBACK_COR: Color = Color(0.55, 0.93, 1.0, 1.0)

func _ready() -> void:
	add_to_group("fishing_spot")
	input_pickable = true

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is not InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	_on_lake_clicked()
	viewport.set_input_as_handled()

func _on_lake_clicked() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager == null or not tool_manager.has_method("is_fishing_rod_selected"):
		_mostrar_feedback("Selecione a Vara de Pesca.")
		return

	if bool(tool_manager.call("is_fishing_rod_selected")):
		_mostrar_feedback("Você lançou a vara.")
		print("FishingSpot: vara lancada.")
	else:
		_mostrar_feedback("Selecione a Vara de Pesca.")

func _mostrar_feedback(texto: String) -> void:
	var feedback_position: Vector2 = global_position + FEEDBACK_OFFSET
	var tree: SceneTree = get_tree()
	if tree == null:
		print(texto)
		return

	var current_scene: Node = tree.current_scene
	if current_scene == null:
		print(texto)
		return

	var ui: Node = current_scene.get_node_or_null("UI")
	if ui != null and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", texto, feedback_position, FEEDBACK_COR)
	else:
		print(texto)

func _obter_tool_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ToolManager")
