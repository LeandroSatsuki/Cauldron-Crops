extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SEED := "semente_basica"
const RECOVERY := "semente_trigo_recuperacao"
const REPLANT := "semente_trigo_replantio"
var home: Node
var chest: VillageChest
var golem: Node2D
var cauldron: Node
var ui: Node
var checks := 0
var failed := false
var _xp_before_production := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var qa_root := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(qa_root):
		_check(false, "exige APPDATA dentro de Builds/QA")
		return _finish()
	PocoManager.set_process(false)
	await _new_home()
	if "--verify-seed-cycle-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish()
	if "--prepare-seed-replant-save" in OS.get_cmdline_user_args():
		# Fixture de persistência, não uma segunda colheita simulada no percurso.
		home.process_mode = Node.PROCESS_MODE_DISABLED
		GlobalInventory.set_inventory_contents({"trigo": 1, "agua": 0})
		chest.set_contents({"trigo": 1})
		_check(cauldron.call("iniciar_producao_em_lote", REPLANT, 1), "fixture replantio reserva dois trigos de origens distintas")
		_check(SaveManager.save_game(), "arquivo QA com replantio em produção")
		return _finish()
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({"agua": 0})
	GlobalInventory.receitas_descobertas = []
	GlobalInventory.pontos_alquimia = 7
	GlobalInventory.skills_desbloqueadas = []
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GroveExpedition.reset_progress()
	chest.set_contents({})
	for live in get_tree().get_nodes_in_group("lotes_terra"):
		live.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": false, "regado": false, "expansion_blocked": false})
	_check(GlobalInventory.get_item_quantity(SEED) == 0 and GlobalInventory.get_item_quantity("trigo") == 0, "recuperação começa sem trigo/semente/marco")
	if not await _travel(home, home.get_node("ExternalPathGateway"), "foraging_grove"):
		return _finish()
	var grove: Node = get_tree().current_scene
	for path in ["ForageNodes/CharcoalNearEntry", "ForageNodes/RenewableCharcoal"]:
		var source: ForageNode = grove.get_node(path)
		_check(grove.call("request_player_interaction", source, source.global_position, source.interaction_distance, Callable(source, "collect")), "coleta aceita aproximação física " + path)
		if not await _wait(func(): return source.is_collected(), "coleta efetiva " + path):
			return _finish()
	_check(GlobalInventory.get_item_quantity("carvao") == 3 and chest.get_contents().is_empty(), "carvão real entra só na Mochila")
	_check(float(GroveExpedition.get_forage_state(GroveExpedition.RENEWABLE_SOURCE)["renewal_remaining"]) > 0, "fonte renovável conserva regra existente")
	_check(SaveManager.save_game(), "save externo preserva recursos coletados")
	if not await _travel(grove, grove.get_node("ReturnGateway"), "farm_village"):
		return _finish()
	_check(get_tree().current_scene == home and GlobalInventory.get_item_quantity("carvao") == 3, "retorno físico mantém vila e carvão")
	_check(SaveManager.load_game() and SaveManager.load_game(), "replay do arquivo de coleta")
	_check(GlobalInventory.get_item_quantity("carvao") == 3 and GlobalInventory.get_item_quantity(SEED) == 0 and chest.get_contents().is_empty(), "load não inventa sementes nem duplica carvão")
	PocoManager.tempo_acumulado = 0.0
	PocoManager.set_process(true)
	await get_tree().create_timer(4.1).timeout
	PocoManager.set_process(false)
	_check(GlobalInventory.get_item_quantity("agua") == 4, "poço real regenera água para produção e rega sem compra/slots")
	_check(GlobalInventory.get_used_slot_count() == 1, "água não ocupa slot")
	await _start_from_book(RECOVERY, 2)
	if not await _wait(func(): return cauldron.get("estado_atual") == "IDLE", "duas produções com timers reais"):
		return _finish()
	_check(GlobalInventory.get_item_quantity(SEED) == 2 and GlobalInventory.get_item_quantity("carvao") == 1 and GlobalInventory.get_item_quantity("agua") == 2, "recuperação produz duas e consome recursos exatos")
	_check(GlobalInventory.pontos_alquimia == _xp_before_production, "recuperação não concede pontos de alquimia")
	_check(not golem.get("seeding_enabled") and not GroveExpedition.restored, "receita não restaura Clareira ou ativa golem")
	for cell in [Vector2i(0, 0), Vector2i(1, 0)]:
		var plot: Node2D = home.call("obter_farm_plot_por_grid_position", cell)
		ToolManager.force_select_tool(ToolManager.ToolType.HOE)
		if not await _interact_plot(plot, func(): return bool(plot.get("arado")), "arar lote real"):
			return _finish()
		ui.call("_on_slot_clicado", SEED, false, null)
		_check(ToolManager.get_active_tool() == ToolManager.ToolType.NONE and GlobalInventory.semente_selecionada == SEED, "seleção da Mochila troca enxada por plantio")
		if not await _interact_plot(plot, func(): return plot.get("estado_atual") != 0, "plantio manual consome semente produzida"):
			return _finish()
		ToolManager.force_select_tool(ToolManager.ToolType.WATERING_CAN)
		if not await _interact_plot(plot, func(): return bool(plot.get("regado")), "rega manual preserva cultura"):
			return _finish()
	_check(GlobalInventory.get_item_quantity(SEED) == 0, "duas sementes viram duas culturas")
	if not await _wait(func(): return _plot(Vector2i(0, 0)).get("estado_atual") == 2 and _plot(Vector2i(1, 0)).get("estado_atual") == 2, "crescimento real das duas culturas"):
		return _finish()
	for cell in [Vector2i(0, 0), Vector2i(1, 0)]:
		var plot: Node2D = _plot(cell)
		ToolManager.force_select_tool(ToolManager.ToolType.HARVEST)
		if not await _interact_plot(plot, func(): return plot.get("estado_atual") == 0, "colheita manual real"):
			return _finish()
	_check(GlobalInventory.get_item_quantity("trigo") == 2, "duas colheitas fornecem dois trigos sem exigir bônus RNG")
	var bonus_seeds := GlobalInventory.get_item_quantity(SEED) # bônus existentes não são requisito.
	await _start_from_book(REPLANT, 1)
	if not await _wait(func(): return cauldron.get("estado_atual") == "IDLE", "reinvestimento com timer real"):
		return _finish()
	_check(GlobalInventory.get_item_quantity("trigo") == 0 and GlobalInventory.get_item_quantity(SEED) == bonus_seeds + 3, "replantio acrescenta três sem depender de bônus")
	_check(GlobalInventory.pontos_alquimia == _xp_before_production, "replantio não concede pontos de alquimia")
	_test_guidance()
	# Pré-condição do piloto do golem, já coberta pelo teste de restauração:
	# não afirmar que produzir sementes concedeu o marco.
	var progress := GroveExpedition.get_save_data()
	progress["discovered"] = true
	progress["restored"] = true
	_check(GroveExpedition.load_save_data(progress), "fixture Clareira restaurada permite integração do golem")
	_check(not golem.get("seeding_enabled"), "marco elegível não ativa sozinho")
	ToolManager.clear_tool()
	golem.call("set_work_priority", 0)
	ui.call("_atualizar_semeador_golem")
	ui.get("golem_seeding_toggle").set_pressed_no_signal(true)
	ui.get("golem_seeding_toggle").toggled.emit(true)
	_check(golem.get("seeding_enabled"), "controle existente ativa somente por ação explícita")
	_check(golem.call("get_seeding_status")["code"] == "no_seeds", "golem não usa sementes pessoais antes de depósito")
	_check("Livro" in str(golem.call("get_seeding_status")["text"]), "falta de estoque indica reposição pelo Livro")
	var panel: Control = ui.get_node("VillageChestPanel")
	ui.call("abrir_bau_vila", chest)
	panel.call("_open_transfer", SEED, false)
	_check("manual" in panel.get("feedback").text and "golem" in panel.get("feedback").text, "modal distingue fontes de plantio")
	await _capture("seed_deposit")
	panel.get("quantity_picker").value = 3
	panel.get("quantity_picker").get_line_edit().text = "3"
	panel.get("move_button").pressed.emit()
	_check(chest.get_item_quantity(SEED) == 3 and GlobalInventory.get_item_quantity(SEED) == bonus_seeds, "depósito seletivo move só três produzidas")
	panel.call("_open_transfer", SEED, true)
	_check("manual" in panel.get("feedback").text and "golem" in panel.get("feedback").text, "retirada também distingue as fontes")
	await _capture("seed_withdraw")
	ui.call("fechar_bau_vila")
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return _cargo().has_seed(), "golem retira perto do baú"):
		return _finish()
	golem.call("set_work_priority", 4)
	_check(chest.get_item_quantity(SEED) == 2 and golem.global_position.distance_to(chest.global_position) <= 62, "custódia física de uma semente produzida")
	var cargo_before: Dictionary = _cargo().get_save_data()
	if not await _travel(home, home.get_node("ExternalPathGateway"), "foraging_grove"):
		return _finish()
	await get_tree().create_timer(0.2).timeout
	_check(not home.is_inside_tree() and _cargo().get_save_data() == cargo_before and _plot(Vector2i(0, 0)).get("estado_atual") == 0, "Bosque não planta/transporta remotamente")
	_check(SaveManager.save_game() and SaveManager.load_game() and SaveManager.load_game(), "arquivo externo e replay preservam carga produzida")
	_check(get_tree().current_scene == home and _cargo().get_save_data() == cargo_before and chest.get_item_quantity(SEED) == 2, "load retorna com uma carga e sem retirada extra")
	golem.call("set_work_priority", 0)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "golem retoma caminho e planta"):
		return _finish()
	_check(_plot(Vector2i(0, 0)).get("estado_atual") != 0 and chest.get_item_quantity(SEED) == 2 and GlobalInventory.get_item_quantity(SEED) == bonus_seeds, "uma semente entregue vira uma cultura, sem consumir Mochila")
	golem.call("set_work_priority", 4)
	_check(GlobalInventory.pontos_alquimia == _xp_before_production, "save/viagem preservam pontos anteriores, inclusive eventos de colheita")
	# Checkpoint para outro processo: ingrediente restante veio da coleta real.
	PocoManager.tempo_acumulado = 0.0
	PocoManager.set_process(true)
	await get_tree().create_timer(1.1).timeout
	PocoManager.set_process(false)
	await _start_from_book(RECOVERY, 1)
	cauldron.get_node("BatchTimer").stop()
	_check(SaveManager.save_game(), "arquivo final com receita nova em produção para reabertura")
	_finish()

func _new_home() -> void:
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await get_tree().process_frame
	await get_tree().physics_frame
	chest = home.get_node("VillageChest")
	golem = home.get_node("Golem")
	cauldron = home.get_node("CauldronUI")
	ui = home.get_node("UI")
	(golem.get("_think_timer") as Timer).stop()
	golem.call("set_work_priority", 4)

func _verify_reopen() -> void:
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.SAVE_PATH))
	var production: Dictionary = disk["cauldrons"][str(home.get_path_to(cauldron))]
	_check(SaveManager.load_game() and SaveManager.load_game(), "novo processo carrega arquivo duas vezes")
	var before := GlobalInventory.get_item_quantity(SEED)
	var storage := chest.get_contents()
	var work: Dictionary = golem.call("get_work_save_data")
	var inventory_valid := true
	for item_id in disk["inventory"]["inventario"]:
		inventory_valid = inventory_valid and GlobalInventory.get_item_quantity(item_id) == int(disk["inventory"]["inventario"][item_id])
	_check(inventory_valid and GlobalInventory.get_item_quantity(SEED) == int(disk["inventory"]["inventario"].get(SEED, 0)), "reabertura conserva água, carvão e demais itens")
	var storage_valid := true
	for item_id in disk["village_chest_inventory"]:
		storage_valid = storage_valid and chest.get_item_quantity(item_id) == int(disk["village_chest_inventory"][item_id])
	_check(storage_valid, "reabertura conserva estoque do baú")
	_check(GlobalInventory.get_item_quantity("trigo") == int(disk["inventory"]["inventario"].get("trigo", 0)) and chest.get_item_quantity("trigo") == int(disk["village_chest_inventory"].get("trigo", 0)), "reabertura não reserva trigos novamente")
	var recipe_id: String = production["batch"]["recipe_id"]
	_check(recipe_id in [RECOVERY, REPLANT] and cauldron.get("_batch_recipe_id") == recipe_id, "reabertura retoma receita nova exata")
	cauldron.get_node("BatchTimer").stop()
	cauldron.call("_processar_tick_lote")
	var quantity := 1 if recipe_id == RECOVERY else 3
	_check(GlobalInventory.get_item_quantity(SEED) == before + quantity and cauldron.get("estado_atual") == "IDLE", "entrega única do resultado após reabertura")
	_check(GlobalInventory.pontos_alquimia == int(disk["inventory"]["pontos_alquimia"]), "entrega retomada não concede XP")
	cauldron.call("_processar_tick_lote")
	_check(GlobalInventory.get_item_quantity(SEED) == before + quantity and chest.get_contents() == storage and golem.call("get_work_save_data") == work, "tentativa repetida não duplica/consome baú/carga")

func _start_from_book(recipe_id: String, quantity: int) -> void:
	_xp_before_production = GlobalInventory.pontos_alquimia
	ui.call("abrir_livro_receitas", false, cauldron)
	var book: Control = ui.get("recipe_book")
	var index := int(book.call("_find_recipe_index", recipe_id))
	_check(index >= 0, "Livro oferece " + recipe_id)
	if index < 0:
		return
	book.get("recipe_list").select(index)
	book.get("recipe_list").item_selected.emit(index)
	_check("Semente de Trigo" in book.get("result_label").text, "Livro usa nome canônico do resultado")
	await _capture(recipe_id)
	book.get("quantity_input").text = str(quantity)
	book.get("quantity_input").text_submitted.emit(str(quantity))
	book.get("btn_produce").pressed.emit()
	_check(cauldron.get("estado_atual") == "BATCH" and cauldron.get("_batch_quantidade_total") == quantity, "Livro inicia quantidade pedida")
	ui.call("fechar_livro_receitas")

func _test_guidance() -> void:
	var text := Database.obter_descricao_item(SEED)
	_check("1 carvão" in text and "2 trigos" in text and "golem" in text, "orientação do item informa receitas/fontes")
	var before := GlobalInventory.inventario.duplicate(true)
	ui.call("atualizar_inventario_visual")
	var found := false
	for child in ui.get("inventory_bar").get_children():
		if child.get("item_id") == SEED:
			found = text in child.tooltip_text
	_check(found, "tooltip da Mochila informa reposição")
	ui.call("abrir_bau_vila", chest)
	var panel: Control = ui.get_node("VillageChestPanel")
	var slot: Button = panel.get("inventory_grid").get_child(0)
	for child in panel.get("inventory_grid").get_children():
		if child.get_meta("item_id", "") == SEED:
			slot = child
	_check(text in slot.tooltip_text, "tooltip do baú usa orientação do catálogo")
	ui.call("fechar_bau_vila")
	_check(GlobalInventory.inventario == before, "consultar orientação não altera estoque")

func _interact_plot(plot: Node2D, condition: Callable, message: String) -> bool:
	_check(home.call("request_player_interaction", plot, plot.global_position, 56.0, Callable(plot, "_on_plot_clicked")), "aproximação aceita: " + message)
	return await _wait(condition, message)

func _travel(scene: Node, gateway: RegionGateway, region_id: String) -> bool:
	_check(scene.call("request_player_interaction", gateway, gateway.global_position, gateway.interaction_distance, Callable(gateway, "activate")), "aproximação aceita para " + region_id)
	return await _wait(func(): return RegionTravelCoordinator.get_active_region_id() == region_id and not RegionTravelCoordinator.is_transition_in_progress(), "viagem real para " + region_id)

func _plot(cell: Vector2i) -> Node2D:
	return home.call("obter_farm_plot_por_grid_position", cell)

func _cargo() -> GolemSeedCargo:
	return golem.get("seed_cargo")

func _capture(label: String) -> void:
	if "--capture-seed-cycle" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/Seeds2/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _wait(condition: Callable, message: String) -> bool:
	for frame in range(2400):
		await get_tree().physics_frame
		if bool(condition.call()):
			_check(true, message)
			return true
	_check(false, "timeout " + message)
	return false

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SustainableFarmCycleSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("SustainableFarmCycleSmokeTest: PASS - %d verificações de orientação, coleta, produção, plantio, viagem e arquivo QA." % checks)
	get_tree().quit(1 if failed else 0)
