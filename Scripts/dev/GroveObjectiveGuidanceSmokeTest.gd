extends Node

const MAIN := preload("res://Scenes/Main.tscn")
var _checks := 0
var _home: Node
var _chest: VillageChest
var _cauldron: Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	_home = MAIN.instantiate()
	get_tree().root.add_child(_home)
	get_tree().current_scene = _home
	await get_tree().process_frame
	await get_tree().process_frame
	_home.process_mode = Node.PROCESS_MODE_DISABLED
	_chest = _home.get_node("VillageChest")
	_cauldron = _home.get_node("CauldronUI")
	GlobalInventory.set_inventory_contents({})
	GlobalInventory.apply_backpack_progress([])
	_chest.set_contents({})
	GroveExpedition.reset_progress()
	if not _check("", "Recompensa"):
		return
	GroveExpedition.discover()
	if not _check("Reúna mais 4 carvões", "Retire"):
		return
	GlobalInventory.set_inventory_contents({"carvao": 1})
	_chest.set_contents({"carvao": 2})
	if not _check("Reúna mais 1 carvão", "Retire"):
		return
	_chest.set_contents({"carvao": 3})
	if not _check("Prepare 2 misturas", "Reúna"):
		return
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 1, "carvao": 2})
	_chest.set_contents({})
	if not _check("Prepare 1 mistura", "Retire"):
		return
	_chest.set_contents({GroveExpedition.MIXTURE_ITEM: 5})
	if not _check("Retire 1 mistura", "Prepare"):
		return
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 2})
	if not _check("Leve as 2 misturas", "Retire"):
		return
	GlobalInventory.set_inventory_contents({})
	_chest.set_contents({})
	_cauldron.call("load_save_data", {"state": "BREWING", "result_item": GroveExpedition.MIXTURE_ITEM, "result_quantity": 1, "time_remaining": 3.0})
	if not _check("Misturas em preparo", "Prepare 2"):
		return
	_cauldron.call("load_save_data", {"state": "READY", "result_item": GroveExpedition.MIXTURE_ITEM, "result_quantity": 1, "time_remaining": 0.0})
	if not _check("Mistura pronta", "Prepare 2"):
		return
	_cauldron.call("load_save_data", {"state": "IDLE"})
	_chest.set_contents({"carvao": 4})
	_cauldron.call("iniciar_producao_em_lote", GroveExpedition.PREPARATION_RECIPE, 2)
	if not _check("Misturas em preparo", "Reúna"):
		return
	var full := {"trigo": 1188}
	GlobalInventory.set_inventory_contents(full)
	_cauldron.call("_processar_tick_lote")
	if not _check("Mistura pronta", "Prepare 2"):
		return
	_cauldron.call("load_save_data", {"state": "IDLE"})
	GlobalInventory.set_inventory_contents({"carvao": 4})
	_chest.set_contents({})
	_cauldron.call("iniciar_producao_em_lote", GroveExpedition.PREPARATION_RECIPE, 2)
	GlobalInventory.set_inventory_contents(full)
	_cauldron.call("cancelar_producao_em_lote")
	if not _check("Cancelamento pendente", "Prepare 2"):
		return
	_cauldron.call("load_save_data", {"state": "IDLE"})
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 1})
	_chest.set_contents({GroveExpedition.MIXTURE_ITEM: 1})
	if not await _travel(&"foraging_grove", &"from_farm"):
		return
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	if not _check("Volte à vila. Retire 1 mistura", "Prepare"):
		return
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 2})
	if not _check("Interaja com a clareira", "Volte à vila"):
		return
	var panel: Control = GroveExpedition.get("_tracker")
	GroveExpedition._toggle_tracker()
	if not _expect(not GroveExpedition.get("_tracker_body").visible, "minimização não foi preservada"):
		return
	GroveExpedition._toggle_tracker()
	for resolution in [Vector2i(800, 720), Vector2i(1024, 768), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		GroveExpedition._refresh_tracker()
		for frame in range(8):
			await get_tree().process_frame
		if not _expect(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(panel.get_global_rect()) and panel.get_global_rect().encloses(GroveExpedition.get("_tracker_body").get_global_rect()), "objetivo não contido na tela"):
			return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/GroveObjective"))
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/GroveObjective/ready.png")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GroveExpedition.get_save_data()))
	GroveExpedition.reset_progress()
	GroveExpedition.load_save_data(saved)
	if not _check("Interaja com a clareira", "Retire"):
		return
	GroveExpedition.complete_restoration()
	GroveExpedition._refresh_tracker()
	if not _expect(not panel.visible and GroveExpedition.get_objective_text() == "", "objetivo concluído continua orientando"):
		return
	print("GroveObjectiveGuidanceSmokeTest: PASS - %d verificações; orientação contextual, estoques, produção, viagem/cache, JSON e minimização." % _checks)
	get_tree().quit(0)

func _check(required: String, forbidden: String) -> bool:
	var inventory := GlobalInventory.inventario.duplicate(true)
	var storage := _chest.get_contents()
	var progress := GroveExpedition.get_save_data()
	var production: Dictionary = _cauldron.call("get_save_data")
	var text := GroveExpedition.get_objective_text()
	GroveExpedition._refresh_tracker()
	if not _expect((text == "" if required == "" else required in text) and forbidden not in text, "orientação incorreta: " + text):
		return false
	return _expect(GlobalInventory.inventario == inventory and _chest.get_contents() == storage and GroveExpedition.get_save_data() == progress and _cauldron.call("get_save_data") == production, "orientação alterou recursos/progresso/produção")

func _travel(region_id: StringName, entry_id: StringName) -> bool:
	if not _expect(get_tree().current_scene.call("request_region_transition", region_id, entry_id, &"objective_test"), "viagem rejeitada"):
		return false
	for frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress():
			break
	return _expect(RegionTravelCoordinator.get_active_region_id() == String(region_id), "viagem não concluiu")

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("GroveObjectiveGuidanceSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
