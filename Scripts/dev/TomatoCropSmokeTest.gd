extends Node

# Teste sintético em sandbox QA, não aceite manual/arte/balanceamento.
# Receitas e os dois ciclos irrigados usam timers reais; snapshots de 60s
# isolam os ensaios de persistência sem mudar duração de produção.
const MAIN := preload("res://Scenes/Main.tscn")
const RECIPE := "semente_tomate_recuperacao"
const SEED := "semente_verao"
const CROP := "tomate_sol"
var home: Node
var plot: Node
var pilot: Node
var chest: VillageChest
var golem: Node
var cauldron: Node
var book: Control
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA sob Builds/QA antes de instanciar Main")
		return _finish("sandbox")
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _frames(4)
	plot = home.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	pilot = home.call("obter_farm_plot_por_grid_position", Vector2i(2, 2))
	chest = home.get_node("VillageChest")
	golem = home.get_node("Golem")
	cauldron = home.get_node("CauldronUI")
	book = home.get_node("UI").get("recipe_book")
	_pause_world()
	if "--verify-tomato-crop-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish("reabertura")
	if "--write-tomato-crop-fixture" in OS.get_cmdline_user_args():
		_write_fixture()
		return _finish("fixture")
	_reset()
	_catalog_and_seasons()
	_planting_authority()
	await _first_seed_and_cycle()
	_crafting_transactions()
	_soil_and_golem()
	_snapshots()
	await _cache()
	_write_fixture()
	_finish("tomate, origens, cultivo, Solo Vivo, GRID, legado e cache")

func _pause_world() -> void:
	home.process_mode = Node.PROCESS_MODE_DISABLED
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()

func _reset(personal: Dictionary = {}, stored: Dictionary = {}) -> void:
	home.call("cancel_consumable_application")
	book.call("fechar")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents(personal)
	GlobalInventory.pontos_alquimia = 0
	# Isolar eventos aleatórios legados: a Colheita Dourada concede XP por fora
	# da receita. O relógio de eventos fica congelado dentro do cooldown.
	EventDirector.debug_reset_for_test()
	EventDirector.set("_last_harvest_event_at", 0.0)
	EventDirector.set("_last_world_event_at", 0.0)
	chest.set_contents(stored)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GroveExpedition.reset_progress()
	cauldron.call("load_save_data", {"state": "IDLE"})
	_blank(plot)
	_blank(pilot)
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	_pause_world()

func _blank(target: Node, treated: bool = false, moisture: bool = false) -> void:
	target.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": true, "regado": moisture, "expansion_blocked": false, "living_soil_treated": treated, "living_soil_moisture": moisture})

func _crop(target: Node, ready: bool, treated: bool = false, pending: Dictionary = {}) -> void:
	target.call("load_save_data", {"estado_atual": 2 if ready else 1, "semente_id_plantada": SEED, "arado": true, "regado": true, "tempo_restante": 0.0 if ready else 60.0, "tempo_total_crescimento": 60.0, "pronto_para_colher": ready, "expansion_blocked": false, "living_soil_treated": treated, "living_soil_moisture": false, "pending_harvest_rewards": pending})

func _catalog_and_seasons() -> void:
	var resolver := RecipeResolver.new()
	var database := RecipeDatabase.new()
	database.load_recipes()
	_check(database.validate_recipes().is_empty(), "catálogo íntegro")
	var data := resolver.get_recipe_data(RECIPE)
	_check(data != null, "Resource da recuperação existe")
	if data == null: return
	_check(data.ingredientes == ["trigo", "agua"] and data.resultado_item == SEED and data.resultado_quantidade == 1, "1 trigo + 1 água → 1 semente existente")
	_check(data.tempo_producao == 2.0 and data.recompensa_pontos_alquimia == 0 and data.desbloqueada_por_padrao and not data.exige_descoberta, "2s/0XP/padrão sem gate")
	_check(resolver.is_recipe_available(RECIPE) and RECIPE in resolver.get_default_unlocked_recipe_ids(), "disponível sem primeira descoberta")
	_check(resolver.find_recipe_for_ingredients(["agua", "trigo"]).get("id") == RECIPE, "par canônico independe da ordem")
	var matches := 0
	for recipe in database.get_all_recipes():
		if recipe.ingredientes.size() == 2 and "agua" in recipe.ingredientes and "trigo" in recipe.ingredientes: matches += 1
	_check(matches == 1, "nenhuma colisão de par")
	var additional := resolver.get_recipe_data("semente_basica_tomate_sol")
	_check(additional != null and additional.resultado_item == SEED and additional.resultado_quantidade == 2 and not additional.desbloqueada_por_padrao, "reposição adicional legada preservada")
	_check(resolver.get_result("tomate_sol_trigo") == "adubo_flamejante" and resolver.get_result("tomate_sol_raiz_gelida") == "semente_outono", "usos antigos intactos")
	_check(Database.semente_verao["estacao_ideal"] == SeasonManager.Estacao.VERAO and Database.semente_verao["tempo_crescimento_segundos"] == 5.0 and Database.semente_verao["produto_colheita"] == CROP, "identidade, ideal Verão e 5s intactos")
	for season in range(4):
		SeasonManager.estacao_atual = season
		for id in ["semente_basica", SEED, "semente_outono", "semente_inverno"]:
			var expected: bool = season in [0, 1] if id == SEED else season == {"semente_basica": 0, "semente_outono": 2, "semente_inverno": 3}[id]
			var before := _domain()
			var result: Dictionary = plot.call("validate_seed_planting", id)
			_check(bool(result["success"]) == expected and _domain() == before, "matriz sazonal consulta pura %s/%d" % [id, season])
			if not expected:
				_check(result["reason"] == "wrong_season" and not plot.call("try_plant_from_personal_inventory", id)["success"] and _domain() == before, "recusa sazonal sem gasto %s/%d" % [id, season])
	for optional in [null, [], "invalid"]:
		var fallback := {"estacao_ideal": 2, "estacoes_permitidas": optional}
		_check(Database.semente_permite_estacao(fallback, 2) and not Database.semente_permite_estacao(fallback, 0), "fallback ideal quando lista ausente/vazia/inválida")
	_check(not Database.semente_permite_estacao({}, 0), "metadados vazios não autorizam primavera")
	SeasonManager.estacao_atual = 0

func _planting_authority() -> void:
	_reset({SEED: 4, "agua": 3}, {SEED: 5})
	var ui: Node = home.get_node("UI")
	ui.call("verificar_e_atualizar_inventario")
	var guidance_found := false
	for slot in ui.get("inventory_bar").get_children():
		if slot.get("item_id") == SEED:
			guidance_found = slot.tooltip_text.contains("Primavera") and slot.tooltip_text.contains("Verão") and slot.tooltip_text.contains("1 trigo + 1 água")
	_check(guidance_found, "tooltip real da Mochila após rebuild orienta estações e recuperação")
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	ui.call("_on_slot_clicado", SEED, false, null)
	_check(GlobalInventory.semente_selecionada == SEED and ToolManager.get_active_tool() == ToolManager.ToolType.NONE, "seleção real de tomate limpa ferramenta sem abrir aplicação/modal")
	ui.call("verificar_e_atualizar_inventario")
	# O mundo está congelado na fixture; execute o refresh visual normal sem avançar tempo.
	ui.call("_process", 0.0)
	_check(str(ui.get("semente_label").tooltip_text).contains("Primavera") and str(ui.get("semente_label").tooltip_text).contains("Verão"), "seleção orienta duas estações sem nova janela")
	var observations := {"count": 0, "atomic": false}
	var observer := func():
		observations.count += 1
		observations.atomic = GlobalInventory.get_item_quantity(SEED) == 3 and plot.get("estado_atual") == 1 and plot.get("semente_id_plantada") == SEED and not plot.get_node("Timer").is_stopped()
	plot.connect("estado_alterado", observer)
	var before := _domain()
	_check(plot.call("validate_seed_planting", SEED)["success"] and _domain() == before and observations.count == 0, "validação não emite sinal nem altera timer/estoque")
	_check(plot.call("try_plant_from_personal_inventory", SEED)["success"] and observations.count == 1 and observations.atomic, "commit síncrono observado após fonte/cultura/timer")
	plot.disconnect("estado_alterado", observer)
	_check(plot.get("tempo_total_crescimento") == 5.0 and chest.get_item_quantity(SEED) == 5, "Primavera seca 5s, sem bônus Verão/consumo remoto")
	before = _domain()
	_check(not plot.call("try_plant_from_personal_inventory", SEED)["success"] and _domain() == before, "ocupado recusa sem gasto")
	_blank(plot)
	GlobalInventory.set_inventory_contents({"agua": 3})
	before = _domain()
	_check(plot.call("try_plant_from_personal_inventory", SEED)["reason"] == "no_stock" and _domain() == before, "sementes no baú não servem para plantar à mão")
	GlobalInventory.set_inventory_contents({SEED: 1})
	for guard in ["blocked", "hidden", "untilled"]:
		_blank(plot)
		if guard == "blocked": plot.call("set_expansion_blocked", true)
		if guard == "hidden": plot.hide()
		if guard == "untilled": plot.set("arado", false)
		before = _domain()
		_check(not plot.call("try_plant_from_personal_inventory", SEED)["success"] and _domain() == before, "guarda %s mantém estoque/lote" % guard)
		plot.show()
	_blank(plot)
	_check(plot.call("validate_seed_planting", "unknown_seed")["reason"] == "invalid_seed", "ID desconhecido recusado")

func _first_seed_and_cycle() -> void:
	_reset({"trigo": 1, "agua": 4})
	var coins: int = EconomyManager.moedas
	_check(GlobalInventory.get_item_quantity(SEED) == 0 and GlobalInventory.get_item_quantity(CROP) == 0 and not GroveExpedition.restored, "bootstrap parte de zero tomate/semente sem Clareira")
	cauldron.process_mode = Node.PROCESS_MODE_ALWAYS
	cauldron.get("drop_slot_1").set("item_vinculado", "trigo")
	cauldron.get("drop_slot_2").set("item_vinculado", "agua")
	cauldron.call("_on_misturar_button_pressed")
	_check(cauldron.get("estado_atual") == "BREWING" and GlobalInventory.get_item_quantity("trigo") == 0 and GlobalInventory.get_item_quantity("agua") == 3, "mistura manual inicia com custo exato")
	_check(GlobalInventory.get_item_quantity(SEED) == 0 and cauldron.get_node("BrewTimer").wait_time == 2.0, "sem crédito antes do timer real 2s")
	await get_tree().create_timer(2.25).timeout
	_check(cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity(SEED) == 1 and chest.get_item_quantity(SEED) == 0, "timer real entrega primeira semente à Mochila")
	cauldron.call("_on_brew_timer_timeout")
	_check(GlobalInventory.get_item_quantity(SEED) == 1, "timeout repetido não duplica")
	for season in [0, 1]:
		_blank(plot)
		SeasonManager.estacao_atual = season
		GlobalInventory.set_inventory_contents({SEED: 1, "agua": 1})
		plot.process_mode = Node.PROCESS_MODE_ALWAYS
		plot.call("_regar_lote_por_ferramenta")
		_check(plot.get("regado") and GlobalInventory.get_item_quantity("agua") == 0, "rega física cobra uma água %d" % season)
		_check(plot.call("try_plant_from_personal_inventory", SEED)["success"], "cultivo real permitido %d" % season)
		var expected_time := 4.0 if season == 0 else 3.2
		_check(is_equal_approx(plot.get("tempo_total_crescimento"), expected_time), "5s × rega0,8 × bônusVerão somente no Verão %d" % season)
		await get_tree().create_timer(expected_time + 0.25).timeout
		_check(plot.get("estado_atual") == 2 and plot.get("pronto_para_colher"), "irrigação evita morte por sede no ciclo real %d" % season)
		_check(plot.call("_colher_manualmente", false) and GlobalInventory.get_item_quantity(CROP) == 1, "colheita real entrega um tomate %d" % season)
		plot.process_mode = Node.PROCESS_MODE_INHERIT
		# Recuperação não depende da possível devolução RNG da Primavera.
		GlobalInventory.set_inventory_contents({"agua": 1})
		chest.set_contents({"trigo": 1})
		book.call("set_cauldron", cauldron)
		book.call("abrir")
		var index: int = book.call("_find_recipe_index", RECIPE)
		_check(index >= 0 and GlobalInventory.receitas_descobertas.count(RECIPE) == 1, "Livro tem recuperação única mesmo sem tomate/semente")
		if index < 0: return
		book.get("recipe_list").select(index)
		book.get("recipe_list").item_selected.emit(index)
		book.get("quantity_input").text = "1"
		book.get("quantity_input").text_submitted.emit("1")
		book.get("btn_produce").pressed.emit()
		_check(cauldron.get("estado_atual") == "BATCH" and chest.get_item_quantity("trigo") == 0, "botão Livro usa trigo do VillageStorage")
		await get_tree().create_timer(2.25).timeout
		_check(cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity(SEED) == 1, "recuperação real repetível após esgotar produto/semente")
	_check(GlobalInventory.pontos_alquimia == 0 and GlobalInventory.get_backpack_milestones().is_empty() and EconomyManager.moedas == coins and not GroveExpedition.restored, "nenhuma XP/moeda/marco/gate nova")
	cauldron.process_mode = Node.PROCESS_MODE_INHERIT

func _crafting_transactions() -> void:
	_reset({"trigo": 1, "agua": 2}, {"trigo": 1})
	_check(cauldron.call("iniciar_producao_em_lote", RECIPE, 2), "lote reserva origens combinadas")
	var receipts: Array = cauldron.get("_batch_reservation_receipts")
	_check(receipts.size() == 2 and receipts[0]["entries"][0]["source"] == "village_storage", "VillageStorage prioritário, recibos por unidade")
	_tick()
	cauldron.call("cancelar_producao_em_lote")
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and GlobalInventory.get_item_quantity("trigo") == 1 and GlobalInventory.get_item_quantity("agua") == 1 and chest.get_item_quantity("trigo") == 0, "refund só pendente à origem pessoal, água existente")
	var before := _domain()
	cauldron.call("cancelar_producao_em_lote")
	_check(_domain() == before, "cancelar novamente não duplica")
	for personal in [{"agua": 1}, {"trigo": 1}, {}]:
		_reset(personal)
		before = _domain()
		_check(not cauldron.call("iniciar_producao_em_lote", RECIPE, 1) and _domain() == before, "falta ingrediente recusa sem reserva parcial")
	_reset({"agua": 1}, {"trigo": 1})
	_fill_capacity()
	_check(GlobalInventory.get_used_slot_count() == 12 and GlobalInventory.get_item_quantity("agua") == 1, "12 slots cheios; água não ocupa slot")
	_check(cauldron.call("iniciar_producao_em_lote", RECIPE, 1), "produção reserva mesmo com resultado sem espaço")
	_tick()
	_check(cauldron.get("_batch_waiting_for_space") and cauldron.get("_batch_quantidade_concluida") == 0 and cauldron.get("_batch_reservation_receipts").size() == 1, "resultado pronto mantém reserva sem confirmar craft")
	_tick()
	_check(GlobalInventory.get_item_quantity(SEED) == 0 and chest.get_item_quantity(SEED) == 0, "retry cheio não desvia ao baú/duplica")
	GlobalInventory.remover_item("capacity_probe_0", 99)
	cauldron.call("_perform_primary_interaction")
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and cauldron.get("estado_atual") == "IDLE", "liberar capacidade entrega pessoal uma vez")
	cauldron.call("_perform_primary_interaction")
	_check(GlobalInventory.get_item_quantity(SEED) == 1, "recolher repetido não duplica")
	_reset({"agua": 2}, {"trigo": 2})
	cauldron.call("iniciar_producao_em_lote", RECIPE, 2)
	var saved: Dictionary = _json(cauldron.call("get_save_data"))
	before = _resources()
	_check(cauldron.call("is_save_data_valid", saved) and cauldron.call("load_save_data", saved) and cauldron.call("load_save_data", saved) and _resources() == before, "JSON/replay produtor conserva reservas sem novo gasto/refund")
	_tick()
	cauldron.call("cancelar_producao_em_lote")
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and GlobalInventory.get_item_quantity("agua") == 1 and chest.get_item_quantity("trigo") == 1, "retomada entrega uma/refunda uma somente")

func _soil_and_golem() -> void:
	_reset({SEED: 2, "agua": 2}, {SEED: 4, "semente_basica": 1})
	_blank(pilot, true, true)
	_check(pilot.call("try_plant_from_personal_inventory", SEED)["success"] and pilot.get("living_soil_treated") and not pilot.get("living_soil_moisture") and not pilot.get("regado") and pilot.get("tempo_total_crescimento") == 5.0, "tomate descarta umidade herdada sem apagar tratamento ou ganhar retenção")
	_check(pilot.call("regar_por_golem") and pilot.get("regado"), "golem rega tomate pelo contrato vigente")
	_crop(pilot, true, true, {CROP: 1})
	_check(pilot.call("_colher_manualmente", false) and not pilot.get("living_soil_moisture") and not pilot.get("regado") and pilot.get("living_soil_treated"), "colheita tomate não retém água no Solo Vivo")
	_crop(plot, true, false, {CROP: 1, "semente_inverno": 1})
	var personal := GlobalInventory.inventario.duplicate(true)
	var rewards: Array = plot.call("harvest_by_golem", Callable(golem, "_receive_harvest_cargo"))
	_check(rewards.size() == 2 and not golem.get("carried_rewards").is_empty() and GlobalInventory.inventario == personal, "tomate/reward pendente passam à custódia golem, não à Mochila")
	_check(plot.call("harvest_by_golem").is_empty(), "golem não colhe duas vezes")
	var cargo := GolemSeedCargo.new()
	_check(cargo.take_from_chest(chest, Vector2i.ZERO) and chest.get_item_quantity(SEED) == 4, "cargo semeador retira só trigo")
	_check(plot.call("try_plant_from_golem_cargo", cargo)["success"] and plot.get("semente_id_plantada") == "semente_basica" and not cargo.has_seed(), "semeador mantém cultura trigo no piloto")
	var forged := {"item_id": SEED, "quantity": 1, "target_cell": {"x": 0, "y": 0}, "intent": "transport"}
	_check(cargo.apply_save_data(forged) and cargo.get_item_id() == SEED and GolemSeedCargo.PILOT_CELLS.size() == 4 and Vector2i(2, 2) not in GolemSeedCargo.PILOT_CELLS, "cargo tomate válido no recorte seletivo; default trigo e território original intactos")

func _snapshots() -> void:
	_reset({"agua": 3, SEED: 2}, {CROP: 4})
	_crop(plot, false)
	_crop(pilot, true, true, {CROP: 1, SEED: 1})
	var saved := _json(SaveManager.call("_build_save_data"))
	_check(saved["version"] == 4 and _tile(saved, Vector2i.ZERO)["crop_id"] == SEED and _integer_totals(_tile(saved, Vector2i(2, 2))["pending_harvest_rewards"]) == {CROP: 1, SEED: 1}, "GRIDv4 captura cultivo vivo e recompensas pendentes")
	for version in [4, 3]:
		var payload := saved.duplicate(true)
		payload["version"] = version
		if version == 3: payload.erase("farm_grid")
		payload["inventory"]["receitas_descobertas"] = []
		_check(SaveManager.call("_apply_save_data", payload), "snapshot completo v%d aplica" % version)
		_check(plot.get("semente_id_plantada") == SEED and plot.get("estado_atual") == 1 and plot.get_node("Timer").time_left == 60.0 and pilot.call("get_save_data")["pending_harvest_rewards"] == {CROP: 1, SEED: 1}, "load v%d mantém cultura/timer/rewards sem offline" % version)
		_check(GlobalInventory.receitas_descobertas.count(RECIPE) == 1 and GlobalInventory.pontos_alquimia == 0 and GlobalInventory.get_item_quantity(SEED) == 2 and GlobalInventory.get_slot_capacity() == 12, "legado v%d aprende padrão sem itens/XP/marcos" % version)
		var before := _domain()
		_check(SaveManager.call("_apply_save_data", payload) and _domain() == before, "replay v%d idempotente" % version)
	var before := _domain()
	_check(SaveManager.call("_apply_save_data", {"version": 4}) and _domain() == before, "payload parcial mantém cultivo/estoques/prêmios")
	var legacy := saved.duplicate(true)
	for entry in legacy["farm_grid"]["tiles"]: entry.erase("pending_harvest_rewards")
	_check(SaveManager.call("_apply_save_data", legacy) and pilot.call("get_save_data")["pending_harvest_rewards"].is_empty() and pilot.get("estado_atual") == 2, "GRID legado sem rewards mantém cultura madura e limpa pendência posterior")
	_check(SaveManager.call("_apply_save_data", saved), "restaura pendências antes capacidade")
	_fill_capacity()
	before = pilot.call("get_save_data")
	_check(not pilot.call("_colher_manualmente", false) and pilot.call("get_save_data") == before, "tomate/reward conjunto bloqueado não perde cultura/sorteio")
	GlobalInventory.set_inventory_contents({})
	_check(pilot.call("_colher_manualmente", false) and GlobalInventory.get_item_quantity(CROP) == 1 and GlobalInventory.get_item_quantity(SEED) == 1, "retry entrega conjunto exato")
	_check(not pilot.call("_colher_manualmente", false) and GlobalInventory.get_item_quantity(CROP) == 1, "retry concluído não duplica")
	var invalid := saved.duplicate(true)
	_tile(invalid, Vector2i(2, 2))["pending_harvest_rewards"] = {CROP: -1}
	before = _domain()
	_check(not SaveManager.call("_apply_save_data", invalid) and _domain() == before, "preflight recompensa inválida atômico")
	SeasonManager.estacao_atual = 2
	plot.call("load_save_data", saved["farm_plots"][0])
	_check(plot.get("estado_atual") == 1 and plot.get("semente_id_plantada") == SEED, "tomate existente não destruído retroativamente no Outono")

func _cache() -> void:
	_reset({SEED: 2, "agua": 4}, {CROP: 4})
	_crop(plot, false)
	_crop(pilot, true, true, {CROP: 1})
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "viagem real cacheia vila com tomate vivo")
	for frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress(): break
	_check(not home.is_inside_tree() and RegionTravelCoordinator.get_active_region_id() == "foraging_grove", "vila fora da árvore em cache")
	var before := _resources()
	_check(not plot.call("try_plant_from_personal_inventory", SEED)["success"] and not plot.call("apply_growth_dose") and _resources() == before, "cache não planta/consome dose/estoques")
	_check(SaveManager.save_game(), "snapshot externo captura HOME com tomates")
	_check(SaveManager.load_game() and get_tree().current_scene == home, "load externo reconstrói HOME")
	_pause_world()
	_check(plot.get("estado_atual") == 1 and plot.get("semente_id_plantada") == SEED, "cache/load preserva cultura viva")
	_check(pilot.call("get_save_data")["pending_harvest_rewards"] == {CROP: 1}, "cache/load preserva recompensa pendente")
	_check(_resources() == before, "cache/load preserva estoques sem colheita automática")

func _write_fixture() -> void:
	_reset({SEED: 2, "agua": 4}, {CROP: 4})
	_crop(plot, false)
	_crop(pilot, true, true, {CROP: 1, SEED: 1})
	# Cargo pendente preservado junto de cultura viva, sem automação ativa.
	golem.call("_receive_harvest_cargo", [{"item_id": CROP, "quantidade": 2}])
	GlobalInventory.receitas_descobertas = [RECIPE]
	_check(plot.get_node("Timer").time_left == 60.0 and pilot.get("living_soil_treated") and not golem.get("carried_rewards").is_empty(), "fixture fixa cultura60s/rewards/cargo tomate")
	_check(SaveManager.save_game(), "fixture grava arquivo QA para novo processo")

func _verify_reopen() -> void:
	# EXATAMENTE oito verificações; runner deve exigir contagem de cada modo.
	_check(SaveManager.has_save(), "arquivo produtor existe")
	_check(SaveManager.load_game(), "novo processo lê arquivo real")
	_check(plot.get("estado_atual") == 1 and plot.get("semente_id_plantada") == SEED and plot.get_node("Timer").time_left == 60.0, "cultura/timer vivo restaurado sem tempo offline")
	_check(pilot.get("estado_atual") == 2 and pilot.get("living_soil_treated") and not pilot.get("living_soil_moisture") and pilot.call("get_save_data")["pending_harvest_rewards"] == {CROP: 1, SEED: 1}, "maduro/rewards/Solo Vivo sem retenção restaurados")
	_check(GlobalInventory.get_item_quantity(SEED) == 2 and GlobalInventory.get_item_quantity("agua") == 4 and chest.get_item_quantity(CROP) == 4 and GlobalInventory.pontos_alquimia == 0 and GlobalInventory.get_slot_capacity() == 12, "origens/água/XP/slots exatos")
	_check(GlobalInventory.receitas_descobertas.count(RECIPE) == 1 and golem.get("carried_rewards").size() == 1 and golem.get("carried_rewards")[0]["item_id"] == CROP and golem.get("carried_rewards")[0]["quantidade"] == 2, "padrão único e custódia tomate restaurados")
	var before := _domain()
	_check(SaveManager.load_game() and _domain() == before, "replay arquivo não duplica gasto/prêmio")
	_check(home.get("selected_consumable") == "" and not home.call("has_pending_player_interaction") and not book.visible, "nenhuma intenção transitória reabre")

func _fill_capacity() -> void:
	var full := {"agua": GlobalInventory.get_item_quantity("agua")}
	for index in range(GlobalInventory.get_slot_capacity()): full["capacity_probe_%d" % index] = 99
	GlobalInventory.set_inventory_contents(full)

func _tick() -> void:
	cauldron.get_node("BatchTimer").stop()
	cauldron.call("_processar_tick_lote")
	cauldron.get_node("BatchTimer").stop()

func _tile(data: Dictionary, cell: Vector2i) -> Dictionary:
	for entry in data["farm_grid"]["tiles"]:
		if int(entry["grid_position"]["x"]) == cell.x and int(entry["grid_position"]["y"]) == cell.y: return entry
	return {}

func _resources() -> Dictionary:
	return {"personal": _integer_totals(GlobalInventory.inventario), "stored": _integer_totals(chest.get_contents()), "xp": GlobalInventory.pontos_alquimia, "slots": GlobalInventory.get_backpack_milestones(), "doses": GlobalInventory.cargas_crescimento}

func _domain() -> Dictionary:
	var data := _resources()
	data["plot"] = plot.call("get_save_data")
	data["pilot"] = pilot.call("get_save_data")
	data["cauldron"] = cauldron.call("get_save_data")
	data["cargo"] = golem.get("carried_rewards").duplicate(true)
	data["recipes"] = GlobalInventory.receitas_descobertas.duplicate()
	return data

func _json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))

func _integer_totals(data: Dictionary) -> Dictionary:
	var result := {}
	for id in data: result[id] = int(data[id])
	return result

func _frames(count: int) -> void:
	for frame in range(count): await get_tree().physics_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("TomatoCropSmokeTest: FAIL - " + message)

func _finish(label: String) -> void:
	if not failed: print("TomatoCropSmokeTest: PASS - %d verificações de %s." % [checks, label])
	get_tree().quit(1 if failed else 0)
