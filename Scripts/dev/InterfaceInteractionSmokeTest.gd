extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_inventory: Dictionary = GlobalInventory.inventario.duplicate(true)
	var original_seed: String = GlobalInventory.semente_selecionada
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var ui: Node = main.get_node_or_null("UI")
	if ui == null:
		_fail("UI principal nao encontrada")
		return
	GlobalInventory.inventario["trigo"] = 1
	GlobalInventory.inventario["semente_basica"] = 1
	GlobalInventory.semente_selecionada = ""
	ToolManager.force_select_tool(ToolManager.ToolType.FISHING_ROD)
	ui.call("_on_slot_clicado", "trigo", false, null)
	if ToolManager.get_active_tool() != ToolManager.ToolType.FISHING_ROD or GlobalInventory.semente_selecionada != "" or str(ui.get("item_focado_id")) != "":
		_fail("item comum alterou o modo de interacao")
		return

	ui.call("_on_slot_clicado", "semente_basica", false, null)
	if GlobalInventory.semente_selecionada != "semente_basica" or ToolManager.get_active_tool() != ToolManager.ToolType.NONE:
		_fail("semente nao entrou no modo de plantio exclusivo")
		return
	ui.call("_on_slot_clicado", "semente_basica", false, null)
	if GlobalInventory.semente_selecionada != "":
		_fail("segundo clique na semente nao removeu a selecao")
		return
	GlobalInventory.semente_selecionada = "semente_basica"
	ToolManager.force_select_tool(ToolManager.ToolType.WATERING_CAN)
	if GlobalInventory.semente_selecionada != "":
		_fail("ferramenta nao limpou a selecao de semente")
		return

	var debug_panel: Control = ui.get("debug_panel")
	var f10 := InputEventKey.new()
	f10.keycode = KEY_F10
	f10.pressed = true
	ui.call("_input", f10)
	if debug_panel != null and debug_panel.visible:
		_fail("F10 abriu o painel de debug no runtime normal")
		return

	var objectives_panel: Control = ui.get("initial_objectives_panel")
	var objectives_toggle: Button = ui.get("initial_objectives_toggle_button")
	if objectives_panel == null or objectives_toggle == null:
		_fail("controle de minimizar objetivos nao foi criado")
		return
	ui.call("_alternar_objetivos_iniciais")
	await get_tree().process_frame
	if objectives_panel.visible:
		_fail("objetivos nao minimizaram")
		return
	ui.call("_alternar_objetivos_iniciais")
	if not objectives_panel.visible:
		_fail("objetivos nao voltaram apos minimizar")
		return
	if ui.get_node("LeftPanel/HeaderLoja").visible or ui.get_node("LeftPanel/GridSementes").visible or ui.get_node("LeftPanel/HeaderUpgrades").visible:
		_fail("lojas iniciais continuam visiveis")
		return

	GlobalInventory.inventario = original_inventory
	GlobalInventory.semente_selecionada = original_seed
	ToolManager.clear_tool()
	main.queue_free()
	await get_tree().process_frame
	print("InterfaceInteractionSmokeTest: PASS - inventario, ferramentas, F10, objetivos e lojas respeitam a UX da V0.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	ToolManager.clear_tool()
	push_error("InterfaceInteractionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
