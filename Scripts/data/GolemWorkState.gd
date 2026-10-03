extends RefCounted
class_name GolemWorkState

const VERSION := 1

static func default_data() -> Dictionary:
	return {"version": VERSION, "seeding_enabled": false, "work_priority": 0, "harvest_cargo": {}, "seed_cargo": null}

static func is_valid(value: Variant, grove_restored: bool) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if data.size() != 5 or not data.has_all(["version", "seeding_enabled", "work_priority", "harvest_cargo", "seed_cargo"]):
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
