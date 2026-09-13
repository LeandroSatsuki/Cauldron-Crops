extends Area2D
class_name RegionGateway


@export var target_region_id: StringName = &""
@export var target_entry_id: StringName = &""
@export var source_exit_id: StringName = &""
@export var interaction_distance: float = 76.0
@export var label_text: String = "Caminho externo"


@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label
@onready var glow: Polygon2D = get_node_or_null("Glow") as Polygon2D


var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group("region_gateway")
	input_pickable = true
	if prompt_label != null:
		prompt_label.text = label_text
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


func _process(delta: float) -> void:
	_pulse_time += delta
	if glow != null:
		var pulse: float = 0.82 + sin(_pulse_time * 2.4) * 0.12
		glow.modulate.a = pulse


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var scene: Node = get_tree().current_scene if get_tree() != null else null
	if scene != null and scene.has_method("request_player_interaction"):
		if bool(scene.call("request_player_interaction", self, global_position, interaction_distance, Callable(self, "activate"))):
			viewport.set_input_as_handled()
			return
	if activate():
		viewport.set_input_as_handled()


func activate() -> bool:
	var tree: SceneTree = get_tree()
	var scene: Node = tree.current_scene if tree != null else null
	if scene == null or not scene.has_method("request_region_transition"):
		return false
	return bool(scene.call("request_region_transition", target_region_id, target_entry_id, source_exit_id))
