extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")

var _interaction_completed: bool = false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_seed: String = GlobalInventory.semente_selecionada
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame

	var player: CharacterBody2D = main.get_node_or_null("PlayerAvatar") as CharacterBody2D
	var camera: Camera2D = main.get_node_or_null("MainCamera") as Camera2D
	var chest: Node2D = main.get_node_or_null("VillageChest") as Node2D
	if player == null or camera == null or chest == null:
		_fail("mapa principal nao possui familiar, camera ou bau")
		return
	if camera.position.distance_to(player.global_position) > 1.0:
		_fail("camera inicial nao centralizou no familiar")
		return

	main.call("set_camera_follow_enabled", false)
	var detached_position: Vector2 = player.global_position + Vector2(180.0, 0.0)
	camera.position = detached_position
	main.call("_process_camera_follow", 0.25)
	if not camera.position.is_equal_approx(detached_position):
		_fail("camera manual continuou seguindo o familiar")
		return
	main.call("set_camera_follow_enabled", true)
	main.call("_process_camera_follow", 0.1)
	if camera.position.distance_to(player.global_position) >= detached_position.distance_to(player.global_position):
		_fail("camera nao retomou acompanhamento suave")
		return

	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	_interaction_completed = false
	if not bool(main.call("request_player_interaction", chest, chest.global_position, 52.0, Callable(self, "_mark_interaction_complete"))):
		_fail("interacao distante nao foi aceita")
		return
	var marker: Node2D = main.get_node_or_null("PlayerDestinationMarker") as Node2D
	if marker == null or not marker.visible or not bool(marker.call("is_interaction_destination")):
		_fail("marcador de interacao nao apareceu com o estado correto")
		return
	if _interaction_completed or not bool(main.call("has_pending_player_interaction")):
		_fail("interacao distante executou sem aproximacao")
		return
	player.global_position = chest.global_position + Vector2(40.0, 0.0)
	main.call("_process_pending_player_interaction")
	if not _interaction_completed or bool(main.call("has_pending_player_interaction")):
		_fail("interacao nao executou ao entrar no alcance")
		return
	if marker.visible:
		_fail("marcador de interacao nao desapareceu ao concluir")
		return

	_interaction_completed = false
	player.global_position = Vector2(1180.0, 700.0)
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	if not bool(main.call("request_player_interaction", chest, chest.global_position, 52.0, Callable(self, "_mark_interaction_complete"))):
		_fail("acao com ferramenta nao iniciou aproximacao")
		return
	ToolManager.force_select_tool(ToolManager.ToolType.WATERING_CAN)
	main.call("_process_pending_player_interaction")
	if bool(main.call("has_pending_player_interaction")) or player.has_active_destination() or _interaction_completed:
		_fail("troca de modo nao cancelou a interacao pendente")
		return

	ToolManager.clear_tool()
	player.global_position = Vector2(1180.0, 700.0)
	var ui: Node = main.get_node_or_null("UI")
	var chest_panel: Control = ui.get_node_or_null("VillageChestPanel") as Control if ui != null else null
	if chest_panel == null:
		_fail("painel do bau nao foi encontrado")
		return
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	chest.call("_on_clickable_area_input_event", main.get_viewport(), click, 0)
	if not bool(main.call("has_pending_player_interaction")) or chest_panel.visible:
		_fail("clique real no bau nao aguardou aproximacao")
		return
	player.global_position = chest.global_position + Vector2(40.0, 0.0)
	main.call("_process_pending_player_interaction")
	if not chest_panel.visible:
		_fail("bau nao abriu depois da aproximacao")
		return
	ui.call("fechar_bau_vila")

	GlobalInventory.semente_selecionada = original_seed
	main.queue_free()
	await get_tree().process_frame
	print("PlayerInteractionSmokeTest: PASS - camera hibrida, aproximacao e cancelamento de contexto estao coerentes.")
	get_tree().quit(0)


func _mark_interaction_complete() -> void:
	_interaction_completed = true


func _fail(message: String) -> void:
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	push_error("PlayerInteractionSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
