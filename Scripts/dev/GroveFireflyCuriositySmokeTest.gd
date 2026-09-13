extends Node


const GROVE_SCENE := preload("res://Scenes/ForagingGroveRegion.tscn")


var _inventory_before: Dictionary = {}
var _lore_before: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_inventory_before = GlobalInventory.inventario.duplicate(true)
	_lore_before = GlobalInventory.lore_descobertas.duplicate()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var grove: Node2D = GROVE_SCENE.instantiate() as Node2D
	if grove == null:
		_fail("a cena do bosque nao pode ser instanciada")
		return
	get_tree().root.add_child(grove)
	get_tree().current_scene = grove
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var curiosities: Array[Node] = get_tree().get_nodes_in_group("ambient_curiosity")
	if curiosities.size() != 1:
		_fail("esperada uma curiosidade ambiental opcional, encontradas %d" % curiosities.size())
		return
	var curiosity: GroveFireflyCuriosity = curiosities[0] as GroveFireflyCuriosity
	if curiosity == null:
		_fail("curiosidade nao implementa o contrato GroveFireflyCuriosity")
		return
	var idle_state: Dictionary = curiosity.get_environment_state()
	if bool(idle_state.get("player_nearby", true)) or int(idle_state.get("reaction_count", -1)) != 0:
		_fail("luzes nao iniciaram em estado ambiental ocioso")
		return
	var inventory_before_interaction := _get_inventory_without_water()

	if not bool(grove.call(
		"request_player_interaction",
		curiosity,
		curiosity.global_position,
		curiosity.interaction_distance,
		Callable(curiosity, "investigate")
	)):
		_fail("aproximacao fisica da curiosidade foi rejeitada")
		return
	for _frame in range(560):
		await get_tree().physics_frame
		if int(curiosity.get_environment_state().get("reaction_count", 0)) > 0:
			break
	var reacted_state: Dictionary = curiosity.get_environment_state()
	if int(reacted_state.get("reaction_count", 0)) != 1 or not bool(reacted_state.get("reacting", false)):
		_fail("observacao nao ativou a reacao ambiental")
		return
	if not bool(reacted_state.get("player_nearby", false)) or float(reacted_state.get("intensity", 0.0)) <= 0.38:
		_fail("luzes nao reagiram a proximidade do familiar")
		return
	var feedback: Label = curiosity.get_node_or_null("FeedbackLabel") as Label
	if feedback == null or not feedback.visible or feedback.text != "As luzes dançam entre as folhas.":
		_fail("curiosidade nao mostrou feedback atmosferico local")
		return
	if _get_inventory_without_water() != inventory_before_interaction:
		_fail("curiosidade concedeu recurso ou alterou a Mochila")
		return
	if GlobalInventory.lore_descobertas != _lore_before:
		_fail("curiosidade criou progresso de lore persistente")
		return

	_restore_globals()
	grove.queue_free()
	await get_tree().process_frame
	print("GroveFireflyCuriositySmokeTest: PASS - curiosidade opcional, reacao ambiental e ausencia de recompensa persistente estao coerentes.")
	get_tree().quit(0)


func _restore_globals() -> void:
	GlobalInventory.inventario = _inventory_before.duplicate(true)
	GlobalInventory.lore_descobertas = _lore_before.duplicate()


func _get_inventory_without_water() -> Dictionary:
	var snapshot: Dictionary = GlobalInventory.inventario.duplicate(true)
	snapshot.erase("agua")
	return snapshot


func _fail(message: String) -> void:
	_restore_globals()
	push_error("GroveFireflyCuriositySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
