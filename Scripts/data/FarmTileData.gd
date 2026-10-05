extends Resource
class_name FarmTileData

enum TileState {
	GRAMA,
	ARADO,
	MOLHADO,
	PLANTADO,
	BLOQUEADO
}

enum SoilType {
	COMUM,
	ENCANTADO,
	SOMBRIO,
	GELADO,
	FLAMEJANTE,
	LUNAR,
	INSTAVEL
}

@export var grid_position: Vector2i = Vector2i.ZERO
@export var tile_state: TileState = TileState.GRAMA
@export var soil_type: SoilType = SoilType.COMUM
@export var crop_id: String = ""
@export var is_watered: bool = false
@export var moisture: float = 0.0
@export var magic_stability: float = 1.0
@export var active_modifiers: Array[String] = []
@export var favored_season: String = ""
@export var occupant_id: String = ""
@export var remaining_growth_time: float = 0.0
@export var total_growth_time: float = 0.0
@export var pending_harvest_rewards: Dictionary = {}
@export var living_soil_treated: bool = false
@export var living_soil_moisture: bool = false
@export var flame_fertilizer_applied: bool = false

static func is_flame_fertilizer_valid(data: Dictionary) -> bool:
	var applied: Variant = data.get("flame_fertilizer_applied", false)
	if not applied is bool:
		return false
	if not applied:
		return true
	var grid := data.has("crop_id") or data.has("tile_state")
	var seed: Variant = data.get("crop_id", "") if grid else data.get("semente_id_plantada", "")
	var state: Variant = data.get("tile_state") if grid else data.get("estado_atual")
	if not seed is String or seed != "semente_verao" or typeof(state) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if not is_finite(float(state)) or float(state) != float(int(state)):
		return false
	if grid:
		if int(state) not in [TileState.MOLHADO, TileState.PLANTADO]:
			return false
	elif int(state) not in [1, 2] or data.get("expansion_blocked", false):
		return false
	var pending: Variant = data.get("pending_harvest_rewards", {})
	if not is_pending_harvest_valid(pending):
		return false
	if pending.is_empty():
		return true
	if int(pending.get("tomate_sol", 0)) < 3:
		return false
	# Recompensa já materializada só pode pertencer a uma colheita madura;
	# recusar antes de um load que descartaria o pending de cultura crescendo.
	var remaining: Variant = data.get("remaining_growth_time", 0.0) if grid else data.get("tempo_restante", 0.0)
	if typeof(remaining) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(remaining)) or float(remaining) < 0.0:
		return false
	return float(remaining) == 0.0 if grid or int(state) == 1 else true

static func is_pending_harvest_valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for item_id in value:
		if not item_id is String or not Database.itens.has(item_id):
			return false
		var quantity: Variant = value[item_id]
		if typeof(quantity) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(quantity)):
			return false
		if float(quantity) <= 0.0 or float(quantity) != float(int(quantity)):
			return false
	return true

func is_empty() -> bool:
	return crop_id == "" and occupant_id == ""

func can_till() -> bool:
	return tile_state == TileState.GRAMA

func can_plant() -> bool:
	return (tile_state == TileState.ARADO or tile_state == TileState.MOLHADO) and crop_id == "" and occupant_id == ""

func clear_crop() -> void:
	flame_fertilizer_applied = false
	living_soil_moisture = false
	crop_id = ""
	pending_harvest_rewards.clear()
	remaining_growth_time = 0.0
	total_growth_time = 0.0
	is_watered = false
	if tile_state == TileState.PLANTADO:
		if moisture > 0.0:
			tile_state = TileState.MOLHADO
		else:
			tile_state = TileState.ARADO

func to_save_data() -> Dictionary:
	var modifiers: Array[String] = active_modifiers.duplicate(true)
	return {
		"grid_position": {
			"x": grid_position.x,
			"y": grid_position.y
		},
		"tile_state": int(tile_state),
		"soil_type": int(soil_type),
		"crop_id": crop_id,
		"is_watered": is_watered,
		"moisture": moisture,
		"magic_stability": magic_stability,
		"active_modifiers": modifiers,
		"favored_season": favored_season,
		"occupant_id": occupant_id,
		"remaining_growth_time": remaining_growth_time,
		"total_growth_time": total_growth_time,
		"pending_harvest_rewards": pending_harvest_rewards.duplicate(true),
		"living_soil_treated": living_soil_treated,
		"living_soil_moisture": living_soil_moisture,
		"flame_fertilizer_applied": flame_fertilizer_applied
	}

func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	if not is_flame_fertilizer_valid(data):
		push_warning("FarmTileData: Adubo Flamejante invalido; tile nao alterado.")
		return
	var incoming_cell := _ler_vector2i_de_grid_position(data.get("grid_position", grid_position))
	if not LivingSoilState.validate_flags(data, incoming_cell):
		push_warning("FarmTileData: Solo Vivo invalido; tile nao alterado.")
		return
	if not is_pending_harvest_valid(data.get("pending_harvest_rewards", {})):
		push_warning("FarmTileData: recompensa pendente invalida; tile nao alterado.")
		return

	grid_position = _ler_vector2i_de_grid_position(data.get("grid_position", grid_position))
	living_soil_treated = data.get("living_soil_treated", false)
	living_soil_moisture = data.get("living_soil_moisture", false)
	flame_fertilizer_applied = data.get("flame_fertilizer_applied", false)
	tile_state = _normalizar_tile_state(int(data.get("tile_state", int(tile_state))))
	soil_type = _normalizar_soil_type(int(data.get("soil_type", int(soil_type))))
	crop_id = str(data.get("crop_id", crop_id))
	is_watered = bool(data.get("is_watered", is_watered))
	moisture = maxf(float(data.get("moisture", moisture)), 0.0)
	magic_stability = maxf(float(data.get("magic_stability", magic_stability)), 0.0)
	active_modifiers = _ler_array_string(data.get("active_modifiers", active_modifiers))
	favored_season = str(data.get("favored_season", favored_season))
	occupant_id = str(data.get("occupant_id", occupant_id))
	remaining_growth_time = maxf(float(data.get("remaining_growth_time", remaining_growth_time)), 0.0)
	total_growth_time = maxf(float(data.get("total_growth_time", total_growth_time)), 0.0)
	pending_harvest_rewards = data.get("pending_harvest_rewards", {}).duplicate(true)

	if crop_id == "":
		pending_harvest_rewards.clear()
		remaining_growth_time = 0.0
		total_growth_time = 0.0

func _ler_vector2i_de_grid_position(value: Variant) -> Vector2i:
	if typeof(value) == TYPE_VECTOR2I:
		return value
	if typeof(value) == TYPE_VECTOR2:
		var vector2_value: Vector2 = value
		return Vector2i(int(vector2_value.x), int(vector2_value.y))
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		var x_value: int = int(dictionary_value.get("x", grid_position.x))
		var y_value: int = int(dictionary_value.get("y", grid_position.y))
		return Vector2i(x_value, y_value)
	if typeof(value) == TYPE_ARRAY:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2i(int(array_value[0]), int(array_value[1]))
	return grid_position

func _ler_array_string(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	var source_array: Array = value
	for item in source_array:
		result.append(str(item))
	return result

func _normalizar_tile_state(value: int) -> TileState:
	if value < int(TileState.GRAMA) or value > int(TileState.BLOQUEADO):
		return tile_state
	return value

func _normalizar_soil_type(value: int) -> SoilType:
	if value < int(SoilType.COMUM) or value > int(SoilType.INSTAVEL):
		return soil_type
	return value
