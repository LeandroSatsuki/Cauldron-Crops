extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const RESOLUTIONS := [Vector2i(800, 720), Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
var _checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	GlobalInventory.set_inventory_contents({"trigo": 10})
	GroveExpedition.reset_progress()
	GroveExpedition.discover()
	var cauldron: Node = main.get_node("CauldronUI")
	var ui: Node = main.get_node("UI")
	var production: Control = cauldron.get("batch_progress_panel")
	var tracker: Control = GroveExpedition.get("_tracker")
	var progress := GroveExpedition.get_save_data()
	var chest: VillageChest = main.get_node("VillageChest")
	for state in ["READY", "BREWING", "BATCH", "BATCH_PAUSED", "CANCEL_PENDING"]:
		cauldron.call("load_save_data", {"state": "IDLE"})
		if state in ["READY", "BREWING"]:
			cauldron.call("load_save_data", {"state": state, "result_item": GroveExpedition.MIXTURE_ITEM, "result_quantity": 2, "time_remaining": 0.0 if state == "READY" else 4.0})
		else:
			GlobalInventory.set_inventory_contents({"semente_basica": 1, "tomate_sol": 2})
			chest.set_contents({"semente_basica": 2, "tomate_sol": 1})
			if not _expect(cauldron.call("iniciar_producao_em_lote", "semente_basica_tomate_sol", 3), "fixture não iniciou lote"):
				return
			var full: Dictionary = {}
			for slot in range(12):
				full["coexistence_probe_%d" % slot] = 99
			GlobalInventory.set_inventory_contents(full)
			if state == "BATCH_PAUSED":
				cauldron.call("_processar_tick_lote")
			elif state == "CANCEL_PENDING":
				cauldron.get("btn_cancelar_producao").pressed.emit()
		var inventory := GlobalInventory.inventario.duplicate(true)
		var storage := chest.get_contents()
		var saved: Dictionary = cauldron.call("get_save_data")
		for resolution in RESOLUTIONS:
			get_tree().root.size = resolution
			GroveExpedition._refresh_tracker()
			for frame in range(20):
				await get_tree().process_frame
			if "--baseline" in OS.get_cmdline_user_args():
				if tracker.get_global_rect().intersects(production.get_global_rect()):
					print("HUDPanelCoexistenceSmokeTest: PASS - baseline reproduziu objetivo encobrindo aviso do caldeirão.")
					get_tree().quit(0)
					return
			if not _expect(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(tracker.get_global_rect()) and Rect2(Vector2.ZERO, Vector2(resolution)).encloses(production.get_global_rect()), "painel fora da tela"):
				return
			if not _expect(not tracker.get_global_rect().intersects(production.get_global_rect()), "objetivo encobre produção em %s: objetivo=%s produção=%s HUD=%s" % [resolution, tracker.get_global_rect(), production.get_global_rect(), preload("res://Scripts/HUDLayout.gd").get_occupied_hud_rects(ui)]):
				return
			for name in ["InventoryBackdrop", "ToolBarPanel", "LeftPanel", "InitialObjectivesPanel"]:
				var obstacle: Control = ui.get_node(name)
				var controls: Array = obstacle.get_children() if name == "LeftPanel" else [obstacle]
				for control in controls:
					if control is Control and control.is_visible_in_tree():
						if not _expect(not tracker.get_global_rect().intersects(control.get_global_rect()) and not production.get_global_rect().intersects(control.get_global_rect()), "painel encobre " + str(control.name) + " em " + str(resolution)):
							return
			var cancel: Control = cauldron.get("btn_cancelar_producao")
			if not _expect(not cancel.is_visible_in_tree() or production.get_global_rect().encloses(cancel.get_global_rect()), "cancelamento fora do painel"):
				return
			if not _expect(GlobalInventory.inventario == inventory and chest.get_contents() == storage and GroveExpedition.get_save_data() == progress and cauldron.call("get_save_data") == saved, "layout alterou produção/estoque/progresso"):
				return
	get_tree().root.size = Vector2i(1280, 720)
	var objectives: Control = ui.get_node("InitialObjectivesPanel")
	objectives.position = Vector2(950, 450)
	for frame in range(20):
		await get_tree().process_frame
	if not _expect(not tracker.get_global_rect().intersects(objectives.get_global_rect()) and not production.get_global_rect().intersects(objectives.get_global_rect()), "painéis ignoraram objetivos arrastados"):
		return
	GroveExpedition._toggle_tracker()
	for frame in range(20):
		await get_tree().process_frame
	if not _expect(not GroveExpedition.get("_tracker_body").visible and not tracker.get_global_rect().intersects(production.get_global_rect()), "minimização perdeu acesso ou sobrepôs produção"):
		return
	GroveExpedition._toggle_tracker()
	if "--capture" in OS.get_cmdline_user_args():
		for frame in range(20):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/HUDCoexistence"))
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/HUDCoexistence/panels.png")
	print("HUDPanelCoexistenceSmokeTest: PASS - %d verificações; coexistência, resize, arraste, minimização e estado invariável." % _checks)
	get_tree().quit(0)

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("HUDPanelCoexistenceSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
