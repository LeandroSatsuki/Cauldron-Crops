extends Node

var _original_inventory: Dictionary = {}
var _original_seed: String = ""
var _original_enforcement: bool = false


func _ready() -> void:
	_run()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_original_seed = GlobalInventory.semente_selecionada
	_original_enforcement = GlobalInventory.is_capacity_enforced()
	GlobalInventory.set_capacity_enforced(false)

	if not GlobalInventory.set_inventory_contents({"trigo": 100, "carvao": 99, "agua": 7, "semente_basica": 0}):
		return _fail("conteudo valido foi recusado")
	if GlobalInventory.get_used_slot_count() != 3 or GlobalInventory.get_free_slot_count() != 9:
		return _fail("ocupacao nao respeitou stacks, zero e agua")
	var visual_entries: Array[Dictionary] = GlobalInventory.get_personal_slot_entries()
	if visual_entries.size() != 3:
		return _fail("representacao visual nao dividiu as pilhas esperadas")
	if str(visual_entries[0].get("item_id", "")) != "trigo" or int(visual_entries[0].get("quantity", 0)) != 99:
		return _fail("primeira pilha visual de trigo nao respeitou o limite")
	if str(visual_entries[1].get("item_id", "")) != "trigo" or int(visual_entries[1].get("quantity", 0)) != 1:
		return _fail("excedente de trigo nao virou uma segunda pilha visual")
	if str(visual_entries[2].get("item_id", "")) != "carvao" or int(visual_entries[2].get("quantity", 0)) != 99:
		return _fail("pilha visual de carvao ficou incorreta")
	if GlobalInventory.get_item_quantity("trigo") != 100 or GlobalInventory.get_item_quantity("inexistente") != 0:
		return _fail("consulta de quantidade nao normalizou o inventario")

	var before_invalid := GlobalInventory.inventario.duplicate(true)
	if GlobalInventory.set_inventory_contents({"trigo": -1}) or GlobalInventory.inventario != before_invalid:
		return _fail("substituicao invalida alterou o inventario")
	for invalid_request in [["", 1], ["trigo", 0], ["trigo", -2]]:
		var invalid_result: Dictionary = GlobalInventory.try_add_item(str(invalid_request[0]), int(invalid_request[1]))
		if bool(invalid_result.get("success", true)) or int(invalid_result.get("accepted", -1)) != 0:
			return _fail("insercao invalida foi aceita")
	if GlobalInventory.inventario != before_invalid:
		return _fail("insercao invalida alterou o inventario")
	if GlobalInventory.remover_item("trigo", 0) or GlobalInventory.remover_item("trigo", -1):
		return _fail("remocao invalida foi aceita")

	var unlimited_result: Dictionary = GlobalInventory.try_add_item("trigo", 2000)
	if not bool(unlimited_result.get("success", false)) or int(unlimited_result.get("accepted", 0)) != 2000:
		return _fail("fundacao alterou gameplay com capacidade desligada")

	var full_inventory := {"trigo": 98, "agua": 10, "semente_basica": 0}
	for index in range(11):
		full_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	if not GlobalInventory.set_inventory_contents(full_inventory):
		return _fail("cenario cheio nao foi configurado")
	GlobalInventory.set_capacity_enforced(true)
	if GlobalInventory.get_used_slot_count() != GlobalInventory.PERSONAL_SLOT_CAPACITY:
		return _fail("cenario de capacidade cheia contou slots incorretamente")

	var partial: Dictionary = GlobalInventory.try_add_item("trigo", 2)
	if bool(partial.get("success", true)) or int(partial.get("accepted", 0)) != 1 or int(partial.get("remainder", 0)) != 1:
		return _fail("aceitacao parcial nao foi explicita")
	if GlobalInventory.get_item_quantity("trigo") != 99:
		return _fail("aceitacao parcial alterou quantidade incorreta")
	var rejected: Dictionary = GlobalInventory.try_add_item("novo_item", 1)
	if bool(rejected.get("success", true)) or int(rejected.get("accepted", -1)) != 0 or str(rejected.get("reason", "")) != "inventory_full":
		return _fail("mochila cheia aceitou nova pilha")
	var water: Dictionary = GlobalInventory.try_add_item("agua", 3)
	if not bool(water.get("success", false)) or GlobalInventory.get_item_quantity("agua") != 13:
		return _fail("agua ocupou capacidade da mochila")

	GlobalInventory.semente_selecionada = "semente_basica"
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.try_add_item("semente_basica", 1)
	if not GlobalInventory.remover_item("semente_basica", 1) or GlobalInventory.semente_selecionada != "":
		return _fail("ultima semente removida permaneceu selecionada")

	_restore_state()
	print("PersonalInventoryContractSmokeTest: PASS - ocupacao, validacao, compatibilidade, capacidade parcial e itens externos aos slots estao coerentes.")
	get_tree().quit(0)


func _restore_state() -> void:
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.set_inventory_contents(_original_inventory)
	GlobalInventory.semente_selecionada = _original_seed
	GlobalInventory.set_capacity_enforced(_original_enforcement)


func _fail(message: String) -> void:
	_restore_state()
	push_error("PersonalInventoryContractSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
