extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


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
	if player == null or not player.is_in_group("player_avatar"):
		_fail("familiar fisico nao foi instanciado no mapa principal")
		return

	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var destination := Vector2(1400.0, 700.0)
	if not bool(main.call("can_issue_player_move", destination, false)):
		_fail("terreno vazio nao aceitou movimento")
		return
	if not bool(main.call("try_move_player_to", destination, false)):
		_fail("pedido de movimento nao chegou ao familiar")
		return
	if not player.get_requested_destination().is_equal_approx(destination):
		_fail("destino solicitado nao foi preservado")
		return

	var initial_position: Vector2 = player.global_position
	for _frame in range(8):
		await get_tree().physics_frame
	if player.global_position.distance_to(initial_position) <= 1.0:
		_fail("familiar nao se deslocou pela navegacao")
		return

	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	if bool(main.call("can_issue_player_move", destination, false)):
		_fail("movimento continuou disponivel com ferramenta ativa")
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if player.has_active_destination():
		_fail("movimento em curso nao parou ao selecionar ferramenta")
		return
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = "semente_basica"
	if bool(main.call("can_issue_player_move", destination, false)):
		_fail("movimento continuou disponivel com semente ativa")
		return
	GlobalInventory.semente_selecionada = ""

	var chest: Node2D = main.get_node_or_null("VillageChest") as Node2D
	if chest == null or not bool(main.call("_world_position_has_interaction_collider", chest.global_position)):
		_fail("bau nao foi reconhecido como area de interacao")
		return
	if bool(main.call("try_move_player_to", chest.global_position)):
		_fail("clique no bau vazou para o movimento")
		return

	player.stop_moving()
	GlobalInventory.semente_selecionada = original_seed
	ToolManager.clear_tool()
	main.queue_free()
	await get_tree().process_frame
	print("PlayerNavigationSmokeTest: PASS - familiar, click-to-move e arbitragem de interacoes estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	push_error("PlayerNavigationSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
