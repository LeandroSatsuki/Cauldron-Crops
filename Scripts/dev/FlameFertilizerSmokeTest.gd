extends Node

# QA sintético com estado e tempos de fixture; não representa aceite manual.
const MAIN := preload("res://Scenes/Main.tscn")
const ITEM := "adubo_flamejante"
const SEED := "semente_verao"
const PRODUCT := "tomate_sol"
var home: Node2D
var plot: Node2D
var pilot: Node2D
var chest: VillageChest
var golem: CharacterBody2D
var checks := 0
var failed := false
var observed_pending: Dictionary = {}
var invalid_observation := false
var observe_reentry := false
var reentry_result := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA sob Builds/QA antes de instanciar Main")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	plot = home.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	pilot = home.call("obter_farm_plot_por_grid_position", Vector2i(2, 2))
	chest = home.get_node("VillageChest")
	golem = home.get_node("Golem")
	home.process_mode = Node.PROCESS_MODE_DISABLED
	plot.connect("estado_alterado", _observe_plot)
	_reset()
	_eligibility()
	_commit_and_rewards()
	_manual_capacity()
	await _golem_custody()
	_lifecycle()
	_snapshots()
	_finish()

func _reset() -> void:
	home.call("cancel_consumable_application")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({ITEM: 3, SEED: 3, "semente_basica": 3, "agua": 4})
	GlobalInventory.pontos_alquimia = 7
	chest.set_contents({ITEM: 7, PRODUCT: 5, "trigo": 3})
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	EventDirector.debug_reset_for_test()
	EventDirector.set("_last_harvest_event_at", 0.0)
	EventDirector.set("_last_world_event_at", 0.0)
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	plot.show()
	_blank(plot)
	_blank(pilot)

func _blank(target: Node) -> void:
	target.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": true, "regado": false, "expansion_blocked": false})

func _crop(target: Node, ready: bool = false, seed_id: String = SEED, marked: bool = false, pending: Dictionary = {}) -> void:
	target.call("load_save_data", _crop_data(ready, seed_id, marked, pending))

func _crop_data(ready: bool = false, seed_id: String = SEED, marked: bool = false, pending: Dictionary = {}) -> Dictionary:
	return {"estado_atual": 2 if ready else 1, "semente_id_plantada": seed_id, "arado": true, "regado": true, "tempo_restante": 0.0 if ready else 60.0, "tempo_total_crescimento": 60.0, "pronto_para_colher": ready, "expansion_blocked": false, "pending_harvest_rewards": pending.duplicate(true), "living_soil_treated": false, "living_soil_moisture": false, "flame_fertilizer_applied": marked}

func _resources() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "chest": chest.get_contents().duplicate(true), "xp": GlobalInventory.pontos_alquimia, "tool": ToolManager.active_tool, "selection": GlobalInventory.semente_selecionada, "growth": GlobalInventory.cargas_crescimento}

func _snapshot() -> Dictionary:
	return plot.call("get_save_data")

func _generation() -> int:
	return int(plot.call("get_crop_generation"))

func _refused(label: String) -> void:
	var before := _snapshot()
	var resources := _resources()
	var generation := _generation()
	_check(not plot.call("can_apply_flame_fertilizer"), label + ": consulta recusa")
	_check(not plot.call("apply_flame_fertilizer") and _snapshot() == before and _resources() == resources and _generation() == generation, label + ": commit recusa sem mutação")

func _eligibility() -> void:
	_refused("vazio")
	_crop(plot, false, "semente_basica")
	_refused("trigo")
	_crop(plot, true, "semente_inverno")
	_refused("outra espécie madura")
	_crop(plot)
	plot.call("set_expansion_blocked", true)
	_refused("expansão bloqueada")
	plot.call("set_expansion_blocked", false)
	plot.hide()
	_refused("lote oculto")
	plot.show()
	home.hide()
	_refused("ancestral oculto")
	home.show()
	GlobalInventory.inventario.erase(ITEM)
	_refused("adubo só no baú")
	GlobalInventory.set_inventory_contents({ITEM: 3, "agua": 4})
	_crop(plot, true, SEED, false, {PRODUCT: 1})
	_refused("recompensa já materializada")
	_crop(plot, true, SEED, true)
	_refused("já adubado")
	_crop(plot)
	home.set("_region_being_cached", true)
	_refused("cache com vila ainda na árvore")
	home.set("_region_being_cached", false)
	get_tree().current_scene = self
	_refused("fora da vila ativa")
	get_tree().current_scene = home
	_reset()

func _commit_and_rewards() -> void:
	for ready in [false, true]:
		_crop(plot, ready)
		var before := _snapshot()
		var resources := _resources()
		var generation := _generation()
		_check(plot.call("can_apply_flame_fertilizer") and _snapshot() == before and _resources() == resources, "consulta pura crescendo/maduro")
		observe_reentry = true
		reentry_result = true
		_check(plot.call("apply_flame_fertilizer"), "commit crescendo/maduro")
		observe_reentry = false
		_check(not reentry_result and plot.get("flame_fertilizer_applied"), "marca publicada antes de reentrada; não empilha")
		_check(GlobalInventory.get_item_quantity(ITEM) == int(resources.personal[ITEM]) - 1 and chest.get_contents() == resources.chest and GlobalInventory.pontos_alquimia == resources.xp, "custo pessoal unitário sem baú/XP")
		before["flame_fertilizer_applied"] = true
		_check(_snapshot() == before and _generation() == generation, "aplicar não muda identidade, timer, água ou sementes")
		_refused("segunda aplicação")
	_reset()
	_crop(pilot, true)
	_check(pilot.call("can_apply_flame_fertilizer") and pilot.call("apply_flame_fertilizer"), "qualquer lote válido existente, inclusive fora piloto do semeador")
	_check(pilot.get("flame_fertilizer_applied") and not pilot.get("living_soil_treated"), "adubo não cria Solo Vivo")
	for season in range(4):
		SeasonManager.estacao_atual = season
		for draw_seed in [7, 19, 61]:
			_crop(plot, true)
			seed(draw_seed)
			var baseline: Array = plot.call("_gerar_recompensas_colheita", PRODUCT)
			_crop(plot, true, SEED, true)
			seed(draw_seed)
			var enhanced: Array = plot.call("_gerar_recompensas_colheita", PRODUCT)
			var expected := _totals(baseline)
			expected[PRODUCT] = int(expected.get(PRODUCT, 0)) + 2
			_check(_totals(enhanced) == expected, "+2 aditivos preservam sorteios na estação %d/seed%d" % [season, draw_seed])
			_check(_snapshot().pending_harvest_rewards.is_empty(), "geração pura não materializa cache")
	_reset()

func _manual_capacity() -> void:
	_crop(plot, true)
	_check(plot.call("apply_flame_fertilizer"), "aplicação antes de capacidade cheia")
	var full := {"agua": 4}
	for index in range(12): full["capacity_probe_%d" % index] = 99
	GlobalInventory.set_inventory_contents(full)
	var resources := _resources()
	_check(GlobalInventory.get_used_slot_count() == 12, "fixture enche doze slots sem tomate")
	_check(not plot.call("_colher_manualmente", false), "colheita cheia recusa atomicamente")
	var saved := _snapshot()
	_check(saved.flame_fertilizer_applied and int(saved.pending_harvest_rewards.get(PRODUCT, 0)) == 3 and int(saved.estado_atual) == 2, "falha conserva marca e bônus único materializado")
	var product_feedback: Array = []
	for reward in plot.get("_pending_manual_harvest_rewards"):
		if reward.get("item_id") == PRODUCT and reward.get("mostrar_texto", false):
			product_feedback.append(reward)
	_check(product_feedback.size() == 1 and product_feedback[0]["quantidade"] == 3 and str(product_feedback[0]["texto_flutuante"]).begins_with("+3 "), "produto adubado mostra um único aviso coerente, sem +1/+2 sobrepostos")
	_check(_resources() == resources, "colheita bloqueada não entrega fração")
	_check(not plot.call("_colher_manualmente", false) and _snapshot() == saved, "retry bloqueado mantém recompensas exatas sem reroll/+2 novo")
	var generation := _generation()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(saved))
	observed_pending = saved.pending_harvest_rewards.duplicate(true)
	invalid_observation = false
	plot.call("load_save_data", parsed)
	observed_pending = {}
	_check(not invalid_observation, "load publica estado somente após reconstruir recompensas pendentes")
	_check(_generation() > generation and plot.get("flame_fertilizer_applied"), "load invalida intenção antiga preservando marca")
	_check(_same_quantities(_snapshot().pending_harvest_rewards, saved.pending_harvest_rewards) and _resources() == resources, "JSON/replay preserva quantidade/custódia sem gastar")
	plot.call("load_save_data", parsed)
	_check(not plot.call("_colher_manualmente", false) and _same_quantities(_snapshot().pending_harvest_rewards, saved.pending_harvest_rewards), "segundo load/recusa não duplica bônus")
	GlobalInventory.set_inventory_contents({"agua": 4})
	generation = _generation()
	_check(plot.call("_colher_manualmente", false), "capacidade liberada entrega colheita")
	_check(_personal_matches(saved.pending_harvest_rewards) and GlobalInventory.get_item_quantity(PRODUCT) == 3, "manual entrega exatamente cache inteiro uma vez")
	_check(not plot.get("flame_fertilizer_applied") and int(plot.get("estado_atual")) == 0 and _generation() > generation, "marca termina apenas no commit de colheita")
	resources = _resources()
	_check(not plot.call("_colher_manualmente", false) and _resources() == resources, "vazio não entrega outra vez")
	GlobalInventory.adicionar_item(SEED, 1)
	generation = _generation()
	var planted: Dictionary = plot.call("try_plant_from_personal_inventory", SEED)
	_check(planted.success and _generation() > generation and not plot.get("flame_fertilizer_applied"), "novo tomate não herda marca e tem outra identidade")
	plot.call("debug_force_ready_to_harvest")
	var next_rewards: Array = plot.call("_obter_ou_gerar_recompensas_colheita", PRODUCT)
	_check(int(_totals(next_rewards).get(PRODUCT, 0)) == 1, "próxima cultura sem aplicação retorna rendimento base")
	_reset()

func _golem_custody() -> void:
	_crop(plot, true)
	_check(plot.call("apply_flame_fertilizer"), "adubo antes de coleta do golem")
	var personal := GlobalInventory.inventario.duplicate(true)
	var generation := _generation()
	var rewards: Array = plot.call("harvest_by_golem", Callable(golem, "_receive_harvest_cargo"))
	var cargo: Array = golem.get("carried_rewards")
	_check(int(_totals(rewards).get(PRODUCT, 0)) == 3 and _totals(cargo) == _totals(rewards), "bônus passa para custódia real de colheita")
	_check(not plot.get("flame_fertilizer_applied") and int(plot.get("estado_atual")) == 0 and _generation() > generation, "coleta física remove promessa do lote")
	_check(GlobalInventory.inventario == personal, "golem não entrega à Mochila")
	var work: Dictionary = golem.call("get_work_save_data")
	_check(not work.has("flame_fertilizer_applied") and _same_quantities(work.harvest_cargo, _totals(rewards)), "save do golem contém somente quantidades existentes")
	_check((plot.call("harvest_by_golem", Callable(golem, "_receive_harvest_cargo")) as Array).is_empty() and _totals(golem.get("carried_rewards")) == _totals(rewards), "segunda coleta não duplica cargo")
	golem.call("set_work_priority", 0)
	golem.set("target_chest", chest)
	golem.set("state", "MOVING_TO_CHEST")
	golem.global_position = chest.global_position + Vector2(0, 48)
	golem.set("deposit_duration", 0.04) # Somente fixture; duração real não alterada.
	golem.call("_chegar_ao_bau")
	await get_tree().create_timer(0.12).timeout
	_check((golem.get("carried_rewards") as Array).is_empty() and chest.get_item_quantity(PRODUCT) == 8, "depósito existente entrega três tomates no baú")
	_check(GlobalInventory.inventario == personal and not golem.get("accelerator_active"), "depósito não cria benefício pessoal/Aceleradora")
	var after: Dictionary = chest.get_contents().duplicate(true)
	golem.call("_chegar_ao_bau")
	await get_tree().create_timer(0.06).timeout
	_check(chest.get_contents() == after, "repetir callback de depósito não duplica")
	_reset()

func _lifecycle() -> void:
	_crop(plot)
	_check(plot.call("apply_flame_fertilizer"), "adubo crescendo para ciclo de identidade")
	var generation := _generation()
	(plot.get_node("Timer") as Timer).stop()
	plot.call("_on_timer_timeout")
	_check(int(plot.get("estado_atual")) == 2 and plot.get("flame_fertilizer_applied") and _generation() == generation, "amadurecimento mantém identidade e marca")
	var personal := GlobalInventory.inventario.duplicate(true)
	plot.call("_concluir_colheita")
	_check(not plot.get("flame_fertilizer_applied") and _generation() > generation and GlobalInventory.inventario == personal, "reset real remove marca sem refund")
	_crop(plot, false, SEED, true)
	plot.set("regado", false)
	generation = _generation()
	var fatal_seed := -1
	for candidate in range(256):
		seed(candidate)
		if randf() <= 0.20:
			fatal_seed = candidate
			break
	_check(fatal_seed >= 0, "fixture encontra sorteio mortal vigente")
	seed(fatal_seed)
	(plot.get_node("Timer") as Timer).stop()
	plot.call("_on_timer_timeout")
	_check(int(plot.get("estado_atual")) == 0 and not plot.get("flame_fertilizer_applied") and _generation() > generation, "morte por sede remove marca/identidade sem mudar probabilidade")
	_check(GlobalInventory.inventario == personal, "morte não reembolsa adubo")
	_crop(plot, true, SEED, true)
	generation = _generation()
	plot.call("load_save_data", {})
	_check(not plot.get("flame_fertilizer_applied") and int(plot.get("estado_atual")) == 0 and _generation() > generation and GlobalInventory.inventario == personal, "snapshot vazio reinicia lote sem refund")
	_reset()

func _snapshots() -> void:
	_crop(plot, true, SEED, true, {PRODUCT: 4, "semente_inverno": 1})
	_check(int(_snapshot().pending_harvest_rewards.get(PRODUCT, 0)) == 4 and plot.get("flame_fertilizer_applied"), "snapshot marcado aceita bônus base e extras sazonais")
	var invalid: Array = []
	for value in [1, 1.0, "true", null, [], {}]:
		var data := _crop_data(true)
		data["flame_fertilizer_applied"] = value
		invalid.append(data)
	for state in [0, -1, 3, 1.5, "2", true]:
		var data := _crop_data(true, SEED, true)
		data["estado_atual"] = state
		invalid.append(data)
	var wrong_crop := _crop_data(true, "semente_basica", true)
	invalid.append(wrong_crop)
	var blocked := _crop_data(true, SEED, true)
	blocked["expansion_blocked"] = true
	invalid.append(blocked)
	for pending in [{PRODUCT: 2}, {PRODUCT: 3.5}, {PRODUCT: true}, {"unknown_item": 3}, {"trigo": 3}, [], null]:
		var data := _crop_data(true, SEED, true)
		data["pending_harvest_rewards"] = pending
		invalid.append(data)
	invalid.append(_crop_data(false, SEED, true, {PRODUCT: 3}))
	for index in range(invalid.size()):
		var before := _snapshot()
		var generation := _generation()
		var resources := _resources()
		plot.call("load_save_data", invalid[index])
		_check(_snapshot() == before and _generation() == generation and _resources() == resources, "preflight inválido %d não altera domínio/identidade/itens" % index)
	var legacy := _crop_data(true, SEED, true, {PRODUCT: 3})
	legacy.erase("flame_fertilizer_applied")
	plot.call("load_save_data", legacy)
	_check(not plot.get("flame_fertilizer_applied") and int(_snapshot().pending_harvest_rewards[PRODUCT]) == 3, "legado sem campo resolve false sem inferir de três tomates")
	_crop(plot, false, SEED, true)
	var generation := _generation()
	var resources := _resources()
	var saved := _snapshot()
	plot.call("load_save_data", saved)
	_check(plot.get("flame_fertilizer_applied") and _generation() > generation and _resources() == resources, "load/cache crescente conserva marca e invalida intenção sem reaplicar")
	_check(not plot.call("apply_flame_fertilizer") and _resources() == resources, "replay marcado não consome outra dose")
	_check(plot.call("is_flame_fertilizer_runtime_valid"), "preflight vivo aceita cultura marcada sem recompensa")
	plot.set("_pending_manual_harvest_rewards", [{"item_id": PRODUCT, "quantidade": 3.5}])
	_check(not plot.call("is_flame_fertilizer_runtime_valid"), "preflight vivo recusa quantidade fracionária antes de snapshot")
	plot.set("flame_fertilizer_applied", false)
	_check(plot.call("is_flame_fertilizer_runtime_valid"), "nova guarda não endurece cultura legada sem marca")
	plot.set("_pending_manual_harvest_rewards", [])

func _observe_plot() -> void:
	if not observed_pending.is_empty():
		if not _same_quantities(_snapshot().pending_harvest_rewards, observed_pending): invalid_observation = true
	if observe_reentry:
		reentry_result = bool(plot.call("apply_flame_fertilizer"))

func _totals(rewards: Array) -> Dictionary:
	var totals := {}
	for reward in rewards:
		var id: String = str(reward.get("item_id", ""))
		totals[id] = int(totals.get(id, 0)) + int(reward.get("quantidade", 0))
	return totals

func _same_quantities(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size(): return false
	for id in expected:
		if not actual.has(id) or float(actual[id]) != float(expected[id]): return false
	return true

func _personal_matches(expected: Dictionary) -> bool:
	for id in expected:
		if GlobalInventory.get_item_quantity(id) != int(expected[id]): return false
	return true

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("FlameFertilizerSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed: print("FlameFertilizerSmokeTest: PASS - %d verificações de domínio/capacidade/custódia/ciclo/preflight." % checks)
	get_tree().quit(1 if failed else 0)
