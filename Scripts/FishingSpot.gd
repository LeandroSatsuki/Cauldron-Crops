extends Area2D

enum FishingState {
	IDLE,
	BOBBER_CAST,
	FISH_BITING,
	MINIGAME_ACTIVE
}

@onready var bobber: Node2D = $Bobber
@onready var fishing_bite_timer: Timer = $FishingBiteTimer
@onready var moving_fishing_area: Node2D = get_node_or_null("MovingFishingArea") as Node2D

const FEEDBACK_OFFSET: Vector2 = Vector2(0.0, -60.0)
const FEEDBACK_COR: Color = Color(0.55, 0.93, 1.0, 1.0)
const BOBBER_READY_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const BOBBER_BITING_MODULATE: Color = Color(1.0, 0.86, 0.42, 1.0)
const BOBBER_BITING_SCALE: Vector2 = Vector2(1.15, 1.15)
const MOVING_AREA_RADIUS: float = 70.0

var fishing_state: FishingState = FishingState.IDLE
var bobber_base_scale: Vector2 = Vector2.ONE
var fishing_minigame_ui: Node = null
var current_cast_is_boosted: bool = false
var moving_area_time: float = 0.0
var moving_area_base_position: Vector2 = Vector2.ZERO
var moving_area_base_scale: Vector2 = Vector2.ONE
var moving_area_base_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
var moving_area_configured_logged: bool = false

func _ready() -> void:
	add_to_group("fishing_spot")
	input_pickable = true
	set_process(true)
	_ensure_moving_fishing_area()
	if bobber != null:
		bobber_base_scale = bobber.scale
	if moving_fishing_area != null:
		moving_area_base_position = moving_fishing_area.position
		moving_area_base_scale = moving_fishing_area.scale
		moving_area_base_modulate = moving_fishing_area.modulate
	if fishing_bite_timer != null and not fishing_bite_timer.timeout.is_connected(_on_fishing_bite_timer_timeout):
		fishing_bite_timer.timeout.connect(_on_fishing_bite_timer_timeout)
		if fishing_bite_timer.wait_time <= 0.0:
			fishing_bite_timer.wait_time = 3.0
		fishing_bite_timer.one_shot = true
	_definir_estado(FishingState.IDLE)

func _process(delta: float) -> void:
	_atualizar_area_com_movimento(delta)

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
	current_cast_is_boosted = _is_point_in_moving_area(click_global_position)
	print("FishingSpot: pesca favorecida = %s" % str(current_cast_is_boosted))
	if fishing_state == FishingState.BOBBER_CAST:
		if current_cast_is_boosted:
			_mostrar_feedback("A água ressoa com força.", click_global_position)
			print("FishingSpot: boia reposicionada na area com movimento.")
		else:
			_mostrar_feedback("Boia reposicionada.", click_global_position)
			print("FishingSpot: boia reposicionada.")
	else:
		if current_cast_is_boosted:
			_mostrar_feedback("Você lançou na ondulação mágica.", click_global_position)
			print("FishingSpot: boia lancada na area com movimento.")
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
	var popup: Variant = ui.call("abrir_pesca_sincronia", origem_global, current_cast_is_boosted)
	if popup == null:
		return false
	if popup is Node:
		fishing_minigame_ui = popup
		if fishing_minigame_ui.has_method("configurar_pesca_favorecida"):
			fishing_minigame_ui.call("configurar_pesca_favorecida", current_cast_is_boosted)
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
	current_cast_is_boosted = false
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

func _is_point_in_moving_area(global_point: Vector2) -> bool:
	if moving_fishing_area == null:
		return false
	return global_point.distance_to(moving_fishing_area.global_position) <= MOVING_AREA_RADIUS

func _obter_tool_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ToolManager")

func _ensure_moving_fishing_area() -> void:
	if moving_fishing_area == null:
		moving_fishing_area = Node2D.new()
		moving_fishing_area.name = "MovingFishingArea"
		moving_fishing_area.position = Vector2(44.0, -10.0)
		moving_fishing_area.scale = Vector2.ONE
		moving_fishing_area.modulate = Color(1.0, 1.0, 1.0, 1.0)
		moving_fishing_area.z_index = 5
		add_child(moving_fishing_area)
		_criar_visual_area_movimento(moving_fishing_area)
	else:
		moving_fishing_area.visible = true
		moving_fishing_area.z_index = 5
		moving_fishing_area.scale = Vector2.ONE
		moving_fishing_area.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if not moving_area_configured_logged:
		print("FishingSpot: area especial de pesca configurada.")
		moving_area_configured_logged = true

func _criar_visual_area_movimento(parent_node: Node2D) -> void:
	var glow := Polygon2D.new()
	glow.name = "MovingFishingAreaGlow"
	glow.z_index = 6
	glow.color = Color(0.27451, 0.984314, 1.0, 0.52)
	glow.polygon = PackedVector2Array([
		Vector2(-58, -12),
		Vector2(-34, -42),
		Vector2(18, -48),
		Vector2(54, -24),
		Vector2(58, 12),
		Vector2(30, 44),
		Vector2(-18, 48),
		Vector2(-56, 22)
	])
	parent_node.add_child(glow)

	var core := Polygon2D.new()
	core.name = "MovingFishingAreaCore"
	core.z_index = 7
	core.color = Color(0.337255, 0.976471, 0.960784, 0.76)
	core.polygon = PackedVector2Array([
		Vector2(-44, -8),
		Vector2(-24, -26),
		Vector2(14, -30),
		Vector2(40, -14),
		Vector2(44, 8),
		Vector2(22, 26),
		Vector2(-12, 30),
		Vector2(-40, 14)
	])
	parent_node.add_child(core)

	var ring := Line2D.new()
	ring.name = "MovingFishingAreaRing"
	ring.z_index = 8
	ring.width = 8.0
	ring.default_color = Color(0.760784, 0.996078, 1.0, 0.92)
	ring.antialiased = true
	ring.joint_mode = Line2D.LINE_JOINT_ROUND
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = PackedVector2Array([
		Vector2(0, -40),
		Vector2(30, -28),
		Vector2(42, 0),
		Vector2(28, 30),
		Vector2(0, 40),
		Vector2(-30, 28),
		Vector2(-42, 0),
		Vector2(-28, -30)
	])
	parent_node.add_child(ring)

	var sparkle := Polygon2D.new()
	sparkle.name = "MovingFishingAreaSparkle"
	sparkle.position = Vector2(20, -16)
	sparkle.z_index = 9
	sparkle.color = Color(0.980392, 1.0, 1.0, 0.92)
	sparkle.polygon = PackedVector2Array([
		Vector2(0, -5),
		Vector2(3, -2),
		Vector2(5, 0),
		Vector2(3, 2),
		Vector2(0, 5),
		Vector2(-3, 2),
		Vector2(-5, 0),
		Vector2(-3, -2)
	])
	parent_node.add_child(sparkle)

func _atualizar_area_com_movimento(delta: float) -> void:
	if moving_fishing_area == null:
		return

	moving_area_time += delta

	var deslocamento: Vector2 = Vector2(
		sin(moving_area_time * 1.15) * 4.0,
		cos(moving_area_time * 1.45) * 2.5
	)
	moving_fishing_area.position = moving_area_base_position + deslocamento
	moving_fishing_area.scale = moving_area_base_scale * Vector2(
		1.0 + sin(moving_area_time * 1.8) * 0.06,
		1.0 + cos(moving_area_time * 1.6) * 0.06
	)
	moving_fishing_area.rotation = sin(moving_area_time * 0.55) * 0.06

	var alpha_base: float = moving_area_base_modulate.a
	var alpha_variacao: float = 0.94 + abs(sin(moving_area_time * 2.0)) * 0.06
	moving_fishing_area.modulate = Color(
		moving_area_base_modulate.r,
		moving_area_base_modulate.g,
		moving_area_base_modulate.b,
		clamp(alpha_base * alpha_variacao, 0.0, 1.0)
	)
