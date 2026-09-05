extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const PILOT_GRID_POSITION := Vector2i(6, 5)
const OUTSIDE_PILOT_GRID_POSITION := Vector2i(3, 5)
const EXPECTED_INITIAL_PLOT_COUNT: int = 34
const OUTSIDE_PILOT_REASON: String = "outside_free_farming_pilot"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)

	var main: Node2D = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame

	if not _assert_plot_count(EXPECTED_INITIAL_PLOT_COUNT, "estado inicial"):
		return
	if main.get_node_or_null("FreeFarmingPilotArea") == null:
		_fail("marcador visual da area piloto nao foi criado")
		return
	if main.call("obter_farm_plot_por_grid_position", PILOT_GRID_POSITION) != null:
		_fail("celula piloto deveria iniciar sem FarmPlot")
		return

	var pilot_global_position: Vector2 = main.call("_converter_grid_em_posicao_global", PILOT_GRID_POSITION)
	var first_attempt_variant: Variant = main.call("tentar_arar_agricultura_livre", pilot_global_position, false)
	if typeof(first_attempt_variant) != TYPE_DICTIONARY:
		_fail("primeira tentativa nao retornou resultado")
		return
	var first_attempt: Dictionary = first_attempt_variant
	if not bool(first_attempt.get("valid", false)) or not bool(first_attempt.get("created", false)) or not bool(first_attempt.get("prepared", false)):
		_fail("primeira tentativa nao criou e arou a celula piloto: %s" % str(first_attempt))
		return

	var pilot_plot_variant: Variant = main.call("obter_farm_plot_por_grid_position", PILOT_GRID_POSITION)
	if pilot_plot_variant is not Node2D:
		_fail("FarmPlot criado nao entrou no registro canonico")
		return
	var pilot_plot: Node2D = pilot_plot_variant
	var original_instance_id: int = pilot_plot.get_instance_id()
	if not _is_plot_tilled(pilot_plot):
		_fail("FarmPlot livre nao ficou arado")
		return
	if not _assert_plot_count(EXPECTED_INITIAL_PLOT_COUNT + 1, "criacao livre"):
		return
	if not _assert_snapshot_tile(main, PILOT_GRID_POSITION, FarmTileData.TileState.ARADO):
		return

	var second_attempt: Dictionary = main.call("tentar_arar_agricultura_livre", pilot_global_position, false)
	if bool(second_attempt.get("created", true)) or bool(second_attempt.get("prepared", true)):
		_fail("segunda tentativa recriou ou rearou o mesmo plot")
		return
	if main.call("obter_farm_plot_por_grid_position", PILOT_GRID_POSITION) != pilot_plot:
		_fail("segunda tentativa trocou a identidade canonica")
		return
	if not _assert_plot_count(EXPECTED_INITIAL_PLOT_COUNT + 1, "reuso da mesma celula"):
		return
	if not _exercise_cultivation_loop(pilot_plot):
		return
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)

	var outside_soil: Dictionary = main.call("avaliar_grid_para_arar", OUTSIDE_PILOT_GRID_POSITION)
	if not bool(outside_soil.get("valid", false)):
		_fail("celula de controle deveria ser solo fisicamente valido")
		return
	var outside_global_position: Vector2 = main.call("_converter_grid_em_posicao_global", OUTSIDE_PILOT_GRID_POSITION)
	var outside_attempt: Dictionary = main.call("tentar_arar_agricultura_livre", outside_global_position, false)
	if bool(outside_attempt.get("valid", true)) or str(outside_attempt.get("reason", "")) != OUTSIDE_PILOT_REASON:
		_fail("criacao fora do piloto nao foi recusada pelo escopo: %s" % str(outside_attempt))
		return
	if main.call("obter_farm_plot_por_grid_position", OUTSIDE_PILOT_GRID_POSITION) != null:
		_fail("tentativa fora do piloto criou FarmPlot")
		return

	var save_variant: Variant = SaveManager.call("_build_save_data")
	if typeof(save_variant) != TYPE_DICTIONARY:
		_fail("SaveManager nao produziu snapshot do piloto")
		return
	var save_data: Dictionary = (save_variant as Dictionary).duplicate(true)
	if _get_grid_tile_count(save_data.get("farm_grid", {})) != EXPECTED_INITIAL_PLOT_COUNT + 1:
		_fail("snapshot do save nao contem o plot livre")
		return

	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var reloaded_main: Node2D = MAIN_SCENE.instantiate()
	get_tree().root.add_child(reloaded_main)
	get_tree().current_scene = reloaded_main
	await get_tree().process_frame
	if not bool(SaveManager.call("_apply_save_data", save_data)):
		_fail("SaveManager recusou o save sintetico do piloto")
		return
	await get_tree().process_frame
	await get_tree().process_frame

	var restored_plot_variant: Variant = reloaded_main.call("obter_farm_plot_por_grid_position", PILOT_GRID_POSITION)
	if restored_plot_variant is not Node2D:
		_fail("plot livre nao foi restaurado no reload")
		return
	var restored_plot: Node2D = restored_plot_variant
	if restored_plot.get_instance_id() == original_instance_id:
		_fail("reload reutilizou instancia da cena anterior")
		return
	if not _is_plot_tilled(restored_plot):
		_fail("plot livre restaurado perdeu o estado arado")
		return
	if not _assert_plot_count(EXPECTED_INITIAL_PLOT_COUNT + 1, "reload do piloto"):
		return

	var restored_instance_id: int = restored_plot.get_instance_id()
	if not bool(SaveManager.call("_apply_save_data", save_data)):
		_fail("segundo load do piloto foi recusado")
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var repeated_plot: Node2D = reloaded_main.call("obter_farm_plot_por_grid_position", PILOT_GRID_POSITION)
	if repeated_plot == null or repeated_plot.get_instance_id() != restored_instance_id:
		_fail("load repetido trocou a identidade do plot livre")
		return
	if not _assert_plot_count(EXPECTED_INITIAL_PLOT_COUNT + 1, "load repetido do piloto"):
		return
	if not _assert_snapshot_tile(reloaded_main, PILOT_GRID_POSITION, FarmTileData.TileState.ARADO):
		return

	print("FreeFarmingPilotSmokeTest: PASS - area 6x2 cria, ara, registra e restaura FarmPlot livre sem duplicacao.")
	ToolManager.clear_tool()
	reloaded_main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _exercise_cultivation_loop(plot: Node2D) -> bool:
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GlobalInventory.semente_selecionada = "semente_basica"
	GlobalInventory.adicionar_item("semente_basica", 1)
	ToolManager.clear_tool()
	plot.call("_on_plot_clicked")
	var planted_data: Dictionary = _get_plot_save_data(plot)
	if str(planted_data.get("semente_id_plantada", "")) != "semente_basica":
		_fail("plot livre nao aceitou plantio real")
		return false

	GlobalInventory.adicionar_item("agua", 1)
	ToolManager.force_select_tool(ToolManager.ToolType.WATERING_CAN)
	plot.call("_on_plot_clicked")
	var watered_data: Dictionary = _get_plot_save_data(plot)
	if not bool(watered_data.get("regado", false)):
		_fail("plot livre nao aceitou rega real")
		return false

	plot.call("debug_force_ready_to_harvest")
	ToolManager.force_select_tool(ToolManager.ToolType.HARVEST)
	plot.call("_on_plot_clicked")
	var harvested_data: Dictionary = _get_plot_save_data(plot)
	if str(harvested_data.get("semente_id_plantada", "")) != "" or not bool(harvested_data.get("arado", false)):
		_fail("plot livre nao concluiu colheita preservando terra arada")
		return false
	return true


func _is_plot_tilled(plot: Node) -> bool:
	return bool(_get_plot_save_data(plot).get("arado", false))


func _get_plot_save_data(plot: Node) -> Dictionary:
	if plot == null or not plot.has_method("get_save_data"):
		return {}
	var save_variant: Variant = plot.call("get_save_data")
	if typeof(save_variant) != TYPE_DICTIONARY:
		return {}
	return save_variant


func _assert_snapshot_tile(main: Node, grid_position: Vector2i, expected_state: FarmTileData.TileState) -> bool:
	var snapshot_variant: Variant = main.call("obter_farm_grid_snapshot")
	if snapshot_variant is not FarmGridManager:
		_fail("Main nao forneceu snapshot do FarmGrid")
		return false
	var tile: FarmTileData = (snapshot_variant as FarmGridManager).get_tile(grid_position)
	if tile == null or tile.tile_state != expected_state:
		_fail("snapshot nao preservou estado %s em %s" % [str(expected_state), str(grid_position)])
		return false
	return true


func _get_grid_tile_count(farm_grid_variant: Variant) -> int:
	if typeof(farm_grid_variant) != TYPE_DICTIONARY:
		return -1
	var tiles_variant: Variant = (farm_grid_variant as Dictionary).get("tiles", [])
	if typeof(tiles_variant) != TYPE_ARRAY:
		return -1
	return (tiles_variant as Array).size()


func _assert_plot_count(expected: int, context: String) -> bool:
	var actual: int = get_tree().get_nodes_in_group("lotes_terra").size()
	if actual != expected:
		_fail("%s: esperado %d plots, obtido %d" % [context, expected, actual])
		return false
	return true


func _fail(message: String) -> void:
	ToolManager.clear_tool()
	push_error("FreeFarmingPilotSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
