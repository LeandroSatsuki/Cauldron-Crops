extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const Resolver := preload("res://Scripts/data/RecipeResolver.gd")

var _farm: Node
var _grove: Node
var _chest: VillageChest
var _cauldron: Node
var _site: GroveRestorationSite
var _checks: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Somente snapshots JSON em memória; nunca abrir/escrever o save pessoal.
	if "--capture" in OS.get_cmdline_user_args():
		get_tree().root.mode = Window.MODE_WINDOWED
		get_tree().root.size = Vector2i(1920, 1080) if "--capture-large" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
		await get_tree().process_frame
	GroveExpedition.reset_progress()
	GlobalInventory.set_inventory_contents({"carvao": 4, "semente_basica": 2, "agua": 10})
	GlobalInventory.receitas_descobertas = []
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	_farm = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_farm)
	get_tree().current_scene = _farm
	await get_tree().process_frame
	await get_tree().physics_frame
	_chest = _farm.get_node("VillageChest")
	_cauldron = _farm.get_node("CauldronUI")
	_chest.set_contents({"carvao": 4, "trigo": 7})
	var resolver := Resolver.new()
	if not _expect(resolver.find_recipe_for_ingredients(["carvao", "carvao"]).is_empty(), "preparação desbloqueou antes da descoberta"):
		return
	var locked_inventory: Dictionary = GlobalInventory.inventario.duplicate(true)
	var locked_storage: Dictionary = _chest.get_contents()
	_cauldron.get("drop_slot_1").set("item_vinculado", "carvao")
	_cauldron.get("drop_slot_2").set("item_vinculado", "carvao")
	_cauldron.call("_on_misturar_button_pressed")
	if not _expect(GlobalInventory.inventario == locked_inventory and _chest.get_contents() == locked_storage and _cauldron.get("estado_atual") == "IDLE", "mistura bloqueada consumiu ingredientes"):
		return
	if not _expect(not _cauldron.call("iniciar_producao_em_lote", GroveExpedition.REWARD_RECIPE, 1), "lote burlou aprendizado"):
		return
	_cauldron.call("_limpar_slots")
	var control_plot: Node = _farm.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	control_plot.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": "semente_basica", "arado": true, "regado": true, "tempo_restante": 90.0, "tempo_total_crescimento": 90.0})
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	_grove = get_tree().current_scene
	_site = _grove.get_node("RestorationSite")
	var player: Node2D = _grove.get_node("PlayerAvatar")
	player.global_position = Vector2(1930, 760)
	if not _expect(_grove.call("request_player_interaction", _site, _site.global_position, _site.INTERACTION_DISTANCE, Callable(_site, "interact")), "aproximação à clareira recusada"):
		return
	for _frame in range(300):
		await get_tree().physics_frame
		if GroveExpedition.discovered:
			break
	if not _expect(GroveExpedition.discovered and not GroveExpedition.restored and resolver.is_recipe_available(GroveExpedition.PREPARATION_RECIPE), "descoberta física não ensinou preparação"):
		return
	await _capture("grove_discovered")
	if not _expect(not resolver.is_recipe_available(GroveExpedition.REWARD_RECIPE), "recompensa desbloqueou antes de restaurar"):
		return
	if not _expect(_chest.get_contents() == locked_storage, "descoberta externa alterou baú"):
		return
	GroveExpedition._toggle_tracker()
	if not _expect(not GroveExpedition.get_node("GroveExpeditionTracker/ExpeditionPanel").get_child(0).get_child(1).visible, "minimizar objetivo não ocultou corpo"):
		return
	await _capture("grove_minimized")
	GroveExpedition._toggle_tracker()
	var source: ForageNode = _grove.get_node("ForageNodes/RenewableCharcoal")
	var full: Dictionary = {}
	for index in range(GlobalInventory.get_slot_capacity()):
		full["capacity_probe_%d" % index] = 99
	GlobalInventory.set_inventory_contents(full)
	if not _expect(not source.collect() and not source.is_collected() and GlobalInventory.inventario == full, "coleta recusada por capacidade esgotou fonte"):
		return
	GlobalInventory.set_inventory_contents(locked_inventory)
	if not _expect(source.collect() and GlobalInventory.get_item_quantity("carvao") == 6, "fonte renovável não entregou dois carvões na Mochila"):
		return
	if not _expect(not source.collect() and source.is_collected(), "fonte renovável duplicou antes do intervalo"):
		return
	GroveExpedition._process(GroveExpedition.CHARCOAL_RENEWAL_SECONDS)
	await get_tree().physics_frame
	if not _expect(not source.is_collected() and source.collect() and GlobalInventory.get_item_quantity("carvao") == 8, "rota determinística não se renovou"):
		return
	var original_source: ForageNode = _grove.get_node("ForageNodes/CharcoalDeepClearing")
	if not _expect(original_source.collect() and not original_source.collect(), "fonte original perdeu contrato de coleta única"):
		return
	var away_save: Dictionary = _json_roundtrip(SaveManager._build_save_data())
	if not _expect(away_save["farm_plots"].size() == 34 and away_save["farm_grid"]["tiles"].size() == 34, "snapshot externo omitiu lotes da vila em cache"):
		return
	if not _expect(away_save["village_chest_inventory"] == _json_roundtrip(locked_storage) and not away_save["cauldrons"].is_empty(), "snapshot externo omitiu baú/caldeirão: %s / %s" % [away_save["village_chest_inventory"], away_save["cauldrons"].keys()]):
		return
	if not _expect(away_save["home_inactive_seconds"] > 0.0, "snapshot externo omitiu tempo agrícola pendente"):
		return
	if not await _travel(&"farm_village", &"from_foraging_grove"):
		return
	var farm_ui: Node = _farm.get_node("UI")
	farm_ui.call("abrir_livro_receitas", false, _cauldron)
	var book: Node = farm_ui.get("recipe_book")
	var preparation_index: int = int(book.call("_find_recipe_index", GroveExpedition.PREPARATION_RECIPE))
	if not _expect(preparation_index >= 0, "receita aprendida não apareceu no Livro"):
		return
	book.call("_show_recipe_by_index", preparation_index)
	book.get("quantity_input").text = "2"
	book.call("_aplicar_quantidade_digitada")
	if not _expect(not book.get("btn_produce").disabled and int(book.get("_craft_quantity")) == 2, "Livro não permitiu fabricar dois crafts com ingredientes duplicados"):
		return
	await _capture("recipe_preparation")
	book.call("_on_produce_pressed")
	if not _expect(_cauldron.get("estado_atual") == "BATCH", "preparação pelo Livro recusada"):
		return
	book.call("fechar")
	if not _expect(bool(farm_ui.get("visible")), "fechar Livro no host local ocultou toda a HUD da Fazenda"):
		return
	var cauldron_popup: CanvasLayer = _cauldron.get_node("PopupLayer")
	book.reparent(cauldron_popup)
	cauldron_popup.visible = true
	book.call("abrir")
	book.call("fechar")
	if not _expect(not cauldron_popup.visible and bool(farm_ui.get("visible")), "fechar Livro no painel do caldeirão não preservou a HUD/fechou o host"):
		return
	book.reparent(farm_ui)
	_finish_batch_unit()
	_finish_batch_unit()
	if not _expect(GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 2 and _chest.get_item_quantity("carvao") == 0 and GlobalInventory.get_item_quantity("carvao") == 9, "craft não respeitou duas unidades/consumo preferencial do Storage"):
		return
	await _capture("farm_preparation")
	# Depósito sintético para provar que o site NÃO retira ingredientes à distância.
	GlobalInventory.remover_item(GroveExpedition.MIXTURE_ITEM, 2)
	_chest.set_contents({GroveExpedition.MIXTURE_ITEM: 2, "trigo": 7})
	var prepared_save: Dictionary = _json_roundtrip(SaveManager._build_save_data())
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	if not _expect(not _site.interact() and not GroveExpedition.restored and _chest.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 2, "restauração consumiu baú remoto"):
		return
	if not _expect(SaveManager._apply_save_data(prepared_save) and get_tree().current_scene == _farm, "load fora da vila não retomou HOME"):
		return
	if not _expect(_chest.get_contents() == prepared_save["village_chest_inventory"] and control_plot.get("estado_atual") == 1, "load externo perdeu storage/cultura"):
		return
	if not _expect(_cauldron.get("estado_atual") == "IDLE" and GroveExpedition.discovered and not GroveExpedition.restored, "retomada parcial perdeu estágio/produção"):
		return
	GlobalInventory.try_add_items({GroveExpedition.MIXTURE_ITEM: 2})
	_chest.set_contents({"trigo": 7})
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	player.global_position = Vector2(2030, 680)
	if not _expect(_grove.call("request_player_interaction", _site, _site.global_position, _site.INTERACTION_DISTANCE, Callable(_site, "interact")), "retorno carregando mistura não aproximou"):
		return
	for _frame in range(240):
		await get_tree().physics_frame
		if GroveExpedition.restored:
			break
	if not _expect(GroveExpedition.restored and GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 0, "restauração não consumiu exatamente duas misturas carregadas"):
		return
	if not _expect(resolver.is_recipe_available(GroveExpedition.REWARD_RECIPE) and GlobalInventory.receitas_descobertas.count(GroveExpedition.REWARD_RECIPE) == 1, "recompensa não ensinou receita única"):
		return
	var after_restoration: Dictionary = GlobalInventory.inventario.duplicate(true)
	if not _expect(not _site.interact() and GlobalInventory.inventario == after_restoration, "repetir restauração consumiu/duplicou recompensa"):
		return
	if not _expect(not GroveExpedition.get_node("GroveExpeditionTracker/ExpeditionPanel").visible, "objetivo concluído não desapareceu"):
		return
	await _capture("grove_restored")
	if not await _travel(&"farm_village", &"from_foraging_grove"):
		return
	if not _expect(_cauldron.call("iniciar_producao_em_lote", GroveExpedition.PREPARATION_RECIPE, 1), "mistura pós-restauração perdeu uso"):
		return
	_finish_batch_unit()
	if not _expect(_cauldron.call("iniciar_producao_em_lote", GroveExpedition.REWARD_RECIPE, 1), "receita agrícola aprendida não produziu"):
		return
	_finish_batch_unit()
	if not _expect(GlobalInventory.get_item_quantity("pocao_crescimento") == 1 and GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 0, "receita não entregou poção/consumo exatos"):
		return
	await _capture("farm_reward")
	var ui: Node = _farm.get_node("UI")
	GlobalInventory.cargas_crescimento = 0
	ui.call("_on_usar_pocao_button_pressed")
	control_plot.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": "semente_basica", "arado": true, "regado": true, "tempo_restante": 8.0, "tempo_total_crescimento": 8.0})
	control_plot.call("_on_plot_clicked")
	if not _expect(GlobalInventory.get_item_quantity("pocao_crescimento") == 0 and GlobalInventory.cargas_crescimento == 2 and is_equal_approx(control_plot.get_node("Timer").time_left, 4.0), "recompensa agrícola não reduziu tempo real do cultivo"):
		return
	var completed_save: Dictionary = _json_roundtrip(SaveManager._build_save_data())
	if not _expect(is_equal_approx(float(completed_save["farm_grid"]["tiles"][0]["remaining_growth_time"]), 4.0), "save agrícola perdeu redução aplicada pela poção"):
		return
	# Cena HOME nova prova persistência sem depender de instância/árvore antiga.
	get_tree().root.remove_child(_farm)
	_farm.free()
	_farm = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_farm)
	get_tree().current_scene = _farm
	await get_tree().process_frame
	await get_tree().physics_frame
	_chest = _farm.get_node("VillageChest")
	_cauldron = _farm.get_node("CauldronUI")
	GroveExpedition.reset_progress()
	if not _expect(SaveManager._apply_save_data(completed_save) and GroveExpedition.restored and GlobalInventory.cargas_crescimento == 2, "JSON em cena nova perdeu restauração/efeito"):
		return
	var retained_sources: Dictionary = GroveExpedition.get_save_data()["forage_sources"]
	if not _expect(SaveManager._apply_save_data({"version": 4, "inventory": {"receitas_descobertas": []}}) and GroveExpedition.restored and resolver.is_recipe_available(GroveExpedition.REWARD_RECIPE) and GroveExpedition.get_save_data()["forage_sources"] == retained_sources, "payload parcial apagou marco/fontes ou receita do marco"):
		return
	_grove.free()
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	_grove = get_tree().current_scene
	_site = _grove.get_node("RestorationSite")
	if not _expect(_site.get_node("Prompt").text == "Clareira restaurada" and _grove.get_node("ForageNodes/CharcoalDeepClearing").is_collected(), "nova sessão visual/coleta não refletiu snapshot"):
		return
	if not _expect(not _site.interact() and GlobalInventory.receitas_descobertas.count(GroveExpedition.REWARD_RECIPE) == 1, "load repetiu recompensa"):
		return
	var probes: Array = [
		{"discovered": false, "restored": true},
		{"discovered": "true", "restored": false},
		{"discovered": true, "restored": false, "forage_sources": {"unknown": {"collected": true, "renewal_remaining": 0.0}}},
		{"discovered": true, "restored": false, "forage_sources": {GroveExpedition.RENEWABLE_SOURCE: {"collected": true, "renewal_remaining": -1.0}}},
		{"discovered": true, "restored": false, "forage_sources": {"charcoal_entry": {"collected": true, "renewal_remaining": 5.0}}},
	]
	for probe in probes:
		var invalid: Dictionary = completed_save.duplicate(true)
		invalid["grove_expedition"] = probe
		invalid["inventory"]["inventario"] = {"trigo": 777}
		var before: Dictionary = GlobalInventory.inventario.duplicate(true)
		if not _expect(not SaveManager._apply_save_data(invalid) and get_tree().current_scene == _grove and GroveExpedition.restored and GlobalInventory.inventario == before, "payload inválido alterou região/estoque/progresso"):
			return
	for bad_interval in [-1.0, "6.0"]:
		var invalid: Dictionary = completed_save.duplicate(true)
		invalid["home_inactive_seconds"] = bad_interval
		if not _expect(not SaveManager._apply_save_data(invalid) and get_tree().current_scene == _grove, "intervalo inválido alterou região"):
			return
	var bad_inventory: Dictionary = completed_save.duplicate(true)
	bad_inventory["inventory"]["inventario"] = {"trigo": -1}
	if not _expect(not SaveManager._apply_save_data(bad_inventory) and get_tree().current_scene == _grove, "inventário inválido ativou HOME antes do preflight"):
		return
	if not await _check_away_production(completed_save):
		return
	var legacy: Dictionary = completed_save.duplicate(true)
	legacy.erase("grove_expedition")
	legacy.erase("home_inactive_seconds")
	if not _expect(SaveManager._apply_save_data(legacy) and not GroveExpedition.discovered and not GroveExpedition.restored and not resolver.is_recipe_available(GroveExpedition.REWARD_RECIPE), "save v4 anterior não iniciou clareira intacta"):
		return
	if not _expect(not _grove.get_node("ForageNodes/CharcoalDeepClearing").is_collected(), "save anterior reteve esgotamento de sessão futura"):
		return
	print("GroveRestorationSliceSmokeTest: PASS - %d verificações; descoberta, rota determinística, craft, Mochila, restauração, efeito agrícola, JSON/cache e compatibilidade." % _checks)
	get_tree().quit(0)


func _check_away_production(completed_save: Dictionary) -> bool:
	if not _expect(SaveManager._apply_save_data(completed_save) and get_tree().current_scene == _farm, "preflight do teste de produção externa falhou"):
		return false
	GlobalInventory.set_inventory_contents({"agua": 10})
	_chest.set_contents({"carvao": 4})
	var plot: Node = _farm.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	plot.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": "semente_basica", "arado": true, "regado": true, "tempo_restante": 12.0, "tempo_total_crescimento": 12.0})
	if not _expect(_cauldron.call("iniciar_producao_em_lote", GroveExpedition.PREPARATION_RECIPE, 2), "produção para snapshot externo recusada"):
		return false
	if not await _travel(&"foraging_grove", &"from_farm"):
		return false
	var away: Dictionary = _json_roundtrip(SaveManager._build_save_data())
	if not _expect(away["cauldrons"]["CauldronUI"]["state"] == "BATCH" and away["village_chest_inventory"].get("carvao", 0) == 0, "snapshot externo omitiu produção/reservas da vila"):
		return false
	# Intervalo de sessão sintético, sem aguardar relógio nem modificar save real.
	away["home_inactive_seconds"] = 6.0
	if not _expect(SaveManager._apply_save_data(away) and get_tree().current_scene == _farm, "retomada da produção externa falhou"):
		return false
	if not _expect(GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 1 and _cauldron.get("estado_atual") == "BATCH" and _chest.get_item_quantity("carvao") == 0, "catch-up duplicou/perdeu produção ou ingredientes"):
		return false
	var remaining: float = plot.get_node("Timer").time_left
	if not _expect(remaining > 4.0 and remaining <= 6.0, "catch-up agrícola não avançou intervalo salvo uma vez"):
		return false
	if not _expect(SaveManager._apply_save_data(away) and GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 1 and is_equal_approx(plot.get_node("Timer").time_left, remaining), "reaplicar snapshot duplicou tempo/resultado"):
		return false
	_cauldron.call("cancelar_producao_em_lote")
	if not _expect(_cauldron.get("estado_atual") == "IDLE" and _chest.get_item_quantity("carvao") == 2 and GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 1, "cancelamento após load externo não restituiu só reserva restante ao Storage"):
		return false
	return true


func _finish_batch_unit() -> void:
	_cauldron.get("batch_timer").stop()
	_cauldron.call("_processar_tick_lote")


func _travel(region_id: StringName, entry_id: StringName) -> bool:
	if not _expect(get_tree().current_scene.call("request_region_transition", region_id, entry_id, &"slice_test"), "viagem rejeitada"):
		return false
	for _frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress():
			break
	return _expect(RegionTravelCoordinator.get_active_region_id() == String(region_id) and not RegionTravelCoordinator.is_input_blocked(), "viagem não concluiu/liberou input")


func _json_roundtrip(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value))


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	var ui: Node = get_tree().current_scene.get_node_or_null("UI")
	if ui != null:
		ui.call("verificar_e_atualizar_inventario")
	GroveExpedition._refresh_tracker()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/GroveRestoration/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + "_%d.png" % get_tree().root.size.x)


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("GroveRestorationSliceSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
