extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const RESTORATION_ID := "first_herbarium"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_inventory: Dictionary = GlobalInventory.inventario.duplicate(true)
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var project: Node = main.get_node_or_null("RestorationProject_FirstHerbarium")
	if project == null or not project.has_method("try_restore") or not project.has_method("get_save_data"):
		_fail("projeto de restauracao nao foi criado com contrato interativo")
		return
	if project.visible or project.input_pickable:
		_fail("projeto apareceu antes da purificacao")
		return

	var obstacle: Node = main.get_node_or_null("PurificationObstacle")
	if obstacle == null or not obstacle.has_method("load_save_data"):
		_fail("obstaculo de purificacao nao foi encontrado")
		return
	obstacle.call("load_save_data", {"obstacle_id": "first_obstacle", "purified": true})
	await get_tree().process_frame
	if not project.visible or not project.input_pickable:
		_fail("projeto nao ficou disponivel apos a purificacao")
		return

	GlobalInventory.inventario = original_inventory.duplicate(true)
	GlobalInventory.inventario["trigo"] = 5
	GlobalInventory.inventario["agua"] = 1
	GlobalInventory.inventario["rama_encantada"] = 0
	if not bool(project.call("try_restore")):
		_fail("projeto nao foi restaurado com requisitos validos")
		return
	if int(GlobalInventory.inventario.get("trigo", -1)) != 0 or int(GlobalInventory.inventario.get("agua", -1)) != 0:
		_fail("restauracao nao consumiu os requisitos corretos")
		return
	if int(GlobalInventory.inventario.get("rama_encantada", 0)) != 1:
		_fail("restauracao nao liberou a Rama Encantada")
		return
	var state: Dictionary = project.call("get_save_data")
	if not bool(state.get("restored", false)):
		_fail("estado restaurado nao foi exposto ao save")
		return

	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	var expansion_data: Dictionary = snapshot.get("farm_expansion", {})
	var projects_data: Dictionary = expansion_data.get("restoration_projects", {})
	if not bool(projects_data.get(RESTORATION_ID, false)):
		_fail("snapshot nao persistiu o projeto restaurado")
		return
	project.call("load_save_data", {"restoration_id": RESTORATION_ID, "restored": false})
	if not bool(SaveManager.call("_apply_save_data", snapshot)):
		_fail("save nao aplicou o estado do projeto")
		return
	state = project.call("get_save_data")
	if not bool(state.get("restored", false)):
		_fail("load nao restaurou o projeto")
		return

	GlobalInventory.inventario = original_inventory
	main.queue_free()
	await get_tree().process_frame
	print("RestorationProjectSmokeTest: PASS - purificacao, restauracao, recompensa unica e save estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RestorationProjectSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
