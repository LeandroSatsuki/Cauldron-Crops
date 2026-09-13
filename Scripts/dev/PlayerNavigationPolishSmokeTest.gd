extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var player: CharacterBody2D = main.get_node_or_null("PlayerAvatar") as CharacterBody2D
	var marker: Node2D = main.get_node_or_null("PlayerDestinationMarker") as Node2D
	var cauldron: Node2D = main.get_node_or_null("CauldronUI/BaseAnchor") as Node2D
	var chest: Node2D = main.get_node_or_null("VillageChest") as Node2D
	var fishing_spot: Node2D = main.get_node_or_null("FishingSpot") as Node2D
	var corruption: Node2D = main.get_node_or_null("PurificationObstacle") as Node2D
	if player == null or marker == null or cauldron == null or chest == null or fishing_spot == null or corruption == null:
		_fail("mapa principal nao possui todos os participantes da navegacao")
		return

	for obstacle_owner in [cauldron, chest, fishing_spot, corruption]:
		var obstacle: NavigationObstacle2D = obstacle_owner.get_node_or_null("PlayerNavigationObstacle") as NavigationObstacle2D
		if obstacle == null or not obstacle.avoidance_enabled:
			_fail("obstaculo de navegacao ausente ou inativo em %s" % obstacle_owner.name)
			return

	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var target := Vector2(850.0, 280.0)
	if not bool(main.call("try_move_player_to", target, false)):
		_fail("trajeto de contorno nao foi iniciado")
		return
	if not marker.visible or bool(marker.call("is_interaction_destination")):
		_fail("marcador de movimento nao apareceu com o estado correto")
		return

	var minimum_cauldron_distance: float = INF
	for _frame in range(420):
		await get_tree().physics_frame
		minimum_cauldron_distance = minf(minimum_cauldron_distance, player.global_position.distance_to(cauldron.global_position))
		if not player.has_active_destination():
			break

	if player.has_active_destination() or player.global_position.distance_to(target) > 20.0:
		_fail("familiar nao concluiu o trajeto ao redor do caldeirao (pos=%s distancia=%.1f minima=%.1f)" % [player.global_position, player.global_position.distance_to(target), minimum_cauldron_distance])
		return
	if minimum_cauldron_distance < 55.0:
		_fail("familiar invadiu o raio fisico do caldeirao")
		return
	await get_tree().process_frame
	if marker.visible:
		_fail("marcador nao desapareceu ao concluir o movimento")
		return

	main.queue_free()
	await get_tree().process_frame
	print("PlayerNavigationPolishSmokeTest: PASS - marcadores e contorno de obstaculos estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	push_error("PlayerNavigationPolishSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
