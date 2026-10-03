extends Area2D

signal restored(restoration_id: String)

const VillageResourceAccessScript = preload("res://Scripts/VillageResourceAccess.gd")

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
var _village_resource_access = null
var _feedback_label: Label

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

func _process(_delta: float) -> void:
	if area_purified and not restored_state:
		prompt_label.text = get_requirements_feedback()

func get_requirements_feedback() -> String:
	# Consulta somente leitura; o consumo continua exclusivo de try_restore.
	if restored_state:
		return "Herbário restaurado"
	var parts: PackedStringArray = []
	var access = _get_village_resource_access()
	var requirements := _build_requirement_totals()
	for item_id in requirements:
		parts.append("%s: %d/%d" % [Database.obter_nome_item(item_id), access.get_available(item_id), requirements[item_id]])
	var source := "Baú da Vila + Mochila" if _find_village_storage() != null else "Recursos da Mochila"
	return "Herbário em ruínas\n" + " · ".join(parts) + "\n" + source + "\nClique para restaurar"


func try_restore() -> bool:
	if not area_purified or restored_state:
		return false
	var missing := get_missing_requirements()
	if not missing.is_empty():
		_show_feedback(_format_missing_requirements(missing))
		return false
	var reward: Dictionary = {}
	if restoration_reward_item_id != "" and restoration_reward_quantity > 0:
		reward[restoration_reward_item_id] = restoration_reward_quantity
		if not GlobalInventory.can_accept_items(reward):
			_show_feedback("Mochila sem espaço para %dx %s.\nDeposite no Baú da Vila e tente restaurar novamente.\nNenhum recurso foi consumido." % [restoration_reward_quantity, Database.obter_nome_item(restoration_reward_item_id)])
			return false
	var requirements := _build_requirement_totals()
	var receipt: Dictionary = {}
	if not requirements.is_empty():
		receipt = _get_village_resource_access().consume(requirements)
		if not bool(receipt.get("success", false)):
			var failed_missing: Dictionary = receipt.get("missing", {})
			if failed_missing.is_empty():
				failed_missing = get_missing_requirements()
			_show_feedback(_format_missing_requirements(failed_missing) if not failed_missing.is_empty() else "Recursos indisponiveis para restauracao.")
			return false
	if not reward.is_empty():
		var insertion: Dictionary = GlobalInventory.try_add_items(reward)
		if not bool(insertion.get("success", false)):
			if not receipt.is_empty() and not _get_village_resource_access().refund(receipt):
				push_warning("RestorationProject: nao foi possivel devolver recursos apos falha inesperada da recompensa.")
			_show_feedback("Não foi possível guardar a recompensa. A restauração não foi concluída.")
			return false
	restored_state = true
	_refresh_state()
	var message := "Herbario restaurado! Uma Rama Encantada floresceu."
	if restoration_id == "first_herbarium" and GlobalInventory.award_backpack_milestone(restoration_id):
		message += "\nMochila ampliada: +%d slots (%d no total)." % [GlobalInventory.BACKPACK_MILESTONE_SLOTS, GlobalInventory.get_slot_capacity()]
	_show_feedback(message)
	restored.emit(restoration_id)
	return true


func get_missing_requirements() -> Dictionary:
	var requirements := _build_requirement_totals()
	if requirements.is_empty():
		return {}
	return _get_village_resource_access().get_missing(requirements)


func _build_requirement_totals() -> Dictionary:
	var requirements: Dictionary = {}
	for requirement_variant in restoration_requirements:
		if typeof(requirement_variant) != TYPE_DICTIONARY:
			continue
		var requirement: Dictionary = requirement_variant
		var item_id := str(requirement.get("item_id", ""))
		var quantity := int(requirement.get("quantity", 0))
		if item_id == "" or quantity <= 0:
			continue
		requirements[item_id] = int(requirements.get(item_id, 0)) + quantity
	return requirements


func _get_village_resource_access():
	var village_storage: Node = _find_village_storage()
	if _village_resource_access == null:
		_village_resource_access = VillageResourceAccessScript.new(village_storage)
	else:
		_village_resource_access.set_village_storage(village_storage)
	return _village_resource_access


func _find_village_storage() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for chest_variant in tree.get_nodes_in_group("village_chest"):
		var chest: Node = chest_variant as Node
		if chest != null and is_instance_valid(chest) and chest.has_method("get_item_quantity"):
			return chest
	return null


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
		var main: Node = get_tree().current_scene
		if main != null and main.has_method("request_player_interaction"):
			if bool(main.call("request_player_interaction", self, global_position, 64.0, Callable(self, "try_restore"))):
				viewport.set_input_as_handled()
				return
		try_restore()
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
		prompt_label.text = get_requirements_feedback()


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
	return "Faltam: %s.\nUsa o Baú da Vila primeiro; a Mochila completa o restante.\nNenhum recurso foi consumido." % ", ".join(parts)


func _show_feedback(text: String) -> void:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		var ui: Node = tree.current_scene.get_node_or_null("UI")
		if ui != null and ui.has_method("criar_texto_flutuante"):
			if is_instance_valid(_feedback_label):
				_feedback_label.queue_free()
			var screen_position := get_viewport().get_canvas_transform() * (global_position + Vector2(0.0, -52.0))
			_feedback_label = ui.call("criar_texto_flutuante", text, screen_position, Color(0.64, 0.95, 0.66, 1.0), 4.0)
			return
	print(text)
