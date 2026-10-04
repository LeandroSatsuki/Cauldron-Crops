extends RefCounted
class_name GolemWorkState

const VERSION := 1
const REQUIRED_KEYS := ["version", "seeding_enabled", "work_priority", "harvest_cargo", "seed_cargo"]
const ACCELERATOR_KEYS := ["accelerator_prepared", "accelerator_active", "harvest_delivery_started"]

static func default_data() -> Dictionary:
	return {"version": VERSION, "seeding_enabled": false, "work_priority": 0, "harvest_cargo": {}, "seed_cargo": null,
		"accelerator_prepared": false, "accelerator_active": false, "harvest_delivery_started": false}

static func accelerator_flags(data: Dictionary) -> Dictionary:
	# Cargo legado é conservadoramente uma entrega já iniciada. Ausentes não
	# herdam flags runtime, mesmo quando os totais da nova carga são iguais.
	return {"accelerator_prepared": data.get("accelerator_prepared", false),
		"accelerator_active": data.get("accelerator_active", false),
		"harvest_delivery_started": data.get("harvest_delivery_started", not data.get("harvest_cargo", {}).is_empty())}

static func is_valid(value: Variant, grove_restored: bool) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if not data.has_all(REQUIRED_KEYS):
		return false
	for key in data:
		if key not in REQUIRED_KEYS and key not in ACCELERATOR_KEYS:
			return false
	for key in ACCELERATOR_KEYS:
		if data.has(key) and not data[key] is bool:
			return false
	if typeof(data["version"]) not in [TYPE_INT, TYPE_FLOAT] or data["version"] != VERSION:
		return false
	if not data["seeding_enabled"] is bool:
		return false
	var priority: Variant = data["work_priority"]
	if typeof(priority) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(priority)) or priority < 0 or priority > 4 or float(int(priority)) != float(priority):
		return false
	if not FarmTileData.is_pending_harvest_valid(data["harvest_cargo"]) or not GolemSeedCargo.is_save_data_valid(data["seed_cargo"]):
		return false
	var has_seed: bool = data["seed_cargo"] != null
	if (data["seeding_enabled"] or has_seed) and not grove_restored:
		return false
	if has_seed:
		if not data["harvest_cargo"].is_empty():
			return false
		if not data["seeding_enabled"] and data["seed_cargo"]["intent"] != GolemSeedCargo.INTENT_RETURN:
			return false
	var flags := accelerator_flags(data)
	if flags["accelerator_prepared"] and flags["accelerator_active"]:
		return false
	if flags["harvest_delivery_started"] and (data["harvest_cargo"].is_empty() or has_seed):
		return false
	if flags["accelerator_active"] and not flags["harvest_delivery_started"]:
		return false
	return true

static func harvest_totals(rewards: Array) -> Variant:
	var totals: Dictionary = {}
	for reward in rewards:
		if not reward is Dictionary or not reward.has_all(["item_id", "quantidade"]):
			return null
		var item_id: Variant = reward["item_id"]
		var quantity: Variant = reward["quantidade"]
		if not item_id is String or not FarmTileData.is_pending_harvest_valid({item_id: quantity}):
			return null
		totals[item_id] = int(totals.get(item_id, 0)) + int(quantity)
	return totals if FarmTileData.is_pending_harvest_valid(totals) else null

static func harvest_rewards(totals: Dictionary) -> Array:
	var rewards: Array = []
	for item_id in totals:
		rewards.append({"item_id": item_id, "quantidade": int(totals[item_id])})
	return rewards
