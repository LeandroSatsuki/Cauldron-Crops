extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const TARGET_POSITION := Vector2i(0, 0)
const EXPECTED_INITIAL_PLOT_COUNT := 34


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var target_variant: Variant = main.call("obter_farm_plot_por_grid_position", TARGET_POSITION)
	if not (target_variant is Node2D) or not is_instance_valid(target_variant):
		_fail("FarmPlot autoridade nao encontrado em %s" % TARGET_POSITION)
		return
	var target: Node2D = target_variant
	_set_plot_tilled(target, false)

	var snapshot_variant: Variant = main.call("obter_farm_grid_snapshot")
	if snapshot_variant is not FarmGridManager:
		_fail("Main nao forneceu snapshot do FarmGrid")
		return
	var external_snapshot: FarmGridManager = snapshot_variant
	var external_tile: FarmTileData = external_snapshot.get_tile(TARGET_POSITION)
	if external_tile == null:
		_fail("snapshot nao contem o tile alvo")
		return

	external_tile.tile_state = FarmTileData.TileState.PLANTADO
	external_tile.crop_id = "trigo"
	external_tile.soil_type = FarmTileData.SoilType.ENCANTADO
	external_snapshot.set_tile(TARGET_POSITION, external_tile)
	external_snapshot.remove_tile(Vector2i(1, 0))

	if _is_plot_tilled(target) or _get_plot_crop_id(target) != "":
		_fail("mutacao externa do snapshot alterou o FarmPlot autoridade")
		return
	if main.call("obter_farm_plot_por_grid_position", Vector2i(1, 0)) == null:
		_fail("remocao externa do snapshot removeu identidade canonica")
		return

	var fresh_snapshot_variant: Variant = main.call("obter_farm_grid_manager")
	if fresh_snapshot_variant is not FarmGridManager:
		_fail("alias de compatibilidade nao forneceu snapshot")
		return
	var fresh_snapshot: FarmGridManager = fresh_snapshot_variant
	var fresh_tile: FarmTileData = fresh_snapshot.get_tile(TARGET_POSITION)
	if fresh_tile == null:
		_fail("novo snapshot perdeu o tile alvo")
		return
	if fresh_tile.tile_state != FarmTileData.TileState.GRAMA or fresh_tile.crop_id != "":
		_fail("mutacao externa vazou para snapshots seguintes")
		return
	if fresh_tile.soil_type != FarmTileData.SoilType.COMUM:
		_fail("metadado laboratorial vazou para o snapshot do mundo")
		return

	_set_plot_tilled(target, true)
	await get_tree().process_frame
	var plot_snapshot: FarmGridManager = main.call("obter_farm_grid_snapshot")
	var plot_tile: FarmTileData = plot_snapshot.get_tile(TARGET_POSITION)
	if plot_tile == null or plot_tile.tile_state != FarmTileData.TileState.ARADO:
		_fail("mudanca no FarmPlot nao foi espelhada no snapshot")
		return
	var built_save_variant: Variant = SaveManager.call("_build_save_data")
	if typeof(built_save_variant) != TYPE_DICTIONARY:
		_fail("SaveManager nao produziu um dicionario de save")
		return
	var built_save: Dictionary = built_save_variant
	var built_grid_variant: Variant = built_save.get("farm_grid", {})
	if typeof(built_grid_variant) != TYPE_DICTIONARY:
		_fail("SaveManager nao serializou o snapshot do FarmGrid")
		return
	var built_grid: Dictionary = built_grid_variant
	var built_tiles_variant: Variant = built_grid.get("tiles", [])
	if typeof(built_tiles_variant) != TYPE_ARRAY or (built_tiles_variant as Array).size() != EXPECTED_INITIAL_PLOT_COUNT:
		_fail("SaveManager nao serializou os 34 tiles canonicos")
		return
	var target_tile_data: Dictionary = _find_tile_save_data(built_tiles_variant as Array, TARGET_POSITION)
	if target_tile_data.is_empty() or int(target_tile_data.get("tile_state", -1)) != int(FarmTileData.TileState.ARADO):
		_fail("SaveManager nao serializou o estado autoritativo do FarmPlot")
		return

	var grass_grid := FarmGridManager.new()
	var grass_tile := FarmTileData.new()
	grass_tile.tile_state = FarmTileData.TileState.GRAMA
	grass_grid.set_tile(TARGET_POSITION, grass_tile)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 4,
		"farm_grid": grass_grid.to_save_data(),
	})):
		_fail("bridge de load recusou grid v4 valido")
		return
	await get_tree().process_frame
	if _is_plot_tilled(target):
		_fail("bridge de load nao aplicou o grid ao FarmPlot autoridade")
		return
	if main.call("obter_farm_plot_por_grid_position", TARGET_POSITION) != target:
		_fail("bridge de load substituiu a identidade do FarmPlot")
		return
	if get_tree().get_nodes_in_group("lotes_terra").size() != EXPECTED_INITIAL_PLOT_COUNT:
		_fail("contrato transitório alterou a quantidade de plots")
		return

	print(
		"FarmGridContractSmokeTest: PASS - FarmPlot e autoridade; FarmGrid e snapshot isolado e bridge de save/load."
	)
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _set_plot_tilled(plot: Node2D, tilled: bool) -> void:
	plot.call("load_save_data", {
		"estado_atual": 0,
		"semente_id_plantada": "",
		"regado": false,
		"arado": tilled,
		"tempo_restante": 0.0,
		"tempo_total_crescimento": 0.0,
		"pronto_para_colher": false,
	})


func _is_plot_tilled(plot: Node2D) -> bool:
	var save_data_variant: Variant = plot.call("get_save_data")
	if typeof(save_data_variant) != TYPE_DICTIONARY:
		return false
	return bool((save_data_variant as Dictionary).get("arado", false))


func _get_plot_crop_id(plot: Node2D) -> String:
	var save_data_variant: Variant = plot.call("get_save_data")
	if typeof(save_data_variant) != TYPE_DICTIONARY:
		return ""
	return str((save_data_variant as Dictionary).get("semente_id_plantada", ""))


func _find_tile_save_data(tiles: Array, grid_position: Vector2i) -> Dictionary:
	for tile_variant in tiles:
		if typeof(tile_variant) != TYPE_DICTIONARY:
			continue
		var tile_data: Dictionary = tile_variant
		var position_variant: Variant = tile_data.get("grid_position", {})
		if typeof(position_variant) != TYPE_DICTIONARY:
			continue
		var position_data: Dictionary = position_variant
		if int(position_data.get("x", -1)) == grid_position.x and int(position_data.get("y", -1)) == grid_position.y:
			return tile_data
	return {}


func _fail(message: String) -> void:
	push_error("FarmGridContractSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
