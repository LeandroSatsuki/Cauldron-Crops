extends Node2D

enum ToolType {
	NONE,
	HOE,
	SEED,
	WATERING_CAN
}

const DEBUG_GROWTH_STEP: float = 2.5

@onready var tool_label: Label = $ToolLabel

var grid_manager: FarmGridManager = null
var active_tool: ToolType = ToolType.HOE
var tile_size: int = 48
var tile_gap: int = 2
var origin: Vector2 = Vector2(100.0, 100.0)

func _ready() -> void:
	grid_manager = FarmGridManager.new()
	grid_manager.create_grid(5, 5)
	set_process_unhandled_input(true)
	_atualizar_texto_ferramenta()
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
			if tile.tile_state == FarmTileData.TileState.PLANTADO and tile.crop_id != "":
				var center: Vector2 = rect.position + (rect.size * 0.5)
				var growth_stage: int = _get_growth_stage(tile)
				var marker_size: float = _get_growth_marker_size(growth_stage)
				var marker_rect: Rect2 = Rect2(center - Vector2(marker_size * 0.5, marker_size * 0.5), Vector2(marker_size, marker_size))
				draw_rect(marker_rect, _get_growth_marker_color(growth_stage), true)
				draw_rect(marker_rect, Color(0.20, 0.20, 0.20, 1.0), false, 1.0)
			if tile.tile_state == FarmTileData.TileState.PLANTADO and tile.is_watered:
				var watered_marker_size: float = 8.0
				var watered_marker_rect: Rect2 = Rect2(rect.position + Vector2(rect.size.x - watered_marker_size - 6.0, 6.0), Vector2(watered_marker_size, watered_marker_size))
				draw_rect(watered_marker_rect, Color(0.35, 0.75, 1.0, 1.0), true)
				draw_rect(watered_marker_rect, Color(0.08, 0.20, 0.30, 1.0), false, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if grid_manager == null:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_D:
			_simular_decay_diario()
			return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_G:
			_simular_crescimento_debug()
			return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_1:
			_definir_ferramenta(ToolType.HOE)
			return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_2:
			_definir_ferramenta(ToolType.SEED)
			return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_3:
			_definir_ferramenta(ToolType.WATERING_CAN)
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
		_usar_ferramenta_ativa(tile_position, tile)
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
		_advance_soil_type(tile)
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: tile (%d, %d) mudou solo para %s" % [tile_position.x, tile_position.y, _get_soil_type_name(tile.soil_type)])
		return

func _usar_ferramenta_ativa(tile_position: Vector2i, tile: FarmTileData) -> void:
	match active_tool:
		ToolType.HOE:
			_usar_enxada(tile_position, tile)
		ToolType.SEED:
			_usar_semente(tile_position, tile)
		ToolType.WATERING_CAN:
			_usar_regador(tile_position, tile)
		_:
			print("FarmGridPreview: nenhuma ferramenta ativa no tile (%d, %d)." % [tile_position.x, tile_position.y])

func _usar_enxada(tile_position: Vector2i, tile: FarmTileData) -> void:
	if tile.tile_state == FarmTileData.TileState.BLOQUEADO:
		print("FarmGridPreview: Enxada sem efeito no tile (%d, %d): BLOQUEADO." % [tile_position.x, tile_position.y])
		return

	if tile.tile_state == FarmTileData.TileState.GRAMA:
		tile.tile_state = FarmTileData.TileState.ARADO
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: Enxada usou no tile (%d, %d): GRAMA -> ARADO" % [tile_position.x, tile_position.y])
		return

	print("FarmGridPreview: Enxada sem efeito no tile (%d, %d): %s." % [tile_position.x, tile_position.y, _get_tile_state_name(tile.tile_state)])

func _usar_semente(tile_position: Vector2i, tile: FarmTileData) -> void:
	if (tile.tile_state == FarmTileData.TileState.ARADO or tile.tile_state == FarmTileData.TileState.MOLHADO) and tile.crop_id == "":
		var estava_molhado: bool = tile.tile_state == FarmTileData.TileState.MOLHADO
		tile.tile_state = FarmTileData.TileState.PLANTADO
		tile.crop_id = "debug_crop"
		tile.remaining_growth_time = 10.0
		tile.total_growth_time = 10.0
		tile.is_watered = estava_molhado
		tile.moisture = 1.0 if tile.is_watered else 0.0
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: Semente plantada no tile (%d, %d)." % [tile_position.x, tile_position.y])
		return

	print("FarmGridPreview: Semente sem efeito no tile (%d, %d): %s." % [tile_position.x, tile_position.y, _get_tile_state_name(tile.tile_state)])

func _usar_regador(tile_position: Vector2i, tile: FarmTileData) -> void:
	if tile.tile_state == FarmTileData.TileState.ARADO:
		tile.tile_state = FarmTileData.TileState.MOLHADO
		tile.is_watered = true
		tile.moisture = 1.0
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: Regador molhou o tile (%d, %d)." % [tile_position.x, tile_position.y])
		return

	if tile.tile_state == FarmTileData.TileState.PLANTADO:
		tile.is_watered = true
		tile.moisture = 1.0
		grid_manager.set_tile(tile_position, tile)
		queue_redraw()
		print("FarmGridPreview: Regador molhou a plantacao no tile (%d, %d)." % [tile_position.x, tile_position.y])
		return

	print("FarmGridPreview: Regador sem efeito no tile (%d, %d): %s." % [tile_position.x, tile_position.y, _get_tile_state_name(tile.tile_state)])

func _simular_decay_diario() -> void:
	if grid_manager == null:
		return

	var tiles_limpos: int = 0
	var tiles: Array = grid_manager.get_all_tiles()
	for tile_variant in tiles:
		if tile_variant is not FarmTileData:
			continue

		var tile: FarmTileData = tile_variant
		if (tile.tile_state == FarmTileData.TileState.ARADO or tile.tile_state == FarmTileData.TileState.MOLHADO) and tile.crop_id == "":
			tile.tile_state = FarmTileData.TileState.GRAMA
			tile.is_watered = false
			tile.moisture = 0.0
			grid_manager.set_tile(tile.grid_position, tile)
			tiles_limpos += 1
		elif tile.tile_state == FarmTileData.TileState.PLANTADO and tile.crop_id != "":
			tile.is_watered = false
			tile.moisture = 0.0
			grid_manager.set_tile(tile.grid_position, tile)

	queue_redraw()
	print("FarmGridPreview: decay diario limpou %d tile(s) arados sem semente." % tiles_limpos)

func _simular_crescimento_debug() -> void:
	if grid_manager == null:
		return

	var tiles_crescidos: int = 0
	var tiles: Array = grid_manager.get_all_tiles()
	for tile_variant in tiles:
		if tile_variant is not FarmTileData:
			continue

		var tile: FarmTileData = tile_variant
		if tile.crop_id == "":
			continue
		if not tile.is_watered:
			continue
		if tile.remaining_growth_time <= 0.0:
			continue

		tile.remaining_growth_time = maxf(tile.remaining_growth_time - DEBUG_GROWTH_STEP, 0.0)
		grid_manager.set_tile(tile.grid_position, tile)
		tiles_crescidos += 1
		print("FarmGridPreview: crescimento no tile (%d, %d) -> %.2f/%.2f" % [tile.grid_position.x, tile.grid_position.y, tile.remaining_growth_time, tile.total_growth_time])

	queue_redraw()
	print("FarmGridPreview: crescimento debug aplicado em %d tile(s) irrigados." % tiles_crescidos)

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

func _get_growth_stage(tile: FarmTileData) -> int:
	if tile == null:
		return 0
	if tile.crop_id == "":
		return 0
	if tile.remaining_growth_time <= 0.0:
		return 3
	if tile.total_growth_time <= 0.0:
		return 1

	var proporcao_restante: float = clampf(tile.remaining_growth_time / tile.total_growth_time, 0.0, 1.0)
	if proporcao_restante > 0.66:
		return 1
	if proporcao_restante > 0.33:
		return 2
	return 3

func _get_growth_marker_size(growth_stage: int) -> float:
	match growth_stage:
		1:
			return 8.0
		2:
			return 12.0
		3:
			return 16.0
		_:
			return 0.0

func _get_growth_marker_color(growth_stage: int) -> Color:
	match growth_stage:
		1:
			return Color(0.90, 0.95, 0.40, 1.0)
		2:
			return Color(0.98, 0.86, 0.28, 1.0)
		3:
			return Color(0.98, 0.98, 0.70, 1.0)
		_:
			return Color(0.95, 0.95, 0.30, 1.0)

func _get_tool_name(tool: int) -> String:
	match tool:
		ToolType.HOE:
			return "Enxada"
		ToolType.SEED:
			return "Semente"
		ToolType.WATERING_CAN:
			return "Regador"
		ToolType.NONE:
			return "Nenhuma"
		_:
			return "Nenhuma"

func _definir_ferramenta(nova_ferramenta: ToolType) -> void:
	active_tool = nova_ferramenta
	_atualizar_texto_ferramenta()
	queue_redraw()
	print("FarmGridPreview: ferramenta ativa = %s" % _get_tool_name(active_tool))

func _atualizar_texto_ferramenta() -> void:
	if tool_label:
		tool_label.text = "Ferramenta ativa: %s" % _get_tool_name(active_tool)
