extends Node

const QUEST_BOARD_SCENE := preload("res://Scenes/QuestBoard.tscn")

var _original_inventory: Dictionary = {}
var _original_quests: Array = []
var _original_capacity: bool = false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_original_quests = QuestManager.quests_ativas.duplicate(true)
	_original_capacity = GlobalInventory.is_capacity_enforced()

	var constrained_inventory: Dictionary = {"trigo": GlobalInventory.DEFAULT_STACK_LIMIT}
	for index in range(11):
		constrained_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	GlobalInventory.set_inventory_contents(constrained_inventory)
	GlobalInventory.set_capacity_enforced(true)
	var quest: Dictionary = {
		"pedido_item": "trigo",
		"pedido_qtd": 1,
		"recompensa_tipo": "semente_inverno",
		"recompensa_qtd": 2,
		"texto": "Teste de capacidade",
		"aceita": true,
	}
	QuestManager.quests_ativas = [quest]

	var board: Panel = QUEST_BOARD_SCENE.instantiate() as Panel
	add_child(board)
	await get_tree().process_frame
	board.call("_on_entregar_pressed", quest)
	if GlobalInventory.get_item_quantity("trigo") != GlobalInventory.DEFAULT_STACK_LIMIT:
		_fail("demanda recusada nao devolveu o pedido integralmente")
		return
	if GlobalInventory.get_item_quantity("semente_inverno") != 0 or not QuestManager.quests_ativas.has(quest):
		_fail("demanda foi concluida ou recompensada sem espaco")
		return

	GlobalInventory.remover_item("item_teste_00", GlobalInventory.DEFAULT_STACK_LIMIT)
	board.call("_on_entregar_pressed", quest)
	if GlobalInventory.get_item_quantity("trigo") != GlobalInventory.DEFAULT_STACK_LIMIT - 1:
		_fail("demanda aprovada nao consumiu o pedido exatamente uma vez")
		return
	if GlobalInventory.get_item_quantity("semente_inverno") != 2 or QuestManager.quests_ativas.has(quest):
		_fail("demanda nao entregou a recompensa depois de liberar espaco")
		return

	_restore_state()
	board.queue_free()
	print("QuestRewardCapacitySmokeTest: PASS - pedido e recompensa permanecem atomicos com a Mochila cheia.")
	get_tree().quit(0)


func _restore_state() -> void:
	GlobalInventory.set_capacity_enforced(_original_capacity)
	GlobalInventory.set_inventory_contents(_original_inventory)
	QuestManager.quests_ativas = _original_quests.duplicate(true)
	QuestManager.quest_atualizada.emit()


func _fail(message: String) -> void:
	_restore_state()
	push_error("QuestRewardCapacitySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
