extends Node2D

var grid_manager: FarmGridManager = null
var tile_size: int = 48
var tile_gap: int = 2
var origin: Vector2 = Vector2(100.0, 100.0)

func _ready() -> void:
	grid_manager = FarmGridManager.new()
	grid_manager.create_grid(5, 5)
	set_process_unhandled_input(true)
	queue_redraw()

func _draw() -> void:
	if grid_manager == null:
		return

	for y in range(grid_manager.height):
		for x in range(grid_manager.width):
			var position: Vector2i = Vector2i(x, y)
			var tile: FarmTileData = grid_manager.get_tile(position)
			if tile == null:
				continue

			var rect: Rect2 = _obter_rect_tile(position)
			draw_rect(rect, _get_tile_state_color(tile.tile_state), true)
			draw_rect(rect, _get_soil_type_color(tile.soil_type), false, 3.0)
			draw_rect(rect, Color(0.08, 0.08, 0.08, 1.0), false, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if grid_manager == null:
		return
	if event is not InputEventMouseButton:
		return

	var mouse_button_event: InputEventMouseButton = event
	if not mouse_button_event.pressed:
		return

	var local_mouse_position: Vector2 = to_local(mouse_button_event.position)
	var tile_position: Vector2i = _get_grid_position_from_local_position(local_mouse_position)
	if tile_position == Vector2i(-1, -1):
		return

	if not grid_manager.has_tile(tile_position):
		return

	var tile: FarmTileData = grid_manager.get_tile(tile_position)
	if tile == null:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
		_advance_tile_state(tile)
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: tile (%d, %d) mudou para %s" % [tile_position.x, tile_position.y, _get_tile_state_name(tile.tile_state)])
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
		_advance_soil_type(tile)
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: tile (%d, %d) mudou solo para %s" % [tile_position.x, tile_position.y, _get_soil_type_name(tile.soil_type)])
		return

func _advance_tile_state(tile: FarmTileData) -> void:
	var novo_estado: FarmTileData.TileState = tile.tile_state
	match tile.tile_state:
		FarmTileData.TileState.GRAMA:
			novo_estado = FarmTileData.TileState.ARADO
		FarmTileData.TileState.ARADO:
			novo_estado = FarmTileData.TileState.MOLHADO
		FarmTileData.TileState.MOLHADO:
			novo_estado = FarmTileData.TileState.GRAMA
		_:
			return

	tile.tile_state = novo_estado

func _advance_soil_type(tile: FarmTileData) -> void:
	var novo_soil_type: FarmTileData.SoilType = tile.soil_type
	match tile.soil_type:
		FarmTileData.SoilType.COMUM:
			novo_soil_type = FarmTileData.SoilType.ENCANTADO
		FarmTileData.SoilType.ENCANTADO:
			novo_soil_type = FarmTileData.SoilType.SOMBRIO
		FarmTileData.SoilType.SOMBRIO:
			novo_soil_type = FarmTileData.SoilType.GELADO
		FarmTileData.SoilType.GELADO:
			novo_soil_type = FarmTileData.SoilType.FLAMEJANTE
		FarmTileData.SoilType.FLAMEJANTE:
			novo_soil_type = FarmTileData.SoilType.LUNAR
		FarmTileData.SoilType.LUNAR:
			novo_soil_type = FarmTileData.SoilType.INSTAVEL
		FarmTileData.SoilType.INSTAVEL:
			novo_soil_type = FarmTileData.SoilType.COMUM
		_:
			novo_soil_type = FarmTileData.SoilType.COMUM

	tile.soil_type = novo_soil_type

func _obter_rect_tile(position: Vector2i) -> Rect2:
	var passo: int = tile_size + tile_gap
	var top_left: Vector2 = origin + Vector2(float(position.x * passo), float(position.y * passo))
	return Rect2(top_left, Vector2(float(tile_size), float(tile_size)))

func _obter_posicao_tile(mouse_position: Vector2) -> Vector2i:
	if grid_manager == null:
		return Vector2i(-1, -1)

	for y in range(grid_manager.height):
		for x in range(grid_manager.width):
			var position: Vector2i = Vector2i(x, y)
			var rect: Rect2 = _obter_rect_tile(position)
			if rect.has_point(mouse_position):
				return position

	return Vector2i(-1, -1)

func _get_grid_position_from_local_position(local_position: Vector2) -> Vector2i:
	return _obter_posicao_tile(local_position)

func _get_tile_state_color(tile_state: FarmTileData.TileState) -> Color:
	match tile_state:
		FarmTileData.TileState.GRAMA:
			return Color(0.25, 0.62, 0.25, 1.0)
		FarmTileData.TileState.ARADO:
			return Color(0.49, 0.30, 0.14, 1.0)
		FarmTileData.TileState.MOLHADO:
			return Color(0.18, 0.34, 0.54, 1.0)
		FarmTileData.TileState.PLANTADO:
			return Color(0.20, 0.74, 0.30, 1.0)
		FarmTileData.TileState.BLOQUEADO:
			return Color(0.50, 0.50, 0.50, 1.0)
		_:
			return Color(0.30, 0.30, 0.30, 1.0)

func _get_tile_state_name(tile_state: FarmTileData.TileState) -> String:
	match tile_state:
		FarmTileData.TileState.GRAMA:
			return "GRAMA"
		FarmTileData.TileState.ARADO:
			return "ARADO"
		FarmTileData.TileState.MOLHADO:
			return "MOLHADO"
		FarmTileData.TileState.PLANTADO:
			return "PLANTADO"
		FarmTileData.TileState.BLOQUEADO:
			return "BLOQUEADO"
		_:
			return "DESCONHECIDO"

func _get_soil_type_color(soil_type: FarmTileData.SoilType) -> Color:
	match soil_type:
		FarmTileData.SoilType.COMUM:
			return Color(0.92, 0.92, 0.92, 1.0)
		FarmTileData.SoilType.ENCANTADO:
			return Color(0.58, 0.30, 0.78, 1.0)
		FarmTileData.SoilType.SOMBRIO:
			return Color(0.12, 0.12, 0.12, 1.0)
		FarmTileData.SoilType.GELADO:
			return Color(0.45, 0.80, 0.95, 1.0)
		FarmTileData.SoilType.FLAMEJANTE:
			return Color(0.95, 0.42, 0.12, 1.0)
		FarmTileData.SoilType.LUNAR:
			return Color(0.58, 0.46, 0.90, 1.0)
		FarmTileData.SoilType.INSTAVEL:
			return Color(0.95, 0.18, 0.72, 1.0)
		_:
			return Color(0.92, 0.92, 0.92, 1.0)

func _get_soil_type_name(soil_type: FarmTileData.SoilType) -> String:
	match soil_type:
		FarmTileData.SoilType.COMUM:
			return "COMUM"
		FarmTileData.SoilType.ENCANTADO:
			return "ENCANTADO"
		FarmTileData.SoilType.SOMBRIO:
			return "SOMBRIO"
		FarmTileData.SoilType.GELADO:
			return "GELADO"
		FarmTileData.SoilType.FLAMEJANTE:
			return "FLAMEJANTE"
		FarmTileData.SoilType.LUNAR:
			return "LUNAR"
		FarmTileData.SoilType.INSTAVEL:
			return "INSTAVEL"
		_:
			return "COMUM"
