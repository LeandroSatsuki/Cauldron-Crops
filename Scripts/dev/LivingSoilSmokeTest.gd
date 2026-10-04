extends Node

# Fixtures sintéticas/arquivos QA; não é aceite manual de mouse, arte ou ritmo.
const MAIN := preload("res://Scenes/Main.tscn")
const SOIL := preload("res://Scripts/LivingSoilState.gd")
const RESOLVER := preload("res://Scripts/data/RecipeResolver.gd")
var home: Node2D
var pilot: Node2D
var other: Node2D
var chest: VillageChest
var golem: Node
var cauldron: Node
var ui: Node
var panel: Control
var player: PlayerAvatar
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA em Builds/QA antes de ler/gravar arquivo")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	pilot = home.call("obter_farm_plot_por_grid_position", SOIL.PILOT_CELL)
	other = home.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	chest = home.get_node("VillageChest")
	golem = home.get_node("Golem")
	cauldron = home.get_node("CauldronUI")
	ui = home.get_node("UI")
	panel = ui.get("item_use_panel")
	player = home.get_node("PlayerAvatar")
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	if "--verify-living-soil-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish()
	_reset()
	_domain_cycles()
	_recipe_contracts()
	_snapshots()
	_growth_contracts()
	await _interface_contracts()
	await _travel_and_file()
	_finish()

func _reset() -> void:
	home.cancel_consumable_application()
	panel.close_card()
	panel.cancel_application()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({SOIL.ITEM_ID: 2, "semente_basica": 8, "semente_inverno": 1, "agua": 7, "pocao_crescimento": 2})
	GlobalInventory.pontos_alquimia = 7
	chest.set_contents({})
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	cauldron.call("load_save_data", {"state": "IDLE"})
	_blank(pilot)
	_blank(other)
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()

func _blank(plot: Node2D, treated: bool = false, moisture: bool = false) -> void:
	plot.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": true, "regado": moisture, "expansion_blocked": false, "living_soil_treated": treated, "living_soil_moisture": moisture})

func _crop(plot: Node2D, ready: bool, watered: bool = true, seed_id: String = "semente_basica", treated: bool = true) -> void:
	plot.call("load_save_data", {"estado_atual": 2 if ready else 1, "semente_id_plantada": seed_id, "arado": true, "regado": watered, "tempo_restante": 0.0 if ready else 60.0, "tempo_total_crescimento": 60.0, "pronto_para_colher": ready, "expansion_blocked": false, "pending_harvest_rewards": {"trigo": 1} if ready and seed_id == "semente_basica" else {}, "living_soil_treated": treated, "living_soil_moisture": false})

func _domain_cycles() -> void:
	_check(pilot.position == Vector2(840, 920) and home.is_living_soil_pilot_plot(pilot), "célula piloto existente e origem preservadas")
	_check(SOIL.PILOT_CELL not in GolemSeedCargo.PILOT_CELLS, "semeador não ganha novo território")
	var before := _domain()
	_check(not other.call("apply_living_soil") and _domain() == before, "outro lote recusa sem gasto")
	var personal := GlobalInventory.inventario.duplicate(true)
	GlobalInventory.inventario.erase(SOIL.ITEM_ID)
	chest.set_contents({SOIL.ITEM_ID: 1})
	before = _domain()
	_check(not pilot.call("apply_living_soil") and _domain() == before, "preparo no baú não é fonte de aplicação")
	GlobalInventory.set_inventory_contents(personal)
	chest.set_contents({})
	before = _domain()
	_check(pilot.call("can_apply_living_soil") and _domain() == before, "consulta de aplicação é pura")
	_check(pilot.call("apply_living_soil"), "aplica um preparo no piloto vazio/arado")
	_check(pilot.get("living_soil_treated") and not pilot.get("regado") and not pilot.get("living_soil_moisture") and pilot.get_node("Timer").is_stopped(), "tratamento não rega nem inicia timer")
	_check(GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and GlobalInventory.get_item_quantity("agua") == 7, "consumo pessoal de uma unidade, sem água")
	before = _domain()
	_check(not pilot.call("apply_living_soil") and _domain() == before, "tratamento não empilha nem cobra de novo")
	_check(pilot.call("try_plant_from_personal_inventory", "semente_basica")["success"], "primeiro trigo plantado normalmente")
	_check(not pilot.get("regado") and is_equal_approx(pilot.get("tempo_total_crescimento"), 3.0), "primeira plantação não recebe água/bônus automático")
	_check(pilot.call("_regar_lote_por_ferramenta"), "primeira rega manual existente")
	_check(GlobalInventory.get_item_quantity("agua") == 6 and pilot.get("regado"), "rega inicial cobra uma água")
	pilot.call("debug_force_ready_to_harvest")
	_check(pilot.call("_colher_manualmente", false), "primeira colheita efetivamente entregue")
	_check(pilot.get("living_soil_moisture") and pilot.get("regado") and pilot.get("estado_atual") == 0, "colheita de trigo conserva umidade no vazio")
	for cycle in range(3):
		_check(pilot.call("try_plant_from_personal_inventory", "semente_basica")["success"], "replantio %d" % cycle)
		_check(pilot.get("regado") and not pilot.get("living_soil_moisture") and is_equal_approx(pilot.get("tempo_total_crescimento"), 2.4), "usa só bônus existente 0,8")
		pilot.call("debug_force_ready_to_harvest")
		_check(pilot.call("_colher_manualmente", false) and pilot.get("living_soil_moisture"), "tratamento sobrevive a vários ciclos")
	_check(GlobalInventory.get_item_quantity("agua") == 6, "replantios não retiram água/itens remotamente")
	_crop(pilot, true)
	_fill_capacity()
	before = _domain()
	_check(not pilot.call("_colher_manualmente", false), "capacidade cheia recusa colheita inteira")
	_check(_domain() == before and pilot.get("_pending_manual_harvest_rewards").size() == 1, "recusa conserva cultura, flags e recompensa determinada")
	GlobalInventory.set_inventory_contents({"agua": 6})
	_check(pilot.call("_colher_manualmente", false) and GlobalInventory.get_item_quantity("trigo") == 1 and pilot.get("living_soil_moisture"), "retry entrega uma vez e só então conserva umidade")
	before = _domain()
	_check(not pilot.call("_colher_manualmente", false) and _domain() == before, "repetição não duplica prêmio/efeito")
	_crop(pilot, true)
	personal = GlobalInventory.inventario.duplicate(true)
	var rewards: Array = pilot.call("harvest_by_golem", Callable(golem, "_receive_harvest_cargo"))
	_check(rewards.size() == 1 and not golem.get("carried_rewards").is_empty(), "golem recebe custódia real antes do lote vazio")
	_check(GlobalInventory.inventario == personal and pilot.get("living_soil_moisture"), "golem não entrega prêmio pessoal e conserva solo")
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	golem.call("set_work_priority", 4)
	GlobalInventory.set_inventory_contents({"semente_inverno": 1})
	SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO
	_check(pilot.call("try_plant_from_personal_inventory", "semente_inverno")["success"], "outro cultivo continua permitido")
	_check(not pilot.get("regado") and not pilot.get("living_soil_moisture") and pilot.get("living_soil_treated"), "não-trigo descarta só umidade herdada, conserva tratamento")
	_crop(pilot, true, true, "semente_inverno")
	_check(pilot.call("_colher_manualmente", false) and not pilot.get("living_soil_moisture") and not pilot.get("regado"), "colheita não-trigo não conserva água")
	_blank(pilot, true, true)
	_check(pilot.call("debug_apply_daily_decay") and pilot.get("living_soil_treated") and not pilot.get("regado") and not pilot.get("living_soil_moisture"), "limpeza preserva tratamento sem gerar água")
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	seed(90210)
	var died := false
	for attempt in range(64):
		_crop(pilot, false, false)
		pilot.call("_on_timer_timeout")
		if pilot.get("estado_atual") == 0:
			died = true
			break
	_check(died and pilot.get("living_soil_treated") and not pilot.get("living_soil_moisture") and not pilot.get("regado"), "morte sintética preserva tratamento sem gerar água")
	personal = GlobalInventory.inventario.duplicate(true)
	pilot.call("load_save_data", {})
	_check(not pilot.get("living_soil_treated") and GlobalInventory.inventario == personal, "snapshot vazio real inicia comum, sem refund")

func _fill_capacity() -> void:
	var contents := {}
	for id in Database.itens:
		if id != "agua":
			contents[id] = 99
		if contents.size() == 12:
			break
	GlobalInventory.set_inventory_contents(contents)

func _recipe_contracts() -> void:
	_reset()
	var resolver := RESOLVER.new()
	var recipe: Dictionary = resolver.get_recipe(SOIL.RECIPE_ID)
	_check(recipe.get("ingredientes") == ["trigo", "mistura_restauradora"] and recipe.get("resultado_item") == SOIL.ITEM_ID and recipe.get("resultado_quantidade") == 1, "receita aprovada de duas entradas")
	_check(recipe.get("tempo_producao") == 2.0 and recipe.get("recompensa_pontos_alquimia") == 0 and recipe.get("resource").exige_descoberta, "tempo/XP/descoberta corretos")
	GroveExpedition.reset_progress()
	GlobalInventory.set_inventory_contents({"trigo": 2, "mistura_restauradora": 2})
	var before := _domain()
	_check(not resolver.is_recipe_available(SOIL.RECIPE_ID) and not cauldron.call("iniciar_producao_em_lote", SOIL.RECIPE_ID, 1) and _domain() == before, "lote bloqueado não reserva")
	cauldron.get("drop_slot_1").item_vinculado = "trigo"
	cauldron.get("drop_slot_2").item_vinculado = "mistura_restauradora"
	cauldron.call("_on_misturar_button_pressed")
	_check(_domain() == before and cauldron.get("estado_atual") == "IDLE", "mistura manual bloqueada não perde ingredientes")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	GroveExpedition.reconcile_recipe_discoveries()
	_check(resolver.is_recipe_available(SOIL.RECIPE_ID) and GlobalInventory.receitas_descobertas.count(SOIL.RECIPE_ID) == 1, "marco reconcilia aprendizado único")
	var xp := GlobalInventory.pontos_alquimia
	cauldron.call("_on_misturar_button_pressed")
	_check(cauldron.get("estado_atual") == "BREWING" and GlobalInventory.get_item_quantity("trigo") == 1 and GlobalInventory.get_item_quantity("mistura_restauradora") == 1, "mistura manual inicia com consumo exato")
	cauldron.get_node("BrewTimer").stop()
	cauldron.call("_on_brew_timer_timeout")
	_check(GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and GlobalInventory.pontos_alquimia == xp, "resultado manual pessoal sem XP")
	GlobalInventory.set_inventory_contents({"trigo": 1, "mistura_restauradora": 1})
	chest.set_contents({"trigo": 1, "mistura_restauradora": 1})
	_check(cauldron.call("iniciar_producao_em_lote", SOIL.RECIPE_ID, 2), "lote de duas unidades usa estoques combinados")
	_check(chest.get_contents().is_empty() and GlobalInventory.get_item_quantity("trigo") == 0 and cauldron.get("_batch_reservation_receipts").size() == 2, "reservas uma por craft, baú primeiro")
	cauldron.get_node("BatchTimer").stop()
	cauldron.call("_processar_tick_lote")
	_check(GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and cauldron.get("_batch_reservation_receipts").size() == 1, "primeira entrega descarta só recibo concluído")
	cauldron.call("cancelar_producao_em_lote")
	_check(GlobalInventory.get_item_quantity("trigo") == 1 and GlobalInventory.get_item_quantity("mistura_restauradora") == 1 and chest.get_contents().is_empty(), "cancelamento devolve pendente à origem pessoal exata")
	before = _domain()
	cauldron.call("cancelar_producao_em_lote")
	_check(_domain() == before, "cancelamento repetido não duplica")
	_fill_capacity()
	# Resultado não deve compartilhar uma pilha já cheia nem ganhar slot.
	chest.set_contents({"trigo": 1, "mistura_restauradora": 1})
	_check(cauldron.call("iniciar_producao_em_lote", SOIL.RECIPE_ID, 1), "reserva do baú com Mochila cheia")
	cauldron.get_node("BatchTimer").stop()
	var production: Dictionary = cauldron.call("get_save_data")
	cauldron.call("_processar_tick_lote")
	_check(cauldron.get("_batch_waiting_for_space") and cauldron.get("_batch_reservation_receipts").size() == 1, "resultado bloqueado conserva reserva")
	_check(cauldron.call("is_save_data_valid", cauldron.call("get_save_data")), "snapshot da espera por espaço válido")
	GlobalInventory.set_inventory_contents({})
	cauldron.call("_processar_tick_lote")
	_check(GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and cauldron.get("estado_atual") == "IDLE", "resultado bloqueado entregue depois uma vez")
	cauldron.call("_processar_tick_lote")
	_check(GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and production["batch"]["total"] == 1, "tick repetido não duplica preparo")

func _snapshots() -> void:
	_reset()
	_blank(pilot, true, true)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	var tile := _saved_tile(saved)
	_check(saved["version"] == 4 and tile["living_soil_treated"] and tile["living_soil_moisture"], "GRID v4 conserva flags no vazio")
	_blank(pilot)
	_check(SaveManager.call("_apply_save_data", saved) and pilot.get("living_soil_moisture"), "JSON restaura solo vazio úmido")
	var before := _domain()
	_check(SaveManager.call("_apply_save_data", saved) and _domain() == before, "replay não reaplica item ou benefício")
	var partial := saved.duplicate(true)
	partial.erase("inventory")
	for entry in partial["farm_grid"]["tiles"]:
		entry.erase("living_soil_treated")
		entry.erase("living_soil_moisture")
	_check(SaveManager.call("_apply_save_data", partial) and pilot.get("living_soil_treated") and pilot.get("living_soil_moisture"), "parcial preserva flags ausentes")
	_check(SaveManager.call("_apply_save_data", {"version": 4}) and pilot.get("living_soil_treated"), "parcial sem fazenda não apaga tratamento")
	for version in [3, 4]:
		var legacy := saved.duplicate(true)
		legacy["version"] = version
		for entry in legacy["farm_plots"]:
			entry.erase("living_soil_treated")
			entry.erase("living_soil_moisture")
		for entry in legacy["farm_grid"]["tiles"]:
			entry.erase("living_soil_treated")
			entry.erase("living_soil_moisture")
		_check(SaveManager.call("_apply_save_data", legacy) and not pilot.get("living_soil_treated"), "completo legado v%d inicia solo comum" % version)
	_check(SaveManager.call("_apply_save_data", saved), "restaura snapshot novo após legado")
	var priority := saved.duplicate(true)
	for entry in priority["farm_plots"]:
		entry["living_soil_treated"] = false
		entry["living_soil_moisture"] = false
	_check(SaveManager.call("_apply_save_data", priority) and pilot.get("living_soil_treated"), "GRID v4 prioritário sobre fallback legado")
	for flag in ["living_soil_treated", "living_soil_moisture"]:
		for invalid_value in [1, "true", null]:
			var invalid := saved.duplicate(true)
			_saved_tile(invalid)[flag] = invalid_value
			_expect_rejected(invalid)
	var invalid := saved.duplicate(true)
	_saved_tile(invalid)["living_soil_treated"] = false
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	_saved_tile(invalid)["crop_id"] = "semente_basica"
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	_saved_tile(invalid)["tile_state"] = 4
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	_saved_tile(invalid)["is_watered"] = false
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	_saved_tile(invalid)["grid_position"] = {"x": 3, "y": 3}
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	invalid["farm_grid"]["tiles"].append(_saved_tile(invalid).duplicate(true))
	_expect_rejected(invalid)
	invalid = saved.duplicate(true)
	var duplicate: Dictionary = _saved_tile(invalid).duplicate(true)
	duplicate["living_soil_treated"] = false
	duplicate["living_soil_moisture"] = false
	invalid["farm_grid"]["tiles"].append(duplicate)
	_expect_rejected(invalid)
	_check(SaveManager.save_game(), "arquivo QA válido antes do estado inválido")
	var disk := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	pilot.set("living_soil_treated", false)
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk, "writer recusa contradição preservando arquivo anterior")
	pilot.set("living_soil_treated", true)
	var previous_doses := GlobalInventory.cargas_crescimento
	GlobalInventory.cargas_crescimento = -1
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk, "writer recusa doses negativas sem substituir arquivo QA válido")
	GlobalInventory.cargas_crescimento = previous_doses
	for child in get_tree().root.get_children():
		if child is AcceptDialog:
			child.queue_free()

func _saved_tile(data: Dictionary) -> Dictionary:
	for entry in data["farm_grid"]["tiles"]:
		if int(entry["grid_position"]["x"]) == 2 and int(entry["grid_position"]["y"]) == 2:
			return entry
	return {}

func _expect_rejected(data: Dictionary) -> void:
	var before := _domain()
	_check(not SaveManager.call("_apply_save_data", data), "preflight recusa flags/identidade contraditórias")
	_check(_domain() == before, "recusa antes de trocar região/estoques/culturas")

func _growth_contracts() -> void:
	_reset()
	_crop(other, false, true, "semente_basica", false)
	other.call("_on_plot_clicked")
	_check(GlobalInventory.cargas_crescimento == 0 and GlobalInventory.get_item_quantity("pocao_crescimento") == 2, "clique simples não abre frasco")
	_check(other.call("apply_growth_dose"), "primeira aplicação explícita válida")
	_check(GlobalInventory.get_item_quantity("pocao_crescimento") == 1 and GlobalInventory.cargas_crescimento == 2 and is_equal_approx(other.get_node("Timer").time_left, 30.0), "abre um frasco, gera três/gasta uma, reduz restante pela metade")
	_check(other.call("apply_growth_dose") and GlobalInventory.cargas_crescimento == 1 and GlobalInventory.get_item_quantity("pocao_crescimento") == 1, "segunda aplicação prioriza dose legada")
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.set_inventory_contents({})
	chest.set_contents({"pocao_crescimento": 2})
	var before := _domain()
	_check(not other.call("apply_growth_dose") and _domain() == before, "sem dose/frasco pessoal recusa, mesmo com frasco no baú")
	chest.set_contents({})
	GlobalInventory.set_inventory_contents({"pocao_crescimento": 1})
	_crop(other, true, true, "semente_basica", false)
	before = _domain()
	_check(not other.call("apply_growth_dose") and _domain() == before, "maduro recusa antes de consumir frasco")
	_crop(other, false, true, "semente_basica", false)
	other.get_node("Timer").stop()
	before = _domain()
	_check(not other.call("apply_growth_dose") and _domain() == before, "timer parado/zero recusa")

func _interface_contracts() -> void:
	_reset()
	home.process_mode = Node.PROCESS_MODE_INHERIT
	for plot in home.get("farm_plot_registry").values():
		plot.process_mode = Node.PROCESS_MODE_DISABLED
	cauldron.process_mode = Node.PROCESS_MODE_DISABLED
	_crop(other, false, true, "semente_basica", false)
	for id in ["mistura_restauradora", "pocao_purificadora_fraca"]:
		GlobalInventory.adicionar_item(id, 1)
		panel.show_item(id)
		_check(panel.is_card_open() and not panel.apply_button.visible, "cartão de reagente explica uso contextual, não aplica " + id)
		panel.close_card()
	panel.show_item("pocao_crescimento")
	var before := _domain()
	_check(panel.is_card_open() and panel.apply_button.visible and ui.call("_tem_popup_modal_aberto") and _domain() == before, "cartão de poção não consome, modal explícito")
	for resolution in [Vector2i(800, 600), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		await _settle()
		panel.call("_process", 0.0)
		_check(get_viewport().get_visible_rect().encloses(panel.card.get_global_rect()) and panel.card.get_theme_stylebox("panel").bg_color.a == 1.0, "cartão opaco/contido %s" % resolution)
		await _capture("card_%d_%d" % [resolution.x, resolution.y])
	await _click(panel.apply_button)
	_check(home.selected_consumable == "pocao_crescimento" and not panel.is_card_open() and _domain_resources() == _resources(before), "Aplicar escolhe modo sem gastar")
	panel.call("_process", 0.0)
	_check(panel.application_bar.visible, "orientação transitória de aplicação")
	for resolution in [Vector2i(800, 600), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		await _settle()
		panel.call("_process", 0.0)
		_check(get_viewport().get_visible_rect().encloses(panel.application_bar.get_global_rect()), "barra contida %s" % resolution)
		await _capture("application_bar_%d_%d" % [resolution.x, resolution.y])
	_place(other.global_position + Vector2(190, 0))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	other.call("_input_event", get_viewport(), click, 0)
	_check(home.has_pending_player_interaction() and GlobalInventory.cargas_crescimento == 0, "collider inicia aproximação sem abrir frasco")
	if not await _wait(func(): return home.selected_consumable == "", "chegada real aplica e encerra intenção"):
		return
	_check(GlobalInventory.get_item_quantity("pocao_crescimento") == 1 and GlobalInventory.cargas_crescimento == 2, "chegada gasta somente uma dose")
	_crop(other, false, true, "semente_basica", false)
	for cancellation in ["escape", "right", "tool", "seed", "new_item", "new_target", "modal", "load"]:
		panel.close_card()
		ToolManager.clear_tool()
		GlobalInventory.semente_selecionada = ""
		_place(other.global_position + Vector2(250, 0))
		_check(home.begin_consumable_application("pocao_crescimento"), "arma cancelamento " + cancellation)
		home.try_apply_selected_consumable_to_plot(other)
		var old_generation: int = home.get("_consumable_generation")
		var resources := _domain_resources()
		if cancellation == "escape":
			var event := InputEventKey.new()
			event.keycode = KEY_ESCAPE
			event.pressed = true
			home.call("_unhandled_input", event)
		elif cancellation == "right":
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT
			event.pressed = true
			home.call("_unhandled_input", event)
		elif cancellation == "tool":
			ToolManager.select_hoe()
			home.call("_process", 0.0)
		elif cancellation == "seed":
			ui.call("_on_slot_clicado", "semente_basica", false, null)
		elif cancellation == "new_item":
			panel.show_item("mistura_restauradora")
		elif cancellation == "new_target":
			home.try_apply_selected_consumable_to_plot(pilot)
		elif cancellation == "modal":
			ui.call("abrir_bau_vila", chest)
			home.call("_process", 0.0)
		elif cancellation == "load":
			var snapshot: Dictionary = SaveManager.call("_build_save_data")
			_check(SaveManager.call("_apply_save_data", snapshot), "load durante aproximação")
		# Callback capturado é executado deliberadamente após cancelamento.
		# Aproximar o fixture evita um falso PASS somente por distância.
		player.stop_moving()
		player.global_position = other.global_position + Vector2(0, 35)
		home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", old_generation)
		_check(_domain_resources() == resources, "callback obsoleto não consome após " + cancellation)
		ui.call("fechar_bau_vila")
		panel.close_card()
		home.cancel_consumable_application()
	for changed in ["mature", "stock"]:
		ToolManager.clear_tool()
		GlobalInventory.semente_selecionada = ""
		GlobalInventory.set_inventory_contents({"pocao_crescimento": 1, SOIL.ITEM_ID: 2})
		GlobalInventory.cargas_crescimento = 0
		_crop(other, false, true, "semente_basica", false)
		_place(other.global_position + Vector2(250, 0))
		_check(home.begin_consumable_application("pocao_crescimento"), "arma alteração durante caminho " + changed)
		home.try_apply_selected_consumable_to_plot(other)
		var valid_generation: int = home.get("_consumable_generation")
		if changed == "mature":
			_crop(other, true, true, "semente_basica", false)
		else:
			GlobalInventory.set_inventory_contents({SOIL.ITEM_ID: 2})
		var resources := _domain_resources()
		player.stop_moving()
		player.global_position = other.global_position + Vector2(0, 35)
		home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", valid_generation)
		_check(_domain_resources() == resources and home.selected_consumable == "pocao_crescimento", "commit revalida " + changed + " sem gasto e conserva intenção")
		home.cancel_consumable_application()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	_check(home.begin_consumable_application(SOIL.ITEM_ID), "arma preparo para teste de fundo")
	before = _domain()
	_check(home.try_apply_selected_consumable_to_plot(null) and _domain_resources() == _resources(before) and not home.has_pending_player_interaction(), "alvo não-lote não aplica nem inicia fallback")
	await _world_nonplot_click()
	_check(pilot.get("estado_atual") == 0 and not pilot.get("living_soil_treated"), "clique inválido não planta/trata automaticamente")
	home.cancel_consumable_application()
	_place(pilot.global_position + Vector2(0, 35))
	panel.show_item(SOIL.ITEM_ID)
	await _click(panel.apply_button)
	pilot.call("_input_event", get_viewport(), click, 0)
	_check(pilot.get("living_soil_treated") and GlobalInventory.get_item_quantity(SOIL.ITEM_ID) == 1 and home.selected_consumable == "", "cartão/preparo/collider confirma uma aplicação no piloto")
	var after := _domain_resources()
	home.try_apply_selected_consumable_to_plot(pilot)
	_check(_domain_resources() == after, "sem intenção ativa, chamada não gasta novamente")
	await _engine_interface_cancellation()

func _engine_interface_cancellation() -> void:
	# Eventos no viewport exercitam dispatch GUI do motor, não cursor do Windows.
	# Câmera usa handler direto; force_drag valida o estado de drag real, não o
	# gesto físico de iniciar arraste nem entrega no caldeirão/dois painéis.
	home.cancel_consumable_application()
	panel.close_card()
	GlobalInventory.set_inventory_contents({"pocao_crescimento": 1, SOIL.ITEM_ID: 2, "mistura_restauradora": 1})
	GlobalInventory.cargas_crescimento = 0
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	_crop(other, false, true, "semente_basica", false)
	var old_page_size: int = ui.get("_inventory_page_size")
	ui.call("atualizar_inventario_visual")
	ui.set("_inventory_page", 0)
	ui.call("set_inventory_page_size", 1)
	await _settle()
	var next_button: Button = ui.get("inventory_next_button")
	_check(next_button.is_visible_in_tree() and not next_button.disabled, "fixture oferece controle GUI genérico de página")
	_place(other.global_position + Vector2(250, 0))
	_check(home.begin_consumable_application("pocao_crescimento"), "arma aplicação antes de clique GUI genérico")
	home.try_apply_selected_consumable_to_plot(other)
	var generation: int = home.get("_consumable_generation")
	var resources := _domain_resources()
	var page_before: int = ui.get("_inventory_page")
	await _click(next_button)
	_check(home.selected_consumable == "" and not home.has_pending_player_interaction() and int(ui.get("_inventory_page")) == page_before + 1, "clique GUI cancela intenção e ainda funciona sem vazamento")
	_place(other.global_position + Vector2(0, 35))
	home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", generation)
	_check(_domain_resources() == resources, "callback antigo depois de GUI não consome mesmo perto")
	await _move_gui_mouse(next_button.get_global_rect().get_center())
	await _settle()
	_place(other.global_position + Vector2(250, 0))
	# Sem nenhum frame/_process da barra entre armar e RMB.
	_check(home.begin_consumable_application("pocao_crescimento") and not panel.application_bar.visible, "arma RMB imediato com barra ainda invisível")
	home.try_apply_selected_consumable_to_plot(other)
	generation = home.get("_consumable_generation")
	resources = _domain_resources()
	_push_mouse_button(next_button.get_global_rect().get_center(), MOUSE_BUTTON_RIGHT, true)
	_check(home.selected_consumable == "" and not home.has_pending_player_interaction() and get_viewport().is_input_handled(), "RMB no viewport sobre GUI cancela antes de atualizar barra")
	_push_mouse_button(next_button.get_global_rect().get_center(), MOUSE_BUTTON_RIGHT, false)
	_place(other.global_position + Vector2(0, 35))
	home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", generation)
	_check(_domain_resources() == resources, "RMB invalida callback perto sem gasto")
	_place(other.global_position + Vector2(250, 0))
	_check(home.begin_consumable_application("pocao_crescimento"), "arma cancelamento por câmera")
	home.try_apply_selected_consumable_to_plot(other)
	generation = home.get("_consumable_generation")
	resources = _domain_resources()
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	home.call("_unhandled_input", middle)
	_check(home.selected_consumable == "" and home.get("_camera_dragging") and not home.has_pending_player_interaction(), "handler MMB inicia câmera e cancela aplicação")
	_place(other.global_position + Vector2(0, 35))
	home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", generation)
	_check(_domain_resources() == resources, "câmera invalida callback perto sem gasto")
	middle.pressed = false
	home.call("_unhandled_input", middle)
	home.call("set_camera_follow_enabled", true)
	_check(not home.get("_camera_dragging"), "release MMB limpa estado transitório da câmera")
	ui.set("_inventory_page", 0)
	ui.call("set_inventory_page_size", old_page_size)
	ui.call("atualizar_inventario_visual")
	await _settle()
	var source: Control = ui.get("inventory_bar").get_child(0)
	for state in ["pending", "card", "active"]:
		home.cancel_consumable_application()
		panel.close_card()
		await _move_gui_mouse(source.get_global_rect().get_center())
		if state == "pending":
			panel.show_item("pocao_crescimento", true)
			_check(panel.pending_item == "pocao_crescimento" and not panel.is_card_open(), "fixture tem cartão adiado antes de drag")
		elif state == "card":
			panel.show_item("pocao_crescimento")
			_check(panel.is_card_open(), "fixture tem cartão aberto antes de drag")
		else:
			_place(other.global_position + Vector2(250, 0))
			_check(home.begin_consumable_application("pocao_crescimento"), "fixture tem intenção ativa antes de drag")
			home.try_apply_selected_consumable_to_plot(other)
		generation = home.get("_consumable_generation")
		resources = _domain_resources()
		var preview := Label.new()
		preview.text = "QA: arraste isolado"
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		source.force_drag("pocao_crescimento", preview)
		_check(get_viewport().gui_is_dragging(), "force_drag ativa drag real do motor: " + state)
		panel.call("_process", 0.0)
		_place(other.global_position + Vector2(0, 35))
		home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", generation)
		_check(panel.pending_item == "" and not panel.is_card_open() and home.selected_consumable == "" and not home.has_pending_player_interaction() and _domain_resources() == resources, "drag aborta cartão/intenção/callback sem gastar: " + state)
		_push_mouse_button(Vector2(-20, -20), MOUSE_BUTTON_LEFT, false)
		await get_tree().process_frame
		if get_viewport().gui_is_dragging():
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			get_viewport().push_input(escape, true)
			await get_tree().process_frame
			escape.pressed = false
			get_viewport().push_input(escape, true)
		_check(not get_viewport().gui_is_dragging() and _domain_resources() == resources, "drag encerrado sem drop/estoque residual: " + state)

func _world_nonplot_click() -> void:
	var cell := Vector2i(6, 5)
	var point: Vector2 = home.call("_converter_grid_em_posicao_global", cell)
	var camera: Camera2D = home.get_node("MainCamera")
	var limits := [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
	var previous_position := camera.position
	var following: bool = home.call("is_camera_follow_enabled")
	home.call("set_camera_follow_enabled", false)
	camera.limit_left = -1000000
	camera.limit_top = -1000000
	camera.limit_right = 1000000
	camera.limit_bottom = 1000000
	camera.position = point
	camera.force_update_scroll()
	camera.position += point - home.get_global_mouse_position()
	camera.force_update_scroll()
	await get_tree().physics_frame
	_check(home.call("obter_farm_plot_por_grid_position", cell) == null and home.call("_consumable_plot_at", point) == null, "fixture de fundo não contém lote")
	var before := _domain_resources()
	var previous_player_position := player.global_position
	var reset := InputEventAction.new()
	reset.action = "living_soil_qa_unused"
	get_viewport().push_input(reset)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	home.call("_unhandled_input", event)
	_check(get_viewport().is_input_handled() and home.selected_consumable == SOIL.ITEM_ID and not home.has_pending_player_interaction() and _domain_resources() == before, "clique de fundo capturado sem gasto/rota/fallback")
	await get_tree().physics_frame
	_check(player.global_position == previous_player_position and home.call("obter_farm_plot_por_grid_position", cell) == null, "fundo não movimenta nem cria lote")
	camera.limit_left = limits[0]
	camera.limit_top = limits[1]
	camera.limit_right = limits[2]
	camera.limit_bottom = limits[3]
	camera.position = previous_position
	camera.force_update_scroll()
	home.call("set_camera_follow_enabled", following)

func _travel_and_file() -> void:
	panel.close_card()
	home.cancel_consumable_application()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	_blank(pilot, true, true)
	GlobalInventory.set_inventory_contents({"pocao_crescimento": 1, "agua": 6, "trigo": 3})
	GlobalInventory.cargas_crescimento = 2
	chest.set_contents({"mistura_restauradora": 2})
	_check(home.begin_consumable_application("pocao_crescimento"), "arma intenção antes da viagem")
	var generation: int = home.get("_consumable_generation")
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "viagem real para Bosque")
	await _wait(func(): return not RegionTravelCoordinator.is_transition_in_progress(), "transição conclui")
	_check(get_tree().current_scene != home and not home.is_inside_tree() and home.selected_consumable == "", "cache cancela intenção")
	var resources := _domain_resources()
	home.call("_commit_consumable_application", weakref(other), "pocao_crescimento", generation)
	_check(_domain_resources() == resources and not pilot.call("apply_living_soil"), "callback/cache não consomem fontes remotamente")
	_check(SaveManager.save_game(), "arquivo QA externo captura solo HOME cacheado")
	_check(SaveManager.load_game() and get_tree().current_scene == home, "load externo retorna HOME")
	home.process_mode = Node.PROCESS_MODE_DISABLED
	_check(pilot.get("living_soil_treated") and pilot.get("living_soil_moisture") and pilot.get("regado"), "cache/load conserva tratamento e umidade")
	_check(GlobalInventory.cargas_crescimento == 2 and GlobalInventory.get_item_quantity("pocao_crescimento") == 1, "viagem/load conservam doses e frasco fechado")
	panel.close_card()
	home.cancel_consumable_application()
	_check(SaveManager.save_game(), "deixa fixture final fixa para processo de reabertura")

func _verify_reopen() -> void:
	# EXATAMENTE oito verificações; runner/exportador deve exigir essa contagem.
	_check(SaveManager.has_save(), "arquivo QA do processo anterior existe")
	_check(SaveManager.load_game(), "novo processo carrega arquivo")
	_check(pilot.get("living_soil_treated") and pilot.get("living_soil_moisture") and pilot.get("regado") and pilot.get("estado_atual") == 0, "solo tratado vazio/úmido restaurado")
	_check(GlobalInventory.cargas_crescimento == 2 and GlobalInventory.get_item_quantity("pocao_crescimento") == 1, "duas doses e um frasco fechado exatos")
	_check(home.is_living_soil_pilot_plot(pilot) and pilot.position == Vector2(840, 920), "identidade e origem conservadas")
	_check(home.selected_consumable == "" and not panel.is_card_open() and not home.has_pending_player_interaction(), "intenção/cartão/rota não persistem")
	var before := _domain()
	_check(SaveManager.load_game() and _domain() == before, "replay de arquivo não duplica estoque/efeito")
	# JSON lê números como floats; comparar quantidade normalizada + único tipo.
	_check(not pilot.call("apply_living_soil") and _domain() == before and chest.get_contents().size() == 1 and chest.get_item_quantity("mistura_restauradora") == 2, "reaplicação não cobra e baú permanece exato")

func _domain() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "doses": GlobalInventory.cargas_crescimento, "stored": chest.get_contents(), "pilot": pilot.call("get_save_data"), "other": other.call("get_save_data"), "grove": GroveExpedition.get_save_data(), "scene": get_tree().current_scene.get_instance_id()}

func _resources(data: Dictionary) -> Dictionary:
	return {"personal": data["personal"], "doses": data["doses"], "stored": data["stored"]}

func _domain_resources() -> Dictionary:
	return _resources(_domain())

func _place(point: Vector2) -> void:
	home.call("_cancel_pending_player_interaction", true)
	player.stop_moving()
	player.global_position = point

func _click(button: BaseButton) -> void:
	await _settle()
	var point := button.get_global_rect().get_center()
	await _move_gui_mouse(point)
	for pressed in [true, false]:
		_push_mouse_button(point, MOUSE_BUTTON_LEFT, pressed)
		await get_tree().process_frame
		await get_tree().physics_frame

func _move_gui_mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	get_viewport().push_input(event, true)
	await get_tree().process_frame

func _push_mouse_button(point: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = pressed
	get_viewport().push_input(event, true)

func _settle() -> void:
	for index in range(8):
		await get_tree().process_frame
	await get_tree().physics_frame

func _wait(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if bool(condition.call()):
			_check(true, label)
			return true
		await get_tree().physics_frame
	_check(false, "timeout: " + label)
	return false

func _capture(label: String) -> void:
	if "--capture-living-soil" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/LivingSoil/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("LivingSoilSmokeTest: FAIL - " + label)

func _finish() -> void:
	if not failed:
		print("LivingSoilSmokeTest: PASS - %d verificações de domínio, receita, uso explícito, persistência e arquivo QA." % checks)
	get_tree().quit(1 if failed else 0)
