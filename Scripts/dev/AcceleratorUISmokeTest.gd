extends Node

# Exercícios sintéticos: não homologam gesto físico, arte ou equilíbrio.
const MAIN := preload("res://Scenes/Main.tscn")
const ITEM := "pocao_aceleradora"
const BODY := "MarginContainer/VBoxGolem/ScrollContainer/Content/"
var home: Node2D
var ui: Node
var golem: Node
var panel: PanelContainer
var scroll: ScrollContainer
var action: Button
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA QA isolado")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	ui = home.get_node("UI")
	golem = home.get_node("Golem")
	panel = ui.get("golem_panel")
	scroll = panel.get_node("MarginContainer/VBoxGolem/ScrollContainer")
	action = ui.get("golem_accelerator_action")
	golem.set_work_priority(4)
	(golem.get("_think_timer") as Timer).stop()
	GlobalInventory.set_inventory_contents({ITEM: 2, "semente_basica": 5})
	home.get_node("VillageChest").set_contents({ITEM: 20})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var tool := ToolManager.get_active_tool()
	ui.abrir_golem_panel()
	await _settle()
	var before: Dictionary = golem.get_work_save_data()
	ui._atualizar_painel_golem()
	_check(golem.get_work_save_data() == before and GlobalInventory.get_item_quantity(ITEM) == 2, "consulta não altera estado/estoque")
	_check(ui.get("modal_blocker").visible and panel.mouse_filter == Control.MOUSE_FILTER_STOP, "modal ativo ao abrir")
	await _click(action)
	_check(golem.get_accelerator_status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 2, "clique GUI prepara sem gastar; status=" + str(golem.get_accelerator_status()) + "; rect=" + str(action.get_global_rect()))
	_check(ToolManager.get_active_tool() == tool and home.selected_consumable == "", "preparo mantém ferramenta sem mira física")
	ui._atualizar_painel_golem()
	_check(action.text == "Cancelar preparo" and not action.disabled, "ação contextual de cancelamento")
	await _key(KEY_SPACE)
	await _key(KEY_4)
	_check(ToolManager.get_active_tool() == tool, "atalhos do modal não mudam ferramenta/pesca")
	var background: Button = ui.get("tool_watering_can_button")
	await _click_at(background.get_global_rect().get_center())
	_check(not panel.get_global_rect().has_point(background.get_global_rect().get_center()) and ToolManager.get_active_tool() == tool, "clique em ferramenta de fundo não atravessa modal")
	var player: PlayerAvatar = home.get_node("PlayerAvatar")
	var destination := player.get_requested_destination()
	await _click_at(Vector2(5, get_viewport().get_visible_rect().size.y - 5))
	_check(player.get_requested_destination() == destination and not player.has_active_destination(), "clique no mundo não movimenta personagem com painel aberto")
	await _key(KEY_ESCAPE)
	_check(not panel.visible and not ui.get("modal_blocker").visible and golem.get_accelerator_status()["state"] == "prepared", "Escape fecha sem cancelar ordem")
	ui.abrir_golem_panel()
	await _settle()
	await _click(action)
	_check(golem.get_accelerator_status()["state"] == "none" and GlobalInventory.get_item_quantity(ITEM) == 2 and golem.get_work_priority() == 4, "cancelamento GUI gratuito não retoma trabalho")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = "semente_basica"
	await _click(action)
	_check(GlobalInventory.semente_selecionada == "semente_basica", "preparo também conserva semente selecionada")
	golem.cancel_accelerator_preparation()
	GlobalInventory.inventario.erase(ITEM)
	ui._atualizar_painel_golem()
	_check(action.disabled and "Mochila: 0" in ui.get("golem_accelerator_stock").text, "baú não fornece estoque pessoal nem habilita preparo")
	GlobalInventory.set_inventory_contents({ITEM: 2, "semente_basica": 5})
	for resolution in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		for code in ["none", "prepared", "active"]:
			var work: Dictionary = GolemWorkState.default_data()
			work["work_priority"] = 4
			work["accelerator_prepared"] = code == "prepared"
			work["accelerator_active"] = code == "active"
			work["harvest_delivery_started"] = code == "active"
			work["harvest_cargo"] = {"trigo": 1} if code == "active" else {}
			_check(golem.load_work_save_data(work, false), "fixture válido " + code)
			ui._atualizar_painel_golem()
			await _settle()
			await _geometry(code)
			await _capture("%d_%d_%s" % [resolution.x, resolution.y, code])
			_check(action.visible == (code != "active"), "ativo não oferece cancelamento/fila")
		panel.position = Vector2(25, 20)
		panel._queue_layout()
		await _settle()
		_check(panel.position.is_equal_approx(Vector2(25, 20)), "resize/reflow preservam posição arrastada")
		_check(panel.get_node("MarginContainer/VBoxGolem/TitleLabel").mouse_default_cursor_shape == Control.CURSOR_MOVE, "título continua handle de arraste")
	ui.fechar_golem_panel()
	var item_panel: Control = ui.get("item_use_panel")
	item_panel.show_item(ITEM)
	await _settle()
	_check(item_panel.is_card_open() and not item_panel.apply_button.visible and "painel Golem" in item_panel.description_label.text, "cartão orienta sem Aplicar livre")
	item_panel.close_card()
	var work: Dictionary = GolemWorkState.default_data()
	work["work_priority"] = 4
	work["accelerator_prepared"] = true
	golem.load_work_save_data(work, false)
	var stock := GlobalInventory.inventario.duplicate(true)
	home.request_region_transition(&"foraging_grove", &"from_farm")
	await _travel()
	_check(not home.is_inside_tree() and not golem.prepare_accelerator_delivery() and not golem.cancel_accelerator_preparation(), "UI/domínio cacheados não comandam vila fora da árvore")
	get_tree().current_scene.request_region_transition(&"farm_village", &"from_foraging_grove")
	await _travel()
	_check(get_tree().current_scene == home and golem.get_accelerator_status()["state"] == "prepared" and GlobalInventory.inventario == stock, "retorno conserva preparo sem consumo remoto")
	ui.abrir_golem_panel()
	await _settle()
	_check(action.text == "Cancelar preparo" and not action.disabled, "UI no retorno consulta autoridade corrente")
	_finish()

func _geometry(code: String) -> void:
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	_check(screen.encloses(panel.get_global_rect()), "painel contido em " + str(screen.size))
	_check((panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0, "fundo opaco")
	for fixed in ["TitleLabel", "BtnFechar"]:
		_check(panel.get_global_rect().encloses(panel.get_node("MarginContainer/VBoxGolem/" + fixed).get_global_rect()), "controle fixo " + fixed)
	for path in ["SeedingToggle", "SeedingStatus", "AcceleratorHeader", "AcceleratorRule", "AcceleratorStatus", "AcceleratorHint", "AcceleratorAction", "GridPriorities"]:
		var control: Control = panel.get_node(BODY + path)
		if control.visible:
			scroll.ensure_control_visible(control)
			await _settle()
			_check(scroll.get_global_rect().encloses(control.get_global_rect()), "controle alcançável por rolagem " + path)
	scroll.ensure_control_visible(panel.get_node(BODY + "AcceleratorStatus"))
	await _settle()
	_check(("Ativa" if code == "active" else "Preparada" if code == "prepared" else "Nenhuma") in ui.get("golem_accelerator_status").text, "estado da poção legível separado do trabalho")

func _click(button: Button) -> void:
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
	var directory := "res://Builds/QA/AcceleratorUI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("AcceleratorUISmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("AcceleratorUISmokeTest: PASS - %d verificações de preparo, estado, modal, layout e viagem." % checks)
	get_tree().quit(1 if failed else 0)
