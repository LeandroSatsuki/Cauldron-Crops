extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const DISCOVERY_ID := "first_purified_whisper"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var discoveries_original: Array = GlobalInventory.lore_descobertas.duplicate()
	GlobalInventory.apply_lore_discoveries_save([])
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var discovery: Node = main.get_node_or_null("LoreDiscovery_FirstPurifiedArea")
	if discovery == null or not discovery.has_method("set_area_purified") or not discovery.has_method("investigate"):
		_fail("descoberta de lore nao foi criada com contrato investigavel")
		return
	if discovery.visible:
		_fail("descoberta de lore apareceu antes da primeira area ser purificada")
		return

	var obstacle: Node = main.get_node_or_null("PurificationObstacle")
	if obstacle == null or not obstacle.has_method("load_save_data"):
		_fail("obstaculo de purificacao nao encontrado")
		return
	obstacle.call("load_save_data", {"obstacle_id": "first_obstacle", "purified": true})
	await get_tree().process_frame
	if not discovery.visible or not discovery.input_pickable:
		_fail("descoberta nao ficou visivel e clicavel apos purificacao")
		return
	if not bool(discovery.call("investigate")) or not GlobalInventory.has_lore_discovery(DISCOVERY_ID):
		_fail("investigacao nao registrou lore opcional")
		return
	if not bool(discovery.call("investigate")) or GlobalInventory.lore_descobertas.size() != 1:
		_fail("investigacao repetida nao preservou uma unica descoberta")
		return

	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	GlobalInventory.apply_lore_discoveries_save([])
	if not bool(SaveManager.call("_apply_save_data", snapshot)) or not GlobalInventory.has_lore_discovery(DISCOVERY_ID):
		_fail("save nao restaurou a descoberta de lore")
		return
	var legacy_snapshot: Dictionary = snapshot.duplicate(true)
	var legacy_inventory: Dictionary = legacy_snapshot.get("inventory", {})
	legacy_inventory.erase("lore_descobertas")
	legacy_snapshot["inventory"] = legacy_inventory
	GlobalInventory.apply_lore_discoveries_save([])
	if not bool(SaveManager.call("_apply_save_data", legacy_snapshot)) or GlobalInventory.has_lore_discovery(DISCOVERY_ID):
		_fail("save anterior sem lore nao preservou estado padrao")
		return

	GlobalInventory.apply_lore_discoveries_save(discoveries_original)
	main.queue_free()
	await get_tree().process_frame
	print("LoreDiscoverySmokeTest: PASS - bloqueio, investigacao opcional e persistencia estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("LoreDiscoverySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
