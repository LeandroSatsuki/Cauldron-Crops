extends Area2D

signal restored(restoration_id: String)

@export var restoration_id: String = "first_herbarium"
@export var required_purification_obstacle_id: String = "first_obstacle"
@export var restoration_requirements: Array[Dictionary] = [
	{"item_id": "trigo", "quantity": 5},
	{"item_id": "agua", "quantity": 1},
]
@export var restoration_reward_item_id: String = "rama_encantada"
@export var restoration_reward_quantity: int = 1

var restored_state: bool = false
var area_purified: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ruined_visual: Node2D = $RuinedVisual
@onready var restored_visual: Node2D = $RestoredVisual
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	add_to_group("restoration_project")
	input_pickable = true
	_refresh_state()


func set_area_purified(value: bool) -> void:
	area_purified = value
	if is_inside_tree():
		_refresh_state()


func try_restore() -> bool:
	if not area_purified or restored_state:
		return false
	var missing := get_missing_requirements()
	if not missing.is_empty():
		_show_feedback(_format_missing_requirements(missing))
		return false
	for requirement_variant in restoration_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue
		var requirement: Dictionary = requirement_variant
		var item_id := str(requirement.get("item_id", ""))
		var quantity := int(requirement.get("quantity", 0))
		if item_id != "" and quantity > 0:
			GlobalInventory.remover_item(item_id, quantity)
	restored_state = true
	_refresh_state()
	if restoration_reward_item_id != "" and restoration_reward_quantity > 0:
		GlobalInventory.adicionar_item(restoration_reward_item_id, restoration_reward_quantity)
	_show_feedback("Herbario restaurado! Uma Rama Encantada floresceu.")
	restored.emit(restoration_id)
	return true


func get_missing_requirements() -> Dictionary:
	var missing: Dictionary = {}
	for requirement_variant in restoration_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue
		var requirement: Dictionary = requirement_variant
		var item_id := str(requirement.get("item_id", ""))
		var quantity := int(requirement.get("quantity", 0))
		if item_id == "" or quantity <= 0:
			continue
		var available := int(GlobalInventory.inventario.get(item_id, 0))
		if available < quantity:
			missing[item_id] = quantity - available
	return missing


func get_save_data() -> Dictionary:
	return {
		"restoration_id": restoration_id,
		"restored": restored_state,
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("restoration_id"):
		restoration_id = str(data.get("restoration_id", restoration_id))
	if data.has("restored"):
		restored_state = bool(data.get("restored", restored_state))
	_refresh_state()


func _input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if not area_purified or restored_state:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if try_restore():
			viewport.set_input_as_handled()


func _refresh_state() -> void:
	visible = area_purified
	input_pickable = area_purified and not restored_state
	if collision_shape:
		collision_shape.disabled = not area_purified or restored_state
	if ruined_visual:
		ruined_visual.visible = area_purified and not restored_state
	if restored_visual:
		restored_visual.visible = area_purified and restored_state
	if prompt_label:
		prompt_label.visible = area_purified and not restored_state


func _format_missing_requirements(missing: Dictionary) -> String:
	var parts: Array[String] = []
	for requirement_variant in restoration_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue
		var requirement: Dictionary = requirement_variant
		var item_id := str(requirement.get("item_id", ""))
		if not missing.has(item_id):
			continue
		var item_name := item_id
		if Database != null and Database.has_method("obter_nome_item"):
			item_name = str(Database.obter_nome_item(item_id))
		parts.append("%s x%d" % [item_name, int(missing.get(item_id, 0))])
	return "Faltam: %s." % ", ".join(parts)


func _show_feedback(text: String) -> void:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		var ui: Node = tree.current_scene.get_node_or_null("UI")
		if ui != null and ui.has_method("criar_texto_flutuante"):
			ui.call("criar_texto_flutuante", text, global_position + Vector2(0.0, -52.0), Color(0.64, 0.95, 0.66, 1.0))
			return
	print(text)
