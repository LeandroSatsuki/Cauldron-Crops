extends Area2D

signal lore_discovered(discovery_id: String)

@export var discovery_id := "first_purified_whisper"
var _area_purified := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var prompt_label: Label = $PromptLabel
@onready var text_label: Label = $TextLabel


func _ready() -> void:
	add_to_group("lore_discovery")
	input_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	_refresh_state()


func set_area_purified(value: bool) -> void:
	_area_purified = value
	if is_inside_tree():
		_refresh_state()


func investigate() -> bool:
	if not _area_purified:
		return false
	var first_discovery := GlobalInventory.register_lore_discovery(discovery_id)
	_refresh_state()
	if first_discovery:
		_show_world_feedback("Uma antiga marca foi compreendida.")
		lore_discovered.emit(discovery_id)
	return true


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if not _area_purified:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main: Node = get_tree().current_scene
		if main != null and main.has_method("request_player_interaction"):
			if bool(main.call("request_player_interaction", self, global_position, 48.0, Callable(self, "investigate"))):
				viewport.set_input_as_handled()
				return
		investigate()
		viewport.set_input_as_handled()


func _refresh_state() -> void:
	visible = _area_purified
	input_pickable = _area_purified
	if collision_shape:
		collision_shape.disabled = not _area_purified
	if not _area_purified:
		return
	var discovered := GlobalInventory.has_lore_discovery(discovery_id)
	if prompt_label:
		prompt_label.visible = not discovered
	if text_label:
		text_label.visible = discovered


func _show_world_feedback(text: String) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var ui := tree.current_scene.get_node_or_null("UI")
	if ui != null and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", text, global_position + Vector2(0.0, -54.0), Color(0.72, 0.88, 1.0, 1.0))
