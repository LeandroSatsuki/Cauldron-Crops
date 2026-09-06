extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	if main.has_node("FarmBlockoutV0"):
		_fail("guias macro de desenvolvimento continuam visiveis no mapa")
		return
	if main.has_node("FreeFarmingPilotArea"):
		_fail("marcador tecnico de agricultura livre esta ativo por padrao")
		return
	if main.get_node_or_null("FishingSpot") == null or main.get_node_or_null("CauldronUI") == null:
		_fail("limpeza visual removeu um elemento funcional do mapa")
		return
	if get_tree().get_nodes_in_group("lotes_terra").size() != 34:
		_fail("limpeza visual alterou a quantidade de FarmPlots")
		return
	var lore: Node = main.get_node_or_null("LoreDiscovery_FirstPurifiedArea")
	if lore == null or lore.visible:
		_fail("descoberta de lore nao respeitou o bloqueio inicial")
		return

	print("WorldLayoutCleanupSmokeTest: PASS - guias tecnicas foram removidas sem afetar mapa funcional ou lore.")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WorldLayoutCleanupSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
