extends Node

const FISHING_MINIGAME_SCENE := preload("res://Scenes/FishingMinigameUI.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var colecao_original: Array = GlobalInventory.colecao_pesca_descobertas.duplicate()
	var concluida_original := GlobalInventory.colecao_pesca_concluida
	GlobalInventory.aplicar_colecao_pesca_save([], false)

	var progresso_inicial := GlobalInventory.obter_progresso_colecao_pesca()
	if int(progresso_inicial.get("quantidade", -1)) != 0 or bool(progresso_inicial.get("concluida", true)):
		_fail("colecao nova nao iniciou vazia")
		return

	var peixe := GlobalInventory.registrar_item_colecao_pesca("peixe_comum")
	if int(peixe.get("quantidade", -1)) != 1 or bool(peixe.get("concluida", true)):
		_fail("primeira descoberta nao registrou progresso 1/2")
		return
	GlobalInventory.registrar_item_colecao_pesca("peixe_comum")
	if int(GlobalInventory.obter_progresso_colecao_pesca().get("quantidade", -1)) != 1:
		_fail("item repetido duplicou a colecao")
		return
	var escama := GlobalInventory.registrar_item_colecao_pesca("escama_brilhante")
	if not bool(escama.get("concluida_agora", false)) or not GlobalInventory.possui_bonus_colecao_pesca():
		_fail("segunda descoberta nao ativou o bonus")
		return

	var minigame: Control = FISHING_MINIGAME_SCENE.instantiate()
	get_tree().root.add_child(minigame)
	await get_tree().process_frame
	minigame.set("_marker_position_x", 181.0)
	if int(minigame.call("_avaliar_resultado")) != 1:
		_fail("bonus da colecao nao ampliou a zona de boa sincronia")
		return
	minigame.queue_free()

	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	var inventory_snapshot: Dictionary = snapshot.get("inventory", {})
	if not bool(inventory_snapshot.get("colecao_pesca_concluida", false)):
		_fail("save nao incluiu conclusao da colecao")
		return
	GlobalInventory.aplicar_colecao_pesca_save([], false)
	if not bool(SaveManager.call("_apply_save_data", snapshot)) or not GlobalInventory.possui_bonus_colecao_pesca():
		_fail("load nao restaurou bonus da colecao")
		return

	GlobalInventory.aplicar_colecao_pesca_save([], false)
	var legacy_snapshot: Dictionary = snapshot.duplicate(true)
	var legacy_inventory: Dictionary = legacy_snapshot.get("inventory", {})
	legacy_inventory.erase("colecao_pesca_descobertas")
	legacy_inventory.erase("colecao_pesca_concluida")
	legacy_snapshot["inventory"] = legacy_inventory
	if not bool(SaveManager.call("_apply_save_data", legacy_snapshot)) or GlobalInventory.possui_bonus_colecao_pesca():
		_fail("save anterior sem campos da colecao nao preservou o estado padrao")
		return

	GlobalInventory.aplicar_colecao_pesca_save(colecao_original, concluida_original)
	print("FishingCollectionSmokeTest: PASS - progresso, bonus e persistencia da colecao estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("FishingCollectionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
