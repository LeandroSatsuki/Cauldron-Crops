extends RefCounted
class_name FarmGridManagerSmokeTest

static func run() -> bool:
	print("FarmGridManagerSmokeTest: iniciando teste manual.")

	var manager: FarmGridManager = FarmGridManager.new()
	manager.create_grid(3, 3)

	if manager.width != 3:
		push_error("FarmGridManagerSmokeTest: width esperado 3, obtido %s." % manager.width)
		return false

	if manager.height != 3:
		push_error("FarmGridManagerSmokeTest: height esperado 3, obtido %s." % manager.height)
		return false

	var all_tiles: Array = manager.get_all_tiles()
	if all_tiles.size() != 9:
		push_error("FarmGridManagerSmokeTest: esperado 9 tiles, obtido %s." % all_tiles.size())
		return false

	var middle_position: Vector2i = Vector2i(1, 1)
	var tile: FarmTileData = manager.get_tile(middle_position)
	if tile == null:
		push_error("FarmGridManagerSmokeTest: tile central não encontrado.")
		return false

	tile.tile_state = FarmTileData.TileState.PLANTADO
	tile.soil_type = FarmTileData.SoilType.ENCANTADO
	tile.crop_id = "trigo"
	tile.is_watered = true
	tile.moisture = 0.75
	tile.magic_stability = 1.5
	tile.remaining_growth_time = 2.5
	tile.total_growth_time = 5.0
	manager.set_tile(middle_position, tile)

	var save_data: Dictionary = manager.to_save_data()
	print("FarmGridManagerSmokeTest: save_data gerado com %s tiles." % _get_tiles_count_from_save(save_data))

	var loaded_manager: FarmGridManager = FarmGridManager.new()
	loaded_manager.load_save_data(save_data)

	if loaded_manager.width != 3:
		push_error("FarmGridManagerSmokeTest: width carregado esperado 3, obtido %s." % loaded_manager.width)
		return false

	if loaded_manager.height != 3:
		push_error("FarmGridManagerSmokeTest: height carregado esperado 3, obtido %s." % loaded_manager.height)
		return false

	var loaded_tile: FarmTileData = loaded_manager.get_tile(middle_position)
	if loaded_tile == null:
		push_error("FarmGridManagerSmokeTest: tile central não restaurado.")
		return false

	if loaded_tile.tile_state != FarmTileData.TileState.PLANTADO:
		push_error("FarmGridManagerSmokeTest: tile_state não foi restaurado corretamente.")
		return false

	if loaded_tile.soil_type != FarmTileData.SoilType.ENCANTADO:
		push_error("FarmGridManagerSmokeTest: soil_type não foi restaurado corretamente.")
		return false

	if loaded_tile.crop_id != "trigo":
		push_error("FarmGridManagerSmokeTest: crop_id não foi restaurado corretamente.")
		return false

	if not loaded_tile.is_watered:
		push_error("FarmGridManagerSmokeTest: is_watered não foi restaurado corretamente.")
		return false

	if absf(loaded_tile.moisture - 0.75) > 0.001:
		push_error("FarmGridManagerSmokeTest: moisture não foi restaurado corretamente.")
		return false

	if absf(loaded_tile.magic_stability - 1.5) > 0.001:
		push_error("FarmGridManagerSmokeTest: magic_stability não foi restaurado corretamente.")
		return false

	if absf(loaded_tile.remaining_growth_time - 2.5) > 0.001:
		push_error("FarmGridManagerSmokeTest: remaining_growth_time não foi restaurado corretamente.")
		return false

	if absf(loaded_tile.total_growth_time - 5.0) > 0.001:
		push_error("FarmGridManagerSmokeTest: total_growth_time não foi restaurado corretamente.")
		return false

	print("FarmGridManagerSmokeTest: teste concluído com sucesso.")
	return true

static func _get_tiles_count_from_save(save_data: Dictionary) -> int:
	var tiles_value: Variant = save_data.get("tiles", [])
	if typeof(tiles_value) != TYPE_ARRAY:
		return 0
	return (tiles_value as Array).size()
