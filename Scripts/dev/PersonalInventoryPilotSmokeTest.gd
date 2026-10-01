extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
var _main: Node
var _fishing: Control
var _chest: VillageChest

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if not _expect(GlobalInventory.is_capacity_enforced(), "piloto nao iniciou ativo por padrao"):
		return
	PocoManager.set_process(false)
	await _create_world()
	if not _test_capacity_and_storage():
		return
	if not await _test_legacy_overflow():
		return
	if not await _test_pending_fishing():
		return
	_main.free()
	print("PersonalInventoryPilotSmokeTest: PASS - limite ativo, bau atomico, overflow legado, captura persistente e retry unico.")
	get_tree().quit(0)

func _create_world() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	_fishing = _main.get_node("UI").get("fishing_minigame_ui")
	_chest = _main.get_node("VillageChest") as VillageChest

func _snapshot() -> Dictionary:
	# JSON em memoria: nao tocar no save pessoal do autor.
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))

func _test_capacity_and_storage() -> bool:
	GlobalInventory.set_inventory_contents({"trigo": 1188, "agua": 7})
	_chest.set_contents({"semente_basica": 10})
	if not _expect(GlobalInventory.get_used_slot_count() == 12, "agua ocupou slot ou pilha incorreta"):
		return false
	if not _expect(not _chest.withdraw_to_personal_inventory("semente_basica", 1), "bau retirou sem espaco"):
		return false
	if not _expect(_chest.get_item_quantity("semente_basica") == 10 and GlobalInventory.get_item_quantity("semente_basica") == 0, "recusa alterou estoques"):
		return false
	var spot: Node = get_tree().get_first_node_in_group("fishing_spot")
	if not _expect(not bool(spot.call("_can_receive_possible_fishing_reward")), "pesca nao recusou mochila cheia"):
		return false
	if not _expect(_chest.deposit_from_personal_inventory("trigo", 99) and _chest.withdraw_to_personal_inventory("semente_basica", 10), "deposito/retirada nao retomou"):
		return false
	var insertion := GlobalInventory.try_add_item("semente_basica", 90)
	return _expect(int(insertion.get("accepted", 0)) == 89 and GlobalInventory.get_used_slot_count() == 12, "API parcial excedeu pilha existente")

func _test_legacy_overflow() -> bool:
	GlobalInventory.set_inventory_contents({"semente_basica": 1300, "trigo": 99, "agua": 7})
	GlobalInventory.semente_selecionada = "semente_basica"
	var legacy := _snapshot()
	legacy.erase("cauldrons")
	legacy.erase("fishing_pending_capture")
	legacy["version"] = 3
	await _create_world()
	if not _expect(bool(SaveManager.call("_apply_save_data", legacy)), "overflow legado recusado"):
		return false
	SaveManager.call("_refresh_ui_after_load")
	if not _expect(GlobalInventory.is_capacity_enforced() and GlobalInventory.get_item_quantity("semente_basica") == 1300 and GlobalInventory.get_used_slot_count() == 15, "load cortou overflow ou desligou limite"):
		return false
	if not _expect(_main.get_node("UI").get("inventory_bar").get_child_count() == 15, "overflow ocultou pilhas"):
		return false
	if not _expect(not GlobalInventory.can_accept_items({"peixe_comum": 1}) and GlobalInventory.try_add_items({"semente_basica": 1}).get("success", false), "overflow nao distinguiu slot novo de pilha existente"):
		return false
	if not _expect(_chest.deposit_from_personal_inventory("semente_basica", 1301), "overflow nao pode ser depositado"):
		return false
	return _expect(GlobalInventory.get_used_slot_count() == 1 and _chest.get_item_quantity("semente_basica") == 1301, "deposito perdeu quantidade")

func _test_pending_fishing() -> bool:
	GlobalInventory.set_inventory_contents({"trigo": 1188, "agua": 7})
	GlobalInventory.aplicar_colecao_pesca_save([], false)
	EventDirector.debug_reset_for_test()
	EventDirector.set("_session_elapsed", EventDirector.RARE_FISH_FIRST_WINDOW_DELAY)
	if not _expect(not bool(_fishing.call("_aplicar_recompensa", 1)), "captura dupla nao ficou pendente"):
		return false
	var pending: Dictionary = _fishing.call("get_save_data")
	if not _expect(_main.get_node("UI").call("abrir_pesca_sincronia", Vector2.ZERO) == null, "UI abriu segunda tentativa"):
		return false
	_fishing.call("_aplicar_recompensa", 2)
	if not _expect(_fishing.call("get_save_data") == pending, "retry trocou recompensa"):
		return false
	var saved := _snapshot()
	await _create_world()
	if not _expect(bool(SaveManager.call("_apply_save_data", saved)) and _fishing.call("get_save_data") == pending, "captura nao sobreviveu ao JSON e recriacao"):
		return false
	if not _expect(not GlobalInventory.possui_bonus_colecao_pesca(), "colecao avancou antes da entrega"):
		return false
	var invalid := saved.duplicate(true)
	invalid["inventory"]["inventario"] = {"trigo": 1}
	invalid["fishing_pending_capture"]["rewards"]["peixe_comum"] = 2
	if not _expect(not bool(SaveManager.call("_apply_save_data", invalid)) and GlobalInventory.get_item_quantity("trigo") == 1188 and _fishing.call("get_save_data") == pending, "payload invalido alterou estado"):
		return false
	if not _expect(bool(SaveManager.call("_apply_save_data", {"version": 4})) and _fishing.call("get_save_data") == pending, "payload parcial apagou captura"):
		return false
	for replay in range(2):
		if not _expect(bool(SaveManager.call("_apply_save_data", saved)), "replay recusado"):
			return false
		GlobalInventory.remover_item("trigo", 198)
		if replay == 0:
			_fishing.call("_process", 0.0)
			_fishing.call("_process", 0.0)
		else:
			# Confirmar retry pelo processamento real, nao somente chamada direta.
			_main.process_mode = Node.PROCESS_MODE_INHERIT
			await get_tree().process_frame
			await get_tree().process_frame
			_main.process_mode = Node.PROCESS_MODE_DISABLED
		if not _expect(GlobalInventory.get_item_quantity("peixe_comum") == 1 and GlobalInventory.get_item_quantity("escama_brilhante") == 1 and not bool(_fishing.call("has_pending_capture")) and GlobalInventory.possui_bonus_colecao_pesca(), "retry perdeu/duplicou captura ou colecao"):
			return false
	SaveManager.call("_apply_save_data", saved)
	var old := saved.duplicate(true)
	old.erase("fishing_pending_capture")
	old["inventory"]["inventario"] = {"semente_basica": 10}
	old["inventory"]["semente_selecionada"] = "semente_basica"
	var spot: Node = get_tree().get_first_node_in_group("fishing_spot")
	spot.call("_definir_estado", 3)
	if not _expect(bool(SaveManager.call("_apply_save_data", old)), "save antigo recusado"):
		return false
	_fishing.call("_process", 0.0)
	return _expect(not bool(_fishing.call("has_pending_capture")) and GlobalInventory.get_item_quantity("peixe_comum") == 0 and GlobalInventory.semente_selecionada == "semente_basica" and int(spot.get("fishing_state")) == 0, "load antigo deixou captura futura/lago ativo ou apagou semente")

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error("PersonalInventoryPilotSmokeTest: FAIL - %s" % message)
		get_tree().quit(1)
	return condition
