extends RefCounted
class_name FarmGridManager

var width: int = 0
var height: int = 0
var tiles: Dictionary = {}

func create_grid(grid_width: int, grid_height: int) -> void:
	clear()

	if grid_width <= 0 or grid_height <= 0:
		return

	width = grid_width
	height = grid_height

	for y in range(height):
		for x in range(width):
			var position: Vector2i = Vector2i(x, y)
			var tile: FarmTileData = FarmTileData.new()
			tile.grid_position = position
			tiles[position] = tile

func has_tile(position: Vector2i) -> bool:
	return tiles.has(position)

func get_tile(position: Vector2i) -> FarmTileData:
	if not tiles.has(position):
		return null

	var tile_variant: Variant = tiles.get(position)
	if tile_variant is FarmTileData:
		return tile_variant
	return null

func set_tile(position: Vector2i, tile: FarmTileData) -> void:
	if tile == null:
		return

	tile.grid_position = position
	tiles[position] = tile

func get_all_tiles() -> Array:
	var result: Array = []
	if tiles.is_empty():
		return result

	var positions: Array = tiles.keys()
	positions.sort_custom(Callable(self, "_ordenar_posicoes"))

	for position_variant in positions:
		var position: Vector2i = position_variant
		var tile: FarmTileData = get_tile(position)
		if tile != null:
			result.append(tile)

	return result

func clear() -> void:
	width = 0
	height = 0
	tiles.clear()

func to_save_data() -> Dictionary:
	var tiles_data: Array = []
	var ordered_tiles: Array = get_all_tiles()
	for tile_variant in ordered_tiles:
		var tile: FarmTileData = tile_variant
		if tile != null:
			tiles_data.append(tile.to_save_data())

	return {
		"width": width,
		"height": height,
		"tiles": tiles_data
	}

func load_save_data(data: Dictionary) -> void:
	clear()

	if data.is_empty():
		return

	width = max(0, int(data.get("width", 0)))
	height = max(0, int(data.get("height", 0)))

	var tiles_data: Array = _safe_array(data.get("tiles", []))
	for tile_data_variant in tiles_data:
		if typeof(tile_data_variant) != TYPE_DICTIONARY:
			continue

		var tile_data: Dictionary = tile_data_variant
		var tile: FarmTileData = FarmTileData.new()
		tile.load_save_data(tile_data)
		var position: Vector2i = tile.grid_position
		tiles[position] = tile

	if width <= 0 or height <= 0:
		_recalcular_tamanho_da_grade()

func _ordenar_posicoes(a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_VECTOR2I or typeof(b) != TYPE_VECTOR2I:
		return false

	var pos_a: Vector2i = a
	var pos_b: Vector2i = b
	if pos_a.y == pos_b.y:
		return pos_a.x < pos_b.x
	return pos_a.y < pos_b.y

func _safe_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []

func _recalcular_tamanho_da_grade() -> void:
	var max_x: int = -1
	var max_y: int = -1

	for position_variant in tiles.keys():
		if typeof(position_variant) != TYPE_VECTOR2I:
			continue

		var position: Vector2i = position_variant
		if position.x > max_x:
			max_x = position.x
		if position.y > max_y:
			max_y = position.y

	width = max_x + 1 if max_x >= 0 else 0
	height = max_y + 1 if max_y >= 0 else 0
