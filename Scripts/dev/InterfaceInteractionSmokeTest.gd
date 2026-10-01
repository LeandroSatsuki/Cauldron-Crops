extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_inventory: Dictionary = GlobalInventory.inventario.duplicate(true)
	var original_seed: String = GlobalInventory.semente_selecionada
	var original_capacity: bool = GlobalInventory.is_capacity_enforced()
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var ui: Node = main.get_node_or_null("UI")
	if ui == null:
		_fail("UI principal nao encontrada")
		return
	GlobalInventory.set_inventory_contents({"trigo": 100, "carvao": 99, "agua": 7})
	ui.call("atualizar_inventario_visual")
	await get_tree().process_frame
	var inventory_bar: HBoxContainer = ui.get("inventory_bar") as HBoxContainer
	var capacity_label: Label = ui.get("inventory_capacity_label") as Label
	if inventory_bar == null or inventory_bar.get_child_count() != GlobalInventory.get_slot_capacity():
		_fail("Mochila nao renderizou os 12 slots fixos")
		return
	var first_slot: Node = inventory_bar.get_child(0)
	var second_slot: Node = inventory_bar.get_child(1)
	var third_slot: Node = inventory_bar.get_child(2)
	var empty_slot: BaseButton = inventory_bar.get_child(3) as BaseButton
	if str(first_slot.get("item_id")) != "trigo" or int(first_slot.get("quantidade")) != 99:
		_fail("primeira pilha visual nao respeitou o stack de 99")
		return
	if str(second_slot.get("item_id")) != "trigo" or int(second_slot.get("quantidade")) != 1:
		_fail("excedente visual nao ocupou o segundo slot")
		return
	if str(third_slot.get("item_id")) != "carvao" or int(third_slot.get("quantidade")) != 99:
		_fail("terceiro slot visual nao preservou o carvao")
		return
	if empty_slot == null or not empty_slot.disabled or capacity_label == null or capacity_label.text != "3/12":
		_fail("slots vazios ou indicador discreto de ocupacao ficaram incorretos")
		return
	if GlobalInventory.is_capacity_enforced() != original_capacity:
		_fail("representacao visual ativou a capacidade da Mochila")
		return
	if not _test_split_seed_selection(ui, inventory_bar, main.get_node("VillageChest") as VillageChest):
		return
	GlobalInventory.inventario["trigo"] = 1
	GlobalInventory.inventario["semente_basica"] = 1
	GlobalInventory.semente_selecionada = ""
	ToolManager.force_select_tool(ToolManager.ToolType.FISHING_ROD)
	ui.call("_on_slot_clicado", "trigo", false, null)
	if ToolManager.get_active_tool() != ToolManager.ToolType.FISHING_ROD or GlobalInventory.semente_selecionada != "" or str(ui.get("item_focado_id")) != "":
		_fail("item comum alterou o modo de interacao")
		return
	var wheat_before_right_click := int(GlobalInventory.inventario.get("trigo", 0))
	var coins_before_right_click := int(EconomyManager.moedas)
	ui.call("_on_slot_clicado", "trigo", true, null)
	if int(GlobalInventory.inventario.get("trigo", 0)) != wheat_before_right_click or int(EconomyManager.moedas) != coins_before_right_click:
		_fail("clique direito ainda vende itens no runtime da V0")
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
	ui.call("abrir_debug_panel")
	if debug_panel != null and debug_panel.visible:
		_fail("painel de debug abriu sem habilitacao explicita")
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
	var release_hidden_paths: Array[String] = [
		"StatusPanel/MoedasLabel",
		"StatusPanel/SementeLabel",
		"StatusPanel/CapacityLabel",
		"StatusPanel/ChestStatusLabel",
		"LeftPanel/DormirButton",
		"LeftPanel/AbrirSkillTreeButton",
		"LeftPanel/AbrirQuestsButton",
		"LeftPanel/HeaderLoja",
		"LeftPanel/GridSementes",
		"LeftPanel/HeaderUpgrades",
		"LeftPanel/ComprarCosmeticoButton",
		"SellMenu"
	]
	for path in release_hidden_paths:
		var deferred_control := ui.get_node_or_null(path) as Control
		if deferred_control == null or deferred_control.visible:
			_fail("controle adiado continua acessivel na V0: %s" % path)
			return

	GlobalInventory.inventario = original_inventory
	GlobalInventory.semente_selecionada = original_seed
	GlobalInventory.set_capacity_enforced(original_capacity)
	ToolManager.clear_tool()
	main.queue_free()
	await get_tree().process_frame
	print("InterfaceInteractionSmokeTest: PASS - inventario, ferramentas, F10, objetivos e lojas respeitam a UX da V0.")
	get_tree().quit(0)


func _test_split_seed_selection(ui: Node, bar: HBoxContainer, chest: VillageChest) -> bool:
	var original_chest: Dictionary = chest.get_contents()
	GlobalInventory.set_inventory_contents({"semente_basica": 100, "agua": 7})
	ToolManager.force_select_fishing_rod()
	ui.call("atualizar_inventario_visual")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	bar.get_child(1).call("_gui_input", click)
	if GlobalInventory.semente_selecionada != "semente_basica" or ToolManager.get_active_tool() != ToolManager.ToolType.NONE:
		_fail("clique na segunda pilha nao selecionou plantio exclusivo")
		return false
	if not _check_seed_highlights(bar, 2):
		return false
	bar.get_child(0).call("_gui_input", click)
	if GlobalInventory.semente_selecionada != "" or not _check_seed_highlights(bar, 0):
		_fail("clique na outra pilha nao removeu a selecao do tipo de semente")
		return false
	bar.get_child(1).call("_gui_input", click)
	if not GlobalInventory.remover_item("semente_basica", 1):
		_fail("consumo de semente falhou")
		return false
	ui.call("atualizar_inventario_visual")
	if GlobalInventory.semente_selecionada != "semente_basica" or int(bar.get_child(0).get("quantidade")) != 99 or not _check_seed_highlights(bar, 1):
		_fail("selecao nao sobreviveu ao desaparecimento da segunda pilha")
		return false
	if not chest.deposit_from_personal_inventory("semente_basica", 1):
		_fail("deposito parcial de semente falhou")
		return false
	ui.call("atualizar_inventario_visual")
	if GlobalInventory.semente_selecionada != "semente_basica" or not _check_seed_highlights(bar, 1):
		_fail("deposito parcial removeu a selecao de sementes restantes")
		return false
	if not chest.deposit_from_personal_inventory("semente_basica", 98):
		_fail("deposito das ultimas sementes falhou")
		return false
	ui.call("atualizar_inventario_visual")
	ui.call("atualizar_destaques")
	if GlobalInventory.semente_selecionada != "" or not _check_seed_highlights(bar, 0):
		_fail("deposito final deixou selecao ou destaque sem sementes")
		return false
	ToolManager.force_select_fishing_rod()
	bar.get_child(0).call("_gui_input", click)
	# Um callback antigo nao pode selecionar sementes que ja sairam da Mochila.
	ui.call("_on_slot_clicado", "semente_basica", false, null)
	if GlobalInventory.semente_selecionada != "" or ToolManager.get_active_tool() != ToolManager.ToolType.FISHING_ROD:
		_fail("slot vazio ou callback obsoleto alterou a selecao")
		return false
	chest.set_contents(original_chest)
	return true


func _check_seed_highlights(bar: HBoxContainer, expected_count: int) -> bool:
	var highlighted := 0
	for slot in bar.get_children():
		if slot.get_node("Destaque").visible:
			if str(slot.get("item_id")) != "semente_basica" or int(slot.get("quantidade")) <= 0:
				_fail("slot vazio recebeu destaque de selecao")
				return false
			highlighted += 1
	if highlighted != expected_count:
		_fail("destaque das pilhas de semente incorreto: %d/%d" % [highlighted, expected_count])
		return false
	return true


func _fail(message: String) -> void:
	ToolManager.clear_tool()
	push_error("InterfaceInteractionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
