extends Node

# Apenas QA isolado; fixtures de estado/custódia não simulam UX ou offline.
const MAIN := preload("res://Scenes/Main.tscn")
const FLAG := "flame_fertilizer_applied"
const PENDING := {"tomate_sol": 3, "palha_rara": 1}
const CARGO := {"tomate_sol": 4, "semente_inverno": 1}

class InvalidPlotProbe:
	extends Node
	var payload: Dictionary = {}
	func get_save_data() -> Dictionary:
		return payload.duplicate(true)

var home: Node
var golem: Node
var chest: VillageChest
var ripe: Node
var growing: Node
var old_ripe: Node
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA sob Builds/QA antes de instanciar Main")
		return _finish("sandbox recusado")
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	ripe = home.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	growing = home.call("obter_farm_plot_por_grid_position", Vector2i(1, 0))
	old_ripe = home.call("obter_farm_plot_por_grid_position", Vector2i(2, 0))
	home.process_mode = Node.PROCESS_MODE_DISABLED
	(golem.get("_think_timer") as Timer).stop()
	if "--verify-flame-fertilizer-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish("reabertura")
	if "--write-flame-fertilizer-fixture" in OS.get_cmdline_user_args():
		_write_fixture()
		return _finish("fixture")
	_test_pure_validator()
	_test_tile_roundtrip()
	_test_integrated_snapshots()
	_test_rejected_snapshots()
	_test_writer()
	await _test_cache()
	_write_fixture()
	_finish("preflight, GRID, legado, parcial, replay, writer e cache")

func _crop(ready: bool, applied: bool, pending: Dictionary = {}) -> Dictionary:
	return {"estado_atual": 2 if ready else 1, "semente_id_plantada": "semente_verao", "arado": true, "regado": true,
		"expansion_blocked": false, "tempo_restante": 0.0 if ready else 5.0, "tempo_total_crescimento": 5.0,
		"pronto_para_colher": ready, "pending_harvest_rewards": pending.duplicate(true), FLAG: applied}

func _reset() -> void:
	golem.call("load_work_save_data", GolemWorkState.default_data(), false)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	GroveExpedition.reset_progress()
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GlobalInventory.set_inventory_contents({"adubo_flamejante": 2, "agua": 7})
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	chest.set_contents({"adubo_flamejante": 5, "tomate_sol": 11})
	for plot in home.get("farm_plot_registry").values():
		plot.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": true, "regado": false, "expansion_blocked": plot.get("expansion_blocked"), FLAG: false})
	ripe.call("load_save_data", _crop(true, true, PENDING))
	growing.call("load_save_data", _crop(false, true))
	old_ripe.call("load_save_data", _crop(true, false, {"tomate_sol": 3}))
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))

func _domain() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "chest": chest.get_contents(),
		"ripe": ripe.call("get_save_data"), "growing": growing.call("get_save_data"), "old": old_ripe.call("get_save_data"),
		"golem": golem.call("get_work_save_data"), "grove": GroveExpedition.get_save_data(),
		"scene": get_tree().current_scene.get_instance_id(), "seed": GlobalInventory.semente_selecionada, "tool": ToolManager.get_active_tool()}

func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))

func _items_match(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size() or not actual.has_all(expected.keys()): return false
	for id in expected:
		var qty: Variant = actual[id]
		if typeof(qty) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(qty)) or float(qty) != float(int(qty)) or int(qty) != int(expected[id]): return false
	return true

func _same_domain(expected: Dictionary) -> bool:
	var current := _domain()
	if not _items_match(current["chest"], expected["chest"]): return false
	var without_chest := expected.duplicate(true)
	without_chest.erase("chest")
	current.erase("chest")
	return current == without_chest

func _tile(snapshot: Dictionary, cell: Vector2i) -> Dictionary:
	for entry in snapshot["farm_grid"]["tiles"]:
		if int(entry["grid_position"]["x"]) == cell.x and int(entry["grid_position"]["y"]) == cell.y: return entry
	return {}

func _test_pure_validator() -> void:
	var good := _crop(true, true, PENDING)
	_check(FarmTileData.is_flame_fertilizer_valid(good) and FarmTileData.is_flame_fertilizer_valid(_crop(false, true)), "marcas madura com extras e crescendo válidas")
	for value in [null, 0, 1, 0.0, 1.0, "true", "false", {}, []]:
		var data := good.duplicate(true)
		data[FLAG] = value
		_check(not FarmTileData.is_flame_fertilizer_valid(data), "marca recusa tipo não bool: %s" % [str(value)])
	for seed in ["", "semente_basica", "semente_inverno", "semente_outono", "tomate_sol", "unknown_seed"]:
		var data := good.duplicate(true)
		data["semente_id_plantada"] = seed
		_check(not FarmTileData.is_flame_fertilizer_valid(data), "marca exige ID de semente de tomate: " + seed)
	for state in [0, -1, 3, 1.5, "2", true]:
		var data := good.duplicate(true)
		data["estado_atual"] = state
		_check(not FarmTileData.is_flame_fertilizer_valid(data), "marca recusa estado inválido: %s" % [str(state)])
	for pending in [{"tomate_sol": 1}, {"tomate_sol": 2}, {"trigo": 3}, {"tomate_sol": 3.5}, {"tomate_sol": 3, "unknown_item": 1}, {"tomate_sol": 3, "palha_rara": -1}]:
		var data := good.duplicate(true)
		data["pending_harvest_rewards"] = pending
		_check(not FarmTileData.is_flame_fertilizer_valid(data), "pending marcado inválido: %s" % [str(pending)])
	var blocked := good.duplicate(true)
	blocked["expansion_blocked"] = true
	_check(not FarmTileData.is_flame_fertilizer_valid(blocked), "marca não vive em lote bloqueado")
	_check(not FarmTileData.is_flame_fertilizer_valid(_crop(false, true, PENDING)), "pending não pode ser descartado por normalização de cultura crescendo")
	var absent := good.duplicate(true)
	absent.erase(FLAG)
	_check(FarmTileData.is_flame_fertilizer_valid(absent), "ausente é legado comum, não inferido por três tomates")

func _test_tile_roundtrip() -> void:
	var data := {"grid_position": {"x": 0, "y": 0}, "tile_state": FarmTileData.TileState.MOLHADO,
		"crop_id": "semente_verao", "remaining_growth_time": 0.0, "total_growth_time": 5.0,
		"is_watered": true, "pending_harvest_rewards": PENDING.duplicate(true), FLAG: true}
	var tile := FarmTileData.new()
	tile.load_save_data(data)
	_check(tile.flame_fertilizer_applied and tile.pending_harvest_rewards == PENDING, "tile restaura marca e pending sem materializar outro bônus")
	var json: Dictionary = JSON.parse_string(JSON.stringify(tile.to_save_data()))
	var replacement := FarmTileData.new()
	replacement.load_save_data(json)
	_check(replacement.flame_fertilizer_applied and replacement.pending_harvest_rewards.size() == 2 and int(replacement.pending_harvest_rewards["tomate_sol"]) == 3, "JSON real conserva bool e totais")
	for state in [FarmTileData.TileState.GRAMA, FarmTileData.TileState.ARADO, FarmTileData.TileState.BLOQUEADO]:
		var invalid := data.duplicate(true)
		invalid["tile_state"] = state
		var before := tile.to_save_data()
		tile.load_save_data(invalid)
		_check(tile.to_save_data() == before, "tile inválido não altera objeto antes de normalizar: %d" % state)
	var before := tile.to_save_data()
	var invalid := data.duplicate(true)
	invalid[FLAG] = "true"
	tile.load_save_data(invalid)
	_check(tile.to_save_data() == before, "tile tipo inválido não sofre coerção bool")
	var legacy := data.duplicate(true)
	legacy.erase(FLAG)
	tile.load_save_data(legacy)
	_check(not tile.flame_fertilizer_applied and int(tile.pending_harvest_rewards["tomate_sol"]) == 3, "load substituído sem campo limpa marca sem inferência")
	tile.load_save_data(data)
	tile.clear_crop()
	_check(not tile.flame_fertilizer_applied and tile.crop_id.is_empty() and tile.pending_harvest_rewards.is_empty(), "clear_crop encerra marca sem gerar item")

func _test_integrated_snapshots() -> void:
	_reset()
	var snapshot := _snapshot()
	_check(_tile(snapshot, Vector2i.ZERO)[FLAG] and _tile(snapshot, Vector2i(1, 0))[FLAG] and not _tile(snapshot, Vector2i(2, 0))[FLAG], "bridge Main conserva marcas individuais sem inferir pelo pending antigo")
	_check(snapshot["version"] == 4 and snapshot["golem_work"]["harvest_cargo"].size() == 2 and not snapshot["golem_work"].has(FLAG), "save v4/cargo guarda totais, não segunda promessa de adubo")
	_check(SaveManager.call("_apply_save_data", snapshot), "load integrado GRID marcado")
	var before := _domain()
	_check(ripe.get(FLAG) and growing.get(FLAG) and not old_ripe.get(FLAG) and ripe.call("get_save_data")["pending_harvest_rewards"] == PENDING, "culturas e recompensa exata restauradas")
	_check(SaveManager.call("_apply_save_data", snapshot) and _domain() == before, "replay não gasta/soma/recalcula recompensa")
	_check(SaveManager.call("_apply_save_data", {"inventory": {"cargas_crescimento": 0}}) and _domain() == before, "parcial sem agricultura conserva marca e custódia")
	var grid_partial := {"version": 4, "farm_grid": snapshot["farm_grid"].duplicate(true)}
	for entry in grid_partial["farm_grid"]["tiles"]: entry.erase(FLAG)
	_check(SaveManager.call("_apply_save_data", grid_partial) and not ripe.get(FLAG) and not growing.get(FLAG), "domínio GRID substituído sem campo resolve false mesmo em payload parcial")
	_check(ripe.call("get_save_data")["pending_harvest_rewards"] == PENDING and GlobalInventory.get_item_quantity("adubo_flamejante") == 2, "limpar marca ausente não retira adubo nem diminui pending antigo")
	for version in [3, 4]:
		var legacy := snapshot.duplicate(true)
		legacy.erase("farm_grid")
		legacy["version"] = version
		_check(SaveManager.call("_apply_save_data", legacy) and ripe.get(FLAG) and growing.get(FLAG), "legado marcado v%d conserva bool e cultura" % version)
		for entry in legacy["farm_plots"]: entry.erase(FLAG)
		_check(SaveManager.call("_apply_save_data", legacy) and not ripe.get(FLAG) and not growing.get(FLAG) and ripe.call("get_save_data")["pending_harvest_rewards"] == PENDING, "legado sem campo v%d não infere por quantidade" % version)
	var authoritative := snapshot.duplicate(true)
	authoritative["farm_plots"][0][FLAG] = "invalid_ignored_legacy"
	_check(SaveManager.call("_apply_save_data", authoritative) and ripe.get(FLAG), "GRID v4 prioritário não lê sombra legada")
	# Aplicar mesmo snapshot deve conservar também recurso já entregue ao cargo.
	before = _domain()
	_check(SaveManager.call("_apply_save_data", snapshot) and _domain() == before and int(golem.call("get_work_save_data")["harvest_cargo"]["tomate_sol"]) == 4, "cargo materializado reabre sem adicionar adubo no transporte")

func _test_rejected_snapshots() -> void:
	_reset()
	var snapshot := _snapshot()
	for legacy in [false, true]:
		for patch in [{FLAG: 1}, {FLAG: "true"}, {FLAG: null}, {"seed": "semente_basica"}, {"state": 0}, {"pending_harvest_rewards": {"tomate_sol": 2}}, {"pending_harvest_rewards": {"tomate_sol": 3, "invalid_probe": 1}}, {"pending_harvest_rewards": {"tomate_sol": 3.5}}]:
			var invalid := snapshot.duplicate(true)
			var entry: Dictionary
			if legacy:
				invalid.erase("farm_grid")
				entry = invalid["farm_plots"][0]
			else: entry = _tile(invalid, Vector2i.ZERO)
			for key in patch:
				if key == "seed": entry["semente_id_plantada" if legacy else "crop_id"] = patch[key]
				elif key == "state": entry["estado_atual" if legacy else "tile_state"] = patch[key]
				else: entry[key] = patch[key]
			invalid["inventory"]["inventario"]["adubo_flamejante"] = 99
			invalid["village_chest_inventory"]["tomate_sol"] = 99
			var before := _domain()
			_check(not SaveManager.call("_apply_save_data", invalid) and _domain() == before, "preflight %s recusa sem mutação: %s" % ["legado" if legacy else "GRID", str(patch)])
	for marked_first in [true, false]:
		var duplicate := snapshot.duplicate(true)
		var entry := _tile(duplicate, Vector2i.ZERO).duplicate(true)
		entry[FLAG] = not marked_first
		_tile(duplicate, Vector2i.ZERO)[FLAG] = marked_first
		duplicate["farm_grid"]["tiles"].append(entry)
		var before := _domain()
		_check(not SaveManager.call("_apply_save_data", duplicate) and _domain() == before, "GRID duplicado tratado/comum não pode sobrescrever promessa")
	var invalid_cell := snapshot.duplicate(true)
	_tile(invalid_cell, Vector2i.ZERO)["grid_position"]["x"] = 0.5
	var before := _domain()
	_check(not SaveManager.call("_apply_save_data", invalid_cell) and _domain() == before, "célula fracionária marcada não normaliza para outro lote")

func _test_writer() -> void:
	_reset()
	_check(SaveManager.save_game(), "writer válido grava sandbox QA")
	var bytes := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	var grid_before: Dictionary = home.call("obter_farm_grid_manager").to_save_data()
	var probe := InvalidPlotProbe.new()
	probe.payload = _crop(true, true, PENDING)
	probe.payload[FLAG] = "true"
	home.add_child(probe)
	probe.add_to_group("lotes_terra")
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes and not SaveManager.last_file_error.is_empty(), "writer recusa bool cru inválido antes de I/O")
	_check(home.call("obter_farm_grid_manager").to_save_data() == grid_before, "writer recusado não reconstrói GRID/normaliza snapshot")
	home.remove_child(probe)
	probe.free()
	var original: Dictionary = ripe.call("get_save_data")
	ripe.set("semente_id_plantada", "semente_basica")
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer recusa runtime com marca em trigo preservando arquivo")
	ripe.call("load_save_data", original)
	var raw: Array = ripe.get("_pending_manual_harvest_rewards").duplicate(true)
	ripe.set("_pending_manual_harvest_rewards", [{"item_id": "tomate_sol", "quantidade": 3.5}])
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer recusa pending cru fracionário antes de agregar/normalizar quantidade")
	ripe.set("_pending_manual_harvest_rewards", raw)
	_check(SaveManager.save_game() and SaveManager.load_game() and ripe.get(FLAG), "snapshot válido volta a gravar/reabrir normalmente")

func _test_cache() -> void:
	_reset()
	var before := _domain()
	if not await _travel(&"foraging_grove", &"from_farm"): return
	_check(not home.is_inside_tree() and ripe.get(FLAG) and growing.get(FLAG), "vila cacheada conserva flags sem consumo/aplicação remota")
	var away := _snapshot()
	_check(_tile(away, Vector2i.ZERO)[FLAG] and _items_match(_tile(away, Vector2i.ZERO)["pending_harvest_rewards"], PENDING) and _items_match(away["golem_work"]["harvest_cargo"], CARGO), "save externo captura marca/pending/cargo do cache")
	# Intervalo sintético salvo zero: esta prova é custódia, não avanço de tempo.
	away["home_inactive_seconds"] = 0.0
	var loaded: bool = SaveManager.call("_apply_save_data", away)
	_check(loaded and get_tree().current_scene == home and _same_domain(before), "load externo retorna vila com estado exato sem somar recompensa")
	_check(SaveManager.call("_apply_save_data", away) and _same_domain(before), "replay externo conserva custo e pending")
	_check(SaveManager.save_game() and SaveManager.load_game() and ripe.get(FLAG), "arquivo QA após viagem conserva marca")

func _write_fixture() -> void:
	_reset()
	_check(ripe.get(FLAG) and growing.get(FLAG) and not old_ripe.get(FLAG) and ripe.call("get_save_data")["pending_harvest_rewards"] == PENDING and golem.call("get_work_save_data")["harvest_cargo"] == CARGO, "fixture marca/culturas/pending/cargo materializado")
	_check(SaveManager.save_game(), "fixture grava arquivo QA para processo novo")

func _verify_reopen() -> void:
	_check(SaveManager.has_save(), "arquivo de processo produtor presente")
	_check(SaveManager.load_game(), "novo processo aplica arquivo real")
	_check(ripe.get(FLAG) and growing.get(FLAG) and not old_ripe.get(FLAG) and int(ripe.get("estado_atual")) == 2 and int(growing.get("estado_atual")) == 1, "marca acompanha duas culturas, não total antigo")
	var pending: Dictionary = ripe.call("get_save_data")["pending_harvest_rewards"]
	_check(pending.size() == 2 and int(pending.get("tomate_sol", 0)) == 3 and int(pending.get("palha_rara", 0)) == 1 and growing.get_node("Timer").time_left == 5.0, "recompensa/tempo exatos sem recálculo/offline")
	_check(GlobalInventory.get_item_quantity("adubo_flamejante") == 2 and chest.get_item_quantity("adubo_flamejante") == 5 and chest.get_item_quantity("tomate_sol") == 11, "estoques pessoal/baú não são debitados no load")
	var work: Dictionary = golem.call("get_work_save_data")
	_check(work["harvest_cargo"].size() == 2 and int(work["harvest_cargo"].get("tomate_sol", 0)) == 4 and int(work["harvest_cargo"].get("semente_inverno", 0)) == 1 and not work.has(FLAG), "cargo já materializado conserva extras sem segunda marca")
	var before := _domain()
	_check(SaveManager.load_game() and _domain() == before, "replay em novo processo não duplica bônus/custo")
	_check(SaveManager.call("_apply_save_data", {"inventory": {"cargas_crescimento": 0}}) and _domain() == before, "parcial sem agricultura conserva estado reaberto")

func _travel(id: StringName, entry: StringName) -> bool:
	if not bool(get_tree().current_scene.call("request_region_transition", id, entry, &"fertilizer_qa")):
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
		push_error("FlameFertilizerPersistenceSmokeTest: " + message)

func _finish(label: String) -> void:
	if not failed: print("FlameFertilizerPersistenceSmokeTest: PASS - %d verificações de %s." % [checks, label])
	get_tree().quit(1 if failed else 0)
