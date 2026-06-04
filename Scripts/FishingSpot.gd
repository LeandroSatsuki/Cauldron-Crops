extends Area2D

enum FishingState {
	IDLE,
	BOBBER_CAST,
	FISH_BITING
}

@onready var bobber: Node2D = $Bobber
@onready var fishing_bite_timer: Timer = $FishingBiteTimer

const FEEDBACK_OFFSET: Vector2 = Vector2(0.0, -60.0)
const FEEDBACK_COR: Color = Color(0.55, 0.93, 1.0, 1.0)
const BOBBER_READY_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const BOBBER_BITING_MODULATE: Color = Color(1.0, 0.86, 0.42, 1.0)
const BOBBER_BITING_SCALE: Vector2 = Vector2(1.15, 1.15)

var fishing_state: FishingState = FishingState.IDLE
var bobber_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("fishing_spot")
	input_pickable = true
	if bobber != null:
		bobber_base_scale = bobber.scale
	if fishing_bite_timer != null and not fishing_bite_timer.timeout.is_connected(_on_fishing_bite_timer_timeout):
		fishing_bite_timer.timeout.connect(_on_fishing_bite_timer_timeout)
		if fishing_bite_timer.wait_time <= 0.0:
			fishing_bite_timer.wait_time = 3.0
		fishing_bite_timer.one_shot = true
	_definir_estado(FishingState.IDLE)

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
		if fishing_state == FishingState.FISH_BITING:
			_mostrar_feedback("A pesca de sincronia ainda não foi implementada.", click_global_position)
			print("FishingSpot: puxada fake aguardando minigame.")
			_definir_estado(FishingState.IDLE)
			return

		_posicionar_boia(click_global_position)
	else:
		_mostrar_feedback("Selecione a Vara de Pesca.", click_global_position)

func _posicionar_boia(click_global_position: Vector2) -> void:
	if bobber == null:
		push_warning("FishingSpot: bobber nao encontrado.")
		return

	bobber.global_position = click_global_position
	if fishing_state == FishingState.BOBBER_CAST:
		_mostrar_feedback("Boia reposicionada.", click_global_position)
		print("FishingSpot: boia reposicionada.")
	else:
		_mostrar_feedback("Boia lançada.", click_global_position)
		print("FishingSpot: boia lancada.")

	_definir_estado(FishingState.BOBBER_CAST)
	if fishing_bite_timer != null:
		fishing_bite_timer.stop()
		fishing_bite_timer.start()

func _on_fishing_bite_timer_timeout() -> void:
	if fishing_state != FishingState.BOBBER_CAST:
		return

	_definir_estado(FishingState.FISH_BITING)
	var feedback_origin: Vector2 = bobber.global_position if bobber != null else global_position
	_mostrar_feedback("Algo puxou a linha!", feedback_origin)
	print("FishingSpot: algo puxou a linha.")

func _definir_estado(novo_estado: FishingState) -> void:
	fishing_state = novo_estado
	if bobber == null:
		return

	match fishing_state:
		FishingState.IDLE:
			bobber.visible = false
			bobber.scale = bobber_base_scale
			bobber.modulate = BOBBER_READY_MODULATE
			if fishing_bite_timer != null:
				fishing_bite_timer.stop()
		FishingState.BOBBER_CAST:
			bobber.visible = true
			bobber.scale = bobber_base_scale
			bobber.modulate = BOBBER_READY_MODULATE
		FishingState.FISH_BITING:
			bobber.visible = true
			bobber.scale = Vector2(
				bobber_base_scale.x * BOBBER_BITING_SCALE.x,
				bobber_base_scale.y * BOBBER_BITING_SCALE.y
			)
			bobber.modulate = BOBBER_BITING_MODULATE

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
