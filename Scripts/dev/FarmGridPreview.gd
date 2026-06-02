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
			draw_rect(rect, _obter_cor_estado(tile.tile_state), true)
			draw_rect(rect, Color(0.08, 0.08, 0.08, 1.0), false, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if grid_manager == null:
		return
	if event is not InputEventMouseButton:
		return

	var mouse_button_event: InputEventMouseButton = event
	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT or not mouse_button_event.pressed:
		return

	var local_mouse_position: Vector2 = to_local(mouse_button_event.position)
	var tile_position: Vector2i = _obter_posicao_tile(local_mouse_position)
	if tile_position == Vector2i(-1, -1):
		return

	var tile: FarmTileData = grid_manager.get_tile(tile_position)
	if tile == null:
		return

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
	grid_manager.set_tile(tile_position, tile)
	queue_redraw()
	print("FarmGridPreview: tile (%d, %d) mudou para %s" % [tile_position.x, tile_position.y, _obter_nome_estado(novo_estado)])

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

func _obter_cor_estado(tile_state: FarmTileData.TileState) -> Color:
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

func _obter_nome_estado(tile_state: FarmTileData.TileState) -> String:
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
