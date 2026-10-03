extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const FORAGE := preload("res://Scenes/ForageNode.tscn")
var _checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var ui: Node = main.get_node("UI")
	var fishing: Control = ui.get("fishing_minigame_ui")
	var spot: Node = main.get_node("FishingSpot")
	var chest: VillageChest = main.get_node("VillageChest")
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({"trigo": 1188})
	GlobalInventory.aplicar_colecao_pesca_save([], false)
	chest.set_contents({})
	var full := GlobalInventory.inventario.duplicate(true)
	var forage: ForageNode = FORAGE.instantiate()
	forage.quantity = 2
	forage.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(forage)
	if not _expect(not forage.collect() and not forage.is_collected() and GlobalInventory.inventario == full, "recusa consumiu fonte/estoque"):
		return
	var message := forage.get_capacity_feedback()
	if not _expect("2x Carvão" in message and "permanece aqui" in message and "Baú da Vila" in message and forage.feedback_label.text == message, "coleta não informa quantidade/retenção/retorno"):
		return
	await get_tree().create_timer(1.0).timeout
	if not _expect(forage.feedback_label.visible and forage.feedback_label.modulate.a == 1.0, "aviso de coleta desapareceu antes da leitura"):
		return
	ToolManager.force_select_fishing_rod()
	spot.call("_definir_estado", 2)
	spot.call("_on_lake_clicked_at", Vector2(5000, 5000))
	var world_label: Label = ui.get_child(ui.get_child_count() - 1) as Label
	await get_tree().process_frame
	if not _expect(world_label != null and "possíveis resultados" in world_label.text and "Baú da Vila" in world_label.text and spot.get("fishing_state") == 2 and not fishing.visible and GlobalInventory.inventario == full, "pré-recusa abriu pesca ou não explicou retomada"):
		return
	if not _expect(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(world_label.get_global_rect()) and world_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "aviso da pesca fora da tela/bloqueando input"):
		return
	# Espaço é ocupado durante a sincronia; captura dupla permanece atômica.
	GlobalInventory.set_inventory_contents({})
	EventDirector.debug_reset_for_test()
	EventDirector.set("_session_elapsed", EventDirector.RARE_FISH_FIRST_WINDOW_DELAY)
	fishing.call("abrir_popup", Vector2(900, 700))
	GlobalInventory.set_inventory_contents(full)
	fishing.set("_marker_position_x", 196.0)
	fishing.call("_confirmar_tentativa")
	var pending: Dictionary = fishing.call("get_save_data")
	if not _expect(fishing.call("has_pending_capture") and pending["rewards"].size() == 2 and GlobalInventory.inventario == full and not GlobalInventory.possui_bonus_colecao_pesca(), "captura dupla perdida/parcial ou coleção prematura"):
		return
	var pending_message: String = fishing.call("get_pending_capture_feedback")
	if not _expect(fishing.get("popup_panel").get_theme_stylebox("panel").bg_color.a == 1.0, "painel da pesca não é opaco"):
		return
	if not _expect("1x Peixe" in pending_message and "1x Escama" in pending_message and fishing.get("result_label").text == pending_message and "automaticamente" in fishing.get("instruction_label").text and fishing.get("auto_close_timer").is_stopped(), "captura preservada não explica itens/entrega automática"):
		return
	for resolution in [Vector2i(800, 600), Vector2i(1024, 768), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		for frame in range(8):
			await get_tree().process_frame
		var panel: Control = fishing.get("popup_panel")
		if not _expect(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(panel.get_global_rect()) and panel.get_global_rect().encloses(fishing.get("result_label").get_global_rect()) and panel.get_global_rect().encloses(fishing.get("instruction_label").get_global_rect()) and panel.get_global_rect().encloses(fishing.get("close_button").get_global_rect()), "instruções/Fechar escapam do painel em " + str(resolution)):
			return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/CollectionFeedback"))
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/CollectionFeedback/pending.png")
	fishing.call("fechar_popup")
	if not _expect(fishing.call("abrir_popup", Vector2.ZERO) == null and fishing.call("get_save_data") == pending, "nova pesca sobrescreveu captura"):
		return
	fishing.call("load_save_data", JSON.parse_string(JSON.stringify(pending)))
	if not _expect(fishing.call("get_pending_capture_feedback") == pending_message and fishing.call("get_save_data") == pending, "JSON não preservou aviso/captura"):
		return
	spot.call("_on_lake_clicked_at", Vector2.ZERO)
	world_label = ui.get_child(ui.get_child_count() - 1) as Label
	if not _expect(world_label != null and "Captura preservada" in world_label.text and "Baú da Vila" in world_label.text, "lago não informa pendência após load"):
		return
	if not _expect(chest.deposit_from_personal_inventory("trigo", 198), "depósito não liberou dois slots"):
		return
	fishing.call("_process", 0.0)
	if not _expect(not fishing.call("has_pending_capture") and fishing.call("get_pending_capture_feedback") == "" and GlobalInventory.get_item_quantity("peixe_comum") == 1 and GlobalInventory.get_item_quantity("escama_brilhante") == 1 and GlobalInventory.possui_bonus_colecao_pesca(), "entrega automática não concluiu integralmente"):
		return
	var delivered := GlobalInventory.inventario.duplicate(true)
	fishing.call("_process", 0.0)
	if not _expect(GlobalInventory.inventario == delivered and chest.get_item_quantity("trigo") == 198, "retry duplicou captura/deposito"):
		return
	chest.deposit_from_personal_inventory("trigo", 99)
	if not _expect(forage.collect() and forage.is_collected() and GlobalInventory.get_item_quantity("carvao") == 2 and not forage.collect(), "coleta não retomou única após liberar espaço"):
		return
	print("CollectionCapacityFeedbackSmokeTest: PASS - %d verificações; recusa, instruções, retenção, layout, JSON e retomada única." % _checks)
	get_tree().quit(0)

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("CollectionCapacityFeedbackSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
