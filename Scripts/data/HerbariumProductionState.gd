extends RefCounted
class_name HerbariumProductionState

const RENEWAL_SECONDS := 90.0

static func default_data() -> Dictionary:
	return {"activated": false, "renewal_remaining": 0.0}

static func is_valid(value: Variant) -> bool:
	if not value is Dictionary or not value.has_all(["activated", "renewal_remaining"]):
		return false
	if value.size() != 2 or not value["activated"] is bool:
		return false
	var remaining: Variant = value["renewal_remaining"]
	if typeof(remaining) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(remaining)):
		return false
	if float(remaining) < 0.0 or float(remaining) > RENEWAL_SECONDS:
		return false
	return value["activated"] or float(remaining) == 0.0
