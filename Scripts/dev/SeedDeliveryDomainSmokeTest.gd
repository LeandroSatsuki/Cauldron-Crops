extends Node

# Somente fixture sintética em APPDATA QA, sem save pessoal ou aceite manual.
const MAIN := preload("res://Scenes/Main.tscn")
const CHEST := preload("res://Scenes/VillageChest.tscn")
const ORDER := preload("res://Scripts/data/SeedDeliveryOrder.gd")
const WHEAT := "semente_trigo_replantio"
const TOMATO := "semente_basica_tomate_sol"
var home: Node
var cauldron: Node
var golem: Node2D
var chest: VillageChest
var player: Node2D
var checks := 0
var failed := false
var probing := false
var observed_coherent := true
var reentrant_refused := true
var notifications := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var qa_root := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(qa_root):
		_check(false, "exige APPDATA absoluto sob Builds/QA antes de Main")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	HerbariumProduction.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	home.process_mode = Node.PROCESS_MODE_DISABLED
	cauldron = home.get_node("CauldronUI")
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	player = home.get_node("PlayerAvatar")
	(cauldron.get_node("BatchTimer") as Timer).stop()
	(golem.get("_think_timer") as Timer).stop()
	cauldron.connect("seed_delivery_changed", _on_delivery_changed)
	_schema()
	_eligibility()
	_conversion_and_deposit()
	_one_seed_and_guards()
	_cancel_and_refund()
	_context_and_generation()
	_snapshot_catchup()
	_legacy_and_personal()
	_finish()

func _reset(personal: Dictionary = {"agua": 7}, storage: Dictionary = {"trigo": 8, "semente_basica": 4, "tomate_sol": 4}) -> void:
	probing = false
	get_tree().current_scene = home
	home.set("_region_being_cached", false)
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents(personal)
	GlobalInventory.receitas_descobertas = [TOMATO]
	GlobalInventory.pontos_alquimia = 19
	chest.set_contents(storage)
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	cauldron.call("load_save_data", {"state": "IDLE"})
	player.global_position = cauldron.get_node("BaseAnchor").global_position + Vector2(0, -54)
	golem.global_position = cauldron.call("get_seed_delivery_pickup_position")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	observed_coherent = true
	reentrant_refused = true
	notifications = 0

func _start(recipe: String = WHEAT, count: int = 2) -> bool:
	return cauldron.call("iniciar_producao_em_lote", recipe, count, ORDER.DESTINATION)

func _order() -> Dictionary:
	var value: Variant = cauldron.call("get_seed_delivery_order_data")
	return value if value is Dictionary else {}

func _convert() -> void:
	(cauldron.get_node("BatchTimer") as Timer).stop()
	cauldron.call("_on_batch_timer_timeout")

func _claim(payload: Dictionary, generation: int = -1) -> bool:
	golem.global_position = cauldron.call("get_seed_delivery_pickup_position")
	return cauldron.call("take_ready_seed_delivery", golem, payload, generation)

func _deposit(payload: Dictionary, generation: int = -1) -> bool:
	golem.global_position = chest.global_position + Vector2(0, 48)
	return cauldron.call("confirm_seed_delivery_deposit", golem, payload, chest, generation)

func _schema() -> void:
	_reset()
	_check(_start(), "fixture lote logístico")
	var base := _order()
	_check(ORDER.is_valid(base) and ORDER.is_valid(JSON.parse_string(JSON.stringify(base))), "schema runtime e JSON válido")
	_check(ORDER.matches_cargo(base, null), "brewing sem cargo")
	for value in [null, true, 3, "x", [], {}]:
		_check(not ORDER.is_valid(value), "tipo/schema inválido")
	for key in ["total", "converted", "delivered", "refunded", "result_quantity"]:
		for value in [true, "1", 0.5, INF, NAN, 9223372036854775808.0]:
			var invalid := base.duplicate(true)
			invalid[key] = value
			_check(not ORDER.is_valid(invalid), "contador estrito " + key)
	for mutation in [{"extra": true}, {"source_id": "other"}, {"order_id": " "}, {"recipe_id": "unknown"}, {"result_item": "semente_outono"}, {"result_quantity": 2}, {"seconds_per_craft": 3.0}, {"time_remaining": -1}, {"time_remaining": 2.1}, {"cancelled": 1}, {"phase": "ready"}, {"delivered": 1}, {"converted": 2}, {"refunded": 1}, {"output": {}}]:
		var invalid := base.duplicate(true)
		invalid.merge(mutation, true)
		_check(not ORDER.is_valid(invalid), "contradição/contrato inválido")
	var bad_receipt := base.duplicate(true)
	bad_receipt.reservations[0].refunded = true
	_check(not ORDER.is_valid(bad_receipt), "recibo já reembolsado recusado")
	bad_receipt = base.duplicate(true)
	bad_receipt.reservations[0].entries[0].quantity += 1
	_check(not ORDER.is_valid(bad_receipt), "origem/quantidade de recibo estrita")
	var before: Dictionary = cauldron.call("get_save_data")
	var generation: int = cauldron.call("get_seed_delivery_generation")
	_check(not cauldron.call("load_save_data", {"state": "SEED_DELIVERY", "delivery": bad_receipt}) and cauldron.call("get_save_data") == before and cauldron.call("get_seed_delivery_generation") == generation, "load inválido não substitui/invalida runtime")
	_check(not cauldron.call("is_save_data_valid", {"state": "IDLE", "delivery": base}), "pedido oculto em estado pessoal recusado")
	_check(cauldron.call("is_save_data_valid", {"state": "IDLE", "delivery": null}), "null opcional pessoal compatível")

func _eligibility() -> void:
	_reset()
	var initial := _resources()
	GroveExpedition.restored = false
	_check(cauldron.call("get_seed_delivery_offer", WHEAT).reason == "locked" and not _start() and _resources() == initial, "gate sem gasto")
	GroveExpedition.restored = true
	_check(cauldron.call("get_seed_delivery_offer", "abobora_sombria_raiz_gelida").reason == "unsupported_result", "resultado fora whitelist")
	_check(not cauldron.call("iniciar_producao_em_lote", WHEAT, 2, "other") and _resources() == initial, "destino inválido recusado")
	_check(not _start(WHEAT, 0) and _resources() == initial, "quantidade zero recusada")
	home.set("_region_being_cached", true)
	_check(not _start() and cauldron.call("get_seed_delivery_offer", WHEAT).reason == "home_unavailable", "cache ainda na árvore recusa")
	home.set("_region_being_cached", false)
	player.global_position += Vector2(500, 0)
	_check(not _start() and cauldron.call("get_seed_delivery_offer", WHEAT).reason == "too_far", "confirmação revalida alcance")
	player.global_position = cauldron.get_node("BaseAnchor").global_position + Vector2(0, -54)
	for priority in [2, 3, 4]:
		golem.call("set_work_priority", priority)
		_check(cauldron.call("get_seed_delivery_offer", WHEAT).eligible, "planejar permitido em modo restrito")
	golem.call("set_work_priority", 0)
	chest.set_contents({"trigo": 1})
	_check(not _start() and chest.get_item_quantity("trigo") == 1, "sem recursos sem gasto parcial")

func _conversion_and_deposit() -> void:
	_reset({"trigo": 3, "agua": 7}, {"trigo": 3})
	var before := _resources()
	probing = true
	_check(_start(WHEAT, 3), "três preparos reservados")
	_check(_order().reservations.size() == 3 and GlobalInventory.get_item_quantity("trigo") == 0 and chest.get_item_quantity("trigo") == 0, "baú primeiro e complemento pessoal")
	_check(_order().reservations[0].entries[0].source == "village_storage" and _order().reservations[2].entries[0].source == "personal_inventory", "origens preservadas por preparo")
	_convert()
	var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
	_check(payload.quantity == 3 and payload.item_id == "semente_basica" and payload.step == 1, "saída inteira da receita de trigo")
	_check(_order().converted == 1 and _order().delivered == 0 and _order().reservations.size() == 2 and _order().phase == "ready", "conversão baixa somente um recibo")
	_check(GlobalInventory.get_item_quantity("semente_basica") == 0 and chest.get_item_quantity("semente_basica") == 0 and (cauldron.get_node("BatchTimer") as Timer).is_stopped(), "sem Mochila/depósito/timer antecipado")
	_check(not cauldron.call("advance_inactive_time", 9000.0) and _order().converted == 1, "backpressure não acumula/catch-up")
	_check(ORDER.matches_cargo(_order(), null) and not ORDER.matches_cargo(_order(), payload), "ready recusa cargo duplicado")
	cauldron.call("_perform_primary_interaction")
	_check(_order().phase == "ready" and _order().reservations.size() == 2, "clique apenas acompanha")
	_check(_claim(payload), "retirada física inteira")
	_check(cauldron.call("get_ready_seed_delivery").is_empty() and ORDER.matches_cargo(_order(), golem.call("get_logistics_cargo_data")), "custódia transferida sem cópia")
	_check(not _claim(payload), "retirada repetida recusada")
	_check(_deposit(payload), "depósito confirma primeira etapa")
	_check(chest.get_item_quantity("semente_basica") == 3 and golem.call("get_logistics_cargo_data") == null and _order().delivered == 1 and _order().phase == "brewing" and not (cauldron.get_node("BatchTimer") as Timer).is_stopped(), "ack reinicia somente após depósito")
	_check(not _deposit(payload) and chest.get_item_quantity("semente_basica") == 3, "ack repetido sem duplicação")
	for step in [2, 3]:
		_convert()
		payload = cauldron.call("get_ready_seed_delivery")
		_check(payload.step == step and _claim(payload) and _deposit(payload), "etapa subsequente única")
	_check(cauldron.get("estado_atual") == "IDLE" and cauldron.call("get_seed_delivery_order_data") == null and chest.get_item_quantity("semente_basica") == 9, "pedido libera somente após último depósito")
	_check(GlobalInventory.pontos_alquimia == before.xp and not golem.get("seeding_enabled") and GlobalInventory.semente_selecionada == before.selection, "sem XP/autorligar/seleção pessoal")
	_check(observed_coherent and reentrant_refused and notifications >= 7, "sinais coerentes e reentrada/transações bloqueadas")
	_reset()
	_check(_start(TOMATO, 1), "receita conhecida de tomate")
	_convert()
	payload = cauldron.call("get_ready_seed_delivery")
	_check(payload.quantity == 2 and payload.item_id == "semente_verao" and _claim(payload) and _deposit(payload) and chest.get_item_quantity("semente_verao") == 2, "tomate transporta rendimento inteiro")

func _cancel_and_refund() -> void:
	_reset({"trigo": 2, "agua": 7}, {"trigo": 2})
	_check(_start(), "lote para cancelar antes conversão")
	cauldron.call("cancelar_producao_em_lote")
	_check(cauldron.get("estado_atual") == "IDLE" and chest.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity("trigo") == 2, "cancelar timer restitui ambas origens")
	_reset({"trigo": 2, "agua": 7}, {"trigo": 2})
	_check(_start(), "lote cancelamento após conversão")
	_convert()
	var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
	cauldron.call("cancelar_producao_em_lote")
	_check(_order().cancelled and _order().phase == "ready" and _order().refunded == 1 and _order().reservations.is_empty(), "cancel mantém saída pronta e só restitui futuro")
	_check(chest.get_item_quantity("trigo") == 0 and GlobalInventory.get_item_quantity("trigo") == 2 and not _start(), "produto convertido não vira ingredientes/nova encomenda")
	_check(_claim(payload) and _deposit(payload) and cauldron.get("estado_atual") == "IDLE", "saída cancelada termina no Baú")
	_reset({"trigo": 2, "agua": 7}, {"trigo": 2})
	_check(_start(), "lote para refund bloqueado")
	_convert()
	payload = cauldron.call("get_ready_seed_delivery")
	_check(_claim(payload), "cargo antes cancelamento")
	var full := {"agua": 7}
	for index in range(12): full["fixture_fill_%02d" % index] = 99
	GlobalInventory.set_inventory_contents(full)
	cauldron.call("cancelar_producao_em_lote")
	_check(_order().cancelled and _order().phase == "carried" and _order().reservations.size() == 1 and ORDER.matches_cargo(_order(), golem.call("get_logistics_cargo_data")), "refund bloqueado conserva cargo e recibo")
	_check(_deposit(payload) and _order().phase == "refund_pending" and _order().delivered == 1 and _order().reservations.size() == 1, "ack não elimina refund pendente")
	_check(not _start(), "pedido pendente impede outro")
	GlobalInventory.remover_item("fixture_fill_00", 99)
	cauldron.call("cancelar_producao_em_lote")
	_check(cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity("trigo") == 2 and chest.get_item_quantity("semente_basica") == 3, "retry refund resolve sem duplicar saída")

func _one_seed_and_guards() -> void:
	for recipe_id in ["semente_trigo_recuperacao", "semente_tomate_recuperacao"]:
		_reset({"agua": 7}, {"carvao": 1, "trigo": 1})
		_check(_start(recipe_id, 1), "recuperação conhecida elegível")
		_convert()
		var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
		_check(payload.quantity == 1 and _claim(payload) and _deposit(payload), "recuperação transporta única semente física")
		_check(chest.get_item_quantity(payload.item_id) == 1 and GlobalInventory.get_item_quantity(payload.item_id) == 0, "recuperação conserva destino logístico")
	_reset()
	_check(_start(WHEAT, 1), "pedido para guardas de identidade")
	_convert()
	var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
	var copied := payload.duplicate(true)
	copied.quantity += 1
	_check(cauldron.call("get_ready_seed_delivery").quantity == 3 and not _claim(copied), "consulta é cópia e payload adulterado não retira")
	golem.global_position = cauldron.call("get_seed_delivery_pickup_position") + Vector2(100, 0)
	_check(not cauldron.call("take_ready_seed_delivery", golem, payload) and _order().phase == "ready", "retirada distante preserva pronto")
	var foreign := Node2D.new()
	home.add_child(foreign)
	foreign.global_position = cauldron.call("get_seed_delivery_pickup_position")
	_check(not cauldron.call("take_ready_seed_delivery", foreign, payload), "outro ator não ganha custódia")
	foreign.free()
	_check(_claim(payload), "ator original ganha custódia")
	golem.global_position = chest.global_position + Vector2(300, 0)
	_check(not cauldron.call("confirm_seed_delivery_deposit", golem, payload, chest) and chest.get_item_quantity("semente_basica") == 4, "depósito distante preserva cargo")
	var foreign_chest: VillageChest = CHEST.instantiate()
	foreign_chest.name = "FixtureForeignChest"
	home.add_child(foreign_chest)
	foreign_chest.global_position = chest.global_position
	_check(not cauldron.call("confirm_seed_delivery_deposit", golem, payload, foreign_chest) and foreign_chest.get_contents().is_empty(), "baú não autoritativo não recebe saída")
	foreign_chest.free()
	_check(_deposit(payload) and cauldron.get("estado_atual") == "IDLE", "guardas não impedem retry válido")

func _context_and_generation() -> void:
	_reset()
	_check(_start(), "pedido para contexto/load")
	_check(cauldron.call("advance_inactive_time", 1000.0) and _order().converted == 1 and _order().phase == "ready", "catch-up converte no máximo preparo corrente")
	var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	var generation: int = cauldron.call("get_seed_delivery_generation")
	_check(cauldron.call("load_save_data", saved) and not _claim(payload, generation), "load invalida callback pickup mesmo pedido")
	generation = cauldron.call("get_seed_delivery_generation")
	home.set("_region_being_cached", true)
	_check(not _claim(payload, generation) and _order().phase == "ready", "cache preserva pronto sem retirada")
	home.set("_region_being_cached", false)
	for priority in [2, 3, 4]:
		golem.call("set_work_priority", priority)
		_check(not _claim(payload) and _order().phase == "ready", "modo restrito preserva pronto")
	golem.call("set_work_priority", 1)
	_check(_claim(payload), "Regar primeiro transporta sem talento")
	saved = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	generation = cauldron.call("get_seed_delivery_generation")
	_check(cauldron.call("load_save_data", saved) and not _deposit(payload, generation) and chest.get_item_quantity("semente_basica") == 4, "load invalida ack sem depósito")
	home.set("_region_being_cached", true)
	_check(not _deposit(payload) and ORDER.matches_cargo(_order(), golem.call("get_logistics_cargo_data")), "cache conserva cargo sem depósito remoto")
	home.set("_region_being_cached", false)
	_check(_deposit(payload) and chest.get_item_quantity("semente_basica") == 7, "retomada deposita uma vez")

func _legacy_and_personal() -> void:
	_reset({"agua": 7}, {"trigo": 4})
	_check(cauldron.call("iniciar_producao_em_lote", WHEAT, 2), "default continua pessoal")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	_check(saved.state == "BATCH" and not saved.has("delivery") and cauldron.call("is_save_data_valid", saved), "schema pessoal sem pedido oculto")
	cauldron.call("_processar_tick_lote")
	_check(GlobalInventory.get_item_quantity("semente_basica") == 3 and chest.get_item_quantity("semente_basica") == 0, "resultado pessoal intacto")
	cauldron.call("cancelar_producao_em_lote")
	_check(chest.get_item_quantity("trigo") == 2 and cauldron.get("estado_atual") == "IDLE", "cancelamento pessoal intacto")
	_check(cauldron.call("load_save_data", {"state": "READY", "result_item": "semente_basica", "result_quantity": 1, "time_remaining": 0}), "READY legado aceito")
	cauldron.call("_perform_primary_interaction")
	_check(GlobalInventory.get_item_quantity("semente_basica") == 4 and cauldron.get("estado_atual") == "IDLE", "recolher READY continua pessoal")

func _snapshot_catchup() -> void:
	_reset()
	_check(_start(), "pedido para catch-up interno de snapshot")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	var timer: Timer = cauldron.get_node("BatchTimer")
	var remaining := timer.time_left
	SaveManager.set("_applying_snapshot", true)
	cauldron.call("_on_batch_timer_timeout")
	_check(_order().phase == "brewing" and _order().converted == 0 and not timer.is_stopped() and is_equal_approx(timer.time_left, remaining), "callback público applying bloqueado antes de parar timer")
	_check(not cauldron.call("advance_inactive_time", 1000.0) and not timer.is_stopped() and is_equal_approx(timer.time_left, remaining), "sem token applying não para timer")
	_check(not _start() and not _claim({}) and not SaveManager.save_game(), "applying mantém comandos/save bloqueados")
	probing = true
	notifications = 0
	_check(cauldron.call("load_save_data", saved), "load validado cria autorização transitória de catch-up")
	cauldron.call("_on_batch_timer_timeout")
	_check(_order().phase == "brewing" and not timer.is_stopped(), "token não libera callback público")
	_check(cauldron.call("advance_inactive_time", 1000.0), "catch-up de snapshot executa internamente")
	_check(_order().phase == "ready" and _order().converted == 1 and _order().delivered == 0 and _order().reservations.size() == 1 and timer.is_stopped(), "snapshot converte só preparo em curso e mantém próximo reservado")
	_check(notifications == 0 and ORDER.matches_cargo(_order(), null) and golem.call("get_logistics_cargo_data") == null and chest.get_item_quantity("semente_basica") == 4 and GlobalInventory.get_item_quantity("semente_basica") == 0, "catch-up sem sinais/retirada/depósito ou item pessoal")
	_check(not cauldron.call("advance_inactive_time", 1000.0) and _order().converted == 1, "catch-up não inicia cadeia dentro do loader")
	SaveManager.set("_applying_snapshot", false)
	probing = false
	var payload: Dictionary = cauldron.call("get_ready_seed_delivery")
	_check(_claim(payload) and _deposit(payload) and _order().phase == "brewing", "saída do loader retoma fluxo físico após guard")
	_reset()
	_check(_start(), "pedido para catch-up parcial do timer")
	saved = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	SaveManager.set("_applying_snapshot", true)
	_check(cauldron.call("load_save_data", saved) and cauldron.call("advance_inactive_time", 0.75), "snapshot curto retoma timer")
	_check(_order().phase == "brewing" and _order().converted == 0 and not timer.is_stopped() and is_equal_approx(timer.time_left, 1.25), "restante preservado desconta somente tempo de sessão")
	_check(not cauldron.call("advance_inactive_time", 1000.0) and is_equal_approx(timer.time_left, 1.25) and not timer.is_stopped(), "token consumido não permite segundo catch-up applying")
	SaveManager.set("_applying_snapshot", false)
	_check(cauldron.call("advance_inactive_time", 2.0) and _order().phase == "ready" and _order().converted == 1, "timer curto continua normalmente depois do loader")

func _resources() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "chest": chest.get_contents(), "xp": GlobalInventory.pontos_alquimia, "selection": GlobalInventory.semente_selecionada}

func _on_delivery_changed() -> void:
	if not probing: return
	notifications += 1
	var order: Variant = cauldron.call("get_seed_delivery_order_data")
	observed_coherent = observed_coherent and ORDER.matches_cargo(order, golem.call("get_logistics_cargo_data"))
	reentrant_refused = reentrant_refused and cauldron.call("is_seed_delivery_transaction_in_progress") and not _start() and not cauldron.call("load_save_data", {"state": "IDLE"}) and not SaveManager.save_game()
	var before: Variant = cauldron.call("get_seed_delivery_order_data")
	cauldron.call("cancelar_producao_em_lote")
	reentrant_refused = reentrant_refused and cauldron.call("get_seed_delivery_order_data") == before

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SeedDeliveryDomainSmokeTest: FAIL check %d - %s" % [checks, label])

func _finish() -> void:
	print("SeedDeliveryDomainSmokeTest: %s - Checks: %d" % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)
