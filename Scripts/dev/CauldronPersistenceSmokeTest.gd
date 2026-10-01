extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const RECIPE_ID := "semente_basica_tomate_sol"
const RESULT_ID := "semente_verao"
var _main: Node
var _cauldron: Node
var _chest: VillageChest


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	PocoManager.set_process(false)
	await _create_world()
	if not await _test_manual_brewing():
		return
	if not await _test_manual_ready():
		return
	if not await _test_batch_running():
		return
	if not await _test_batch_waiting():
		return
	if not await _test_cancel_pending():
		return
	if not await _test_legacy_golem_result():
		return
	if not await _test_legacy_and_validation():
		return
	GlobalInventory.set_capacity_enforced(false)
	_main.free()
	print("CauldronPersistenceSmokeTest: PASS - producao, pronto, lote, reservas, cancelamento, legado e payload invalido sobrevivem ao JSON sem perda/duplicacao.")
	get_tree().quit(0)


func _create_world() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	# Tempo deterministico: progresso apenas pelas chamadas explicitas do teste.
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	_cauldron = _main.get_node("CauldronUI")
	_chest = _main.get_node("VillageChest") as VillageChest


func _snapshot() -> Dictionary:
	# Round-trip JSON real em memoria; nenhum acesso ao save pessoal em disco.
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))


func _reload(data: Dictionary, recreate: bool = true) -> bool:
	if recreate:
		await _create_world()
	return _expect(bool(SaveManager.call("_apply_save_data", data)), "save valido foi recusado")


func _setup(contents: Dictionary, storage: Dictionary, capacity: bool = false) -> void:
	GlobalInventory.set_capacity_enforced(capacity)
	GlobalInventory.set_inventory_contents(contents)
	_chest.set_contents(storage)
	_cauldron.call("load_save_data", {"state": "IDLE"})


func _start_manual() -> void:
	_cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot1").set("item_vinculado", "semente_basica")
	_cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot2").set("item_vinculado", "tomate_sol")
	_cauldron.call("_on_misturar_button_pressed")


func _full_backpack() -> Dictionary:
	var contents: Dictionary = {"agua": 7}
	for index in range(12):
		contents["item_teste_%02d" % index] = 99
	return contents


func _test_manual_brewing() -> bool:
	_setup({"tomate_sol": 1, "agua": 7}, {"semente_basica": 1})
	GlobalInventory.receitas_descobertas = []
	GlobalInventory.pontos_alquimia = 0
	_start_manual()
	_cauldron.get_node("BrewTimer").start(1.25)
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	if not _expect(_cauldron.get("estado_atual") == "BREWING" and is_equal_approx(_cauldron.get_node("BrewTimer").time_left, 1.25), "mistura nao restaurou estado/tempo restante"):
		return false
	if not _expect(GlobalInventory.get_item_quantity("tomate_sol") == 0 and _chest.get_item_quantity("semente_basica") == 0 and GlobalInventory.pontos_alquimia == 1, "load repetiu consumo ou descoberta"):
		return false
	_start_manual()
	if not _expect(_cauldron.get("estado_atual") == "BREWING", "nova mistura sobrescreveu producao restaurada"):
		return false
	if not _expect(bool(_cauldron.call("advance_inactive_time", 1.3)) and GlobalInventory.get_item_quantity(RESULT_ID) == 2, "mistura restaurada nao entregou quantidade capturada"):
		return false
	_cauldron.call("_on_brew_timer_timeout")
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 2, "timeout obsoleto duplicou mistura concluida"):
		return false
	var cauldron_id := str(_main.get_path_to(_cauldron))
	saved["cauldrons"][cauldron_id]["time_remaining"] = 0.1
	if not await _reload(saved, false):
		return false
	_main.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(0.3).timeout
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	return _expect(_cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity(RESULT_ID) == 2, "timer real de mistura nao retomou depois do load")


func _test_manual_ready() -> bool:
	_setup(_full_backpack(), {"semente_basica": 1, "tomate_sol": 1}, true)
	_start_manual()
	_cauldron.get_node("BrewTimer").stop()
	_cauldron.call("_on_brew_timer_timeout")
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	if not _expect(_cauldron.get("estado_atual") == "READY" and _cauldron.get_node("BrewTimer").is_stopped() and GlobalInventory.get_item_quantity(RESULT_ID) == 0, "resultado pronto foi entregue ou descartado no load"):
		return false
	_cauldron.call("_perform_primary_interaction")
	if not _expect(_cauldron.get("estado_atual") == "READY", "resultado saiu do caldeirao com mochila cheia"):
		return false
	GlobalInventory.remover_item("item_teste_00", 99)
	_cauldron.call("_perform_primary_interaction")
	_cauldron.call("_on_brew_timer_timeout")
	if not _expect(_cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity(RESULT_ID) == 2, "recolher resultado restaurado perdeu ou duplicou itens"):
		return false
	# Dois loads substituem o mesmo snapshot; nao acumulam recompensa/reserva.
	if not await _reload(saved, false) or not await _reload(saved, false):
		return false
	GlobalInventory.remover_item("item_teste_00", 99)
	_cauldron.call("_perform_primary_interaction")
	return _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 2 and _chest.get_contents().is_empty(), "loads repetidos duplicaram o resultado ou devolveram ingredientes consumidos")


func _test_batch_running() -> bool:
	_setup({"semente_basica": 1, "tomate_sol": 2, "agua": 7}, {"semente_basica": 2, "tomate_sol": 1})
	if not _expect(bool(_cauldron.call("iniciar_producao_em_lote", RECIPE_ID, 3)), "lote combinado nao iniciou"):
		return false
	_cauldron.call("_processar_tick_lote")
	_cauldron.get_node("BatchTimer").start(1.4)
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	if not _expect(int(_cauldron.get("_batch_quantidade_concluida")) == 1 and _cauldron.get("_batch_reservation_receipts").size() == 2 and is_equal_approx(_cauldron.get_node("BatchTimer").time_left, 1.4), "lote nao restaurou progresso, reservas e tempo"):
		return false
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 2 and _chest.get_contents().is_empty(), "load de lote consumiu/entregou recursos novamente"):
		return false
	_cauldron.call("advance_inactive_time", 1.41)
	_cauldron.call("cancelar_producao_em_lote")
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 4 and GlobalInventory.get_item_quantity("semente_basica") == 1 and GlobalInventory.get_item_quantity("tomate_sol") == 1 and _chest.get_contents().is_empty(), "retomada/cancelamento nao respeitou crafts entregues e origens restantes"):
		return false
	if not await _reload(saved):
		return false
	_cauldron.call("cancelar_producao_em_lote")
	_cauldron.call("cancelar_producao_em_lote")
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 2 and GlobalInventory.get_item_quantity("semente_basica") == 1 and GlobalInventory.get_item_quantity("tomate_sol") == 2 and _chest.get_item_quantity("semente_basica") == 1, "refund apos reconstruir cena nao respeitou cada origem uma unica vez"):
		return false
	var cauldron_id := str(_main.get_path_to(_cauldron))
	saved["cauldrons"][cauldron_id]["batch"]["time_remaining"] = 0.1
	if not await _reload(saved, false):
		return false
	_main.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(0.3).timeout
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 4 and int(_cauldron.get("_batch_quantidade_concluida")) == 2, "timer real de lote nao retomou exatamente o proximo craft"):
		return false
	_cauldron.call("cancelar_producao_em_lote")
	return true


func _test_batch_waiting() -> bool:
	_setup(_full_backpack(), {"semente_basica": 2, "tomate_sol": 2}, true)
	_cauldron.call("iniciar_producao_em_lote", RECIPE_ID, 2)
	_cauldron.call("_processar_tick_lote")
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	if not _expect(bool(_cauldron.get("_batch_waiting_for_space")) and _cauldron.get_node("BatchTimer").is_stopped() and _cauldron.get("_batch_reservation_receipts").size() == 2, "lote pausado nao preservou resultado e reservas"):
		return false
	if not _expect(not bool(_cauldron.call("advance_inactive_time", 100.0)) and GlobalInventory.get_item_quantity(RESULT_ID) == 0, "tempo inativo concluiu lote bloqueado"):
		return false
	GlobalInventory.remover_item("item_teste_00", 99)
	_cauldron.call("_perform_primary_interaction")
	if not _expect(not bool(_cauldron.get("_batch_waiting_for_space")) and GlobalInventory.get_item_quantity(RESULT_ID) == 2 and int(_cauldron.get("_batch_quantidade_concluida")) == 1, "retomada de lote pausado nao entregou exatamente o craft pronto"):
		return false
	_cauldron.call("cancelar_producao_em_lote")
	return _expect(_chest.get_item_quantity("semente_basica") == 1 and _chest.get_item_quantity("tomate_sol") == 1, "cancelar depois de retomar devolveu craft ja entregue")


func _test_cancel_pending() -> bool:
	_setup({"semente_basica": 1, "tomate_sol": 2}, {"semente_basica": 2, "tomate_sol": 1})
	_cauldron.call("iniciar_producao_em_lote", RECIPE_ID, 3)
	GlobalInventory.set_inventory_contents(_full_backpack())
	GlobalInventory.set_capacity_enforced(true)
	_cauldron.call("cancelar_producao_em_lote")
	if not _expect(bool(_cauldron.get("_batch_cancel_pending")) and _cauldron.get("_batch_reservation_receipts").size() == 2 and _chest.get_item_quantity("semente_basica") == 1, "refund bloqueado descartou reservas ou duplicou parte do bau"):
		return false
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	_cauldron.call("_processar_tick_lote")
	_cauldron.call("cancelar_producao_em_lote")
	if not _expect(GlobalInventory.get_item_quantity(RESULT_ID) == 0 and _chest.get_item_quantity("semente_basica") == 1 and _cauldron.get("_batch_reservation_receipts").size() == 2, "cancelamento restaurado produziu item ou repetiu refund parcial"):
		return false
	GlobalInventory.remover_item("item_teste_00", 99)
	GlobalInventory.remover_item("item_teste_01", 99)
	_cauldron.call("cancelar_producao_em_lote")
	_cauldron.call("cancelar_producao_em_lote")
	return _expect(_cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity("semente_basica") == 1 and GlobalInventory.get_item_quantity("tomate_sol") == 2 and _chest.get_item_quantity("semente_basica") == 2 and _chest.get_item_quantity("tomate_sol") == 1, "nova tentativa de cancelamento nao recuperou todas as origens uma unica vez")


func _test_legacy_golem_result() -> bool:
	_setup({}, {})
	EconomyManager.total_golems = 5
	EconomyManager.max_golems = 5
	_cauldron.call("load_save_data", {"state": "READY", "result_item": "golem_coletor", "result_quantity": 1, "time_remaining": 0})
	var saved := _snapshot()
	if not await _reload(saved):
		return false
	_cauldron.call("_perform_primary_interaction")
	if not _expect(_cauldron.get("estado_atual") == "READY" and EconomyManager.total_golems == 5, "resultado legado ignorou limite de golems depois do load"):
		return false
	EconomyManager.max_golems = 6
	_cauldron.call("_perform_primary_interaction")
	if not _expect(EconomyManager.total_golems == 6, "resultado legado nao entregou uma unidade"):
		return false
	if not await _reload(saved, false):
		return false
	EconomyManager.max_golems = 6
	_cauldron.call("_perform_primary_interaction")
	return _expect(EconomyManager.total_golems == 6, "recarregar resultado legado acumulou golems fora do snapshot")


func _test_legacy_and_validation() -> bool:
	_setup({"agua": 7}, {"semente_basica": 2, "tomate_sol": 2})
	var idle_save := _snapshot()
	_cauldron.call("iniciar_producao_em_lote", RECIPE_ID, 2)
	var saved := _snapshot()
	var cauldron_id := str(_main.get_path_to(_cauldron))
	var invalid_cases: Array[Dictionary] = []
	var invalid := saved.duplicate(true)
	invalid["cauldrons"] = []
	invalid_cases.append(invalid)
	for corruption in ["state", "quantity", "time", "count", "source", "refunded", "entry_quantity"]:
		invalid = saved.duplicate(true)
		var state: Dictionary = invalid["cauldrons"][cauldron_id]
		match corruption:
			"state": state["state"] = "UNKNOWN"
			"quantity": state["batch"]["result_quantity"] = 0
			"time": state["batch"]["time_remaining"] = -1
			"count": state["batch"]["reservations"].pop_back()
			"source": state["batch"]["reservations"][0]["entries"][0]["source"] = "teleport"
			"refunded": state["batch"]["reservations"][0]["refunded"] = true
			"entry_quantity": state["batch"]["reservations"][0]["entries"][0]["quantity"] = 0.5
		invalid_cases.append(invalid)
	for malformed in invalid_cases:
		var inventory_before: Dictionary = GlobalInventory.inventario.duplicate(true)
		var chest_before: Dictionary = _chest.get_contents()
		var production_before: Dictionary = _cauldron.call("get_save_data")
		if not _expect(not bool(SaveManager.call("_apply_save_data", malformed)), "payload de caldeirao malformado foi aceito"):
			return false
		if not _expect(GlobalInventory.inventario == inventory_before and _chest.get_contents() == chest_before and _cauldron.call("get_save_data") == production_before, "payload recusado alterou estoques ou producao"):
			return false
	SaveManager.call("_apply_save_data", {"version": 4})
	if not _expect(_cauldron.get("estado_atual") == "BATCH", "payload parcial apagou producao atual"):
		return false
	if not await _reload(idle_save, false):
		return false
	if not _expect(_cauldron.get("estado_atual") == "IDLE" and _cauldron.get_node("BatchTimer").is_stopped() and _chest.get_item_quantity("semente_basica") == 2, "snapshot IDLE preservou timer antigo ou reembolsou reservas duas vezes"):
		return false
	var legacy: Dictionary = idle_save.duplicate(true)
	legacy.erase("cauldrons")
	for version in [3, 4]:
		legacy["version"] = version
		_cauldron.call("iniciar_producao_em_lote", RECIPE_ID, 1)
		if not await _reload(legacy, false):
			return false
		if not _expect(_cauldron.get("estado_atual") == "IDLE" and _chest.get_item_quantity("semente_basica") == 2, "save antigo nao limpou produtor ou duplicou reservas antigas"):
			return false
	return true


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		GlobalInventory.set_capacity_enforced(false)
		push_error("CauldronPersistenceSmokeTest: FAIL - %s" % message)
		get_tree().quit(1)
	return condition
