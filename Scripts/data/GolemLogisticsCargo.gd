extends RefCounted
class_name GolemLogisticsCargo

# Uma saída convertida inteira. Não é semente de plantio nem colheita.
const SOURCE_ID := "cauldron_village"
const KEYS := ["order_id", "step", "source_id", "item_id", "quantity"]
var _payload: Dictionary = {}

func has_cargo() -> bool:
	return not _payload.is_empty()

func get_item_id() -> String:
	return str(_payload.get("item_id", ""))

func get_save_data() -> Variant:
	return _payload.duplicate(true) if has_cargo() else null

func accepts(value: Variant) -> bool:
	return not has_cargo() and value != null and is_save_data_valid(value)

func accept(value: Dictionary) -> bool:
	if not accepts(value):
		return false
	return apply_save_data(value)

func matches(value: Variant) -> bool:
	if not has_cargo() or value == null or not is_save_data_valid(value):
		return false
	return _payload["order_id"] == value["order_id"] and _payload["source_id"] == value["source_id"] \
		and _payload["item_id"] == value["item_id"] and int(_payload["step"]) == int(value["step"]) \
		and int(_payload["quantity"]) == int(value["quantity"])

func clear(expected: Dictionary) -> bool:
	if not matches(expected):
		return false
	_payload.clear()
	return true

func apply_save_data(value: Variant) -> bool:
	if not is_save_data_valid(value):
		return false
	_payload = {} if value == null else (value as Dictionary).duplicate(true)
	if has_cargo():
		_payload["step"] = int(_payload["step"])
		_payload["quantity"] = int(_payload["quantity"])
	return true

static func is_save_data_valid(value: Variant) -> bool:
	if value == null:
		return true
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if data.size() != KEYS.size() or not data.has_all(KEYS):
		return false
	if typeof(data["order_id"]) != TYPE_STRING or data["order_id"].strip_edges() == "" or data["order_id"] != data["order_id"].strip_edges():
		return false
	if typeof(data["source_id"]) != TYPE_STRING or data["source_id"] != SOURCE_ID:
		return false
	if not GolemSeedCargo.is_selectable_seed_id(data["item_id"]):
		return false
	return _positive_integer(data["step"]) and _positive_integer(data["quantity"])

static func _positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and value > 0 and float(value) < 9223372036854775807.0 and float(int(value)) == float(value)
