extends Node


const GROVE_SCENE := preload("res://Scenes/ForagingGroveRegion.tscn")
const EXPECTED_NODE_COUNT := 4


var _inventory_before: Dictionary = {}
var _capacity_enforcement_before: bool = false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_inventory_before = GlobalInventory.inventario.duplicate(true)
	_capacity_enforcement_before = GlobalInventory.is_capacity_enforced()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var initial_charcoal: int = int(GlobalInventory.inventario.get("carvao", 0))
	var grove: Node2D = GROVE_SCENE.instantiate() as Node2D
	if grove == null:
		_fail("a cena do bosque nao pode ser instanciada")
		return
	get_tree().root.add_child(grove)
	get_tree().current_scene = grove
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Preservar o contrato dos quatro pontos originais. A nova fonte renovável
	# tem quantidade/ciclo próprios, cobertos por GroveRestorationSliceSmokeTest.
	var forage_nodes: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group("forage_node"):
		if node.get("expedition_source_id") != GroveExpedition.RENEWABLE_SOURCE:
			forage_nodes.append(node)
	if forage_nodes.size() != EXPECTED_NODE_COUNT:
		_fail("esperados %d pontos fisicos, encontrados %d" % [EXPECTED_NODE_COUNT, forage_nodes.size()])
		return
	for node_variant: Node in forage_nodes:
		var state: Dictionary = node_variant.call("get_collection_state")
		if state.get("resource_id", "") != "carvao" or int(state.get("quantity", 0)) != 1:
			_fail("ponto de coleta nao usa o recurso comum deterministico aprovado")
			return
		if bool(state.get("collected", true)):
			_fail("ponto de coleta nasceu esgotado")
			return

	var forage_node: ForageNode = forage_nodes[0] as ForageNode
	if forage_node == null:
		_fail("primeiro ponto nao implementa o contrato ForageNode")
		return
	var constrained_inventory: Dictionary = {"carvao": 98, "agua": 4}
	for index in range(11):
		constrained_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	GlobalInventory.set_inventory_contents(constrained_inventory)
	GlobalInventory.set_capacity_enforced(true)
	forage_node.quantity = 2
	if forage_node.collect():
		_fail("ponto foi consumido sem espaco para a recompensa inteira")
		return
	if forage_node.is_collected() or GlobalInventory.get_item_quantity("carvao") != 98:
		_fail("coleta recusada alterou o ponto ou aceitou recompensa parcial")
		return
	var blocked_feedback: Label = forage_node.get_node_or_null("FeedbackLabel") as Label
	if blocked_feedback == null or not blocked_feedback.visible or "Mochila" not in blocked_feedback.text:
		_fail("recusa por capacidade nao informou o jogador")
		return
	forage_node.quantity = 1
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.set_inventory_contents(_inventory_before)
	if not bool(grove.call(
		"request_player_interaction",
		forage_node,
		forage_node.global_position,
		forage_node.interaction_distance,
		Callable(forage_node, "collect")
	)):
		_fail("aproximacao fisica para coleta foi rejeitada")
		return
	for _frame in range(300):
		await get_tree().physics_frame
		if forage_node.is_collected():
			break
	if not forage_node.is_collected():
		_fail("familiar nao concluiu a coleta apos se aproximar")
		return
	if int(GlobalInventory.inventario.get("carvao", 0)) != initial_charcoal + 1:
		_fail("recurso nao entrou na Mochila temporaria")
		return
	if bool(forage_node.collect()):
		_fail("mesmo ponto permitiu uma segunda coleta")
		return
	if int(GlobalInventory.inventario.get("carvao", 0)) != initial_charcoal + 1:
		_fail("segunda tentativa duplicou o recurso")
		return
	var feedback: Label = forage_node.get_node_or_null("FeedbackLabel") as Label
	if feedback == null or not feedback.visible or "Carvão" not in feedback.text:
		_fail("feedback curto da coleta nao foi exibido no mundo")
		return
	for node_variant: Node in forage_nodes.slice(1):
		if bool(node_variant.call("is_collected")):
			_fail("coletar um ponto esgotou outro ponto da regiao")
			return
	get_tree().current_scene = null
	get_tree().root.remove_child(grove)
	get_tree().root.add_child(grove)
	get_tree().current_scene = grove
	await get_tree().process_frame
	if not forage_node.is_collected():
		_fail("ponto coletado reapareceu ao reentrar na mesma instancia da regiao")
		return
	if int(GlobalInventory.inventario.get("carvao", 0)) != initial_charcoal + 1:
		_fail("reentrada na regiao duplicou o recurso")
		return

	_restore_inventory()
	grove.queue_free()
	await get_tree().process_frame
	print("ForagingCollectionSmokeTest: PASS - aproximacao, coleta unica, Mochila temporaria e feedback no mundo estao coerentes.")
	get_tree().quit(0)


func _restore_inventory() -> void:
	GlobalInventory.set_capacity_enforced(false)
	if not _inventory_before.is_empty():
		GlobalInventory.set_inventory_contents(_inventory_before)
	GlobalInventory.set_capacity_enforced(_capacity_enforcement_before)


func _fail(message: String) -> void:
	_restore_inventory()
	push_error("ForagingCollectionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
