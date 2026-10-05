extends Node

# Física real de rotas; produção preparada por tick explícito somente no QA.
const MAIN := preload("res://Scenes/Main.tscn")
const CARGO := preload("res://Scripts/data/GolemLogisticsCargo.gd")
const DESTINATION := "village_storage"
const RECIPES := ["semente_trigo_recuperacao", "semente_trigo_replantio", "semente_tomate_recuperacao", "semente_basica_tomate_sol"]
var home: Node2D
var golem: CharacterBody2D
var chest: VillageChest
var cauldron: Node2D
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA absoluto de QA antes de Main")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	cauldron = home.get_node("CauldronUI")
	(golem.get("_think_timer") as Timer).stop()
	# Não desabilitar a cena/caldeirão: colliders/mapa físicos ficam vivos.
	for plot in get_tree().get_nodes_in_group("lotes_terra"):
		plot.set_process(false)
	_domain()
	for recipe_id in RECIPES:
		_reset()
		var recipe: Dictionary = RecipeResolver.new().get_recipe(recipe_id)
		_ready_output(recipe_id)
		var expected: Dictionary = cauldron.call("get_ready_seed_delivery")
		var personal := _personal()
		var chest_before := chest.get_item_quantity(str(recipe.resultado_item))
		golem.call("prepare_accelerator_delivery")
		golem.call("set_work_priority", 1 if recipe_id == RECIPES[3] else 0)
		golem.call("_on_think_timer_timeout")
		_check(golem.get("state") == "MOVING_TO_LOGISTICS_SOURCE" and golem.call("get_logistics_cargo_data") == null and not expected.is_empty(), "ida física sem retirada antecipada " + recipe_id)
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") != null, "retirada " + recipe_id): return _finish()
		_check(CARGO.is_save_data_valid(golem.call("get_logistics_cargo_data")) and int(golem.call("get_logistics_cargo_data")["quantity"]) == int(recipe.resultado_quantidade), "cargo conserva preparo inteiro/rendimento " + recipe_id)
		_check(cauldron.call("get_ready_seed_delivery").is_empty() and _order()["phase"] == "carried" and chest.get_item_quantity(str(recipe.resultado_item)) == chest_before, "custódia exclusiva sem Baú antecipado")
		_check(golem.global_position.distance_to(cauldron.call("get_seed_delivery_pickup_position")) <= 14.0, "retirada próxima ao ponto externo do collider")
		await get_tree().process_frame
		_check((golem.get_node("SeedCargoVisual") as Sprite2D).visible, "reusa textura de semente no cargo físico")
		_check(not golem.call("_start_seeding") and golem.call("get_delivery_move_speed") == golem.get("move_speed_pixels_per_second"), "cargo não semeia nem recebe velocidade Aceleradora")
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") == null and golem.get("state") == "IDLE", "depósito " + recipe_id): return _finish()
		_check(chest.get_item_quantity(str(recipe.resultado_item)) == chest_before + int(recipe.resultado_quantidade) and _order().is_empty(), "ack único deposita toda saída " + recipe_id)
		_check(golem.global_position.distance_to(chest.global_position + Vector2(0, 48)) <= 14.0, "depósito próximo ao baú vivo")
		_check(_personal() == personal and not golem.get("seeding_enabled") and golem.get("selected_seed_id") == "semente_verao", "Mochila/ferramenta/escolha/OFF conservados")
		_check(golem.get("accelerator_prepared") and not golem.get("accelerator_active") and GlobalInventory.get_item_quantity("pocao_aceleradora") == 2, "transporte não gasta/frustra preparo da Aceleradora")
		_check(not cauldron.call("confirm_seed_delivery_deposit", golem, expected, chest) and chest.get_item_quantity(str(recipe.resultado_item)) == chest_before + int(recipe.resultado_quantidade), "ack repetido não duplica depósito")
	await _priority_and_retries()
	await _task_precedence()
	await _travel()
	_finish()

func _reset() -> void:
	_check(cauldron.call("load_save_data", {"state": "IDLE"}), "reset QA do caldeirão")
	_check(golem.call("load_work_save_data", GolemWorkState.default_data(), true), "reset QA da custódia")
	(golem.get("_think_timer") as Timer).stop()
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GlobalInventory.set_inventory_contents({"trigo": 30, "tomate_sol": 10, "semente_basica": 10, "agua": 10, "carvao": 10, "pocao_aceleradora": 2})
	GlobalInventory.receitas_descobertas = RECIPES.duplicate()
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	GlobalInventory.semente_selecionada = "semente_basica"
	chest.set_contents({"trigo": 30, "tomate_sol": 10, "semente_basica": 10, "semente_verao": 3, "carvao": 10})
	golem.set("move_speed_pixels_per_second", 600.0)
	golem.set("deposit_duration", 0.05)
	golem.set("harvest_duration", 0.05)
	golem.global_position = cauldron.call("get_seed_delivery_pickup_position") + Vector2(180, 0)
	(home.get_node("PlayerAvatar") as Node2D).global_position = cauldron.call("get_seed_delivery_pickup_position") + Vector2(0, -40)
	golem.call("set_selected_seed_id", "semente_verao")
	for plot in get_tree().get_nodes_in_group("lotes_terra"):
		plot.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": false, "regado": false, "expansion_blocked": false})
		plot.set_process(false)

func _ready_output(recipe_id: String = "semente_trigo_replantio", total: int = 1) -> void:
	_check(cauldron.call("iniciar_producao_em_lote", recipe_id, total, DESTINATION), "pedido finito opt-in " + recipe_id)
	(cauldron.get_node("BatchTimer") as Timer).stop()
	cauldron.call("_on_batch_timer_timeout")
	_check(not cauldron.call("get_ready_seed_delivery").is_empty(), "tick QA converte somente uma saída")

func _personal() -> Dictionary:
	return {"items": GlobalInventory.inventario.duplicate(true), "tool": ToolManager.get_active_tool(), "selected": GlobalInventory.semente_selecionada}

func _order() -> Dictionary:
	var value: Variant = cauldron.call("get_seed_delivery_order_data")
	return value if value is Dictionary else {}

func _domain() -> void:
	var payload := {"order_id": "qa_order", "step": 1, "source_id": "cauldron_village", "item_id": "semente_verao", "quantity": 2}
	var cargo := CARGO.new()
	_check(cargo.accept(payload) and cargo.matches(JSON.parse_string(JSON.stringify(payload))), "cargo normaliza JSON sem redistribuir unidades")
	_check(not cargo.accept(payload), "segunda custódia recusada")
	var wrong := payload.duplicate(true)
	wrong["step"] = 2
	_check(not cargo.clear(wrong) and cargo.has_cargo() and cargo.clear(payload) and not cargo.has_cargo(), "clear exige identidade completa e só ocorre uma vez")
	for key in payload:
		var broken := payload.duplicate(true)
		broken.erase(key)
		_check(not CARGO.is_save_data_valid(broken), "payload exige campo " + str(key))
	for pair in [["order_id", " qa "], ["order_id", ""], ["source_id", "cache"], ["item_id", "semente_inverno"], ["step", true], ["step", 1.5], ["quantity", 0], ["quantity", INF], ["quantity", -1]]:
		var broken := payload.duplicate(true)
		broken[pair[0]] = pair[1]
		_check(not CARGO.is_save_data_valid(broken), "payload estrito recusa " + str(pair))
	var work := GolemWorkState.default_data()
	work["logistics_cargo"] = payload
	_check(GolemWorkState.is_valid(work, true) and not GolemWorkState.is_valid(work, false), "cargo exige gate mas não semeador ligado")
	work["accelerator_prepared"] = true
	_check(GolemWorkState.is_valid(work, true), "preparo da Aceleradora independente")
	work["harvest_cargo"] = {"trigo": 1}
	_check(not GolemWorkState.is_valid(work, true), "cargo de colheita não coexiste")
	work["harvest_cargo"] = {}
	work["seed_cargo"] = {"item_id": "semente_verao", "quantity": 1, "target_cell": {"x": 0, "y": 0}, "intent": "return"}
	_check(not GolemWorkState.is_valid(work, true), "cargo de semeadura não coexiste")
	work = GolemWorkState.default_data()
	work.erase("logistics_cargo")
	_check(GolemWorkState.is_valid(work, false) and golem.call("load_work_save_data", work, false) and golem.call("get_logistics_cargo_data") == null, "legado sem campo resolve sem carga logística")

func _priority_and_retries() -> void:
	for priority in [2, 3, 4]:
		_reset()
		_ready_output()
		golem.call("set_work_priority", priority)
		var output: Dictionary = cauldron.call("get_ready_seed_delivery")
		golem.call("_on_think_timer_timeout")
		_check(cauldron.call("get_ready_seed_delivery") == output and golem.call("get_logistics_cargo_data") == null and golem.get("work_priority") == priority, "modo restrito não retira nem troca prioridade " + str(priority))
		golem.call("set_work_priority", 0)
		golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") != null, "retirada para pausa"): return
		var payload: Dictionary = golem.call("get_logistics_cargo_data")
		var stale: Callable = golem.get("_movement_callback")
		golem.call("set_work_priority", priority)
		var stopped := golem.global_position
		if stale.is_valid(): stale.call()
		golem.call("_on_think_timer_timeout")
		await get_tree().create_timer(0.08).timeout
		_check(golem.global_position == stopped and golem.call("get_logistics_cargo_data") == payload and golem.get("state") == "IDLE", "modo restrito pausa cargo/token e não permite nova agricultura " + str(priority))
		golem.call("set_work_priority", 1)
		golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") == null, "retoma modo misto"): return
		_check(chest.get_item_quantity("semente_basica") == 13, "retomada deposita uma vez")
	for interference in ["chest", "cancel", "load", "blocked", "deposit_pause"]:
		_reset()
		_ready_output("semente_trigo_replantio", 2)
		golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") != null, "cargo para " + interference): return
		if interference == "deposit_pause":
			golem.set("deposit_duration", 0.2)
			if not await _wait(func(): return golem.get("state") == "DEPOSITING_LOGISTICS", "pausa durante depósito"): return
		var payload: Dictionary = golem.call("get_logistics_cargo_data")
		var stale: Callable = golem.get("_movement_callback")
		golem.call("set_work_priority", 4)
		if interference == "chest": home.remove_child(chest)
		elif interference == "cancel": cauldron.call("cancelar_producao_em_lote")
		elif interference == "load":
			var work: Dictionary = golem.call("get_work_save_data")
			_check(golem.call("load_work_save_data", JSON.parse_string(JSON.stringify(work)), true), "load JSON substitui mesma custódia sem retirada/refund")
		elif interference == "deposit_pause":
			await get_tree().create_timer(0.25).timeout
			_check(golem.call("get_logistics_cargo_data") == payload and chest.get_item_quantity("semente_basica") == 10, "timer obsoleto não confirma depósito pausado")
		if stale.is_valid(): stale.call()
		golem.call("set_work_priority", 0)
		golem.call("_on_think_timer_timeout")
		if interference == "blocked":
			var nav: NavigationAgent2D = golem.get("navigation_agent")
			golem.set("navigation_agent", null)
			await get_tree().physics_frame
			await get_tree().physics_frame
			golem.set("navigation_agent", nav)
		_check(golem.call("get_logistics_cargo_data") == payload and cauldron.call("get_ready_seed_delivery").is_empty(), "interferência conserva custódia exclusiva " + interference)
		if interference == "chest": home.add_child(chest)
		if golem.get("state") == "IDLE": golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return golem.call("get_logistics_cargo_data") == null, "depósito após " + interference): return
		_check(chest.get_item_quantity("semente_basica") == 13, "retry não duplica unidades " + interference)
		if interference == "cancel":
			_check(_order().is_empty(), "cancelamento resolve cargo sem iniciar futuro")
		else:
			_check(_order()["phase"] == "brewing", "próximo preparo só inicia após ack físico")

func _task_precedence() -> void:
	_reset()
	_ready_output()
	# Cargo agrícola já retirado tem precedência, mesmo com saída pronta.
	var seed: GolemSeedCargo = golem.get("seed_cargo")
	_check(seed.take_from_chest(chest, Vector2i.ZERO, "semente_verao") and seed.mark_return_pending(), "fixture de cargo agrícola atual")
	golem.global_position = chest.global_position + Vector2(180, 48)
	golem.call("_on_think_timer_timeout")
	_check(golem.get("state") == "MOVING_TO_SEED_RETURN" and golem.call("get_logistics_cargo_data") == null, "finaliza cargo agrícola antes do pickup pronto")
	if not await _wait(func(): return not seed.has_seed() and golem.get("state") == "IDLE", "devolução agrícola corrente"): return
	golem.call("_on_think_timer_timeout")
	_check(golem.get("state") == "MOVING_TO_LOGISTICS_SOURCE", "depois atende saída pronta antes de nova agricultura")
	if not await _wait(func(): return golem.call("get_logistics_cargo_data") == null and _order().is_empty(), "logística após agricultura"): return

func _travel() -> void:
	_reset()
	_ready_output()
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.call("get_logistics_cargo_data") != null, "cargo para viagem"): return
	var payload: Dictionary = golem.call("get_logistics_cargo_data")
	var stale: Callable = golem.get("_movement_callback")
	golem.call("set_work_priority", 4)
	var contents := chest.get_contents()
	home.call("request_region_transition", &"foraging_grove", &"from_farm")
	await _settle_travel()
	_check(not home.is_inside_tree(), "viagem real cacheia HOME")
	if stale.is_valid(): stale.call()
	golem.call("_on_think_timer_timeout")
	_check(golem.call("get_logistics_cargo_data") == payload and chest.get_contents() == contents, "cache não entrega remotamente nem perde cargo")
	get_tree().current_scene.call("request_region_transition", &"farm_village", &"from_foraging_grove")
	await _settle_travel()
	_check(get_tree().current_scene == home and golem.call("get_logistics_cargo_data") == payload, "retorno conserva mesma identidade")
	(golem.get("_think_timer") as Timer).stop()
	golem.call("set_work_priority", 0)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.call("get_logistics_cargo_data") == null, "depósito pós-retorno"): return
	_check(chest.get_item_quantity("semente_basica") == 13, "retorno reconstrói rota sem duplicação")

func _settle_travel() -> void:
	for _frame in range(240):
		await get_tree().process_frame
		if not RegionTravelCoordinator.is_transition_in_progress(): break
	await _settle()

func _settle() -> void:
	for _frame in range(6): await get_tree().process_frame

func _wait(condition: Callable, label: String) -> bool:
	for _frame in range(1200):
		await get_tree().physics_frame
		if bool(condition.call()):
			_check(true, label)
			return true
	_check(false, "timeout " + label + "; state=" + str(golem.get("state")))
	return false

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SeedDeliveryGolemSmokeTest: FAIL - " + label)

func _finish() -> void:
	if not failed: print("SeedDeliveryGolemSmokeTest: PASS - %d verificações de custódia e física." % checks)
	get_tree().quit(1 if failed else 0)
