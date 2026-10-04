extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SEED := "semente_basica"
const RESOLUTIONS := [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]
var main: Node
var ui: Node
var golem: Node
var chest: VillageChest
var plot: Node
var panel: PanelContainer
var toggle: CheckButton
var status_label: Label
var checks := 0
var failed := false
var toggles := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("GolemSowerUISmokeTest: exige APPDATA em Builds/QA.")
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	GlobalInventory.set_inventory_contents({SEED: 7, "agua": 2})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await _settle()
	ui = main.get_node("UI")
	golem = main.get_node("Golem")
	chest = main.get_node("VillageChest")
	plot = main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	panel = ui.get("golem_panel")
	toggle = ui.get("golem_seeding_toggle")
	status_label = ui.get("golem_seeding_status")
	(golem.get("_think_timer") as Timer).stop()
	toggle.toggled.connect(func(_enabled): toggles += 1)
	ui.call("abrir_golem_panel")
	await _settle()
	if "--verify-seeding-ui-reopen" in OS.get_cmdline_user_args():
		_check(SaveManager.load_game(), "novo processo lê save QA")
		ui.call("_atualizar_painel_golem")
		_check(toggle.button_pressed and not toggle.disabled and GroveExpedition.restored, "novo processo apresenta opção ON elegível")
		_check(toggles == 0 and chest.get_item_quantity(SEED) == 3 and not _cargo().has_seed(), "reabertura não emite toggle/retira semente")
		return _finish()
	_reset()
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
	_expect_code("locked")
	_check(toggle.disabled and not toggle.button_pressed, "novo jogo bloqueado e OFF")
	await _click(toggle)
	_check(not golem.get("seeding_enabled") and toggles == 0, "clique em opção bloqueada não ativa")
	var stock := GlobalInventory.inventario.duplicate(true)
	var recipes := GlobalInventory.receitas_descobertas.duplicate()
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	_expect_code("off")
	var expected_recipes := recipes.duplicate()
	for existing_reward in [GroveExpedition.PREPARATION_RECIPE, GroveExpedition.REWARD_RECIPE, GroveExpedition.LIVING_SOIL_RECIPE]:
		if existing_reward not in expected_recipes:
			expected_recipes.append(existing_reward)
	expected_recipes.sort()
	var restored_recipes := GlobalInventory.receitas_descobertas.duplicate()
	restored_recipes.sort()
	_check(not toggle.disabled and not toggle.button_pressed and stock == GlobalInventory.inventario and expected_recipes == restored_recipes, "marco libera OFF sem item extra, mantendo as três receitas aprovadas da Clareira")
	await _click(toggle)
	_check(toggle.button_pressed and golem.get("seeding_enabled") and toggles == 1, "clique real no toggle ativa API")
	_expect_code("soil")
	_prepare(plot)
	chest.set_contents({})
	_expect_code("no_seeds")
	_check(GlobalInventory.get_item_quantity(SEED) == 7, "sementes na Mochila não satisfazem Storage")
	chest.set_contents({SEED: 3})
	_expect_code("ready")
	SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO
	_expect_code("season")
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	for cell in GolemSeedCargo.PILOT_CELLS:
		var live: Node = main.call("obter_farm_plot_por_grid_position", cell)
		live.call("set_expansion_blocked", true)
	_expect_code("unavailable")
	_prepare(plot)
	_check(plot.call("try_plant_from_personal_inventory", SEED)["success"], "fixture ocupa canteiro")
	_expect_code("occupied")
	GlobalInventory.set_inventory_contents(stock)
	_prepare(plot)
	main.remove_child(chest)
	_expect_code("no_chest")
	main.add_child(chest)
	for priority in [2, 3]:
		golem.call("set_work_priority", priority)
		_expect_code("exclusive")
	golem.call("set_work_priority", 4)
	_expect_code("paused")
	golem.call("set_work_priority", 0)
	golem.set("carried_rewards", [{"item_id": "trigo", "quantidade": 1}])
	_expect_code("other_work")
	golem.set("carried_rewards", [])
	golem.set("state", "MOVING_TO_SEED_CHEST")
	_expect_code("fetching")
	golem.call("set_work_priority", 4)
	golem.call("set_work_priority", 1) # Sem talento de rega: não mascara semeadura.
	_check(_cargo().take_from_chest(chest, Vector2i(0, 0)), "fixture instala carga real")
	golem.set("state", "MOVING_TO_SEED_PLOT")
	_expect_code("transporting")
	_check(not str(golem.call("get_current_task_label")).contains("bloqueada"), "talento de rega não mascara transporte")
	_check(not ui.get("golem_task_label").visible, "transporte não é repetido em dois textos")
	golem.set("state", "PLANTING_SEED")
	_expect_code("planting")
	golem.set("state", "IDLE")
	_expect_code("cargo_waiting")
	golem.call("set_work_priority", 4)
	_expect_code("paused_cargo")
	await _click(toggle)
	_check(not toggle.button_pressed and not golem.get("seeding_enabled") and _cargo().is_return_pending() and chest.get_item_quantity(SEED) == 2, "OFF pelo painel conserva devolução durante pausa")
	_expect_code("paused_cargo")
	golem.call("set_work_priority", 0)
	_expect_code("return_pending")
	golem.set("state", "MOVING_TO_SEED_RETURN")
	_expect_code("returning")
	golem.call("set_work_priority", 4)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	var before_toggles := toggles
	_check(SaveManager.call("_apply_save_data", saved) and SaveManager.call("_apply_save_data", saved), "load/replay da opção OFF com cargo")
	ui.call("_atualizar_painel_golem")
	_check(not toggle.button_pressed and _cargo().is_return_pending() and chest.get_item_quantity(SEED) == 2 and toggles == before_toggles, "sincronização de load não emite toggle ou refund")
	var legacy := saved.duplicate(true)
	legacy.erase("golem_work")
	_check(SaveManager.call("_apply_save_data", legacy), "save antigo restaurado aceita ausência de bloco")
	ui.call("_atualizar_painel_golem")
	_check(not toggle.button_pressed and not toggle.disabled and not _cargo().has_seed() and toggles == before_toggles, "legado elegível OFF sem cargo inventado")
	_reset()
	_prepare(plot)
	ui.call("abrir_golem_panel") # Load fecha o modal; geometria deve exercitar painel aberto.
	ui.call("_atualizar_painel_golem")
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await _settle()
		for code in ["ready", "no_seeds", "season", "soil"]:
			SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO if code == "season" else SeasonManager.Estacao.PRIMAVERA
			_prepare(plot, code != "soil")
			chest.set_contents({SEED: 3} if code != "no_seeds" else {})
			golem.call("set_seeding_enabled", true)
			_expect_code(code)
			await _settle()
			await _test_geometry()
			await _capture("golem_%d_%d_%s" % [resolution.x, resolution.y, code])
		panel.position = Vector2(25, 20)
		panel.call("_queue_layout") # Recalcular não pode apagar a posição do arraste.
		await _settle()
		_check(panel.position.is_equal_approx(Vector2(25, 20)), "posição arrastada preservada")
		_check(panel.get_node("MarginContainer/VBoxGolem/TitleLabel").mouse_default_cursor_shape == Control.CURSOR_MOVE, "handle de arraste preservado")
	ui.get("golem_close_button").pressed.emit()
	_check(not panel.visible and panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fechar libera input do mundo")
	ui.call("abrir_golem_panel")
	await _settle()
	_check(panel.visible and panel.mouse_filter == Control.MOUSE_FILTER_STOP, "reabrir mantém interação do painel")
	_reset()
	_prepare(plot)
	golem.call("set_seeding_enabled", true)
	golem.call("set_work_priority", 4)
	ui.call("_atualizar_painel_golem")
	var toggles_before_travel := toggles
	main.call("request_region_transition", &"foraging_grove", &"from_farm")
	for _frame in range(180):
		await get_tree().process_frame
		if not main.is_inside_tree() and not RegionTravelCoordinator.is_transition_in_progress():
			break
	_check(not main.is_inside_tree(), "UI da vila entra no cache")
	get_tree().root.size = Vector2i(800, 720)
	var external := get_tree().current_scene
	external.call("request_region_transition", &"farm_village", &"from_foraging_grove")
	for _frame in range(180):
		await get_tree().process_frame
		if main.is_inside_tree() and not RegionTravelCoordinator.is_transition_in_progress():
			break
	await _settle()
	ui.call("abrir_golem_panel") # Retorno do cache conserva estado, não janela aberta.
	ui.call("_atualizar_painel_golem")
	_check(get_tree().current_scene == main and toggle.button_pressed and not toggle.disabled and toggles == toggles_before_travel, "cache/resize conserva ON sem emitir toggle")
	await _test_geometry()
	_check(SaveManager.save_game(), "grava ON em arquivo QA para reabertura")
	_finish()

func _reset() -> void:
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	chest.set_contents({SEED: 3})
	for live in get_tree().get_nodes_in_group("lotes_terra"):
		_prepare(live, false)

func _prepare(live: Node, tilled: bool = true) -> void:
	live.show()
	live.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": tilled, "regado": false, "expansion_blocked": false, "pronto_para_colher": false, "tempo_restante": 0.0, "tempo_total_crescimento": 0.0})

func _expect_code(code: String) -> void:
	var before := {"work": golem.call("get_work_save_data"), "generation": golem.get("_task_generation"), "stock": chest.get_contents(), "inventory": GlobalInventory.inventario.duplicate(true), "selection": GlobalInventory.semente_selecionada, "tool": ToolManager.get_active_tool()}
	var status: Dictionary = golem.call("get_seeding_status")
	ui.call("_atualizar_painel_golem")
	_check(status["code"] == code and status_label.text == status["text"], "estado legível " + code + "; recebido=" + str(status["code"]))
	_check(before == {"work": golem.call("get_work_save_data"), "generation": golem.get("_task_generation"), "stock": chest.get_contents(), "inventory": GlobalInventory.inventario.duplicate(true), "selection": GlobalInventory.semente_selecionada, "tool": ToolManager.get_active_tool()}, "consulta/UI não muta domínio " + code)

func _test_geometry() -> void:
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	_check(screen.encloses(panel.get_global_rect()), "painel contido em " + str(screen.size) + "; rect=" + str(panel.get_global_rect()))
	_check((panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0, "fundo opaco")
	var scroll: ScrollContainer = panel.get_node("MarginContainer/VBoxGolem/ScrollContainer")
	for path in ["TitleLabel", "StatusLabel", "TalentLabel", "TaskLabel", "PriorityLabel", "SeedingToggle", "SeedSelection", "SeedSelectionStatus", "SeedingStatus", "SeedingHint", "GridPriorities", "BtnFechar"]:
		var fixed: bool = path in ["TitleLabel", "BtnFechar"]
		var control: Control = panel.get_node("MarginContainer/VBoxGolem/" + ("" if fixed else "ScrollContainer/Content/") + path)
		if not fixed and control.visible:
			scroll.ensure_control_visible(control)
			await _settle()
		_check(panel.get_global_rect().encloses(control.get_global_rect()), "controle acessível por rolagem " + path)
	for button in panel.get_node("MarginContainer/VBoxGolem/ScrollContainer/Content/GridPriorities").get_children():
		scroll.ensure_control_visible(button)
		await _settle()
		_check(panel.get_global_rect().encloses(button.get_global_rect()), "prioridade acessível")
	_check(not ui.get("debug_panel").visible and not panel.get_node("MarginContainer/VBoxGolem/ScrollContainer/Content/CountsLabel").visible, "sem F10/HUD/diagnóstico extra")

func _click(button: BaseButton) -> void:
	await _settle()
	var center := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.global_position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func _cargo() -> GolemSeedCargo:
	return golem.get("seed_cargo") as GolemSeedCargo

func _settle() -> void:
	for _frame in range(10):
		await get_tree().process_frame

func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/GolemSowerUI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("GolemSowerUISmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("GolemSowerUISmokeTest: PASS - %d verificações de marco, toggle, estados, load e geometria." % checks)
	get_tree().quit(1 if failed else 0)
