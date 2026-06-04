extends Area2D

enum FishingState {
	IDLE,
	BOBBER_CAST,
	FISH_BITING,
	MINIGAME_ACTIVE
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
var fishing_minigame_ui: Node = null

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
	if fishing_state == FishingState.MINIGAME_ACTIVE:
		_mostrar_feedback("Finalize a pesca atual.", click_global_position)
		return

	var tool_manager: Node = _obter_tool_manager()
	if tool_manager == null or not tool_manager.has_method("is_fishing_rod_selected"):
		_mostrar_feedback("Selecione a Vara de Pesca.", click_global_position)
		return

	if bool(tool_manager.call("is_fishing_rod_selected")):
		if fishing_state == FishingState.FISH_BITING:
			if _abrir_pesca_sincronia(click_global_position):
				_definir_estado(FishingState.MINIGAME_ACTIVE)
			else:
				_mostrar_feedback("Nao foi possivel abrir a sincronia.", click_global_position)
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
		FishingState.MINIGAME_ACTIVE:
			bobber.visible = false
			bobber.scale = bobber_base_scale
			bobber.modulate = BOBBER_READY_MODULATE
			if fishing_bite_timer != null:
				fishing_bite_timer.stop()

func _mostrar_feedback(texto: String, origem_global: Vector2) -> void:
	var feedback_position: Vector2 = origem_global + FEEDBACK_OFFSET
	var ui: Node = _obter_ui_principal()
	if ui != null and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", texto, feedback_position, FEEDBACK_COR)
	else:
		print(texto)

func _abrir_pesca_sincronia(origem_global: Vector2) -> bool:
	var ui: Node = _obter_ui_principal()
	if ui == null:
		push_warning("FishingSpot: UI principal nao encontrada para pesca de sincronia.")
		return false
	if not ui.has_method("abrir_pesca_sincronia"):
		push_warning("FishingSpot: UI principal nao possui abrir_pesca_sincronia.")
		return false
	var popup: Variant = ui.call("abrir_pesca_sincronia", origem_global)
	if popup == null:
		return false
	if popup is Node:
		fishing_minigame_ui = popup
		if fishing_minigame_ui.has_signal("minigame_closed") and not fishing_minigame_ui.minigame_closed.is_connected(_on_fishing_minigame_closed):
			fishing_minigame_ui.minigame_closed.connect(_on_fishing_minigame_closed)
		return true
	return false

func _on_fishing_minigame_closed() -> void:
	_reset_fishing_state()
	_force_fishing_rod_active()
	_atualizar_ui_pos_fishing()

func _reset_fishing_state() -> void:
	fishing_minigame_ui = null
	_definir_estado(FishingState.IDLE)
	if bobber != null:
		bobber.visible = false
		bobber.scale = bobber_base_scale
		bobber.modulate = BOBBER_READY_MODULATE
	if fishing_bite_timer != null:
		fishing_bite_timer.stop()

func _force_fishing_rod_active() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager == null:
		return
	if tool_manager.has_method("force_select_fishing_rod"):
		tool_manager.call("force_select_fishing_rod")

func _atualizar_ui_pos_fishing() -> void:
	var ui: Node = _obter_ui_principal()
	if ui == null:
		return
	if ui.has_method("atualizar_status_jogo"):
		ui.call("atualizar_status_jogo")
	if ui.has_method("atualizar_toolbar_ferramentas"):
		ui.call("atualizar_toolbar_ferramentas")

func _obter_ui_principal() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var current_scene: Node = tree.current_scene
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("UI")

func _obter_tool_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ToolManager")
