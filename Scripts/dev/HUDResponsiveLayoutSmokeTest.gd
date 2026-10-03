extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
var _main: Node
var _ui: Node
var _checks := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Regeneração do poço não pertence à regressão de geometria/estoque da HUD.
	PocoManager.set_process(false)
	ToolManager.clear_tool()
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = RESOLUTIONS[0]
	await get_tree().process_frame
	GlobalInventory.apply_backpack_progress(["first_herbarium", "foraging_grove_collection"])
	GlobalInventory.set_inventory_contents({"trigo": 1980, "semente_basica": 100, "carvao": 99, "rama_encantada": 99, "palha_rara": 99})
	GlobalInventory.semente_selecionada = ""
	var stock_before: Dictionary = GlobalInventory.inventario.duplicate(true)
	_main = MAIN_SCENE.instantiate()
	if "--baseline-layout" in OS.get_cmdline_user_args():
		# Reproduzir geometria histórica sem modificar arquivos de produção.
		_main.get_node("UI/HUDLayout").free()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	_ui = _main.get_node("UI")
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await _settle_layout()
		if not _test_geometry(resolution):
			return
		if not await _test_all_pages():
			return
		if not _expect(GlobalInventory.inventario == stock_before and GlobalInventory.get_slot_capacity() == 20, "resize/páginas alteraram estoque/capacidade"):
			return
		_ui.set("_inventory_page", 0)
		_ui.call("_refresh_inventory_page")
		await _settle_layout()
		await _capture("hud_%d" % resolution.x)
	# A pilha de sementes no overflow continua selecionável por páginas.
	var bar: HBoxContainer = _ui.get_node("InventoryBar")
	var seed_slot: Node = bar.get_child(20)
	var selected_page := floori(20.0 / int(_ui.get("_inventory_page_size")))
	_ui.set("_inventory_page", selected_page)
	_ui.call("_refresh_inventory_page")
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	seed_slot.call("_gui_input", click)
	if not _expect(seed_slot.visible and GlobalInventory.semente_selecionada == "semente_basica" and ToolManager.get_active_tool() == ToolManager.ToolType.NONE, "semente paginada perdeu exclusividade com ferramenta"):
		return
	var first_visible := int(_ui.get("_inventory_page")) * int(_ui.get("_inventory_page_size"))
	get_tree().root.size = Vector2i(1280, 720)
	await _settle_layout()
	if not _expect(bar.get_child(first_visible).visible, "resize perdeu o ponto de leitura da página"):
		return
	var objectives: Control = _ui.get_node("InitialObjectivesPanel")
	var toggle: Button = _ui.get("initial_objectives_toggle_button")
	objectives.position = Vector2(80, 180) # Mesmo contrato de posição usado pelo UIDragHelper.
	await _settle_layout()
	if not _expect(objectives.position.is_equal_approx(Vector2(80, 180)) and objectives.get_global_rect().encloses(toggle.get_global_rect()), "layout reposicionou painel arrastado ou deixou botão para trás"):
		return
	toggle.pressed.emit()
	if not _expect(not objectives.visible and toggle.visible, "minimizar removeu acesso ao objetivo"):
		return
	toggle.pressed.emit()
	get_tree().root.size = Vector2i(800, 720)
	await _settle_layout()
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	if not _expect(objectives.visible and screen.encloses(objectives.get_global_rect()) and screen.encloses(toggle.get_global_rect()), "objetivos/controle saíram da tela após resize"):
		return
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_inventory_contents({"trigo": 1})
	_ui.call("verificar_e_atualizar_inventario")
	await _settle_layout()
	if not _expect(bar.get_child_count() == 12 and _ui.get("inventory_capacity_label").text == "1/12" and int(_ui.get("_inventory_page")) < ceili(12.0 / int(_ui.get("_inventory_page_size"))), "refresh de capacidade/estoque manteve página inválida"):
		return
	while int(_ui.get("_inventory_page")) > 0:
		_ui.get("inventory_previous_button").pressed.emit()
	if not _expect(bar.get_child(0).visible and bar.get_child(0).get("quantidade") == 1, "item restante ficou inacessível após refresh"):
		return
	get_tree().root.size = Vector2i(1280, 720)
	await _settle_layout()
	var travel_stock: Dictionary = GlobalInventory.inventario.duplicate(true)
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	get_tree().root.size = Vector2i(1920, 1080)
	await _settle_layout()
	if not await _travel(&"farm_village", &"from_foraging_grove"):
		return
	await _settle_layout()
	if not _expect(_ui.is_inside_tree() and int(_ui.get("_inventory_page_size")) == 12 and GlobalInventory.inventario == travel_stock, "HUD voltou do cache com largura antiga ou estoque alterado"):
		return
	print("HUDResponsiveLayoutSmokeTest: PASS - %d verificações; cinco resoluções, páginas/overflow, seleção, resize, objetivos e estoque." % _checks)
	get_tree().quit(0)


func _test_geometry(resolution: Vector2i) -> bool:
	var backdrop: Control = _ui.get_node("InventoryBackdrop")
	var objectives: Control = _ui.get_node("InitialObjectivesPanel")
	if not _expect(not backdrop.get_global_rect().intersects(objectives.get_global_rect()), "Mochila sobrepôs objetivos em %s" % resolution):
		return false
	var tools: Control = _ui.get_node("ToolBarPanel")
	if not _expect(not tools.get_global_rect().intersects(objectives.get_global_rect()), "ferramentas sobrepuseram objetivos em %s" % resolution):
		return false
	for button: Control in tools.get_children():
		if not _expect(tools.get_global_rect().encloses(button.get_global_rect()) and not button.get_global_rect().intersects(objectives.get_global_rect()), "botão de ferramenta cortado/sobreposto em %s" % resolution):
			return false
	if resolution.x <= 1024:
		for index in range(tools.get_child_count()):
			var button: Button = tools.get_child(index)
			if not _expect(button.text.replace("> ", "") == str(index + 1) and not button.tooltip_text.is_empty(), "texto compacto foi sobrescrito pela atualização da HUD"):
				return false
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	for node_name in ["InventoryBackdrop", "InventoryTitle", "InventoryCapacityLabel", "InventoryPreviousButton", "InventoryPageLabel", "InventoryNextButton", "ToolBarPanel", "InitialObjectivesPanel"]:
		var control: Control = _ui.get_node(node_name)
		if not _expect(screen.encloses(control.get_global_rect()), "%s fora da tela em %s: %s / %s" % [node_name, resolution, control.get_global_rect(), screen]):
			return false
	if not _expect(int(_ui.get("_inventory_page_size")) == 12 if resolution.x >= 1920 else int(_ui.get("_inventory_page_size")) < 12, "quantidade visível não adaptou à largura"):
		return false
	return true


func _test_all_pages() -> bool:
	var bar: HBoxContainer = _ui.get_node("InventoryBar")
	_ui.set("_inventory_page", 0)
	_ui.call("_refresh_inventory_page")
	var reached: Dictionary = {}
	for _page in range(bar.get_child_count()):
		await _settle_layout()
		for index in range(bar.get_child_count()):
			var slot: Control = bar.get_child(index)
			if not slot.visible:
				continue
			reached[index] = true
			if not _expect(slot.size.x >= 60.0 and _ui.get_node("InventoryBackdrop").get_global_rect().encloses(slot.get_global_rect()), "slot acessível ficou cortado/encolhido"):
				return false
		if _ui.get("inventory_next_button").disabled:
			break
		_ui.get("inventory_next_button").pressed.emit()
	return _expect(reached.size() == 25 and bar.get_child_count() == 25, "páginas perderam pilhas do overflow legado")


func _settle_layout() -> void:
	for _frame in range(4):
		await get_tree().process_frame


func _travel(region_id: StringName, entry_id: StringName) -> bool:
	if not _expect(get_tree().current_scene.call("request_region_transition", region_id, entry_id, &"hud_test"), "viagem recusada"):
		return false
	for _frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress():
			break
	return _expect(RegionTravelCoordinator.get_active_region_id() == String(region_id), "viagem não concluiu")


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/HUDResponsive/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("HUDResponsiveLayoutSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
