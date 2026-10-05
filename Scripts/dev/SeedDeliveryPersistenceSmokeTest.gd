extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const RECIPE := "semente_trigo_replantio"
var home: Node
var cauldron: Node
var golem: Node
var chest: VillageChest
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "APPDATA isolado obrigatório antes de Main")
		return _finish("sandbox recusado")
	for service in [PocoManager, GroveExpedition, HerbariumProduction, EventDirector]:
		service.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	cauldron = home.get_node("CauldronUI")
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	home.process_mode = Node.PROCESS_MODE_DISABLED
	(golem.get("_think_timer") as Timer).stop()
	if "--verify-seed-delivery-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish("reabertura")
	if "--write-seed-delivery-fixture" in OS.get_cmdline_user_args():
		_write_fixture()
		return _finish("fixture")
	_test_round_trip()
	_test_snapshot_catchup()
	_test_cross_domain_refusals()
	_test_legacy_and_partial()
	_test_writer_guards()
	await _test_cache()
	_write_fixture()
	_finish("custódia conjunta, parcial, legado, writer, replay e cache")

func _reset() -> void:
	cauldron.call("load_save_data", {"state": "IDLE"})
	golem.call("load_work_save_data", GolemWorkState.default_data(), false)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	HerbariumProduction.reset_progress()
	EconomyManager.well_improved_by_project = false
	EconomyManager.poco_capacidade_maxima = 10
	GlobalInventory.set_inventory_contents({"agua": 7, "trigo": 2})
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.apply_backpack_progress([])
	ToolManager.clear_tool()
	chest.set_contents({"trigo": 20})
	home.get_node("PlayerAvatar").global_position = cauldron.get_node("BaseAnchor").global_position + Vector2(0, 64)

func _ready_fixture() -> Dictionary:
	_reset()
	_check(bool(cauldron.call("iniciar_producao_em_lote", RECIPE, 2, "village_storage")), "encomenda natural de duas preparações")
	cauldron.call("_on_batch_timer_timeout")
	var snapshot := _snapshot()
	_check(snapshot["cauldrons"]["CauldronUI"]["delivery"]["phase"] == "ready", "uma saída pronta")
	return snapshot

func _carried_fixture() -> Dictionary:
	var data := _ready_fixture()
	var order: Dictionary = data["cauldrons"]["CauldronUI"]["delivery"]
	data["golem_work"]["logistics_cargo"] = order["output"].duplicate(true)
	order["output"] = null
	order["phase"] = "carried"
	return data

func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SeedDeliveryPersistenceSmokeTest: " + label)

func _test_round_trip() -> void:
	for carried in [false, true]:
		var data := _carried_fixture() if carried else _ready_fixture()
		_check(bool(SaveManager.call("_seed_delivery_snapshot_valid", data)), "preflight pronto/cargo válido")
		for _repeat in range(2):
			_check(bool(SaveManager.call("_apply_save_data", data)), "load/replay conserva snapshot")
			_check(_snapshot()["cauldrons"] == data["cauldrons"], "pedido exato sem conversão/refund")
			_check(_snapshot()["golem_work"] == data["golem_work"], "cargo exato sem depósito")
			_check(chest.get_item_quantity("trigo") == 16 and chest.get_item_quantity("semente_basica") == 0, "reservas retiradas uma vez e saída não teleporta")
			_check(GlobalInventory.get_item_quantity("semente_basica") == 0, "nenhuma semente pessoal")

func _refuse(data: Dictionary, label: String) -> void:
	var before := _snapshot()
	_check(not bool(SaveManager.call("_apply_save_data", data)), label)
	_check(_snapshot() == before, label + " sem mutação")

func _test_snapshot_catchup() -> void:
	_reset()
	_check(bool(cauldron.call("iniciar_producao_em_lote", RECIPE, 2, "village_storage")), "inicia preparo para catch-up real do loader")
	var data := _snapshot()
	data["home_inactive_seconds"] = 99.0
	for _repeat in range(2):
		_check(bool(SaveManager.call("_apply_save_data", data)), "loader aplica preparo e tempo inativo")
		var order: Dictionary = cauldron.call("get_seed_delivery_order_data")
		_check(order["phase"] == "ready" and int(order["converted"]) == 1 and int(order["delivered"]) == 0, "catch-up converte só o preparo atual")
		_check(order["reservations"].size() == 1 and int(order["output"]["quantity"]) == 3, "saída integral e reserva futura conservadas")
		_check((cauldron.get("batch_timer") as Timer).is_stopped() and golem.call("get_logistics_cargo_data") == null, "aguarda entrega física sem iniciar outro timer/cargo")
		_check(chest.get_item_quantity("trigo") == 16 and chest.get_item_quantity("semente_basica") == 0 and GlobalInventory.get_item_quantity("semente_basica") == 0, "replay não duplica estoques nem entrega remotamente")

func _test_cross_domain_refusals() -> void:
	var ready := _ready_fixture()
	for invalid_success in [1, "true", null]:
		var malformed_receipt := ready.duplicate(true)
		malformed_receipt["cauldrons"]["CauldronUI"]["delivery"]["reservations"][0]["success"] = invalid_success
		_refuse(malformed_receipt, "recibo success exige booleano: " + str(invalid_success))
	var duplicate := ready.duplicate(true)
	duplicate["golem_work"]["logistics_cargo"] = duplicate["cauldrons"]["CauldronUI"]["delivery"]["output"].duplicate(true)
	_refuse(duplicate, "caldeirão e golem não possuem a mesma saída")
	var carried := _carried_fixture()
	_check(bool(SaveManager.call("_apply_save_data", carried)), "instala cargo válido")
	for key in ["order_id", "step", "item_id", "quantity", "source_id"]:
		var invalid := carried.duplicate(true)
		var cargo: Dictionary = invalid["golem_work"]["logistics_cargo"]
		cargo[key] = "outro" if key in ["order_id", "source_id"] else ("semente_verao" if key == "item_id" else int(cargo[key]) + 1)
		_refuse(invalid, "identidade incoerente: " + key)
	var no_order := carried.duplicate(true)
	no_order["cauldrons"]["CauldronUI"] = {"state": "IDLE"}
	_refuse(no_order, "cargo órfão")
	var no_cargo := carried.duplicate(true)
	no_cargo["golem_work"]["logistics_cargo"] = null
	_refuse(no_cargo, "promessa de cargo ausente")
	var two_cargos := carried.duplicate(true)
	two_cargos["golem_work"]["harvest_cargo"] = {"trigo": 1}
	_refuse(two_cargos, "cargas simultâneas")
	var revoked := carried.duplicate(true)
	revoked["grove_expedition"] = {"discovered": true, "restored": false, "forage_sources": {}}
	_refuse(revoked, "gate revogado")

func _test_legacy_and_partial() -> void:
	var carried := _carried_fixture()
	_check(bool(SaveManager.call("_apply_save_data", carried)), "instala parcial base")
	var generation: int = cauldron.call("get_seed_delivery_generation")
	_check(bool(SaveManager.call("_apply_save_data", {})), "parcial ausente conserva ambos domínios")
	_check(_snapshot()["cauldrons"] == carried["cauldrons"] and _snapshot()["golem_work"] == carried["golem_work"], "parcial não cria ou apaga saída")
	_check(int(cauldron.call("get_seed_delivery_generation")) != generation, "parcial invalida callback antigo")
	_check(bool(SaveManager.call("_apply_save_data", {"golem_work": carried["golem_work"]})), "cargo parcial resolve gate e pedido preservados")
	_check(bool(SaveManager.call("_apply_save_data", {"cauldrons": carried["cauldrons"]})), "pedido parcial resolve cargo preservado")
	_refuse({"golem_work": GolemWorkState.default_data()}, "parcial não remove cargo prometido")
	_refuse({"cauldrons": {}}, "parcial não remove origem do cargo")
	_refuse({"grove_expedition": {"discovered": true, "restored": false, "forage_sources": {}}}, "parcial não revoga gate preservando pedido")
	for version in [3, 4]:
		var legacy := carried.duplicate(true)
		legacy["version"] = version
		legacy.erase("cauldrons")
		legacy.erase("golem_work")
		_check(bool(SaveManager.call("_apply_save_data", legacy)), "legado completo sem logística v%d" % version)
		_check(cauldron.call("get_save_data") == {"state": "IDLE"} and golem.call("get_logistics_cargo_data") == null, "legado limpa ambos sem refund")
		_check(chest.get_item_quantity("trigo") == 16, "legado não devolve ingredientes do estado substituído")

func _test_writer_guards() -> void:
	var ready := _ready_fixture()
	_check(bool(SaveManager.save_game()), "writer aceita saída pronta")
	var file_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	golem.set("_logistics_transaction", true)
	_check(not SaveManager.save_game(), "writer recusa durante transferência")
	_check(not SaveManager.load_game(), "loader recusa durante transferência")
	_check(not bool(SaveManager.call("_apply_save_data", ready)), "aplicador recusa durante transferência")
	golem.set("_logistics_transaction", false)
	_check(FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == file_before, "arquivo anterior intacto")
	var cargo: GolemLogisticsCargo = golem.get("logistics_cargo")
	_check(cargo.apply_save_data(ready["cauldrons"]["CauldronUI"]["delivery"]["output"]), "fixture de cópia inválida isolada")
	_check(not SaveManager.save_game(), "writer recusa custódia duplicada")
	_check(FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == file_before, "recusa não sobrescreve arquivo")
	cargo.apply_save_data(null)

func _test_cache() -> void:
	var data := _carried_fixture()
	_check(bool(SaveManager.call("_apply_save_data", data)), "prepara viagem")
	_check(bool(home.call("request_region_transition", &"foraging_grove", &"from_farm", &"seed_delivery_persistence_qa")), "solicita viagem ao Bosque")
	for _frame in range(240):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress(): break
	_check(RegionTravelCoordinator.get_active_region_id() == "foraging_grove" and not RegionTravelCoordinator.is_input_blocked(), "viagem concluída ao Bosque")
	_check(bool(SaveManager.call("_seed_delivery_snapshot_valid", {})), "preflight usa vila em cache")
	_check(bool(SaveManager.save_game()), "writer no Bosque conserva cargo físico")
	_check(SaveManager.load_game(), "load retorna à vila com snapshot coerente")
	_check(get_tree().current_scene == home and golem.call("get_logistics_cargo_data") != null, "retorno não deposita cargo")
	(golem.get("_think_timer") as Timer).stop()
	home.process_mode = Node.PROCESS_MODE_DISABLED

func _write_fixture() -> void:
	# Helpers preparatórios não contam como verificações no modo fixture.
	var previous_checks := checks
	var data := _carried_fixture()
	checks = previous_checks
	_check(bool(SaveManager.call("_apply_save_data", data)), "fixture carregável de cargo")
	_check(SaveManager.save_game(), "fixture persistida isolada")

func _verify_reopen() -> void:
	_check(SaveManager.load_game(), "reabrir carrega")
	var data := _snapshot()
	_check(data["cauldrons"]["CauldronUI"]["state"] == "SEED_DELIVERY", "pedido persistido")
	var order: Dictionary = data["cauldrons"]["CauldronUI"]["delivery"]
	_check(order["phase"] == "carried", "cargo ainda em trânsito sem offline")
	_check(int(order["converted"]) == 1 and int(order["delivered"]) == 0 and int(order["total"]) == 2, "contadores preservados")
	_check(order["reservations"].size() == 1 and order["output"] == null, "custódia exclusiva e reserva futura")
	_check(SeedDeliveryOrder.matches_cargo(order, data["golem_work"]["logistics_cargo"]), "identidade conjunta")
	_check(chest.get_item_quantity("trigo") == 16 and chest.get_item_quantity("semente_basica") == 0, "estoques preservados")
	_check(GlobalInventory.get_item_quantity("semente_basica") == 0, "sem presente pessoal")

func _finish(detail: String) -> void:
	print("SeedDeliveryPersistenceSmokeTest: %s - %d verificações; %s" % ["FAIL" if failed else "PASS", checks, detail])
	get_tree().quit(1 if failed else 0)
