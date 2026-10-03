extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const MAX_APPROACH_FRAMES: int = 300

var _main: Node2D = null
var _original_seed: String = ""
var _original_tool: int = 0
var _original_inventory: Dictionary = {}
var _original_lore: Array = []
var _original_milestones: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_seed = GlobalInventory.semente_selecionada
	_original_tool = int(ToolManager.get_active_tool())
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_original_lore = GlobalInventory.lore_descobertas.duplicate()
	_original_milestones = GlobalInventory.get_backpack_milestones().duplicate()
	PocoManager.set_process(false)
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()

	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var player: PlayerAvatar = _main.get_node_or_null("PlayerAvatar") as PlayerAvatar
	var chest: VillageChest = _main.get_node_or_null("VillageChest") as VillageChest
	var cauldron: Node2D = _main.get_node_or_null("CauldronUI") as Node2D
	var fishing_spot: Node2D = _main.get_node_or_null("FishingSpot") as Node2D
	var ui: Node = _main.get_node_or_null("UI")
	if player == null or chest == null or cauldron == null or fishing_spot == null or ui == null:
		_fail("cena principal incompleta para validar interacoes")
		return

	if not _test_hoe_input_priority(chest, cauldron, fishing_spot):
		return
	if not await _test_chest_approach(player, chest, ui):
		return
	if not await _test_cauldron_approach(player, cauldron):
		return
	if not await _test_fishing_approach(player, fishing_spot):
		return
	if not await _test_existing_plot_approach(player):
		return
	if not await _test_golem_delivery_through_player(player, chest):
		return
	if not await _test_purification_to_restoration_route(player, chest, ui):
		return

	_restore_global_state()
	_main.queue_free()
	await get_tree().process_frame
	print("CoreWorldInteractionSmokeTest: PASS - aproximacao, pesca/bau/caldeirao/golem, purificacao -> pedra -> quatro lotes -> Herbario e JSON/resize preservam o percurso.")
	get_tree().quit(0)


func _test_hoe_input_priority(chest: VillageChest, cauldron: Node2D, fishing_spot: Node2D) -> bool:
	# Align the canvas with the viewport mouse, without OS pointer automation.
	# Exercise _unhandled_input before the later physics picking stage.
	var camera: Camera2D = _main.get_node("MainCamera") as Camera2D
	var original_position: Vector2 = camera.position
	_main.call("set_camera_follow_enabled", false)
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var targets: Array[Vector2] = [
		chest.global_position,
		(cauldron.get_node("BaseAnchor/ObstacleBody/CollisionShape2D") as Node2D).global_position,
		fishing_spot.global_position,
		(_main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0)) as Node2D).global_position,
	]
	for target in targets:
		camera.position += target - _main.get_global_mouse_position()
		camera.force_update_scroll()
		if not _expect_route(_main.get_global_mouse_position().distance_to(target) < 0.1, "fixture nao alinhou clique ao objeto"):
			return false
		if not _expect_route(_main.call("_world_position_has_interaction_collider", target), "fixture do objeto sem collider em " + str(target)):
			return false
		var reset_event := InputEventAction.new()
		reset_event.action = "smoke_test_unused_action"
		_main.get_viewport().push_input(reset_event)
		_main.call("_unhandled_input", _left_click())
		if not _expect_route(not _main.get_viewport().is_input_handled() and not _main.call("has_pending_player_interaction"), "enxada consumiu clique de objeto antes do physics picking em " + str(target)):
			return false
	var free_cell := Vector2i(6, 5)
	var free_position: Vector2 = _main.call("_converter_grid_em_posicao_global", free_cell)
	camera.position += free_position - _main.get_global_mouse_position()
	camera.force_update_scroll()
	if not _expect_route(not _main.call("_world_position_has_interaction_collider", free_position), "fixture de solo livre contem collider"):
		return false
	var reset_event := InputEventAction.new()
	reset_event.action = "smoke_test_unused_action"
	_main.get_viewport().push_input(reset_event)
	_main.call("_unhandled_input", _left_click())
	var free_plot: Node2D = _main.call("obter_farm_plot_por_grid_position", free_cell) as Node2D
	if not _expect_route(_main.get_viewport().is_input_handled() and free_plot != null and free_plot.get("arado"), "prioridade dos objetos bloqueou enxada em solo livre"):
		return false
	camera.position = original_position
	camera.force_update_scroll()
	_main.call("set_camera_follow_enabled", true)
	ToolManager.clear_tool()
	return true


func _test_chest_approach(player: PlayerAvatar, chest: VillageChest, ui: Node) -> bool:
	ToolManager.clear_tool()
	_place_player(player, chest.global_position + Vector2(240.0, 0.0))
	await get_tree().physics_frame

	var chest_panel: Control = ui.get_node_or_null("VillageChestPanel") as Control
	if chest_panel == null:
		_fail("painel do Village Storage ausente")
		return false
	var click := _left_click()
	chest.call("_on_clickable_area_input_event", _main.get_viewport(), click, 0)
	if not bool(_main.call("has_pending_player_interaction")) or chest_panel.visible:
		_fail("bau nao iniciou aproximacao contextual")
		return false
	if not await _wait_until_visible(chest_panel):
		_fail("bau nao abriu antes de o personagem encerrar a rota")
		return false
	if not _assert_approach_completed(player, chest.global_position, 52.0, "bau"):
		return false
	ui.call("fechar_bau_vila")
	await get_tree().process_frame
	return true


func _test_cauldron_approach(player: PlayerAvatar, cauldron: Node2D) -> bool:
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var target_position: Vector2 = (cauldron.get_node("BaseAnchor") as Node2D).global_position
	_place_player(player, target_position + Vector2(250.0, 0.0))
	await get_tree().physics_frame

	var popup: Control = cauldron.get_node_or_null("PopupLayer/CenterContainer/PopupUI") as Control
	if popup == null:
		_fail("painel do caldeirao ausente")
		return false
	var click := _left_click()
	cauldron.call("_on_area_2d_input_event", _main.get_viewport(), click, 0)
	if not bool(_main.call("has_pending_player_interaction")) or popup.visible:
		_fail("caldeirao nao iniciou aproximacao contextual")
		return false
	if not await _wait_until_visible(popup):
		_fail("caldeirao nao abriu antes de o personagem encerrar a rota")
		return false
	if not _assert_approach_completed(player, target_position, 64.0, "caldeirao"):
		return false
	cauldron.call("fechar_popup")
	await get_tree().process_frame
	return true


func _test_fishing_approach(player: PlayerAvatar, fishing_spot: Node2D) -> bool:
	ToolManager.force_select_tool(ToolManager.ToolType.FISHING_ROD)
	var target_position: Vector2 = fishing_spot.global_position
	_place_player(player, target_position + Vector2(0.0, 300.0))
	await get_tree().physics_frame

	var accepted: bool = bool(_main.call(
		"request_player_interaction",
		fishing_spot,
		target_position,
		150.0,
		Callable(fishing_spot, "_on_lake_clicked_at").bind(target_position)
	))
	if not accepted or not bool(_main.call("has_pending_player_interaction")):
		_fail("pesca nao iniciou aproximacao contextual")
		return false
	if not await _wait_until_fishing_started(fishing_spot):
		_fail("vara selecionada nao iniciou a pesca depois da aproximacao")
		return false
	if not ToolManager.is_fishing_rod_selected():
		_fail("vara foi desselecionada durante a aproximacao para pesca")
		return false
	if not _assert_approach_completed(player, target_position, 150.0, "pesca"):
		return false
	fishing_spot.call("_reset_fishing_state")
	return true


func _test_existing_plot_approach(player: PlayerAvatar) -> bool:
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var plot: Node2D = _main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0)) as Node2D
	if plot == null:
		_fail("lote inicial 0,0 ausente")
		return false
	if bool(plot.call("get_save_data").get("arado", false)):
		_fail("lote inicial deveria estar vazio antes do teste")
		return false
	_place_player(player, plot.global_position + Vector2(180.0, 100.0))
	await get_tree().physics_frame

	var result: Dictionary = _main.call("handle_hoe_world_click", plot.global_position)
	if not bool(result.get("handled", false)) or not bool(result.get("existing_plot", false)):
		_fail("clique com enxada confundiu lote existente com cultivo livre")
		return false
	if not bool(_main.call("has_pending_player_interaction")):
		_fail("lote existente nao iniciou aproximacao contextual")
		return false
	if not await _wait_until_plot_tilled(plot):
		_fail("lote existente nao foi arado depois da aproximacao")
		return false
	return _assert_approach_completed(player, plot.global_position, 46.0, "lote", false)


func _test_golem_delivery_through_player(player: PlayerAvatar, chest: VillageChest) -> bool:
	var golem: CharacterBody2D = _main.get_node_or_null("Golem") as CharacterBody2D
	if golem == null:
		_fail("golem ausente para validar entrega obstruida")
		return false
	var think_timer: Timer = golem.get("_think_timer") as Timer
	if think_timer != null:
		think_timer.stop()
	var wheat_before: int = int(chest.get_contents().get("trigo", 0))
	golem.set("move_speed_pixels_per_second", 220.0)
	golem.set("carried_rewards", [{"item_id": "trigo", "quantidade": 1}])
	golem.global_position = chest.global_position + Vector2(260.0, 0.0)
	_place_player(player, chest.global_position + Vector2(130.0, 0.0))
	await get_tree().physics_frame
	golem.call("_procurar_bau")
	for _frame in range(MAX_APPROACH_FRAMES):
		await get_tree().physics_frame
		if int(chest.get_contents().get("trigo", 0)) == wheat_before + 1:
			break
	if int(chest.get_contents().get("trigo", 0)) != wheat_before + 1:
		_fail("colisao com o familiar cancelou a entrega do golem")
		return false
	var carried_rewards: Array = golem.get("carried_rewards") as Array
	if not carried_rewards.is_empty() or str(golem.get("state")) != "IDLE":
		_fail("golem depositou, mas manteve carga ou estado de entrega")
		return false
	return true


func _test_purification_to_restoration_route(player: PlayerAvatar, chest: VillageChest, ui: Node) -> bool:
	# Synthetic resources/speed only in this process; no personal save file I/O.
	# Invoke the game's handlers and keep physics/navigation active. This does
	# not cover OS mouse picking, Control hit boxes, or manual comfort/visual QA.
	(player.get_node("NavigationAgent2D") as NavigationAgent2D).max_speed = 450.0
	player.move_speed_pixels_per_second = 450.0
	(_main.get_node("Golem").get("_think_timer") as Timer).stop()
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.apply_lore_discoveries_save([])
	GlobalInventory.set_inventory_contents({"semente_basica": 4, "agua": 4})
	chest.set_contents({"trigo": 8, "agua": 1, "pocao_purificadora_fraca": 1, "escama_brilhante": 1})
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var obstacle: Node2D = _main.get_node("PurificationObstacle")
	var lore: Node2D = _main.get_node("LoreDiscovery_FirstPurifiedArea")
	var project: Node2D = _main.get_node("RestorationProject_FirstHerbarium")
	var pocket: Array[Vector2i] = [Vector2i(6, 0), Vector2i(6, 1), Vector2i(7, 0), Vector2i(7, 1)]
	if not _expect_route(not lore.visible and not project.visible, "pedra/Herbario visiveis antes de purificar"):
		return false
	for cell in pocket:
		if not _expect_route(_main.call("obter_farm_plot_por_grid_position", cell).get("expansion_blocked"), "pocket iniciou liberado"):
			return false
	var panel: Control = ui.get_node("PurificationPanel")
	if not _expect_route(obstacle.call("try_handle_global_click", obstacle.global_position), "clique de purificacao nao iniciou aproximacao"):
		return false
	if not await _wait_for_route(func() -> bool: return panel.visible, "aproximacao a purificacao"):
		return false
	var buttons: Node = panel.get_node("MarginContainer/VBoxPurification/ButtonsRow")
	var deliver: Button = buttons.get_node("BtnEntregarTudo")
	var purify: Button = buttons.get_node("BtnPurificarArea")
	if not _expect_route(not deliver.disabled and purify.disabled, "preflight dos botoes de purificacao inconsistente"):
		return false
	deliver.pressed.emit()
	await get_tree().process_frame
	if not _expect_route(not purify.disabled, "entrega pela UI nao habilitou purificacao"):
		return false
	purify.pressed.emit()
	await get_tree().physics_frame
	if not _expect_route(obstacle.get("purified_state") and not panel.visible and lore.visible and project.visible, "purificacao nao liberou pontos ou deixou modal aberto"):
		return false
	if not _expect_route(chest.get_item_quantity("trigo") == 5 and chest.get_item_quantity("pocao_purificadora_fraca") == 0 and chest.get_item_quantity("escama_brilhante") == 0, "purificacao consumiu quantidades incorretas"):
		return false
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	await get_tree().process_frame
	if not _expect_route(_main.get_viewport_rect().size == Vector2(1280, 720) or DisplayServer.get_name() != "headless", "viewport inicial do percurso nao corresponde a resolucao pedida"):
		return false
	lore.call("_on_input_event", _main.get_viewport(), _left_click(), 0)
	if not await _wait_for_route(func() -> bool: return GlobalInventory.has_lore_discovery("first_purified_whisper"), "aproximacao a pedra"):
		return false
	if not _expect_route(GlobalInventory.lore_descobertas.size() == 1, "investigacao duplicou descoberta"):
		return false
	for cell in pocket:
		var plot: Node2D = _main.call("obter_farm_plot_por_grid_position", cell)
		if not _expect_route(not plot.get("expansion_blocked"), "lote permaneceu bloqueado apos purificar"):
			return false
		ToolManager.force_select_tool(ToolManager.ToolType.HOE)
		var result: Dictionary = _main.call("handle_hoe_world_click", plot.global_position)
		if not _expect_route(result.get("handled", false) and result.get("existing_plot", false), "enxada nao reconheceu lote do pocket"):
			return false
		if not await _wait_for_route(func() -> bool: return plot.call("get_save_data").get("arado", false), "arar pocket " + str(cell)):
			return false
		ToolManager.clear_tool()
		GlobalInventory.semente_selecionada = "semente_basica"
		plot.call("_input_event", _main.get_viewport(), _left_click(), 0)
		if not await _wait_for_route(func() -> bool: return plot.call("get_save_data").get("semente_id_plantada", "") == "semente_basica", "plantar pocket " + str(cell)):
			return false
		ToolManager.force_select_tool(ToolManager.ToolType.WATERING_CAN)
		plot.call("_input_event", _main.get_viewport(), _left_click(), 0)
		if not await _wait_for_route(func() -> bool: return plot.call("get_save_data").get("regado", false), "regar pocket " + str(cell)):
			return false
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	project.call("_input_event", _main.get_viewport(), _left_click(), 0)
	if not await _wait_for_route(func() -> bool: return project.get("restored_state"), "aproximacao ao Herbario"):
		return false
	if not _expect_route(chest.get_item_quantity("trigo") == 0 and chest.get_item_quantity("agua") == 0 and GlobalInventory.get_item_quantity("rama_encantada") == 1 and GlobalInventory.get_slot_capacity() == 16, "restauracao perdeu recursos/recompensa ou marco"):
		return false
	project.call("_input_event", _main.get_viewport(), _left_click(), 0)
	if not _expect_route(GlobalInventory.get_item_quantity("rama_encantada") == 1 and GlobalInventory.get_slot_capacity() == 16, "restauracao repetida duplicou recompensa/marco"):
		return false
	var expected_positions: Dictionary = {}
	for cell in pocket:
		expected_positions[cell] = (_main.call("obter_farm_plot_por_grid_position", cell) as Node2D).global_position
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	_main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().root.size = Vector2i(1920, 1080)
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().physics_frame
	await get_tree().physics_frame
	(_main.get_node("Golem").get("_think_timer") as Timer).stop()
	if not _expect_route(_main.get_viewport_rect().size == Vector2(1920, 1080) or DisplayServer.get_name() != "headless", "viewport recriado nao corresponde a resolucao pedida"):
		return false
	if not _expect_route(SaveManager.call("_apply_save_data", saved), "JSON do percurso foi recusado"):
		return false
	await get_tree().physics_frame
	for cell in pocket:
		var restored: Node2D = _main.call("obter_farm_plot_por_grid_position", cell)
		var data: Dictionary = restored.call("get_save_data")
		if not _expect_route(restored.global_position == expected_positions[cell] and data["arado"] and data["regado"] and not data["expansion_blocked"] and data["semente_id_plantada"] == "semente_basica", "reload perdeu posicao/cultura do pocket " + str(cell)):
			return false
	if not _expect_route(_main.get_node("RestorationProject_FirstHerbarium").get("restored_state") and GlobalInventory.has_lore_discovery("first_purified_whisper") and GlobalInventory.get_slot_capacity() == 16 and GlobalInventory.get_item_quantity("rama_encantada") == 1, "reload perdeu restauracao/lore/recompensa/marco"):
		return false
	print("Restoration route: PASS - physical handlers/navigation, four crops, UI purification buttons, restoration and JSON across scene/resolution.")
	return true


func _wait_for_route(condition: Callable, label: String) -> bool:
	for _frame in range(600):
		await get_tree().physics_frame
		if bool(condition.call()):
			var player: PlayerAvatar = _main.get_node("PlayerAvatar") as PlayerAvatar
			return _expect_route(not _main.call("has_pending_player_interaction") and not player.has_active_destination(), label + " permaneceu com rota pendente apos interagir")
	_fail("percurso nao concluiu: " + label)
	return false


func _expect_route(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
	return condition


func _place_player(player: PlayerAvatar, position: Vector2) -> void:
	player.stop_moving()
	player.global_position = position


func _assert_approach_completed(
	player: PlayerAvatar,
	target_position: Vector2,
	requested_distance: float,
	label: String,
	must_remain_outside_requested_distance: bool = true
) -> bool:
	if bool(_main.call("has_pending_player_interaction")) or player.has_active_destination():
		_fail("%s permaneceu com rota pendente apos interagir" % label)
		return false
	var final_distance: float = player.global_position.distance_to(target_position)
	if must_remain_outside_requested_distance and final_distance <= requested_distance:
		_fail("%s exigiu entrar no obstaculo para interagir (distancia %.1f)" % [label, final_distance])
		return false
	return true


func _wait_until_visible(control: Control) -> bool:
	for _frame in range(MAX_APPROACH_FRAMES):
		await get_tree().physics_frame
		if control.visible:
			return true
	return false


func _wait_until_fishing_started(fishing_spot: Node) -> bool:
	for _frame in range(MAX_APPROACH_FRAMES):
		await get_tree().physics_frame
		if int(fishing_spot.get("fishing_state")) != 0:
			return true
	return false


func _wait_until_plot_tilled(plot: Node) -> bool:
	for _frame in range(MAX_APPROACH_FRAMES):
		await get_tree().physics_frame
		var save_data: Dictionary = plot.call("get_save_data")
		if bool(save_data.get("arado", false)):
			return true
	return false


func _left_click() -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	return click


func _restore_global_state() -> void:
	GlobalInventory.set_inventory_contents(_original_inventory)
	GlobalInventory.apply_lore_discoveries_save(_original_lore)
	GlobalInventory.apply_backpack_progress(_original_milestones)
	GlobalInventory.semente_selecionada = _original_seed
	if _original_tool == int(ToolManager.ToolType.NONE):
		ToolManager.clear_tool()
	else:
		ToolManager.force_select_tool(_original_tool)


func _fail(message: String) -> void:
	_restore_global_state()
	push_error("CoreWorldInteractionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
