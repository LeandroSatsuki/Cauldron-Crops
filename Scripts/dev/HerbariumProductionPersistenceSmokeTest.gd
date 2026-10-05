extends Node

# Fixtures sintéticas exclusivamente em APPDATA de QA; nunca abre save pessoal.
const MAIN := preload("res://Scenes/Main.tscn")
const BLOCK := "herbarium_production"
const LOCAL := {"activated": true, "renewal_remaining": 37.5}
const ROOT := {"collected": true, "renewal_remaining": 22.5}

var home: Node
var chest: VillageChest
var golem: Node
var project: Node
var checks := 0
var failed := false
var publications := 0
var incoherent_publications := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "APPDATA deve estar sob Builds/QA antes de Main")
		return _finish("sandbox recusado")
	get_tree().root.gui_embed_subwindows = true
	for service in [PocoManager, GroveExpedition, HerbariumProduction, EventDirector]:
		service.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	chest = home.get_node("VillageChest")
	golem = home.get_node("Golem")
	project = home.get("restoration_projects")["first_obstacle"]
	home.process_mode = Node.PROCESS_MODE_DISABLED
	(golem.get("_think_timer") as Timer).stop()
	HerbariumProduction.progress_changed.connect(_on_publication)
	if "--verify-herbarium-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish("reabertura")
	if "--write-herbarium-fixture" in OS.get_cmdline_user_args():
		_write_fixture()
		return _finish("fixture")
	_test_validator()
	_test_snapshots()
	_test_invalid_preflight()
	_test_writer_and_transactions()
	await _test_cache()
	_write_fixture()
	_finish("schema, gates efetivos, replay, parcial, writer e cache")

func _on_publication() -> void:
	publications += 1
	if SaveManager.is_applying_snapshot() or not SaveManager.call("_resolve_herbarium_snapshot", {}).get("valid", false):
		incoherent_publications += 1

func _set_fixture() -> void:
	HerbariumProduction.reset_progress()
	golem.call("load_work_save_data", GolemWorkState.default_data(), false)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	GlobalInventory.set_inventory_contents({"trigo": 17, "tomate_sol": 4, "mistura_restauradora": 3, "raiz_gelida": 2, "rama_encantada": 1, "agua": 7})
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.pontos_alquimia = 3
	GlobalInventory.apply_backpack_progress(["first_herbarium"])
	ToolManager.clear_tool()
	EconomyManager.well_improved_by_project = false
	EconomyManager.poco_capacidade_maxima = 10
	chest.set_contents({"trigo": 21, "tomate_sol": 7, "mistura_restauradora": 5, "raiz_gelida": 11})
	var setup := {
		"farm_expansion": {"purification_obstacles": {"first_obstacle": true}, "restoration_projects": {"first_herbarium": true}},
		"grove_expedition": {"discovered": true, "restored": true, "forage_sources": {"grove_root": ROOT.duplicate(true)}},
		BLOCK: LOCAL.duplicate(true),
	}
	if not SaveManager.call("_apply_save_data", setup):
		failed = true
		push_error("HerbariumProductionPersistenceSmokeTest: preparação recusada")

func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))

func _node_ids(node: Node, output: Array) -> void:
	output.append(node.get_instance_id())
	for child in node.get_children(): _node_ids(child, output)

func _domain() -> Dictionary:
	var plot_states: Array = []
	for plot in home.get("farm_plot_registry").values(): plot_states.append(plot.call("get_save_data"))
	var obstacle_states: Array = []
	for obstacle in SaveManager.call("_get_save_group_nodes", "purification_obstacle"):
		obstacle_states.append(obstacle.call("get_save_data"))
	var ids: Array = []
	_node_ids(home, ids)
	return {
		"personal": GlobalInventory.inventario.duplicate(true), "chest": chest.get_contents(),
		"milestones": GlobalInventory.get_backpack_milestones(), "xp": GlobalInventory.pontos_alquimia,
		"recipes": GlobalInventory.receitas_descobertas.duplicate(true), "skills": GlobalInventory.skills_desbloqueadas.duplicate(true),
		"lore": GlobalInventory.lore_descobertas.duplicate(true), "fishing": GlobalInventory.colecao_pesca_descobertas.duplicate(true),
		"charges": GlobalInventory.cargas_crescimento, "tool": ToolManager.get_active_tool(), "seed": GlobalInventory.semente_selecionada,
		"economy": [EconomyManager.moedas, EconomyManager.total_golems, EconomyManager.max_golems, EconomyManager.poco_capacidade_maxima, EconomyManager.well_improved_by_project],
		"quests": QuestManager.quests_ativas.duplicate(true), "max_quests": QuestManager.max_quests, "season": [SeasonManager.estacao_atual, SeasonManager.ano],
		"local": HerbariumProduction.get_save_data(), "grove": GroveExpedition.get_save_data(),
		"project": project.call("get_save_data"), "area": project.get("area_purified"),
		"plots": plot_states, "obstacles": obstacle_states, "golem": golem.call("get_work_save_data"),
		"cauldrons": SaveManager.call("_build_cauldron_save_data"), "pending_fish": SaveManager.call("_build_fishing_save_data"),
		"scene": get_tree().current_scene.get_instance_id(), "home_nodes": ids,
		"player": home.get_node("PlayerAvatar").global_position,
	}

func _same_domain(before: Dictionary, include_nodes: bool = false) -> bool:
	# JSON números inteiros/float representam a mesma quantidade após leitura.
	var current := _domain()
	var expected := before.duplicate(true)
	if not include_nodes:
		current.erase("home_nodes")
		expected.erase("home_nodes")
	return JSON.parse_string(JSON.stringify(current)) == JSON.parse_string(JSON.stringify(expected))

func _test_validator() -> void:
	for value in [HerbariumProductionState.default_data(), LOCAL, {"activated": true, "renewal_remaining": 0}, {"activated": true, "renewal_remaining": 90.0}]:
		_check(HerbariumProductionState.is_valid(value), "schema aceita extremos e fração finita: " + str(value))
	for value in [null, true, 0, "", [], {}, {"activated": true}, {"renewal_remaining": 0}, {"activated": true, "renewal_remaining": 0, "extra": 1}]:
		_check(not HerbariumProductionState.is_valid(value), "schema exige dicionário exato: " + str(value))
	for value in [null, 0, 1, 0.0, 1.0, "true", {}, []]:
		_check(not HerbariumProductionState.is_valid({"activated": value, "renewal_remaining": 0}), "activated sem coerção: " + str(value))
	for value in [null, true, false, "0", [], {}, -0.1, 90.1, INF, -INF, NAN]:
		_check(not HerbariumProductionState.is_valid({"activated": true, "renewal_remaining": value}), "remaining sem coerção finito 0..90: " + str(value))
	_check(not HerbariumProductionState.is_valid({"activated": false, "renewal_remaining": 1}), "desativada exige zero")

func _test_snapshots() -> void:
	_set_fixture()
	var snapshot := _snapshot()
	_check(int(snapshot["version"]) == 4 and snapshot[BLOCK] == LOCAL, "campo top opcional preserva v4 e tempo exato")
	var before := _domain()
	var generation := HerbariumProduction.get_generation()
	var signals_before := publications
	_check(SaveManager.call("_apply_save_data", snapshot) and _same_domain(before), "snapshot completo não paga nem entrega raiz/prêmio antigo")
	_check(HerbariumProduction.get_generation() > generation, "load invalida geração transitória de callback")
	_check(publications == signals_before + 1 and incoherent_publications == 0, "uma publicação coerente só após finalizar snapshot")
	_check(SaveManager.call("_apply_save_data", snapshot) and _same_domain(before), "replay completo sem duplicação de custo/recompensa")
	generation = HerbariumProduction.get_generation()
	_check(SaveManager.call("_apply_save_data", {"inventory": {"cargas_crescimento": 0}}) and _same_domain(before), "parcial ausente preserva fonte local e raiz do Bosque")
	_check(HerbariumProduction.get_generation() > generation, "parcial preservado ainda invalida callback")
	for version in [3, 4]:
		var legacy := snapshot.duplicate(true)
		legacy["version"] = version
		legacy.erase(BLOCK)
		_check(SaveManager.call("_apply_save_data", legacy) and HerbariumProduction.get_save_data() == HerbariumProductionState.default_data(), "completo antigo v%d sem bloco inicia desativado" % version)
		_check(GlobalInventory.get_item_quantity("raiz_gelida") == 2 and GlobalInventory.get_item_quantity("rama_encantada") == 1 and GlobalInventory.pontos_alquimia == 3, "legado v%d não premia nem paga" % version)
		SaveManager.call("_apply_save_data", snapshot)
	var old_complete := snapshot.duplicate(true)
	old_complete.erase(BLOCK)
	old_complete.erase("grove_expedition")
	old_complete.erase("golem_work")
	_check(SaveManager.call("_apply_save_data", old_complete) and not GroveExpedition.restored and not HerbariumProduction.activated, "completo antigo sem Grove reseta domínios, não usa gate runtime")
	SaveManager.call("_apply_save_data", snapshot)
	var inactive := snapshot.duplicate(true)
	inactive["home_inactive_seconds"] = 180.0
	_check(SaveManager.call("_apply_save_data", inactive) and HerbariumProduction.get_save_data() == LOCAL, "home_inactive_seconds não avança domínio local pela segunda vez")
	_check(GroveExpedition.get_forage_state("grove_root") == ROOT, "snapshot da raiz externa conserva intervalo independente")
	var ready := {BLOCK: {"activated": true, "renewal_remaining": 0.0}}
	var items_before := GlobalInventory.inventario.duplicate(true)
	_check(SaveManager.call("_apply_save_data", ready) and HerbariumProduction.activated and HerbariumProduction.renewal_remaining == 0, "disponibilidade zero reaberta no ponto")
	_check(GlobalInventory.inventario == items_before, "primeira disponibilidade não insere raiz no load")
	var disabled := {BLOCK: HerbariumProductionState.default_data(), "farm_expansion": {}}
	_check(SaveManager.call("_apply_save_data", disabled) and not HerbariumProduction.activated and not project.get("restored_state"), "desativação explícita permite substituir gates sem novo contrato global")
	var old_unmarked := {BLOCK: HerbariumProductionState.default_data(), "inventory": {"backpack_milestones": GlobalInventory.get_backpack_milestones()}, "farm_expansion": {"restoration_projects": {"first_herbarium": 1}, "purification_obstacles": {"first_obstacle": 1}}}
	_check(SaveManager.call("_apply_save_data", old_unmarked), "legado desativado mantém coerção anterior de gates não marcados")
	_set_fixture()
	var site := home.get_node_or_null("ProductiveHerbarium")
	if site != null:
		home.get_node("PlayerAvatar").global_position = site.global_position
		site.call("open_panel")
		var opened: bool = site.call("is_panel_open")
		_check(opened and SaveManager.call("_apply_save_data", {}) and not bool(site.call("is_panel_open")), "load fecha painel realmente aberto da melhoria ao final")
	else:
		_check(false, "site integrado necessário ao teste de painel")

func _reject(payload: Dictionary, label: String) -> void:
	var before := _domain()
	var generation := HerbariumProduction.get_generation()
	var signal_count := publications
	_check(not SaveManager.call("_apply_save_data", payload) and _same_domain(before, true) and HerbariumProduction.get_generation() == generation and publications == signal_count, label + " sem alterar recursos, produtores, nós/cena/geração/sinais")

func _test_invalid_preflight() -> void:
	_set_fixture()
	var snapshot := _snapshot()
	for value in [null, true, [], {}, {"activated": "true", "renewal_remaining": 0}, {"activated": true, "renewal_remaining": "0"}, {"activated": true, "renewal_remaining": true}, {"activated": true, "renewal_remaining": -1}, {"activated": true, "renewal_remaining": 91}, {"activated": true, "renewal_remaining": INF}, {"activated": true, "renewal_remaining": NAN}, {"activated": false, "renewal_remaining": 2}]:
		var invalid := snapshot.duplicate(true)
		invalid[BLOCK] = value
		invalid["inventory"]["inventario"]["trigo"] = 99
		invalid["village_chest_inventory"]["trigo"] = 99
		invalid["economy"]["moedas"] = 999
		_reject(invalid, "preflight bruto inválido: " + str(value))
	for patch in [
		{"farm_expansion": {}},
		{"farm_expansion": {"restoration_projects": {"first_herbarium": true}}},
		{"farm_expansion": {"purification_obstacles": {"first_obstacle": true}}},
		{"farm_expansion": {"restoration_projects": {"first_herbarium": 1}, "purification_obstacles": {"first_obstacle": true}}},
		{"farm_expansion": {"restoration_projects": {"first_herbarium": true}, "purification_obstacles": {"first_obstacle": "true"}}},
		{"grove_expedition": {"discovered": true, "restored": false, "forage_sources": {}}},
	]:
		_reject(patch, "parcial sem bloco não revoga gate ativo: " + str(patch))
	var missing_grove := snapshot.duplicate(true)
	missing_grove.erase("grove_expedition")
	missing_grove.erase("golem_work")
	_reject(missing_grove, "completo ativado sem Grove não herda gate atual")
	var contradiction := snapshot.duplicate(true)
	contradiction["farm_expansion"]["purification_obstacles"]["first_obstacle"] = false
	_reject(contradiction, "Herbário restaurado exige área purificada coerente")

func _test_writer_and_transactions() -> void:
	_set_fixture()
	_check(SaveManager.save_game(), "writer válido grava somente QA")
	var bytes := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	var grid_before: Dictionary = home.call("obter_farm_grid_manager").to_save_data()
	for remaining in [-1.0, 90.1, INF, NAN]:
		HerbariumProduction.renewal_remaining = remaining
		_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer bruto inválido preserva arquivo: " + str(remaining))
		_check(home.call("obter_farm_grid_manager").to_save_data() == grid_before, "writer inválido não reconstrói GRID")
	HerbariumProduction.renewal_remaining = 37.5
	var obstacle: Node = SaveManager.call("_get_save_group_nodes", "purification_obstacle")[0]
	obstacle.set("purified_state", false)
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer recusa obstáculo real contraditório mesmo com área derivada true")
	_check(home.call("obter_farm_grid_manager").to_save_data() == grid_before, "contradição real recusa antes de reconstruir GRID")
	_reject({}, "parcial ativo não preserva área derivada contraditória")
	obstacle.set("purified_state", true)
	project.set("area_purified", false)
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer ativo sem área preserva arquivo")
	project.set("area_purified", true)
	project.set("restored_state", false)
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer ativo sem Herbário preserva arquivo")
	project.set("restored_state", true)
	GroveExpedition.restored = false
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer ativo sem Clareira preserva arquivo")
	GroveExpedition.restored = true
	HerbariumProduction.set("_transaction_in_progress", true)
	var before := _domain()
	var generation := HerbariumProduction.get_generation()
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "save recusa transação antes de I/O")
	_check(not SaveManager.load_game() and _same_domain(before), "load recusa transação antes de ler/aplicar arquivo")
	_check(not SaveManager.call("_apply_save_data", {}) and _same_domain(before) and HerbariumProduction.get_generation() == generation, "apply recusa transação sem mutação")
	HerbariumProduction.set("_transaction_in_progress", false)
	_check(SaveManager.save_game() and SaveManager.load_game() and HerbariumProduction.get_save_data() == LOCAL, "writer volta a operar após transação/estado válido")

func _test_cache() -> void:
	_set_fixture()
	if not await _travel(&"foraging_grove", &"from_farm"): return
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	_check(not home.is_inside_tree() and HerbariumProduction.get_save_data() == LOCAL, "fonte local conserva estado com vila cacheada")
	HerbariumProduction.advance_session_time(7.5)
	_check(HerbariumProduction.renewal_remaining == 30.0 and GroveExpedition.get_forage_state("grove_root") == ROOT, "relógio local único avança sessão no Bosque independentemente da raiz externa")
	var away := _snapshot()
	_check(away[BLOCK]["renewal_remaining"] == 30.0 and SaveManager.save_game(), "save no Bosque captura fonte e gates do cache")
	var bad := away.duplicate(true)
	bad[BLOCK]["renewal_remaining"] = true
	_reject(bad, "preflight externo não retorna Home em recusa")
	var revoked := {"farm_expansion": {}}
	_reject(revoked, "gate externo parcial não retorna Home em recusa")
	away["home_inactive_seconds"] = 180.0
	_check(SaveManager.call("_apply_save_data", away) and get_tree().current_scene == home and HerbariumProduction.renewal_remaining == 30.0, "load externo retorna Home sem catch-up duplo/offline")
	var before := _domain()
	_check(SaveManager.call("_apply_save_data", away) and _same_domain(before), "replay externo conserva tempo, estoques e prêmios")

func _write_fixture() -> void:
	_set_fixture()
	_check(HerbariumProduction.get_save_data() == LOCAL and GroveExpedition.get_forage_state("grove_root") == ROOT and project.get("restored_state") and project.get("area_purified"), "fixture fonte/gates/intervalos independentes")
	_check(SaveManager.save_game(), "fixture grava QA para processo novo")

func _verify_reopen() -> void:
	_check(SaveManager.has_save(), "arquivo do processo produtor existe")
	_check(SaveManager.load_game(), "novo processo carrega arquivo real")
	_check(HerbariumProduction.get_save_data() == LOCAL, "intervalo local 37.5 exato sem offline")
	_check(GroveExpedition.restored and GroveExpedition.get_forage_state("grove_root") == ROOT and project.get("restored_state") and project.get("area_purified"), "gates e raiz externa reabertos coerentemente")
	_check(GlobalInventory.get_item_quantity("trigo") == 17 and GlobalInventory.get_item_quantity("tomate_sol") == 4 and GlobalInventory.get_item_quantity("mistura_restauradora") == 3 and chest.get_item_quantity("trigo") == 21 and chest.get_item_quantity("mistura_restauradora") == 5, "load não repete investimento em nenhuma origem")
	_check(GlobalInventory.get_item_quantity("raiz_gelida") == 2 and chest.get_item_quantity("raiz_gelida") == 11 and GlobalInventory.get_item_quantity("rama_encantada") == 1 and GlobalInventory.pontos_alquimia == 3 and GlobalInventory.get_backpack_milestones() == ["first_herbarium"], "load sem raiz/prêmio antigo/XP/slots extra")
	var before := _domain()
	_check(SaveManager.load_game() and _same_domain(before), "replay novo processo conserva snapshot")
	_check(SaveManager.call("_apply_save_data", {}) and _same_domain(before), "parcial novo processo conserva fonte e raiz")

func _travel(id: StringName, entry: StringName) -> bool:
	if not get_tree().current_scene.call("request_region_transition", id, entry, &"herbarium_persistence_qa"):
		_check(false, "viagem recusada")
		return false
	for _frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress(): break
	var arrived := RegionTravelCoordinator.get_active_region_id() == String(id) and not RegionTravelCoordinator.is_input_blocked()
	_check(arrived, "viagem concluída: " + String(id))
	return arrived

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("HerbariumProductionPersistenceSmokeTest: " + message)

func _finish(label: String) -> void:
	if not failed: print("HerbariumProductionPersistenceSmokeTest: PASS - %d verificações de %s." % [checks, label])
	get_tree().quit(1 if failed else 0)
