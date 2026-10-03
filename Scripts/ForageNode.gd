extends Area2D
class_name ForageNode


signal resource_collected(item_id: String, quantity: int)


const FEEDBACK_COLOR := Color(0.82, 0.94, 0.66, 1.0)
const BLOCKED_FEEDBACK_COLOR := Color(1.0, 0.76, 0.42, 1.0)


@export var resource_id: String = "carvao"
@export_range(1, 99, 1) var quantity: int = 1
@export_range(24.0, 160.0, 1.0) var interaction_distance: float = 62.0
@export var prompt_verb: String = "Coletar"
@export var backpack_milestone_id: String = ""
@export var expedition_source_id: String = ""


@onready var available_visual: Node2D = get_node_or_null("AvailableVisual") as Node2D
@onready var depleted_visual: Node2D = get_node_or_null("DepletedVisual") as Node2D
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label
@onready var feedback_label: Label = get_node_or_null("FeedbackLabel") as Label
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


var _collected: bool = false
var _hovered: bool = false
var _pulse_time: float = 0.0
var _feedback_tween: Tween = null
var _feedback_origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("forage_node")
	if expedition_source_id != "":
		GroveExpedition.forage_state_changed.connect(_on_persistent_state_changed)
		_collected = bool(GroveExpedition.get_forage_state(expedition_source_id)["collected"])
	input_pickable = true
	if prompt_label != null:
		prompt_label.text = "%s %s" % [prompt_verb, Database.obter_nome_item(resource_id)]
		if expedition_source_id == GroveExpedition.RENEWABLE_SOURCE:
			prompt_label.offset_left = -230.0
			prompt_label.offset_right = 230.0
	if feedback_label != null:
		_feedback_origin = feedback_label.position
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	_refresh_state()


func _process(delta: float) -> void:
	z_index = int(global_position.y) + 8
	if expedition_source_id == GroveExpedition.RENEWABLE_SOURCE and prompt_label != null:
		var remaining: float = float(GroveExpedition.get_forage_state(expedition_source_id)["renewal_remaining"])
		prompt_label.visible = true
		prompt_label.text = "Carvão renovável · %ds" % ceili(remaining) if _collected else "Coletar 2 carvões · renova em 45s"
	if _collected or available_visual == null:
		return
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 2.2) * 0.025
	available_visual.scale = Vector2.ONE * pulse


func collect() -> bool:
	if _collected or resource_id == "" or quantity <= 0:
		return false
	var insertion: Dictionary = GlobalInventory.try_add_items({resource_id: quantity})
	if not bool(insertion.get("success", false)):
		_show_feedback(get_capacity_feedback(), BLOCKED_FEEDBACK_COLOR, 4.0)
		return false
	_collected = true
	if expedition_source_id != "":
		GroveExpedition.record_collection(expedition_source_id)
	_refresh_state()
	var message := "+%d %s" % [quantity, Database.obter_nome_item(resource_id)]
	if GlobalInventory.award_backpack_milestone(backpack_milestone_id):
		message += "\nMochila ampliada: +%d slots (%d no total)." % [GlobalInventory.BACKPACK_MILESTONE_SLOTS, GlobalInventory.get_slot_capacity()]
	_show_feedback(message)
	resource_collected.emit(resource_id, quantity)
	return true


func is_collected() -> bool:
	return _collected

func get_capacity_feedback() -> String:
	return "Mochila sem espaço para %dx %s.\nRecurso permanece aqui.\nDeposite no Baú da Vila e volte para coletar." % [quantity, Database.obter_nome_item(resource_id)]


func _on_persistent_state_changed(source_id: String) -> void:
	if source_id != expedition_source_id:
		return
	_collected = bool(GroveExpedition.get_forage_state(expedition_source_id)["collected"])
	_refresh_state()


func get_collection_state() -> Dictionary:
	return {
		"resource_id": resource_id,
		"quantity": quantity,
		"collected": _collected,
	}


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if _collected or event is not InputEventMouseButton:
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
			Callable(self, "collect")
		)):
			viewport.set_input_as_handled()
		return
	if collect():
		viewport.set_input_as_handled()


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_prompt()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_prompt()


func _refresh_state() -> void:
	if available_visual != null:
		available_visual.visible = not _collected
		if _collected:
			available_visual.scale = Vector2.ONE
	if depleted_visual != null:
		depleted_visual.visible = _collected
	input_pickable = not _collected
	if collision_shape != null:
		collision_shape.set_deferred("disabled", _collected)
	_refresh_prompt()


func _refresh_prompt() -> void:
	if prompt_label != null:
		prompt_label.visible = expedition_source_id == GroveExpedition.RENEWABLE_SOURCE or (_hovered and not _collected)


func _show_feedback(text: String, color: Color = FEEDBACK_COLOR, hold_seconds: float = 0.0) -> void:
	if feedback_label == null:
		print(text)
		return
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	feedback_label.text = text
	feedback_label.position = _feedback_origin
	feedback_label.modulate = color
	feedback_label.visible = true
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_QUAD)
	_feedback_tween.set_ease(Tween.EASE_OUT)
	if hold_seconds > 0.0:
		_feedback_tween.tween_interval(hold_seconds)
	_feedback_tween.tween_property(feedback_label, "position", _feedback_origin + Vector2(0.0, -30.0), 0.75)
	_feedback_tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 0.75)
	_feedback_tween.tween_callback(func() -> void: feedback_label.visible = false)
