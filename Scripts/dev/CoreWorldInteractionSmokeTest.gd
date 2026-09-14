extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const MAX_APPROACH_FRAMES: int = 300

var _main: Node2D = null
var _original_seed: String = ""
var _original_tool: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_seed = GlobalInventory.semente_selecionada
	_original_tool = int(ToolManager.get_active_tool())
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

	if not await _test_chest_approach(player, chest, ui):
		return
	if not await _test_cauldron_approach(player, cauldron):
		return
	if not await _test_fishing_approach(player, fishing_spot):
		return
	if not await _test_existing_plot_approach(player):
		return

	_restore_global_state()
	_main.queue_free()
	await get_tree().process_frame
	print("CoreWorldInteractionSmokeTest: PASS - bau, caldeirao, pesca e lote concluem apos aproximacao segura.")
	get_tree().quit(0)


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
	GlobalInventory.semente_selecionada = _original_seed
	if _original_tool == int(ToolManager.ToolType.NONE):
		ToolManager.clear_tool()
	else:
		ToolManager.force_select_tool(_original_tool)


func _fail(message: String) -> void:
	_restore_global_state()
	push_error("CoreWorldInteractionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
