extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const GROVE_SCENE := preload("res://Scenes/ForagingGroveRegion.tscn")
var _main: Node
var _grove: Node
var _ui: Node
var _chest: VillageChest

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	_ui = _main.get_node("UI")
	_chest = _main.get_node("VillageChest")
	_grove = GROVE_SCENE.instantiate()
	get_tree().root.add_child(_grove)
	_grove.process_mode = Node.PROCESS_MODE_DISABLED
	if not _test_balance_and_milestones():
		return
	if not _test_real_actions():
		return
	_grove.hide()
	_grove.get_node("TitleLayer").hide()
	_main.get_node("MainCamera").make_current()
	if not await _test_pages_and_transfer():
		return
	if not await _test_persistence():
		return
	_grove.free()
	_main.free()
	print("BackpackExpansionSmokeTest: PASS - 12/16/20, marcos deterministas, recusa, paginas, transferencia e save v3/v4 atomico.")
	get_tree().quit(0)

func _test_balance_and_milestones() -> bool:
	if not _expect(GlobalInventory.get_slot_capacity() == 12 and GlobalInventory.is_capacity_enforced(), "baseline inicial mudou"):
		return false
	# Variedade real: quatro sementes, quatro culturas, carvao e peixe = 10.
	var expedition := {"semente_basica": 10, "semente_verao": 10, "semente_outono": 10, "semente_inverno": 10,
		"trigo": 99, "tomate_sol": 99, "abobora_sombria": 99, "raiz_gelida": 99, "carvao": 1, "peixe_comum": 1, "agua": 999}
	GlobalInventory.set_inventory_contents(expedition)
	if not _expect(GlobalInventory.get_used_slot_count() == 10 and GlobalInventory.try_add_items({"escama_brilhante": 1, "fragmento_celestial": 1}).success, "expedicao de 12 pilhas nao cabe"):
		return false
	if not _expect(not GlobalInventory.try_add_items({"rama_encantada": 1}).success, "13a variedade ignorou limite"):
		return false
	for order in [["first_herbarium", "foraging_grove_collection"], ["foraging_grove_collection", "first_herbarium"]]:
		GlobalInventory.apply_backpack_progress([])
		for index in range(order.size()):
			if not _expect(GlobalInventory.award_backpack_milestone(order[index]) and GlobalInventory.get_slot_capacity() == 16 + index * 4, "marcos nao sao independentes"):
				return false
			if not _expect(not GlobalInventory.award_backpack_milestone(order[index]), "marco duplicado foi premiado"):
				return false
	if not _expect(not GlobalInventory.award_backpack_milestone("unknown"), "marco desconhecido concedeu slots"):
		return false
	var external_copy: Array[String] = GlobalInventory.get_backpack_milestones()
	external_copy.clear()
	if not _expect(GlobalInventory.get_slot_capacity() == 20, "consulta permitiu mutacao externa"):
		return false
	for milestones in [[], ["first_herbarium"], ["first_herbarium", "foraging_grove_collection"]]:
		GlobalInventory.apply_backpack_progress(milestones)
		var capacity: int = GlobalInventory.get_slot_capacity()
		GlobalInventory.set_inventory_contents({"trigo": capacity * 99 - 1})
		if not _expect(GlobalInventory.try_add_item("trigo", 2).accepted == 1 and not GlobalInventory.can_accept_items({"carvao": 1}), "limite dinamico/aceitacao parcial falhou"):
			return false
		GlobalInventory.remover_item("trigo", 99)
		if not _expect(GlobalInventory.try_add_items({"carvao": 99}).success and GlobalInventory.get_free_slot_count() == 0, "insercao atomica ignorou expansao"):
			return false
	return true

func _test_real_actions() -> bool:
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_inventory_contents({"trigo": 1188})
	var forage: ForageNode = _grove.get_node("ForageNodes/CharcoalOptionalBranch")
	if not _expect(not forage.collect() and GlobalInventory.get_slot_capacity() == 12 and not forage.is_collected(), "coleta recusada concedeu progresso"):
		return false
	GlobalInventory.set_inventory_contents({})
	var storage_before: Dictionary = _chest.get_contents()
	if not _expect(forage.collect() and GlobalInventory.get_slot_capacity() == 16 and GlobalInventory.get_item_quantity("carvao") == 1, "coleta real nao concedeu marco"):
		return false
	if not _expect("Mochila ampliada" in forage.feedback_label.text and _chest.get_contents() == storage_before, "feedback ausente ou coleta teleportou ao bau"):
		return false
	_grove.get_node("ForageNodes/CharcoalNearEntry").collect()
	if not _expect(GlobalInventory.get_slot_capacity() == 16 and not forage.collect(), "segunda coleta repetiu ampliacao"):
		return false
	var project: Node = _main.get_node("RestorationProject_FirstHerbarium")
	project.call("set_area_purified", true)
	_chest.set_contents({})
	if not _expect(not project.call("try_restore") and GlobalInventory.get_slot_capacity() == 16, "restauracao sem recursos premiou"):
		return false
	_chest.set_contents({"trigo": 5, "agua": 1})
	GlobalInventory.set_inventory_contents({"trigo": 16 * 99})
	if not _expect(not project.call("try_restore") and _chest.get_item_quantity("trigo") == 5 and GlobalInventory.get_slot_capacity() == 16, "recusa da recompensa gastou/premiou"):
		return false
	GlobalInventory.set_inventory_contents({})
	if not _expect(project.call("try_restore") and GlobalInventory.get_slot_capacity() == 20 and GlobalInventory.get_item_quantity("rama_encantada") == 1, "restauracao real nao concedeu slots/recompensa"):
		return false
	return _expect(not project.call("try_restore") and GlobalInventory.get_slot_capacity() == 20 and _chest.get_item_quantity("trigo") == 0, "restauracao repetida concedeu bonus")

func _test_pages_and_transfer() -> bool:
	GlobalInventory.set_inventory_contents({"trigo": 1188, "semente_basica": 100})
	_ui.call("verificar_e_atualizar_inventario")
	await get_tree().process_frame
	var bar: HBoxContainer = _ui.get("inventory_bar")
	var next: Button = _ui.get("inventory_next_button")
	var previous: Button = _ui.get("inventory_previous_button")
	if not _expect(bar.get_child_count() == 20 and _visible_slots(bar) == 12 and next.visible and previous.disabled, "primeira pagina incorreta"):
		return false
	for slot in bar.get_children():
		if slot.visible and not _expect(slot.get_global_rect().end.x <= bar.get_global_rect().end.x, "slot visivel ultrapassou a barra"):
			return false
	next.pressed.emit()
	await get_tree().process_frame
	if not _expect(_visible_slots(bar) == 8 and bar.get_child(12).visible and not bar.get_child(0).visible and next.disabled, "segunda pagina inacessivel"):
		return false
	# Clique GUI real na semente fora da pagina inicial, preservando tool exclusivity.
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	bar.get_child(12).call("_gui_input", click)
	if not _expect(GlobalInventory.semente_selecionada == "semente_basica" and ToolManager.get_active_tool() == ToolManager.ToolType.NONE, "semente da segunda pagina conflitou com ferramenta"):
		return false
	bar.get_child(13).call("_gui_input", click)
	if not _expect(GlobalInventory.semente_selecionada == "", "segunda pilha nao desmarcou plantio"):
		return false
	_ui.call("abrir_bau_vila", _chest)
	var panel: Control = _ui.get_node("VillageChestPanel")
	if not _expect(panel.get("inventory_grid").get_child_count() == 20 and "✓" in panel.get("inventory_progress_label").text, "painel nao acompanhou marcos"):
		return false
	await _capture("expanded")
	_chest.deposit_item("semente_basica", 494)
	if not _expect(_chest.withdraw_to_personal_inventory("semente_basica", 494) and GlobalInventory.get_used_slot_count() == 18, "retirada nao usou slots adicionais"):
		return false
	# Mudanca so de capacidade precisa redesenhar ambos os paineis, inclusive load.
	GlobalInventory.apply_backpack_progress([])
	_ui.call("verificar_e_atualizar_inventario")
	panel.call("refresh_items")
	if not _expect("18/12" in panel.get("inventory_capacity_label").text and "18/12" in _ui.get("inventory_capacity_label").text, "UI manteve capacidade obsoleta"):
		return false
	# Overflow maior que todas as expansoes continua alcancavel por pagina.
	GlobalInventory.set_inventory_contents({"trigo": 25 * 99})
	_ui.call("verificar_e_atualizar_inventario")
	next.pressed.emit()
	if not _expect(bar.get_child_count() == 25 and bar.get_child(24).visible and _visible_slots(bar) == 1, "excesso legado nao chegou a terceira pagina"):
		return false
	GlobalInventory.set_inventory_contents({"trigo": 1})
	_ui.call("verificar_e_atualizar_inventario")
	if not _expect(_visible_slots(bar) == 12 and not next.visible and bar.get_child(0).visible, "pagina nao foi limitada apos load menor"):
		return false
	_ui.call("fechar_bau_vila")
	GlobalInventory.apply_backpack_progress(["first_herbarium", "foraging_grove_collection"])
	GlobalInventory.set_inventory_contents({"trigo": 1188, "semente_basica": 100})
	_ui.call("verificar_e_atualizar_inventario")
	next.pressed.emit()
	await _capture("hud")
	return true

func _test_persistence() -> bool:
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	# Recriar a vila valida referencias de cena; nenhum arquivo de save e escrito.
	_main.free()
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	GlobalInventory.apply_backpack_progress([])
	for replay in range(2):
		if not _expect(SaveManager.call("_apply_save_data", saved) and GlobalInventory.get_slot_capacity() == 20 and GlobalInventory.get_item_quantity("trigo") == 1188, "JSON/recriacao/replay perdeu estado"):
			return false
	if not _expect(SaveManager.call("_apply_save_data", {"version": 4}) and GlobalInventory.get_slot_capacity() == 20, "payload parcial apagou marcos"):
		return false
	for bad_value in [null, 2, "first_herbarium", ["unknown"], ["first_herbarium", "first_herbarium"], [true]]:
		var invalid := saved.duplicate(true)
		invalid["inventory"]["inventario"] = {"trigo": 1}
		invalid["inventory"]["backpack_milestones"] = bad_value
		if not _expect(not SaveManager.call("_apply_save_data", invalid) and GlobalInventory.get_item_quantity("trigo") == 1188 and GlobalInventory.get_slot_capacity() == 20, "payload invalido alterou estado"):
			return false
	for version in [3, 4]:
		var legacy := saved.duplicate(true)
		legacy["version"] = version
		legacy["inventory"].erase("backpack_milestones")
		legacy["farm_expansion"]["restoration_projects"] = {"first_herbarium": true}
		if not _expect(SaveManager.call("_apply_save_data", legacy) and GlobalInventory.get_slot_capacity() == 16, "save antigo nao recuperou Herbário ou herdou Bosque"):
			return false
		legacy["farm_expansion"]["restoration_projects"] = {}
		if not _expect(SaveManager.call("_apply_save_data", legacy) and GlobalInventory.get_slot_capacity() == 12 and GlobalInventory.get_used_slot_count() == 14, "save antigo cortou excesso ou herdou expansao"):
			return false
	# Snapshot explicito vazio e autoridade, mesmo com runtime mais avancado.
	saved["inventory"]["backpack_milestones"] = []
	return _expect(SaveManager.call("_apply_save_data", saved) and GlobalInventory.get_slot_capacity() == 12, "load acumulou marcos do runtime")

func _visible_slots(bar: HBoxContainer) -> int:
	var count := 0
	for child in bar.get_children():
		if child.visible:
			count += 1
	return count

func _capture(suffix: String) -> void:
	if "--capture-backpack" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "user://backpack_phase_e_%s.png" % suffix
	get_viewport().get_texture().get_image().save_png(path)
	print("Backpack screenshot: ", ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error("BackpackExpansionSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
