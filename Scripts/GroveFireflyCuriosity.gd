extends Area2D
class_name GroveFireflyCuriosity


signal curiosity_investigated(reaction_count: int)


const IDLE_INTENSITY: float = 0.38
const ALERT_INTENSITY: float = 1.0
const FEEDBACK_COLOR := Color(0.68, 0.94, 0.74, 1.0)


@export_range(24.0, 160.0, 1.0) var interaction_distance: float = 68.0
@export_range(80.0, 360.0, 1.0) var awareness_distance: float = 190.0
@export_range(0.5, 6.0, 0.1) var reaction_duration: float = 2.4


@onready var firefly_cluster: Node2D = get_node_or_null("FireflyCluster") as Node2D
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label
@onready var feedback_label: Label = get_node_or_null("FeedbackLabel") as Label


var _fireflies: Array[Node2D] = []
var _base_positions: Array[Vector2] = []
var _hovered: bool = false
var _player_nearby: bool = false
var _reaction_remaining: float = 0.0
var _reaction_count: int = 0
var _intensity: float = IDLE_INTENSITY
var _time: float = 0.0
var _feedback_origin: Vector2 = Vector2.ZERO
var _feedback_tween: Tween = null


func _ready() -> void:
	add_to_group("ambient_curiosity")
	input_pickable = true
	if firefly_cluster != null:
		for child in firefly_cluster.get_children():
			if child is Node2D:
				var firefly: Node2D = child as Node2D
				_fireflies.append(firefly)
				_base_positions.append(firefly.position)
	if feedback_label != null:
		_feedback_origin = feedback_label.position
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	_refresh_prompt()


func _process(delta: float) -> void:
	_time += delta
	_reaction_remaining = maxf(_reaction_remaining - delta, 0.0)
	_player_nearby = _is_player_nearby()
	var target_intensity: float = ALERT_INTENSITY if _player_nearby or _reaction_remaining > 0.0 else IDLE_INTENSITY
	_intensity = move_toward(_intensity, target_intensity, delta * 1.8)
	_animate_fireflies()


func investigate() -> bool:
	_reaction_count += 1
	_reaction_remaining = reaction_duration
	_show_feedback("As luzes dançam entre as folhas.")
	curiosity_investigated.emit(_reaction_count)
	return true


func get_environment_state() -> Dictionary:
	return {
		"player_nearby": _player_nearby,
		"reacting": _reaction_remaining > 0.0,
		"reaction_count": _reaction_count,
		"intensity": _intensity,
	}


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var scene: Node = get_tree().current_scene if get_tree() != null else null
	if scene != null and scene.has_method("request_player_interaction"):
		if bool(scene.call(
			"request_player_interaction",
			self,
			global_position,
			interaction_distance,
			Callable(self, "investigate")
		)):
			viewport.set_input_as_handled()
		return
	if investigate():
		viewport.set_input_as_handled()


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_prompt()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_prompt()


func _refresh_prompt() -> void:
	if prompt_label != null:
		prompt_label.visible = _hovered


func _is_player_nearby() -> bool:
	var tree: SceneTree = get_tree()
	var scene: Node = tree.current_scene if tree != null else null
	var player: Node2D = scene.get_node_or_null("PlayerAvatar") as Node2D if scene != null else null
	return player != null and player.global_position.distance_to(global_position) <= awareness_distance


func _animate_fireflies() -> void:
	for index in range(_fireflies.size()):
		var firefly: Node2D = _fireflies[index]
		if firefly == null or not is_instance_valid(firefly):
			continue
		var phase: float = _time * (1.4 + float(index) * 0.09) + float(index) * 1.73
		var amplitude: float = lerpf(2.0, 10.0, _intensity)
		firefly.position = _base_positions[index] + Vector2(
			sin(phase) * amplitude,
			cos(phase * 1.37) * amplitude * 0.62
		)
		var alpha: float = 0.38 + _intensity * 0.62 + sin(phase * 2.1) * 0.08
		firefly.modulate.a = clampf(alpha, 0.0, 1.0)
		var scale_factor: float = 0.88 + _intensity * 0.24 + sin(phase * 2.5) * 0.06
		firefly.scale = Vector2.ONE * scale_factor


func _show_feedback(text: String) -> void:
	if feedback_label == null:
		print(text)
		return
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	feedback_label.text = text
	feedback_label.position = _feedback_origin
	feedback_label.modulate = FEEDBACK_COLOR
	feedback_label.visible = true
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_QUAD)
	_feedback_tween.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(feedback_label, "position", _feedback_origin + Vector2(0.0, -30.0), 1.0)
	_feedback_tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 1.0)
	_feedback_tween.tween_callback(func() -> void: feedback_label.visible = false)
