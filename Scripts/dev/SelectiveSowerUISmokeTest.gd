extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const WHEAT := "semente_basica"
const TOMATO := "semente_verao"
const BODY := "MarginContainer/VBoxGolem/ScrollContainer/Content/"
const RESOLUTIONS := [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]
var main: Node
var ui: Node
var golem: Node
var chest: VillageChest
var plot: Node
var panel: PanelContainer
var scroll: ScrollContainer
var wheat: Button
var tomato: Button
var toggle: CheckButton
var selection_label: Label
var checks := 0
var failed := false
var toggles := 0
var choices := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("SelectiveSowerUISmokeTest: exige APPDATA isolado em Builds/QA.")
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	GlobalInventory.set_inventory_contents({WHEAT: 7, TOMATO: 5, "agua": 2})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	# Fixture intencional: ambas as escolhas pessoais ficam não vazias para
	# provar independência da UI. O load deve restaurar a exclusividade vigente.
	GlobalInventory.semente_selecionada = WHEAT
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await _settle()
	ui = main.get_node("UI")
	golem = main.get_node("Golem")
	chest = main.get_node("VillageChest")
	plot = main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	panel = ui.get("golem_panel")
	scroll = panel.get_node("MarginContainer/VBoxGolem/ScrollContainer")
	wheat = ui.get("golem_seed_wheat_button")
	tomato = ui.get("golem_seed_tomato_button")
	toggle = ui.get("golem_seeding_toggle")
	selection_label = ui.get("golem_seed_selection_status")
	(golem.get("_think_timer") as Timer).stop()
	golem.set_physics_process(false) # Fixtures da UI não executam retirada/plantio de domínio.
	toggle.toggled.connect(func(_value): toggles += 1)
	wheat.pressed.connect(func(): choices += 1)
	tomato.pressed.connect(func(): choices += 1)
	if "--verify-selective-ui-reopen" in OS.get_cmdline_user_args():
		await _reopen()
		return
	_reset()
	ui.call("abrir_golem_panel")
	await _settle()
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
	_expect_selection("locked")
	await _click(tomato)
	_check(choices == 0 and _selected() == WHEAT and not toggle.button_pressed, "gate bloqueia escolha sem autorligar")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	_expect_selection("")
	var personal := _personal()
	await _click(tomato)
	_check(_selected() == TOMATO and tomato.button_pressed and not wheat.button_pressed, "clique escolhe somente Tomate")
	_check(not toggle.button_pressed and toggles == 0 and golem.get("work_priority") == 0, "escolher não liga habilidade nem muda prioridade")
	_check(_personal() == personal, "escolha independe da semente/ferramenta/Mochila pessoal")
	await _click(wheat)
	_check(_selected() == WHEAT and wheat.button_pressed and not tomato.button_pressed, "clique escolhe somente Trigo")
	_check(_personal() == personal and not toggle.button_pressed, "segunda escolha continua independente e OFF")
	ui.call("_on_golem_seed_selected", "semente_inverno")
	_check(_selected() == WHEAT and _personal() == personal and not toggle.button_pressed, "handler não amplia whitelist nem autorliga")
	for seed_id in [WHEAT, TOMATO]:
		golem.call("set_selected_seed_id", seed_id)
		golem.call("set_seeding_enabled", true)
		_prepare(plot)
		chest.set_contents({WHEAT: 3, TOMATO: 4})
		SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
		_expect_status("ready", seed_id)
		var other_seed: String = TOMATO if seed_id == WHEAT else WHEAT
		chest.set_contents({other_seed: 4})
		_expect_status("no_seeds", seed_id)
		_check(_personal() == personal and _selected() == seed_id, "sem fallback/Mochila para " + seed_id)
		chest.set_contents({WHEAT: 3, TOMATO: 4})
		SeasonManager.estacao_atual = SeasonManager.Estacao.VERAO
		_expect_status("season" if seed_id == WHEAT else "ready", seed_id)
		SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO
		_expect_status("season", seed_id)
		SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
		golem.set("state", "MOVING_TO_SEED_CHEST")
		await _settle()
		_check(wheat.disabled and tomato.disabled, "refresh de frame bloqueia ida sem depender de consulta de teste")
		_expect_selection("seed_job")
		var previous_choices := choices
		await _click(tomato if seed_id == WHEAT else wheat)
		_check(choices == previous_choices and _selected() == seed_id, "ida sem cargo recusa clique " + seed_id)
		ui.call("_on_golem_seed_selected", TOMATO if seed_id == WHEAT else WHEAT)
		_check(_selected() == seed_id, "handler revalida tarefa sem cargo " + seed_id)
		golem.set("state", "IDLE")
		_check(_cargo().take_from_chest(chest, Vector2i(0, 0), seed_id), "cargo real " + seed_id)
		for state in ["MOVING_TO_SEED_PLOT", "PLANTING_SEED", "MOVING_TO_SEED_RETURN", "RETURNING_SEED", "IDLE"]:
			golem.set("state", state)
			_expect_selection("seed_cargo")
			ui.call("_on_golem_seed_selected", TOMATO if seed_id == WHEAT else WHEAT)
			_check(_selected() == seed_id and _cargo().get_item_id() == seed_id, "cargo mantém ID/bloqueio " + state)
		golem.set("state", "IDLE")
		golem.call("set_work_priority", 4)
		_expect_selection("seed_cargo")
		var before_chest := chest.get_contents()
		await _click(toggle)
		_check(not toggle.button_pressed and not golem.get("seeding_enabled") and _cargo().is_return_pending(), "OFF continua permitido com cargo pausado " + seed_id)
		_check(chest.get_contents() == before_chest and _cargo().get_item_id() == seed_id, "OFF não deposita/converte remotamente " + seed_id)
		_expect_selection("seed_cargo")
		_reset()
		ui.call("abrir_golem_panel")
	_reset()
	ui.call("abrir_golem_panel")
	golem.call("set_selected_seed_id", TOMATO)
	var stock := chest.get_contents()
	var commands := Vector2i(choices, toggles)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	_check(SaveManager.call("_apply_save_data", saved), "load completo selecionado")
	_check(not panel.visible and not get_tree().paused, "load fecha painel sem pausar mundo")
	ui.call("abrir_golem_panel")
	await _settle()
	_check(_selected() == TOMATO and tomato.button_pressed and not wheat.button_pressed and not toggle.button_pressed, "reabrir após load consulta escolha OFF")
	_check(SaveManager.call("_apply_save_data", saved), "replay selecionado")
	ui.call("abrir_golem_panel")
	await _settle()
	_check(_chest_matches(stock), "load/replay conserva IDs e quantidades exatas do baú; recebido=" + str(chest.get_contents()))
	_check(Vector2i(choices, toggles) == commands, "load/replay/refresh não emitem comandos; recebido=" + str(Vector2i(choices, toggles)))
	_check(GlobalInventory.inventario == personal["inventory"], "load/replay conserva inventário pessoal salvo; recebido=" + str(GlobalInventory.inventario))
	_check(GlobalInventory.semente_selecionada == WHEAT and GlobalInventory.semente_selecionada == saved["inventory"]["semente_selecionada"] and ToolManager.get_active_tool() == ToolManager.ToolType.NONE, "load restaura semente pessoal e limpa ferramenta pela política anterior; recebido=" + str(_personal()))
	# As verificações seguintes partem da seleção normalizada pelo load,
	# sem atribuir essa normalização ao seletor do golem.
	personal = _personal()
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await _settle()
		for presentation in ["wheat", "tomato", "locked", "seed_job", "seed_cargo"]:
			_reset()
			golem.call("set_selected_seed_id", TOMATO if presentation in ["tomato", "seed_cargo"] else WHEAT)
			if presentation == "locked":
				GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
			elif presentation == "seed_job":
				golem.set("state", "MOVING_TO_SEED_CHEST")
			elif presentation == "seed_cargo":
				_cargo().take_from_chest(chest, Vector2i(0, 0), TOMATO)
				golem.call("set_work_priority", 4)
			ui.call("_atualizar_painel_golem")
			_check(wheat.disabled == (presentation in ["locked", "seed_job", "seed_cargo"]) and wheat.button_pressed != tomato.button_pressed, "apresentação exclusiva/bloqueada " + presentation)
			await _geometry()
			scroll.ensure_control_visible(panel.get_node(BODY + "SeedSelection"))
			await _settle()
			await _capture("selective_%d_%d_%s" % [resolution.x, resolution.y, presentation])
		panel.position = Vector2(25, 20)
		panel.call("_queue_layout")
		await _settle()
		_check(panel.position.is_equal_approx(Vector2(25, 20)), "arraste preservado ao recalcular")
	_reset()
	golem.call("set_selected_seed_id", TOMATO)
	ui.call("_atualizar_painel_golem")
	await _key(KEY_2)
	await _click_at(Vector2(4, 4))
	_check(_personal() == personal and panel.visible, "modal bloqueia atalho e clique de fundo")
	ui.get("golem_close_button").pressed.emit()
	_check(not panel.visible and panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and not get_tree().paused, "Fechar libera mundo sem pausa")
	ui.call("abrir_golem_panel")
	_check(panel.visible and panel.mouse_filter == Control.MOUSE_FILTER_STOP, "reabrir restaura modal")
	golem.call("set_work_priority", 4)
	golem.call("set_selected_seed_id", TOMATO)
	main.call("request_region_transition", &"foraging_grove", &"from_farm")
	await _travel()
	_check(not main.is_inside_tree() and not panel.visible, "viagem fecha painel antes/cache")
	ui.call("_on_golem_seed_selected", WHEAT)
	ui.call("_on_golem_seeding_toggled", true)
	ui.call("abrir_golem_panel")
	_check(_selected() == TOMATO and not golem.get("seeding_enabled") and not panel.visible, "UI cacheada não comanda/reabre")
	get_tree().root.size = Vector2i(800, 600)
	get_tree().current_scene.call("request_region_transition", &"farm_village", &"from_foraging_grove")
	await _travel()
	ui.call("abrir_golem_panel")
	await _settle()
	_check(get_tree().current_scene == main and tomato.button_pressed and not toggle.button_pressed and Vector2i(choices, toggles) == commands, "cache/resize conserva escolha OFF sem sinal")
	_check(_personal() == personal and chest.get_contents() == stock, "viagem não gasta recursos nem seleções pessoais")
	_check(SaveManager.save_game(), "grava escolha OFF em arquivo QA")
	_finish()

func _reopen() -> void:
	_check(SaveManager.load_game(), "novo processo lê arquivo QA")
	_check(_selected() == TOMATO, "novo processo conserva Tomate")
	_check(not golem.get("seeding_enabled"), "novo processo conserva OFF")
	_check(GroveExpedition.restored, "novo processo conserva gate")
	ui.call("abrir_golem_panel")
	await _settle()
	_check(tomato.button_pressed and not wheat.button_pressed and not tomato.disabled, "seletor representa escolha persistida")
	_check(not toggle.button_pressed and not toggle.disabled, "controle ON/OFF não autorliga")
	_check(choices == 0 and toggles == 0 and not _cargo().has_seed(), "reabertura não emite comando nem inventa cargo")
	_check(_chest_matches({WHEAT: 3, TOMATO: 4}), "reabertura mantém estoque dos dois IDs")
	_finish()

func _reset() -> void:
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	chest.set_contents({WHEAT: 3, TOMATO: 4})
	for live in get_tree().get_nodes_in_group("lotes_terra"):
		_prepare(live, false)
	_prepare(plot)

func _prepare(live: Node, tilled: bool = true) -> void:
	live.show()
	live.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": tilled, "regado": false, "expansion_blocked": false, "pronto_para_colher": false, "tempo_restante": 0.0, "tempo_total_crescimento": 0.0})

func _expect_selection(reason: String) -> void:
	var before := _snapshot()
	var status: Dictionary = golem.call("get_seed_selection_status")
	ui.call("_atualizar_painel_golem")
	_check(status.get("reason") == reason and status.get("can_change") == (reason == ""), "razão consultável " + reason)
	_check(wheat.disabled == (reason != "") and tomato.disabled == (reason != ""), "ambas escolhas refletem bloqueio " + reason)
	_check(selection_label.text != "" and (reason == "" or selection_label.text == wheat.tooltip_text), "motivo visível/tooltip " + reason)
	_check(_snapshot() == before, "consulta/refresh não mutam domínio " + reason)

func _expect_status(code: String, seed_id: String) -> void:
	var before := _snapshot()
	ui.call("_atualizar_painel_golem")
	var status: Dictionary = golem.call("get_seeding_status")
	_check(status.get("code") == code and status.get("selected_seed_id") == seed_id and ui.get("golem_seeding_status").text == status.get("text"), "estado/ID atual " + code + "/" + seed_id)
	_check(_snapshot() == before, "UI consultiva " + code)

func _geometry() -> void:
	await _settle()
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	_check(screen.encloses(panel.get_global_rect()), "painel cabe em " + str(screen.size))
	_check((panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0, "painel opaco")
	for fixed in ["TitleLabel", "BtnFechar"]:
		_check(panel.get_global_rect().encloses(panel.get_node("MarginContainer/VBoxGolem/" + fixed).get_global_rect()), "fixo visível " + fixed)
	for path in ["SeedingToggle", "SeedSelection", "SeedSelectionStatus", "SeedingStatus", "SeedingHint", "AcceleratorAction", "GridPriorities"]:
		var control: Control = panel.get_node(BODY + path)
		scroll.ensure_control_visible(control)
		await _settle()
		_check(scroll.get_global_rect().encloses(control.get_global_rect()), "controle alcançável " + path)
	_check(panel.get_node("MarginContainer/VBoxGolem/TitleLabel").mouse_default_cursor_shape == Control.CURSOR_MOVE and not get_tree().paused, "arraste e mundo rodando preservados")

func _snapshot() -> Dictionary:
	return {"work": golem.call("get_work_save_data"), "generation": golem.get("_task_generation"), "stock": chest.get_contents(), "personal": _personal(), "commands": Vector2i(choices, toggles)}

func _personal() -> Dictionary:
	return {"inventory": GlobalInventory.inventario.duplicate(true), "selection": GlobalInventory.semente_selecionada, "tool": ToolManager.get_active_tool()}

func _chest_matches(expected: Dictionary) -> bool:
	# JSON representa números como float; VillageChest preserva esse tipo no
	# load. Comparar contrato de IDs/quantidades, sem exigir tipo interno int.
	var contents := chest.get_contents()
	if contents.size() != expected.size():
		return false
	for item_id in expected:
		if not contents.has(item_id) or contents[item_id] != expected[item_id] or chest.get_item_quantity(item_id) != int(expected[item_id]):
			return false
	return true

func _selected() -> String:
	return golem.call("get_selected_seed_id")

func _cargo() -> GolemSeedCargo:
	return golem.get("seed_cargo") as GolemSeedCargo

func _click(button: BaseButton) -> void:
	scroll.ensure_control_visible(button)
	await _settle()
	await _click_at(button.get_global_rect().get_center())

func _click_at(center: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.global_position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await _settle()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	await _settle()

func _settle() -> void:
	for _frame in range(10):
		await get_tree().process_frame

func _travel() -> void:
	for _frame in range(180):
		await get_tree().process_frame
		if not RegionTravelCoordinator.is_transition_in_progress():
			break
	await _settle()

func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/SelectiveSowerUI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SelectiveSowerUISmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("SelectiveSowerUISmokeTest: PASS - %d verificações de escolha, bloqueio, independência, load/cache e layout." % checks)
	get_tree().quit(1 if failed else 0)
