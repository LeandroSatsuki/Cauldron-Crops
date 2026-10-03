extends Node
const HUD := preload("res://Scripts/HUDLayout.gd")
const MAIN := preload("res://Scenes/Main.tscn")
var checks := 0
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for screen in [Vector2(800, 720), Vector2(1024, 768), Vector2(1280, 720)]:
		var panel := Vector2(336, 190)
		var old: Vector2 = screen - panel - Vector2(20, 20)
		var occupied: Array[Rect2] = [Rect2(Vector2.ZERO, screen)]
		var protected: Array[Rect2] = [Rect2(old, panel)]
		var position := HUD.find_free_panel_position(panel, screen, occupied, protected)
		if not _check(Rect2(Vector2.ZERO, screen).encloses(Rect2(position, panel)), "fallback fora da tela"):
			return
		if not _check(not Rect2(position, panel).intersects(protected[0].grow(6)), "fallback cobre controle evitável"):
			return
		if not _check(position == HUD.find_free_panel_position(panel, screen, occupied, protected), "fallback instável"):
			return
		# Toda a tela está ocupada, mas a região duplicada pode ser evitada.
		occupied = [Rect2(Vector2.ZERO, screen), Rect2(old, panel)]
		position = HUD.find_free_panel_position(panel, screen, occupied)
		if not _check(not Rect2(position, panel).intersects(Rect2(old, panel).grow(6)), "fallback não reduz sobreposição evitável"):
			return
		# Saturação total: manter limites sem prometer espaço livre inexistente.
		occupied = [Rect2(Vector2.ZERO, screen * Vector2(1, 0.8)), Rect2(Vector2(0, screen.y * 0.8), screen * Vector2(1, 0.2))]
		protected = [Rect2(Vector2.ZERO, screen)]
		position = HUD.find_free_panel_position(panel, screen, occupied, protected)
		if not _check(Rect2(Vector2.ZERO, screen).encloses(Rect2(position, panel)), "ocupação impossível escapou da tela"):
			return
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var ui: Node = main.get_node("UI")
	var objectives: Control = ui.get_node("InitialObjectivesPanel")
	var cauldron: Node = main.get_node("CauldronUI")
	GlobalInventory.set_inventory_contents({"semente_basica": 3, "tomate_sol": 3})
	if not _check(cauldron.call("iniciar_producao_em_lote", "semente_basica_tomate_sol", 3), "fixture não iniciou lote"):
		return
	GroveExpedition.reset_progress()
	GroveExpedition.discover()
	var inventory := GlobalInventory.inventario.duplicate(true)
	var progress := GroveExpedition.get_save_data()
	var production: Dictionary = cauldron.call("get_save_data")
	var collapsed: bool = GroveExpedition.get("_tracker_collapsed")
	var cancel: Control = cauldron.get("btn_cancelar_producao")
	for point in [Vector2(250, 150), Vector2(300, 295), Vector2(485, 200)]:
		objectives.position = point
		await get_tree().process_frame
		await get_tree().process_frame
		var actual := objectives.position
		for frame in range(20):
			await get_tree().process_frame
		var panel: Control = cauldron.get("batch_progress_panel")
		var tracker: Control = GroveExpedition.get("_tracker")
		var toggle: Control = ui.get("initial_objectives_toggle_button")
		if not _check(not panel.get_global_rect().intersects(toggle.get_global_rect()) and not tracker.get_global_rect().intersects(toggle.get_global_rect()), "avisos cobrem minimizar"):
			return
		if not _check(cancel.is_visible_in_tree() and not tracker.get_global_rect().intersects(cancel.get_global_rect()), "tracker cobre cancelar produção"):
			return
		if not _check(objectives.position == actual and collapsed == GroveExpedition.get("_tracker_collapsed"), "layout mudou escolha do jogador"):
			return
		if not _check(GlobalInventory.inventario == inventory and GroveExpedition.get_save_data() == progress and cauldron.call("get_save_data") == production, "layout mudou gameplay"):
			return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://Builds/QA/HUDCrowded")
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/HUDCrowded/layout.png")
	print("HUDCrowdedFallbackSmokeTest: PASS - %d verificações; fallback limitado, prioridade e escolhas preservadas." % checks)
	get_tree().quit(0)
func _check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		push_error("HUDCrowdedFallbackSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return ok
