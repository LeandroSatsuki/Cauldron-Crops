extends Area2D

@onready var bobber: Node2D = $Bobber

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
	var click_global_position: Vector2 = get_global_mouse_position()
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager == null or not tool_manager.has_method("is_fishing_rod_selected"):
		_mostrar_feedback("Selecione a Vara de Pesca.", click_global_position)
		return

	if bool(tool_manager.call("is_fishing_rod_selected")):
		_posicionar_boia(click_global_position)
	else:
		_mostrar_feedback("Selecione a Vara de Pesca.", click_global_position)

func _posicionar_boia(click_global_position: Vector2) -> void:
	if bobber == null:
		push_warning("FishingSpot: bobber nao encontrado.")
		return

	bobber.global_position = click_global_position
	if bobber.visible:
		_mostrar_feedback("Boia reposicionada.", click_global_position)
		print("FishingSpot: boia reposicionada.")
	else:
		bobber.visible = true
		_mostrar_feedback("Boia lançada.", click_global_position)
		print("FishingSpot: boia lancada.")

func _mostrar_feedback(texto: String, origem_global: Vector2) -> void:
	var feedback_position: Vector2 = origem_global + FEEDBACK_OFFSET
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
