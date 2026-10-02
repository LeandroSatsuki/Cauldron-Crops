extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const ORIGIN := Vector2(680, 760)
const SPACING := 80.0
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(2560, 1009),
]
const FIXED_LANDMARKS := {
	"VillageChest": Vector2(286, 716),
	"CauldronUI/BaseAnchor/ObstacleBody/CollisionShape2D": Vector2(990, 521),
	"FishingSpot": Vector2(1288, 172),
	"ExternalPathGateway": Vector2(1530, 475),
	"PurificationObstacle": Vector2(1728, 802),
	"RegionContext/VillageArrival": Vector2(1180, 700),
	"RegionContext/FromForagingGrove": Vector2(1435, 555),
}
const READY_CELL := Vector2i(3, 2)
const GROWING_CELL := Vector2i(2, 1)
const TILLED_CELL := Vector2i(1, 4)
const DYNAMIC_CELL := Vector2i(6, 5)
const PENDING_REWARDS := {"trigo": 2, "palha_rara": 1}

var _main: Node2D
var _v4_save: Dictionary
var _v3_save: Dictionary
var _initial_order: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await get_tree().process_frame
		_main = MAIN_SCENE.instantiate()
		_main.set("show_free_farming_pilot_marker", true)
		get_tree().root.add_child(_main)
		get_tree().current_scene = _main
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		# Keep world colliders active; disabling the parent removes physics bodies.
		_main.set_process(false)
		var golem: Node = _main.get_node("Golem")
		golem.set_physics_process(false)
		(golem.get("_think_timer") as Timer).stop()
		if not _expect(_main.get_viewport_rect().size == Vector2(resolution) or DisplayServer.get_name() != "headless", "viewport headless nao corresponde ao tamanho pedido"):
			return
		var measured_viewport: Vector2 = _main.get_viewport_rect().size
		if not _assert_initial_order() or not _assert_coordinates() or not _assert_clear_soil():
			return
		if _v4_save.is_empty():
			_build_fixtures()
		if not _expect(SaveManager.call("_apply_save_data", _v4_save), "save v4 recusado"):
			return
		await get_tree().physics_frame
		if not _assert_saved_state(true) or not _assert_coordinates() or not _assert_clear_soil():
			return
		var dynamic_id: int = _plot(DYNAMIC_CELL).get_instance_id()
		if not _expect(SaveManager.call("_apply_save_data", _v4_save), "replay v4 recusado"):
			return
		if not _expect(_plot(DYNAMIC_CELL).get_instance_id() == dynamic_id and _plots().size() == 35, "replay duplicou ou substituiu lote dinamico"):
			return
		if not _expect(SaveManager.call("_apply_save_data", _v3_save), "save legado v3 recusado"):
			return
		if not _assert_saved_state(true) or not _assert_initial_order(35):
			return
		# Legacy save without optional harvest data must retain the ready crop.
		var old_v3: Dictionary = _v3_save.duplicate(true)
		for data: Dictionary in old_v3["farm_plots"]:
			data.erase("pending_harvest_rewards")
		if not _expect(SaveManager.call("_apply_save_data", old_v3), "v3 antigo recusado") or not _assert_saved_state(false):
			return
		if not _expect(SaveManager.call("_apply_save_data", _v4_save), "v4 recusado apos legado"):
			return
		var before := _world_positions()
		get_tree().root.size = Vector2i(1366, 768)
		var camera: Camera2D = _main.get_node("MainCamera")
		camera.position = Vector2(940, 900)
		camera.zoom = Vector2(1.4, 1.4)
		await get_tree().process_frame
		if not _expect(before == _world_positions(), "resize/pan/zoom moveu objetos do mundo") or not _assert_coordinates():
			return
		if not _assert_translated_grid():
			return
		print("Farm coordinates: requested ", resolution, ", measured ", measured_viewport, " -> origin ", _main.get("farm_origin"), "; v4/v3, replay and world blockers verified.")
		if "--capture-stable-world" in OS.get_cmdline_user_args() and resolution == RESOLUTIONS.back():
			await _capture_world()
		_main.queue_free()
		get_tree().current_scene = null
		await get_tree().process_frame
		await get_tree().process_frame
	print("FarmWorldCoordinatesSmokeTest: PASS - origem fixa, 34 IDs/ordem, piloto 6x2, colliders, v4/v3, recompensas, resize/camera e conversao local/global.")
	get_tree().quit(0)


func _assert_initial_order(expected_count: int = 34) -> bool:
	var expected: Array[String] = []
	for x in range(6):
		for y in range(4):
			expected.append("FarmPlot_%d_%d" % [x, y])
	for x in range(6):
		expected.append("FarmPlot_%d_4" % x)
	for x in range(6, 8):
		for y in range(2):
			expected.append("FarmPlot_%d_%d" % [x, y])
	var plots := _plots()
	if not _expect(plots.size() == expected_count, "contagem de lotes alterada"):
		return false
	var actual: Array[String] = []
	for index in range(34):
		actual.append(str(plots[index].name))
	if _initial_order.is_empty():
		_initial_order = actual.duplicate()
	return _expect(actual == expected and actual == _initial_order, "ordem agricola legada alterada")


func _assert_coordinates() -> bool:
	var anchor: Marker2D = _main.get_node("FarmOrigin")
	if not _expect(anchor.position == ORIGIN and _main.get("farm_origin") == ORIGIN, "origem deixou de ser o marcador explicito da cena"):
		return false
	for path: String in FIXED_LANDMARKS:
		if not _expect((_main.get_node(path) as Node2D).global_position == FIXED_LANDMARKS[path], "objeto fixo deslocado: " + path):
			return false
	var registry: Dictionary = _main.get("farm_plot_registry")
	if not _expect(registry.size() == _plots().size(), "registro e grupo agricola divergiram"):
		return false
	for cell: Vector2i in registry:
		var expected := ORIGIN + Vector2(cell) * SPACING
		var plot: Node2D = registry[cell]
		if not _expect(str(plot.name) == "FarmPlot_%d_%d" % [cell.x, cell.y] and plot.global_position == expected, "identidade/posicao do lote alterada: " + str(cell)):
			return false
		if not _expect(_main.call("_converter_grid_em_posicao_global", cell) == expected and _main.call("_converter_posicao_global_em_grid", expected) == cell, "conversao grid/world inconsistente"):
			return false
	if not _expect((_main.get_node("BlockedAreaVisual") as Node2D).position == ORIGIN + Vector2(520, 56), "pocket deslocado"):
		return false
	if not _expect((_main.get_node("LoreDiscovery_FirstPurifiedArea") as Node2D).position == ORIGIN + Vector2(574, -74), "pedra fora da posicao de borda"):
		return false
	if not _expect((_main.get_node("RestorationProject_FirstHerbarium") as Node2D).position == ORIGIN + Vector2(700, 166), "herbario deslocado"):
		return false
	return _expect((_main.get_node("FreeFarmingPilotArea") as Node2D).position == ORIGIN + Vector2(520, 440), "marcador do piloto deslocado")


func _assert_clear_soil() -> bool:
	var registry: Dictionary = _main.get("farm_plot_registry")
	for cell: Vector2i in registry:
		if not _assert_no_blocker(cell):
			return false
	var bounds: Rect2i = _main.get("free_farming_pilot_bounds")
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			if not _assert_no_blocker(cell):
				return false
			if not _expect(_main.call("avaliar_grid_para_arar", cell).get("valid", false), "solo do piloto indisponivel: " + str(cell)):
				return false
	return true


func _assert_no_blocker(cell: Vector2i) -> bool:
	var blockers: Dictionary = _main.call("_obter_bloqueios_solo_na_celula", cell)
	for kind in blockers:
		if not _expect(not bool(blockers[kind]), "lote %s cruza %s" % [cell, kind]):
			return false
	return true


func _build_fixtures() -> void:
	_plot(READY_CELL).call("load_save_data", {
		"estado_atual": 2, "semente_id_plantada": "semente_basica", "arado": true,
		"regado": true, "pronto_para_colher": true, "pending_harvest_rewards": PENDING_REWARDS,
	})
	_plot(GROWING_CELL).call("load_save_data", {
		"estado_atual": 1, "semente_id_plantada": "semente_inverno", "arado": true,
		"regado": true, "tempo_restante": 37.5, "tempo_total_crescimento": 60.0,
	})
	_plot(TILLED_CELL).call("load_save_data", {"arado": true})
	var legacy_plots: Array = []
	for plot in _plots():
		legacy_plots.append(plot.call("get_save_data"))
	var expansion := {"purification_obstacles": {"first_obstacle": true}, "purification_progress": {}}
	_v3_save = JSON.parse_string(JSON.stringify({"version": 3, "farm_plots": legacy_plots, "farm_expansion": expansion}))
	var dynamic: Node2D = _main.call("garantir_farm_plot_por_grid_position", DYNAMIC_CELL)
	dynamic.call("load_save_data", {"arado": true})
	# _build_save_data serializes logical IDs, not camera/viewport/world positions.
	var saved: Dictionary = SaveManager.call("_build_save_data")
	_v4_save = JSON.parse_string(JSON.stringify({"version": saved["version"], "farm_grid": saved["farm_grid"], "farm_expansion": expansion}))


func _assert_saved_state(expect_pending: bool) -> bool:
	for cell in [READY_CELL, GROWING_CELL, TILLED_CELL, DYNAMIC_CELL]:
		if not _expect(_plot(cell) != null, "lote salvo ausente: " + str(cell)):
			return false
	var ready: Dictionary = _plot(READY_CELL).call("get_save_data")
	var rewards: Dictionary = ready.get("pending_harvest_rewards", {})
	if not _expect(ready["semente_id_plantada"] == "semente_basica" and ready["pronto_para_colher"] and ready["arado"] and ready["regado"], "cultura pronta alterada no load"):
		return false
	if not _expect(rewards == (PENDING_REWARDS if expect_pending else {}), "colheita pendente alterada no load"):
		return false
	var growing: Dictionary = _plot(GROWING_CELL).call("get_save_data")
	if not _expect(growing["semente_id_plantada"] == "semente_inverno" and growing["regado"] and not growing["pronto_para_colher"] and growing["tempo_restante"] > 0.0 and growing["tempo_restante"] <= 37.5 and growing["tempo_total_crescimento"] == 60.0, "cultura crescendo alterada no load"):
		return false
	if not _expect(_plot(TILLED_CELL).call("get_save_data")["arado"] and _plot(DYNAMIC_CELL).call("get_save_data")["arado"], "solo arado ou dinamico perdido"):
		return false
	if not _expect(_plots().size() == 35, "load mudou contagem de lotes"):
		return false
	for cell in [Vector2i(6, 0), Vector2i(6, 1), Vector2i(7, 0), Vector2i(7, 1)]:
		if not _expect(not _plot(cell).get("expansion_blocked"), "pocket purificado voltou a bloquear"):
			return false
	return true


func _assert_translated_grid() -> bool:
	var initial: Vector2 = _main.position
	_main.position += Vector2(123, 45)
	var expected: Vector2 = _plot(DYNAMIC_CELL).global_position
	var matched: bool = _main.call("_converter_grid_em_posicao_global", DYNAMIC_CELL) == expected and _main.call("_converter_posicao_global_em_grid", expected) == DYNAMIC_CELL
	var pilot: Node2D = _main.get_node("FreeFarmingPilotArea")
	matched = matched and pilot.global_position == _main.to_global(ORIGIN + Vector2(520, 440))
	_main.position = initial
	return _expect(matched, "conversao confundiu coordenadas locais e globais")


func _world_positions() -> Dictionary:
	var positions: Dictionary = {}
	for plot in _plots():
		positions[str(plot.name)] = plot.global_position
	for path: String in FIXED_LANDMARKS:
		positions[path] = (_main.get_node(path) as Node2D).global_position
	for path in ["BlockedAreaVisual", "LoreDiscovery_FirstPurifiedArea", "RestorationProject_FirstHerbarium", "FreeFarmingPilotArea"]:
		positions[path] = (_main.get_node(path) as Node2D).global_position
	return positions


func _plots() -> Array[Node]:
	return get_tree().get_nodes_in_group("lotes_terra")


func _plot(cell: Vector2i) -> Node2D:
	return _main.call("obter_farm_plot_por_grid_position", cell)


func _capture_world() -> void:
	if DisplayServer.get_name() == "headless":
		print("Stable farm screenshot skipped: capture requires a renderer.")
		return
	get_tree().root.size = Vector2i(1600, 900)
	_main.get_node("FreeFarmingPilotArea").hide()
	for plot in _plots():
		plot.set("arado", true)
		plot.call("_atualizar_visual")
	var camera: Camera2D = _main.get_node("MainCamera")
	camera.position = Vector2(1020, 710)
	camera.zoom = Vector2(0.8, 0.8)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "user://farm_world_coordinates.png"
	get_viewport().get_texture().get_image().save_png(path)
	print("Stable farm screenshot: ", ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FarmWorldCoordinatesSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
