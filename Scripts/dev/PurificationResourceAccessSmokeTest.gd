extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")

var _original_inventory: Dictionary = {}
var _main: Node = null
var _chest: VillageChest = null


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame

	var obstacle: Node = _main.get_node_or_null("PurificationObstacle")
	_chest = _main.get_node_or_null("VillageChest") as VillageChest
	if obstacle == null or not obstacle.has_method("deliver_all_available") or _chest == null:
		_fail("obstaculo ou Village Storage ausente")
		return

	obstacle.call("load_save_data", {
		"obstacle_id": "first_obstacle",
		"purified": false,
		"purification_progress": {},
	})
	GlobalInventory.inventario = {
		"pocao_purificadora_fraca": 0,
		"escama_brilhante": 1,
		"trigo": 2,
	}
	_chest.set_contents({
		"pocao_purificadora_fraca": 1,
		"trigo": 2,
	})

	var delivered_variant: Variant = obstacle.call("deliver_all_available")
	if not (delivered_variant is Dictionary):
		_fail("entrega total nao retornou o contrato esperado")
		return
	var delivered: Dictionary = delivered_variant
	if int(delivered.get("pocao_purificadora_fraca", 0)) != 1 or int(delivered.get("escama_brilhante", 0)) != 1 or int(delivered.get("trigo", 0)) != 3:
		_fail("entrega combinada nao completou os requisitos exatos")
		return
	if _chest.get_item_quantity("pocao_purificadora_fraca") != 0 or _chest.get_item_quantity("trigo") != 0:
		_fail("purificacao nao priorizou o Village Storage")
		return
	if int(GlobalInventory.inventario.get("escama_brilhante", -1)) != 0 or int(GlobalInventory.inventario.get("trigo", -1)) != 1:
		_fail("Mochila nao completou apenas os recursos restantes")
		return
	if not bool(obstacle.call("can_purify")):
		_fail("requisitos entregues nao liberaram a purificacao")
		return
	if not bool(obstacle.call("finalize_purification")):
		_fail("purificacao completa foi recusada")
		return

	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	var expansion: Dictionary = snapshot.get("farm_expansion", {})
	var obstacle_states: Dictionary = expansion.get("purification_obstacles", {})
	var progress_states: Dictionary = expansion.get("purification_progress", {})
	if not bool(obstacle_states.get("first_obstacle", false)):
		_fail("snapshot nao preservou a conclusao da purificacao")
		return
	var first_progress: Dictionary = progress_states.get("first_obstacle", {})
	if int(first_progress.get("trigo", 0)) != 3:
		_fail("snapshot nao preservou o progresso entregue")
		return

	_restore_state()
	print("PurificationResourceAccessSmokeTest: PASS - purificacao consome Village Storage primeiro, completa pela Mochila e preserva o save.")
	get_tree().quit(0)


func _restore_state() -> void:
	GlobalInventory.inventario = _original_inventory.duplicate(true)
	if _main != null and is_instance_valid(_main):
		_main.queue_free()


func _fail(message: String) -> void:
	_restore_state()
	push_error("PurificationResourceAccessSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
