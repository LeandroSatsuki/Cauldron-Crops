extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SEED := "semente_basica"
var main: Node
var golem: Node
var chest: VillageChest
var plot: Node
var checks := 0
var failed := false
var observe_harvest := false
var harvest_observed := false
var blocked_reentrant_save := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("GolemWorkPersistenceSmokeTest: exige APPDATA em Builds/QA; nenhum arquivo alterado.")
		get_tree().quit(1)
		return
	await _new_home()
	if "--verify-sower-reopen" in OS.get_cmdline_user_args():
		_check(SaveManager.has_save(), "arquivo do processo anterior disponível")
		_check(SaveManager.load_game(), "novo processo lê save existente")
		var reopened: Dictionary = golem.call("get_work_save_data")
		_check(not reopened["seeding_enabled"] and reopened["seed_cargo"] != null and (golem.get("seed_cargo") as GolemSeedCargo).is_return_pending(), "novo processo restaura OFF com devolução")
		_check(chest.get_item_quantity(SEED) == 2 and GlobalInventory.get_item_quantity(SEED) == 7, "novo processo mantém fontes separadas")
		_check(GroveExpedition.restored and golem.get("work_priority") == 4, "novo processo conserva marco e pausa")
		_check(SaveManager.load_game() and golem.call("get_work_save_data") == reopened and chest.get_item_quantity(SEED) == 2, "replay no novo processo não duplica")
		main.queue_free()
		if not failed:
			print("GolemWorkPersistenceSmokeTest: PASS - %d verificações de reabertura em outro processo." % checks)
		get_tree().quit(1 if failed else 0)
		return
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	GlobalInventory.set_inventory_contents({SEED: 7, "agua": 4})
	GlobalInventory.semente_selecionada = SEED
	chest.set_contents({SEED: 3, "trigo": 2})
	var cargo: GolemSeedCargo = golem.get("seed_cargo")
	golem.set("seeding_enabled", true)
	_check(cargo.take_from_chest(chest, Vector2i(0, 0)), "fixture retira uma semente real do baú")
	var seed_save: Dictionary = SaveManager.call("_build_save_data")
	_check(seed_save["golem_work"]["seed_cargo"]["quantity"] == 1 and seed_save["village_chest_inventory"][SEED] == 2, "snapshot registra custódia exclusiva")
	_check(not seed_save["golem_work"].has("state") and not seed_save["golem_work"].has("position"), "snapshot não persiste rota/estado de navegação")
	var personal_before := GlobalInventory.inventario.duplicate(true)
	var expected_work: Dictionary = seed_save["golem_work"].duplicate(true)
	seed_save["golem_work"]["seed_cargo"]["target_cell"]["x"] = 99
	_check(cargo.get_target_cell() == Vector2i(0, 0), "snapshot profundo não altera carga runtime")
	seed_save = SaveManager.call("_build_save_data")
	var json: Dictionary = JSON.parse_string(JSON.stringify(seed_save))
	_check(bool(SaveManager.call("_apply_save_data", json)), "load JSON transportando aceita snapshot elegível")
	_check(golem.call("get_work_save_data") == expected_work and chest.get_item_quantity(SEED) == 2, "load mantém uma semente em carga e não refaz retirada")
	_check(bool(SaveManager.call("_apply_save_data", json)), "replay transportando aceita")
	_check(golem.call("get_work_save_data") == expected_work and GlobalInventory.inventario == personal_before and chest.get_item_quantity(SEED) == 2, "replay não duplica nem usa Mochila")
	var changed_input: Dictionary = json.duplicate(true)
	_check(bool(SaveManager.call("_apply_save_data", changed_input)), "load copia input")
	changed_input["golem_work"]["seed_cargo"]["target_cell"]["y"] = 99
	_check((golem.get("seed_cargo") as GolemSeedCargo).get_target_cell() == Vector2i(0, 0), "input aplicado não compartilha referência")
	(golem.get("seed_cargo") as GolemSeedCargo).mark_return_pending()
	golem.set("seeding_enabled", false)
	var return_save: Dictionary = SaveManager.call("_build_save_data")
	_check(bool(SaveManager.call("_apply_save_data", return_save)) and (golem.get("seed_cargo") as GolemSeedCargo).is_return_pending(), "OFF com devolução pendente persiste")
	_check(SaveManager.save_game(), "gravação real em arquivo QA")
	var old_instance := main.get_instance_id()
	main.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	await _new_home()
	_check(main.get_instance_id() != old_instance, "reabertura usa nova instância da vila/golem")
	_check(SaveManager.load_game(), "arquivo real restaura carga após reabertura da cena")
	_check((golem.get("seed_cargo") as GolemSeedCargo).is_return_pending() and chest.get_item_quantity(SEED) == 2, "arquivo real preserva devolução/estoque")
	_check(SaveManager.load_game() and chest.get_item_quantity(SEED) == 2, "segundo load real não faz refund")
	var disk_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	golem.set("carried_rewards", [{"item_id": "item_desconhecido", "quantidade": 1}])
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk_before, "carga runtime inválida não sobrescreve arquivo")
	golem.set("carried_rewards", [])
	for node in get_tree().root.get_children():
		if node is AcceptDialog:
			node.queue_free()

	_test_invalid_payloads(return_save)
	_test_legacy_and_replacement(seed_save)
	await _test_cancelled_work()
	await _test_harvest_commit_and_disk()
	await _test_cached_village(return_save)
	_check(not failed, "fechamento das invariantes")
	if is_instance_valid(main):
		main.queue_free()
	if not failed:
		print("GolemWorkPersistenceSmokeTest: PASS - %d verificações de snapshots, arquivos QA, legado, replay, callbacks e vila cacheada." % checks)
	get_tree().quit(1 if failed else 0)

func _new_home() -> void:
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame
	golem = main.get_node("Golem")
	chest = main.get_node("VillageChest")
	plot = main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	(golem.get("_think_timer") as Timer).stop()
	golem.call("set_work_priority", 4)

func _test_invalid_payloads(base: Dictionary) -> void:
	var invalid: Array = [null, [], {}, false]
	for key in ["version", "seeding_enabled", "work_priority", "harvest_cargo", "seed_cargo"]:
		var missing: Dictionary = base["golem_work"].duplicate(true)
		missing.erase(key)
		invalid.append(missing)
	for version in [0, 2, 1.5, "1", true]:
		var work: Dictionary = base["golem_work"].duplicate(true)
		work["version"] = version
		invalid.append(work)
	for priority in [-1, 5, 1.5, "4", false, INF, NAN]:
		var work: Dictionary = base["golem_work"].duplicate(true)
		work["work_priority"] = priority
		invalid.append(work)
	for enabled in [0, "false", null]:
		var work: Dictionary = base["golem_work"].duplicate(true)
		work["seeding_enabled"] = enabled
		invalid.append(work)
	for harvest in [[], null, {"trigo": 0}, {"trigo": -1}, {"trigo": 1.2}, {"trigo": true}, {"trigo": "1"}, {"item_desconhecido": 1}, {"trigo": 1}]:
		var work: Dictionary = base["golem_work"].duplicate(true)
		work["harvest_cargo"] = harvest
		invalid.append(work)
	for seed in [{}, {"item_id": SEED}, false]:
		var work: Dictionary = base["golem_work"].duplicate(true)
		work["seed_cargo"] = seed
		invalid.append(work)
	var disabled_transport: Dictionary = base["golem_work"].duplicate(true)
	disabled_transport["seed_cargo"]["intent"] = "transport"
	invalid.append(disabled_transport)
	for value in invalid:
		var incoming := base.duplicate(true)
		incoming["golem_work"] = value
		_expect_rejected(incoming)
	var no_unlock := base.duplicate(true)
	no_unlock["grove_expedition"] = {"discovered": false, "restored": false, "forage_sources": {}}
	_expect_rejected(no_unlock)
	no_unlock.erase("grove_expedition")
	_expect_rejected(no_unlock)
	var before: Dictionary = golem.call("get_work_save_data")
	_check(not bool(golem.call("load_work_save_data", disabled_transport, true)) and golem.call("get_work_save_data") == before, "load direto inválido não cancela/muda carga")
	var default := GolemWorkState.default_data()
	for priority in range(5):
		default["work_priority"] = priority
		_check(GolemWorkState.is_valid(default, false), "prioridade %d válida sem unlock semeadura" % priority)
	default["seeding_enabled"] = true
	_check(not GolemWorkState.is_valid(default, false) and GolemWorkState.is_valid(default, true), "flag exige marco no snapshot")

func _test_legacy_and_replacement(seed_save: Dictionary) -> void:
	for version in [3, 4]:
		_check(bool(SaveManager.call("_apply_save_data", seed_save)), "prepara carga antes de legado")
		var legacy := seed_save.duplicate(true)
		legacy["version"] = version
		legacy.erase("golem_work")
		_check(bool(SaveManager.call("_apply_save_data", legacy)), "legado v%d sem bloco aceito" % version)
		_check(golem.call("get_work_save_data") == GolemWorkState.default_data(), "legado limpa carga e mantém OFF sem refund")
		_check(GroveExpedition.restored and chest.get_item_quantity(SEED) == 2, "legado restaurado permanece elegível sem gerar semente")
	_check(bool(SaveManager.call("_apply_save_data", seed_save)), "reinstala carga transportada")
	var partial := {"version": 4, "farm_grid": main.call("obter_farm_grid_save_data")}
	var before: Dictionary = golem.call("get_work_save_data")
	_check(bool(SaveManager.call("_apply_save_data", partial)) and golem.call("get_work_save_data") == before, "contrato agrícola parcial sem bloco preserva golem")
	var empty := seed_save.duplicate(true)
	empty["golem_work"] = GolemWorkState.default_data()
	empty["golem_work"]["work_priority"] = 4
	empty["village_chest_inventory"] = {SEED: 20}
	_check(bool(SaveManager.call("_apply_save_data", empty)), "snapshot vazio substitui carga antiga")
	_check(chest.get_item_quantity(SEED) == 20 and not (golem.get("seed_cargo") as GolemSeedCargo).has_seed(), "substituição não devolve semente antiga ao novo estoque")
	var harvest := empty.duplicate(true)
	harvest["golem_work"]["harvest_cargo"] = {"trigo": 3, "palha_rara": 1}
	_check(bool(SaveManager.call("_apply_save_data", harvest)), "carga de colheita é restaurada")
	_check(golem.call("get_work_save_data")["harvest_cargo"] == harvest["golem_work"]["harvest_cargo"], "totais de colheita preservados")
	_check(bool(SaveManager.call("_apply_save_data", harvest)) and chest.get_item_quantity(SEED) == 20, "replay de colheita não deposita")
	_check(bool(SaveManager.call("_apply_save_data", empty)) and (golem.get("carried_rewards") as Array).is_empty(), "snapshot vazio descarta apenas runtime antigo sem refund")

func _test_cancelled_work() -> void:
	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	snapshot["golem_work"]["work_priority"] = 0
	snapshot["golem_work"]["harvest_cargo"] = {"trigo": 2}
	golem.call("load_work_save_data", snapshot["golem_work"], true)
	var probe := {"calls": 0}
	golem.call("_iniciar_deslocamento", Vector2.ZERO, func(): probe.calls += 1)
	var stale: Callable = golem.get("_movement_callback")
	_check(bool(SaveManager.call("_apply_save_data", snapshot)), "load invalida movimento antigo")
	stale.call()
	_check(probe.calls == 0, "callback capturado antes do load não executa")
	golem.set("deposit_duration", 0.08)
	golem.set("target_chest", chest)
	golem.set("state", "MOVING_TO_CHEST")
	golem.call("_chegar_ao_bau")
	_check(golem.get("state") == "DEPOSITING", "depósito entrou em espera")
	_check(bool(SaveManager.call("_apply_save_data", snapshot)), "load durante espera de depósito")
	# Mesmo estado após load: o token, não apenas a string, precisa recusar a espera antiga.
	golem.set("target_chest", chest)
	golem.set("state", "DEPOSITING")
	var stock := chest.get_contents()
	await get_tree().create_timer(0.14).timeout
	_check(chest.get_contents() == stock and golem.call("get_work_save_data")["harvest_cargo"] == {"trigo": 2}, "espera obsoleta não deposita carga restaurada")
	golem.call("_parar_execucao_atual")
	golem.set("harvest_duration", 0.08)
	_reset_ready_plot()
	for action in ["_chegar_ao_lote", "_chegar_para_regar"]:
		golem.set("target_plot", plot)
		golem.set("state", "MOVING_TO_PLOT")
		golem.call(action)
		var waiting_state: String = golem.get("state")
		_check(bool(SaveManager.call("_apply_save_data", snapshot)), "load invalida espera %s" % action)
		_reset_ready_plot()
		golem.set("target_plot", plot)
		golem.set("state", waiting_state)
		var before: Dictionary = plot.call("get_save_data")
		await get_tree().create_timer(0.14).timeout
		_check(plot.call("get_save_data") == before, "espera %s não altera novo lote" % action)
		golem.call("_parar_execucao_atual")
	golem.set("work_priority", 0)
	golem.set("target_chest", null)
	golem.set("state", "MOVING_TO_CHEST")
	golem.call("_chegar_ao_bau")
	await get_tree().create_timer(0.14).timeout
	_check(golem.call("get_work_save_data")["harvest_cargo"] == {"trigo": 2}, "baú ausente não limpa colheita carregada")
	golem.call("_iniciar_deslocamento", Vector2.ZERO, func(): probe.calls += 1)
	stale = golem.get("_movement_callback")
	golem.call("set_work_priority", 4)
	stale.call()
	_check(probe.calls == 0, "pausa invalida callback sem destruir carga")

func _test_harvest_commit_and_disk() -> void:
	golem.set("carried_rewards", [])
	golem.set("work_priority", 0)
	_reset_ready_plot()
	plot.set("_pending_manual_harvest_rewards", [{"item_id": "trigo", "quantidade": 1}])
	plot.connect("estado_alterado", _on_plot_changed)
	observe_harvest = true
	golem.set("target_plot", plot)
	golem.set("state", "MOVING_TO_PLOT")
	golem.call("_chegar_ao_lote")
	await get_tree().create_timer(0.14).timeout
	observe_harvest = false
	_check(harvest_observed, "observador do lote viu colheita já na carga")
	golem.call("set_work_priority", 4)
	_check(golem.call("get_work_save_data")["harvest_cargo"] == {"trigo": 1}, "colheita física instalada no snapshot")
	_check(SaveManager.save_game(), "grava colheita em disco QA")
	var saved: Dictionary = SaveManager.call("_build_save_data")
	golem.set("carried_rewards", [])
	chest.set_contents({"trigo": 99})
	_check(SaveManager.load_game() and golem.call("get_work_save_data")["harvest_cargo"] == {"trigo": 1}, "load real restaura colheita e substitui estoque")
	var stock_matches: bool = chest.get_contents().size() == saved["village_chest_inventory"].size()
	for item_id in saved["village_chest_inventory"]:
		stock_matches = stock_matches and chest.get_item_quantity(item_id) == int(saved["village_chest_inventory"][item_id])
	_check(stock_matches, "load não deposita sobre estoque restaurado")
	QuestManager.quest_atualizada.connect(_attempt_reentrant_save)
	_check(bool(SaveManager.call("_apply_save_data", saved)), "load com observador de progresso")
	QuestManager.quest_atualizada.disconnect(_attempt_reentrant_save)
	_check(blocked_reentrant_save, "gravação durante sinais intermediários de load é recusada")

func _test_cached_village(seed_save: Dictionary) -> void:
	_check(bool(SaveManager.call("_apply_save_data", seed_save)), "prepara semente antes da viagem")
	var probe := {"calls": 0}
	golem.call("_iniciar_deslocamento", Vector2.ZERO, func(): probe.calls += 1)
	var stale: Callable = golem.get("_movement_callback")
	main.call("request_region_transition", &"foraging_grove", &"from_farm")
	for _frame in range(180):
		await get_tree().process_frame
		if get_tree().current_scene != main and not RegionTravelCoordinator.is_transition_in_progress():
			break
	_check(not main.is_inside_tree(), "viagem remove vila da árvore")
	stale.call()
	_check(probe.calls == 0, "saída da árvore invalida movimento antigo")
	await get_tree().create_timer(0.15).timeout
	var cached: Dictionary = SaveManager.call("_build_save_data")
	_check(cached["golem_work"] == seed_save["golem_work"], "save externo lê carga congelada da vila cacheada")
	var invalid := cached.duplicate(true)
	invalid["golem_work"]["seed_cargo"]["quantity"] = 2
	var external := get_tree().current_scene
	_expect_rejected(invalid)
	_check(get_tree().current_scene == external and not main.is_inside_tree(), "payload inválido não troca região")
	_check(SaveManager.save_game(), "save real no Bosque inclui carga da vila")
	_check(SaveManager.load_game() and get_tree().current_scene == main, "load externo retorna à vila com snapshot")
	_check(golem.call("get_work_save_data") == cached["golem_work"] and chest.get_item_quantity(SEED) == 2, "tempo ausente não planta/retira/devolve semente")
	_check(SaveManager.load_game() and chest.get_item_quantity(SEED) == 2, "replay do arquivo externo conserva custódia")

func _expect_rejected(data: Dictionary) -> void:
	var before := _domain_snapshot()
	_check(not bool(SaveManager.call("_apply_save_data", data)), "payload inválido recusado")
	_check(before == _domain_snapshot(), "recusa não altera domínio/estoques/região/golem")

func _domain_snapshot() -> Dictionary:
	return {"inventory": GlobalInventory.inventario.duplicate(true), "selection": GlobalInventory.semente_selecionada,
		"chest": chest.get_contents(), "golem": golem.call("get_work_save_data"), "generation": golem.get("_task_generation"),
		"grove": GroveExpedition.get_save_data(), "plot": plot.call("get_save_data"), "scene": get_tree().current_scene.get_instance_id()}

func _reset_ready_plot() -> void:
	plot.call("load_save_data", {"estado_atual": 2, "semente_id_plantada": SEED, "regado": false, "arado": true, "tempo_restante": 0.0, "tempo_total_crescimento": 3.0, "pronto_para_colher": true})

func _on_plot_changed() -> void:
	if observe_harvest and plot.get("estado_atual") == 0:
		var data: Dictionary = SaveManager.call("_build_save_data")
		harvest_observed = data["golem_work"]["harvest_cargo"] == {"trigo": 1}

func _attempt_reentrant_save() -> void:
	blocked_reentrant_save = not SaveManager.save_game()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("GolemWorkPersistenceSmokeTest: FAIL - %s" % message)
