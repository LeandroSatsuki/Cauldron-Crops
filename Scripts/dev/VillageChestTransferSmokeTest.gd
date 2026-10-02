extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
var _main: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	PocoManager.set_process(false)
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	var chest := _main.get_node("VillageChest") as VillageChest
	var ui: Node = _main.get_node("UI")
	var panel: Control = ui.get_node("VillageChestPanel")
	var quantity: SpinBox = panel.get("quantity_picker")
	var move: Button = panel.get("move_button")
	var all: Button = panel.get("move_all_button")
	var popup: Control = panel.get("transfer_popup")
	var backpack: GridContainer = panel.get("inventory_grid")
	var storage: GridContainer = panel.get("chest_grid")
	if not _test_personal_stack_view(ui, panel, chest):
		return
	GlobalInventory.inventario = {"trigo": 6, "carvao": 2, "agua": 4, "semente_basica": 3}
	chest.set_contents({"trigo": 2})
	ToolManager.force_select_fishing_rod()
	ui.call("abrir_bau_vila", chest)
	await get_tree().process_frame
	if popup.visible or _slot(backpack, "agua") != null:
		return _fail("abertura selecionou item ou exibiu agua do poco")
	for path in ["Panels/Chest", "Panels/Backpack", "TransferPopup"]:
		var surface := panel.get_node(path) as PanelContainer
		var style := surface.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null or style.bg_color.a != 1.0:
			return _fail("painel nao possui fundo opaco")
	await _capture("panels")
	var before: Dictionary = GlobalInventory.inventario.duplicate(true)
	for invalid in [["trigo", 0], ["trigo", -1], ["trigo", 7], ["", 1], ["inexistente", 1], ["agua", 1]]:
		if chest.deposit_from_personal_inventory(invalid[0], invalid[1]):
			return _fail("transferencia invalida foi aceita")
	if before != GlobalInventory.inventario or chest.get_contents() != {"trigo": 2}:
		return _fail("recusa alterou inventarios")
	var full_inventory: Dictionary = {"trigo": 98, "agua": 4}
	for index in range(11):
		full_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	GlobalInventory.set_inventory_contents(full_inventory)
	GlobalInventory.set_capacity_enforced(true)
	chest.set_contents({"trigo": 2, "novo_item": 2})
	if chest.withdraw_to_personal_inventory("trigo", 2):
		return _fail("retirada parcial alterou origem antes de validar destino")
	if GlobalInventory.get_item_quantity("trigo") != 98 or chest.get_item_quantity("trigo") != 2:
		return _fail("recusa por capacidade nao foi atomica")
	if not chest.withdraw_to_personal_inventory("trigo", 1):
		return _fail("retirada que completava pilha existente foi recusada")
	if GlobalInventory.get_item_quantity("trigo") != 99 or chest.get_item_quantity("trigo") != 1:
		return _fail("retirada aceita nao preservou o total")
	var legacy_withdrawn: Dictionary = chest.withdraw_all_to_global_inventory()
	if not legacy_withdrawn.is_empty() or chest.get_item_quantity("novo_item") != 2 or chest.get_item_quantity("trigo") != 1:
		return _fail("retirada global legada apagou itens sem espaco")
	panel.call("refresh_items", true)
	_slot(storage, "novo_item").pressed.emit()
	move.pressed.emit()
	if str(panel.get("feedback").text) != "A Mochila não tem espaço para esta quantidade.":
		return _fail("interface nao explicou a recusa por capacidade")
	panel.call("_close_transfer")
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.set_inventory_contents(before)
	chest.set_contents({"trigo": 2})
	panel.call("refresh_items", true)
	_slot(backpack, "trigo").pressed.emit()
	if not popup.visible:
		return _fail("clique no slot nao abriu popup")
	await _capture("quantity")
	quantity.get_line_edit().text = "4"
	var key := InputEventKey.new()
	key.keycode = KEY_2
	key.pressed = true
	ui.call("_input", key)
	if ToolManager.get_active_tool() != ToolManager.ToolType.FISHING_ROD:
		return _fail("campo numerico ativou ferramenta")
	move.pressed.emit()
	move.pressed.emit()
	if int(GlobalInventory.inventario["trigo"]) != 2 or chest.get_item_quantity("trigo") != 6 or popup.visible:
		return _fail("deposito parcial/duplo clique alterou total")
	_slot(storage, "trigo").pressed.emit()
	quantity.get_line_edit().text = "2"
	move.pressed.emit()
	if int(GlobalInventory.inventario["trigo"]) != 4 or chest.get_item_quantity("trigo") != 4:
		return _fail("retirada parcial falhou")
	_slot(storage, "trigo").pressed.emit()
	all.pressed.emit()
	all.pressed.emit()
	if int(GlobalInventory.inventario["trigo"]) != 8 or chest.get_item_quantity("trigo") != 0:
		return _fail("mover tudo retirando perdeu/duplicou itens")
	_slot(backpack, "carvao").pressed.emit()
	quantity.get_line_edit().text = "2"
	GlobalInventory.inventario["carvao"] = 1
	move.pressed.emit()
	if chest.get_item_quantity("carvao") != 0:
		return _fail("estoque obsoleto permitiu transferencia parcial")
	all.pressed.emit()
	if chest.get_item_quantity("carvao") != 1 or int(GlobalInventory.inventario["carvao"]) != 0:
		return _fail("mover tudo nao usou estoque atual")
	# Mover tudo transfere apenas o tipo selecionado, nao o inventario inteiro.
	if int(GlobalInventory.inventario["trigo"]) != 8 or int(GlobalInventory.inventario["semente_basica"]) != 3:
		return _fail("mover tudo afetou outros itens")
	_slot(storage, "carvao").pressed.emit()
	chest.withdraw_item("carvao", 1)
	move.pressed.emit()
	if int(GlobalInventory.inventario["carvao"]) != 0 or popup.visible:
		return _fail("retirada obsoleta gerou item")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = "semente_basica"
	_slot(backpack, "semente_basica").pressed.emit()
	all.pressed.emit()
	if GlobalInventory.semente_selecionada != "" or chest.get_item_quantity("semente_basica") != 3:
		return _fail("deposito total manteve selecao fantasma")
	_slot(backpack, "trigo").pressed.emit()
	ui.call("fechar_bau_vila")
	all.pressed.emit()
	if int(GlobalInventory.inventario["trigo"]) != 8 or popup.visible:
		return _fail("fechamento permitiu transferencia")
	ui.call("abrir_bau_vila", chest)
	_slot(backpack, "trigo").pressed.emit()
	quantity.get_line_edit().text = "6"
	move.pressed.emit()
	chest.deposit_item("peixe_comum", 2)
	ui.call("_atualizar_painel_bau_vila")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	_slot(storage, "peixe_comum").pressed.emit()
	all.pressed.emit()
	_slot(storage, "trigo").pressed.emit()
	all.pressed.emit()
	for repetition in range(2):
		if not bool(SaveManager.call("_apply_save_data", snapshot)):
			return _fail("save foi recusado")
		SaveManager.call("_refresh_ui_after_load")
		if int(GlobalInventory.inventario["trigo"]) != 2 or chest.get_item_quantity("trigo") != 6:
			return _fail("load duplicou/perdeu recursos")
		if int(GlobalInventory.inventario.get("peixe_comum", 0)) != 0 or chest.get_item_quantity("peixe_comum") != 2:
			return _fail("load duplicou item que so existia no bau ao salvar")
		if _slot(backpack, "semente_basica") != null or _slot(storage, "semente_basica") == null:
			return _fail("load nao atualizou ambas as grades")
	_slot(storage, "trigo").pressed.emit()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel.call("_input", escape)
	if popup.visible or not panel.visible:
		return _fail("Escape nao fechou apenas a transferencia")
	panel.call("_input", escape)
	if panel.visible or bool(ui.call("_tem_popup_modal_aberto")):
		return _fail("fechamento deixou bloqueio")
	_main.queue_free()
	await get_tree().process_frame
	print("VillageChestTransferSmokeTest: PASS - grades opacas, 12 slots/pilhas reais, overflow, transferencia por tipo, callbacks obsoletos, teclado e save.")
	get_tree().quit(0)


func _capture(suffix: String) -> void:
	if "--capture-chest-panel" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "user://village_chest_" + suffix + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("Preview: " + ProjectSettings.globalize_path(path))


func _slot(grid: GridContainer, item_id: String) -> Button:
	for child in grid.get_children():
		if child is Button and str(child.get_meta("item_id", "")) == item_id:
			return child as Button
	return null


func _item_slots(grid: GridContainer, item_id: String) -> Array[Button]:
	var slots: Array[Button] = []
	for child in grid.get_children():
		if child is Button and str(child.get_meta("item_id", "")) == item_id:
			slots.append(child)
	return slots


func _test_personal_stack_view(ui: Node, panel: Control, chest: VillageChest) -> bool:
	var backpack: GridContainer = panel.get("inventory_grid")
	var storage: GridContainer = panel.get("chest_grid")
	var capacity: Label = panel.get("inventory_capacity_label")
	var popup: Control = panel.get("transfer_popup")
	var quantity: SpinBox = panel.get("quantity_picker")
	GlobalInventory.set_inventory_contents({"agua": 4, "semente_basica": 0})
	chest.set_contents({"trigo": 100})
	ui.call("abrir_bau_vila", chest)
	if backpack.get_child_count() != 12 or capacity.text != "0/12 slots" or _slot(backpack, "agua") != null or _slot(backpack, "semente_basica") != null:
		return _fail_stack_view("Mochila vazia nao mostrou 12 slots reais, ou contou agua/zero")
	if _item_slots(storage, "trigo").size() != 1 or int(_slot(storage, "trigo").get_meta("quantity")) != 100 or storage.get_child_count() != 20:
		return _fail_stack_view("pilhas pessoais alteraram agrupamento do bau")
	GlobalInventory.set_inventory_contents({"trigo": 99, "agua": 4})
	panel.call("refresh_items", true)
	if _item_slots(backpack, "trigo").size() != 1 or int(_slot(backpack, "trigo").get_meta("quantity")) != 99 or capacity.text != "1/12 slots":
		return _fail_stack_view("99 unidades nao ocuparam uma pilha")
	GlobalInventory.set_inventory_contents({"trigo": 100, "agua": 4})
	panel.call("refresh_items", true)
	var wheat_slots := _item_slots(backpack, "trigo")
	if wheat_slots.size() != 2 or int(wheat_slots[0].get_meta("quantity")) != 99 or int(wheat_slots[1].get_meta("quantity")) != 1 or capacity.text != "2/12 slots" or backpack.get_child_count() != 12:
		return _fail_stack_view("100 unidades nao dividiram 99+1 em dois slots")
	wheat_slots[1].pressed.emit()
	if not popup.visible or quantity.max_value != 100 or str(panel.get("_available_label").text) != "Total do item: 100":
		return _fail_stack_view("clique na segunda pilha nao consultou total atual do item")
	panel.call("_close_transfer")
	# O item ainda existe, mas o botao antigo pertence a outra versao da grade.
	GlobalInventory.set_inventory_contents({"trigo": 99, "agua": 4})
	panel.call("refresh_items", true)
	wheat_slots[1].pressed.emit()
	if popup.visible:
		return _fail_stack_view("callback de pilha removida abriu transferencia")
	var stale_storage := _slot(storage, "trigo")
	panel.call("refresh_items", true)
	stale_storage.pressed.emit()
	if popup.visible:
		return _fail_stack_view("callback obsoleto do bau abriu transferencia")
	GlobalInventory.set_inventory_contents({"trigo": 100, "carvao": 3, "agua": 4})
	chest.set_contents({})
	panel.call("refresh_items", true)
	_item_slots(backpack, "trigo")[1].pressed.emit()
	quantity.get_line_edit().text = "1"
	panel.get("move_button").pressed.emit()
	if GlobalInventory.get_item_quantity("trigo") != 99 or chest.get_item_quantity("trigo") != 1 or _item_slots(backpack, "trigo").size() != 1 or capacity.text != "2/12 slots":
		return _fail_stack_view("deposito parcial nao atualizou pilhas/ocupacao")
	GlobalInventory.set_inventory_contents({"trigo": 100, "carvao": 3, "agua": 4})
	chest.set_contents({})
	panel.call("refresh_items", true)
	_item_slots(backpack, "trigo")[1].pressed.emit()
	panel.get("move_all_button").pressed.emit()
	if GlobalInventory.get_item_quantity("trigo") != 0 or chest.get_item_quantity("trigo") != 100 or GlobalInventory.get_item_quantity("carvao") != 3 or capacity.text != "1/12 slots":
		return _fail_stack_view("mover tudo nao preservou transferencia por tipo")
	GlobalInventory.set_inventory_contents({"trigo": 1188, "agua": 4})
	panel.call("refresh_items", true)
	if _item_slots(backpack, "trigo").size() != 12 or backpack.get_child_count() != 12 or capacity.text != "12/12 slots":
		return _fail_stack_view("Mochila cheia nao mostrou 12 pilhas")
	GlobalInventory.set_inventory_contents({"semente_basica": 1300, "trigo": 99, "agua": 4})
	panel.call("refresh_items", true)
	if backpack.get_child_count() != 15 or capacity.text != "15/12 slots · excesso legado" or not (backpack.get_parent() is ScrollContainer):
		return _fail_stack_view("overflow legado ocultou pilhas ou nao explicou excesso")
	_item_slots(backpack, "semente_basica")[13].pressed.emit()
	panel.get("move_all_button").pressed.emit()
	if GlobalInventory.get_item_quantity("semente_basica") != 0 or chest.get_item_quantity("semente_basica") != 1300 or GlobalInventory.get_item_quantity("trigo") != 99 or capacity.text != "1/12 slots":
		return _fail_stack_view("deposito do overflow perdeu recursos ou nao liberou slots")
	# Limites do catalogo, nao um 99 duplicado na UI.
	Database.itens["trigo"]["stack_maximo"] = 25
	GlobalInventory.set_inventory_contents({"trigo": 26, "agua": 4})
	panel.call("refresh_items", true)
	var custom_slots := _item_slots(backpack, "trigo")
	var respects_custom_limit: bool = custom_slots.size() == 2 and int(custom_slots[0].get_meta("quantity")) == 25 and int(custom_slots[1].get_meta("quantity")) == 1
	Database.itens["trigo"].erase("stack_maximo")
	if not respects_custom_limit:
		return _fail_stack_view("painel ignorou stack_maximo do catalogo")
	ui.call("fechar_bau_vila")
	return true


func _fail_stack_view(message: String) -> bool:
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("VillageChestTransferSmokeTest: FAIL - " + message)
	get_tree().quit(1)
