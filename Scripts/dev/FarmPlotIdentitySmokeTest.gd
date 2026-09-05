extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const EXPANSION_GRID_POSITIONS: Array[Vector2i] = [
	Vector2i(6, 0),
	Vector2i(6, 1),
	Vector2i(7, 0),
	Vector2i(7, 1),
]
const EXPECTED_INITIAL_PLOT_COUNT: int = 34
const DYNAMIC_TEST_POSITION: Vector2i = Vector2i(20, 20)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if not FarmGridManagerSmokeTest.run():
		_fail("smoke test base do FarmGridManager falhou")
		return

	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var plots_before: Array = get_tree().get_nodes_in_group("lotes_terra")
	if plots_before.size() != EXPECTED_INITIAL_PLOT_COUNT:
		_fail(
			"quantidade inicial esperada %d, obtida %d"
			% [EXPECTED_INITIAL_PLOT_COUNT, plots_before.size()]
		)
		return
	if not _assert_initial_registry(main):
		return

	var expansion_instance_ids: Dictionary = {}

	for grid_position in EXPANSION_GRID_POSITIONS:
		var plot_variant: Variant = main.call("obter_farm_plot_por_grid_position", grid_position)
		if not (plot_variant is Node2D) or not is_instance_valid(plot_variant):
			_fail("plot da expansao nao registrado em %s" % grid_position)
			return

		var guaranteed_variant: Variant = main.call("garantir_farm_plot_por_grid_position", grid_position)
		if guaranteed_variant != plot_variant:
			_fail("lookup e garantia retornaram plots diferentes em %s" % grid_position)
			return

		expansion_instance_ids[str(grid_position)] = (plot_variant as Node2D).get_instance_id()

	var grid_manager_variant: Variant = main.call("obter_farm_grid_manager")
	if grid_manager_variant is not FarmGridManager:
		_fail("Main nao forneceu FarmGridManager")
		return

	var farm_grid_data: Dictionary = (grid_manager_variant as FarmGridManager).to_save_data()
	if _get_grid_tile_count(farm_grid_data) != EXPECTED_INITIAL_PLOT_COUNT:
		_fail("snapshot inicial nao contem 34 tiles")
		return

	SaveManager.call("_apply_save_data", _build_save_data(farm_grid_data, false))
	await get_tree().process_frame
	await get_tree().process_frame

	if not _assert_plot_count("load v4 com expansao bloqueada", EXPECTED_INITIAL_PLOT_COUNT):
		return
	if not _assert_expansion_instances(main, expansion_instance_ids, "load v4 bloqueado"):
		return

	var modified_plot_variant: Variant = main.call(
		"obter_farm_plot_por_grid_position",
		EXPANSION_GRID_POSITIONS[0]
	)
	if not (modified_plot_variant is Node2D):
		_fail("plot da expansao nao encontrado para teste purificado")
		return

	var modified_plot: Node2D = modified_plot_variant
	modified_plot.call("set_expansion_blocked", false)
	modified_plot.call("load_save_data", {
		"estado_atual": 0,
		"semente_id_plantada": "",
		"regado": false,
		"arado": true,
		"expansion_blocked": false,
		"tempo_restante": 0.0,
		"tempo_total_crescimento": 0.0,
		"pronto_para_colher": false,
	})
	var purified_grid_data: Dictionary = (main.call("obter_farm_grid_manager") as FarmGridManager).to_save_data()
	SaveManager.call("_apply_save_data", _build_save_data(purified_grid_data, true))
	await get_tree().process_frame
	await get_tree().process_frame

	if not _assert_plot_count("load v4 com expansao purificada", EXPECTED_INITIAL_PLOT_COUNT):
		return
	if not _assert_expansion_instances(main, expansion_instance_ids, "load v4 purificado"):
		return

	var legacy_plots: Array = []
	for plot_variant in get_tree().get_nodes_in_group("lotes_terra"):
		if plot_variant is Node and plot_variant.has_method("get_save_data"):
			legacy_plots.append(plot_variant.call("get_save_data"))
	SaveManager.call("_apply_save_data", {
		"version": 3,
		"farm_plots": legacy_plots,
		"farm_expansion": {
			"purification_obstacles": {"first_obstacle": true},
			"purification_progress": {},
		},
	})
	await get_tree().process_frame
	await get_tree().process_frame

	if not _assert_plot_count("fallback legado v3", EXPECTED_INITIAL_PLOT_COUNT):
		return
	if not _assert_expansion_instances(main, expansion_instance_ids, "fallback v3"):
		return

	var dynamic_plot_variant: Variant = main.call("garantir_farm_plot_por_grid_position", DYNAMIC_TEST_POSITION)
	if not (dynamic_plot_variant is Node2D):
		_fail("nao foi possivel criar plot dinamico para testar desregistro")
		return
	var dynamic_plot: Node2D = dynamic_plot_variant
	var original_dynamic_id: int = dynamic_plot.get_instance_id()
	if main.call("garantir_farm_plot_por_grid_position", DYNAMIC_TEST_POSITION) != dynamic_plot:
		_fail("garantia repetida criou outra instancia na mesma coordenada")
		return
	if not _assert_plot_count("criacao dinamica", EXPECTED_INITIAL_PLOT_COUNT + 1):
		return

	dynamic_plot.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	if main.call("obter_farm_plot_por_grid_position", DYNAMIC_TEST_POSITION) != null:
		_fail("plot dinamico continuou registrado apos sair da arvore")
		return
	var manager_after_removal_variant: Variant = main.call("obter_farm_grid_manager")
	if manager_after_removal_variant is FarmGridManager:
		if (manager_after_removal_variant as FarmGridManager).has_tile(DYNAMIC_TEST_POSITION):
			_fail("tile dinamico continuou no snapshot apos desregistro")
			return
	if not _assert_plot_count("desregistro dinamico", EXPECTED_INITIAL_PLOT_COUNT):
		return

	var recreated_plot_variant: Variant = main.call("garantir_farm_plot_por_grid_position", DYNAMIC_TEST_POSITION)
	if not (recreated_plot_variant is Node2D):
		_fail("plot dinamico nao foi recriado apos desregistro")
		return
	var recreated_plot: Node2D = recreated_plot_variant
	if recreated_plot.get_instance_id() == original_dynamic_id:
		_fail("recriacao dinamica reutilizou uma instancia removida")
		return
	recreated_plot.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	if not _assert_plot_count("limpeza final", EXPECTED_INITIAL_PLOT_COUNT):
		return

	print(
		"FarmPlotIdentitySmokeTest: PASS - 34 plots preservados em load v4/v3; expansao e desregistro usam identidade canonica."
	)
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _build_save_data(farm_grid_data: Dictionary, purified: bool) -> Dictionary:
	return {
		"version": 4,
		"farm_grid": farm_grid_data,
		"farm_expansion": {
			"purification_obstacles": {"first_obstacle": purified},
			"purification_progress": {},
		},
	}


func _assert_initial_registry(main: Node) -> bool:
	var registered_instance_ids: Dictionary = {}
	var expected_positions: Array[Vector2i] = []

	for grid_x in range(6):
		for grid_y in range(4):
			expected_positions.append(Vector2i(grid_x, grid_y))
	for grid_x in range(6):
		expected_positions.append(Vector2i(grid_x, 4))
	for grid_position in EXPANSION_GRID_POSITIONS:
		expected_positions.append(grid_position)

	if expected_positions.size() != EXPECTED_INITIAL_PLOT_COUNT:
		_fail("lista de coordenadas iniciais nao contem 34 posicoes")
		return false

	for grid_position in expected_positions:
		var plot_variant: Variant = main.call("obter_farm_plot_por_grid_position", grid_position)
		if not (plot_variant is Node2D) or not is_instance_valid(plot_variant):
			_fail("registry inicial nao contem a coordenada %s" % grid_position)
			return false

		var instance_id: int = (plot_variant as Node2D).get_instance_id()
		if registered_instance_ids.has(instance_id):
			_fail("uma instancia responde por mais de uma coordenada inicial")
			return false
		registered_instance_ids[instance_id] = true

	return true


func _get_grid_tile_count(farm_grid_data: Dictionary) -> int:
	var tiles_variant: Variant = farm_grid_data.get("tiles", [])
	if typeof(tiles_variant) != TYPE_ARRAY:
		return 0
	return (tiles_variant as Array).size()


func _assert_plot_count(context: String, expected: int) -> bool:
	var current_count: int = get_tree().get_nodes_in_group("lotes_terra").size()
	if current_count == expected:
		return true
	_fail("%s alterou a quantidade de plots: esperado %d, obtido %d" % [context, expected, current_count])
	return false


func _assert_expansion_instances(main: Node, expected_ids: Dictionary, context: String) -> bool:
	for grid_position in EXPANSION_GRID_POSITIONS:
		var plot_variant: Variant = main.call("obter_farm_plot_por_grid_position", grid_position)
		if not (plot_variant is Node2D) or not is_instance_valid(plot_variant):
			_fail("%s perdeu o plot da expansao em %s" % [context, grid_position])
			return false

		var original_instance_id: int = int(expected_ids.get(str(grid_position), 0))
		if (plot_variant as Node2D).get_instance_id() != original_instance_id:
			_fail("%s substituiu o plot da expansao em %s" % [context, grid_position])
			return false

	return true


func _fail(message: String) -> void:
	push_error("FarmPlotIdentitySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
