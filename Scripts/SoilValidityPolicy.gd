extends RefCounted
class_name SoilValidityPolicy

const REASON_VALID: String = "valid"
const REASON_FARM_NOT_READY: String = "farm_not_ready"
const REASON_OUTSIDE_CULTIVABLE_BOUNDS: String = "outside_cultivable_bounds"
const REASON_CORRUPTED: String = "corrupted"
const REASON_WATER: String = "water"
const REASON_BUILDING: String = "building"
const REASON_OBSTACLE: String = "obstacle"
const REASON_RESERVED_ZONE: String = "reserved_zone"


static func evaluate(grid_position: Vector2i, context: Dictionary) -> Dictionary:
	if not bool(context.get("farm_ready", false)):
		return _result(false, REASON_FARM_NOT_READY, grid_position)

	var has_existing_plot: bool = bool(context.get("has_existing_plot", false))
	var is_corrupted: bool = bool(context.get("is_corrupted", false))
	var requires_purification: bool = bool(context.get("requires_purification", false))
	var is_area_purified: bool = bool(context.get("is_area_purified", true))
	if is_corrupted or (requires_purification and not is_area_purified):
		return _result(false, REASON_CORRUPTED, grid_position)

	# Compatibilidade transitória: um FarmPlot já registrado continua jogável
	# mesmo que tenha sido criado antes da política atual de limites e reservas.
	if has_existing_plot:
		return _result(true, REASON_VALID, grid_position)

	if not bool(context.get("inside_cultivable_bounds", false)):
		return _result(false, REASON_OUTSIDE_CULTIVABLE_BOUNDS, grid_position)
	if bool(context.get("has_water", false)):
		return _result(false, REASON_WATER, grid_position)
	if bool(context.get("has_building", false)):
		return _result(false, REASON_BUILDING, grid_position)
	if bool(context.get("has_obstacle", false)):
		return _result(false, REASON_OBSTACLE, grid_position)
	if bool(context.get("is_reserved_zone", false)):
		return _result(false, REASON_RESERVED_ZONE, grid_position)

	return _result(true, REASON_VALID, grid_position)


static func _result(is_valid: bool, reason: String, grid_position: Vector2i) -> Dictionary:
	return {
		"valid": is_valid,
		"reason": reason,
		"grid_position": grid_position,
	}
