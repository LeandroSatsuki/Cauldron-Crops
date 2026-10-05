extends RefCounted
class_name SeedDeliveryOrder

# Contrato específico do único pedido de sementes; não é uma fila logística.
const SOURCE_ID := "cauldron_village"
const DESTINATION := "village_storage"
const ITEM_IDS := ["semente_basica", "semente_verao"]
const PHASES := ["brewing", "ready", "carried", "refund_pending"]
const KEYS := ["order_id", "source_id", "recipe_id", "result_item", "result_quantity", "seconds_per_craft", "total", "converted", "delivered", "refunded", "cancelled", "phase", "time_remaining", "ingredients", "reservations", "output"]
const PAYLOAD_KEYS := ["order_id", "step", "source_id", "item_id", "quantity"]
const Resolver := preload("res://Scripts/data/RecipeResolver.gd")

static func is_integer(value: Variant, minimum: int = 0) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= minimum and float(value) < 9223372036854775807.0 and float(int(value)) == float(value)

static func is_id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value == value.strip_edges()

static func is_payload_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != PAYLOAD_KEYS.size() or not value.has_all(PAYLOAD_KEYS):
		return false
	return is_id(value.order_id) and value.source_id is String and value.source_id == SOURCE_ID and value.item_id is String and value.item_id in ITEM_IDS and is_integer(value.step, 1) and is_integer(value.quantity, 1)

static func expected_payload(order: Dictionary) -> Dictionary:
	return {"order_id": order.order_id, "step": order.converted, "source_id": SOURCE_ID, "item_id": order.result_item, "quantity": order.result_quantity}

static func payloads_match(left: Variant, right: Variant) -> bool:
	if not is_payload_valid(left) or not is_payload_valid(right):
		return false
	return left.order_id == right.order_id and left.source_id == right.source_id and left.item_id == right.item_id and int(left.step) == int(right.step) and int(left.quantity) == int(right.quantity)

static func receipt_is_valid(value: Variant, ingredients: Dictionary) -> bool:
	if not value is Dictionary or not value.get("success") is bool or not value.get("success") or not value.get("refunded") is bool or value.refunded:
		return false
	if not value.get("requirements") is Dictionary or not value.get("entries") is Array:
		return false
	var requirements: Dictionary = value.requirements
	if requirements.size() != ingredients.size():
		return false
	for item_id in ingredients:
		if not is_integer(requirements.get(item_id), 1) or int(requirements[item_id]) != int(ingredients[item_id]):
			return false
	var totals := {}
	for entry in value.entries:
		if not entry is Dictionary or not is_id(entry.get("item_id")) or not is_integer(entry.get("quantity"), 1) or typeof(entry.get("source")) not in [TYPE_STRING, TYPE_STRING_NAME] or entry.source not in ["village_storage", "personal_inventory"]:
			return false
		if not ingredients.has(entry.item_id):
			return false
		totals[entry.item_id] = int(totals.get(entry.item_id, 0)) + int(entry.quantity)
	if totals.size() != ingredients.size():
		return false
	for item_id in ingredients:
		if int(totals.get(item_id, 0)) != int(ingredients[item_id]):
			return false
	return true

static func is_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != KEYS.size() or not value.has_all(KEYS):
		return false
	var order: Dictionary = value
	if not is_id(order.order_id) or not is_id(order.recipe_id) or not order.source_id is String or order.source_id != SOURCE_ID or not order.result_item is String or order.result_item not in ITEM_IDS:
		return false
	for key in ["total", "result_quantity"]:
		if not is_integer(order[key], 1): return false
	for key in ["converted", "delivered", "refunded"]:
		if not is_integer(order[key]): return false
	if not order.cancelled is bool or not order.phase is String or order.phase not in PHASES:
		return false
	for key in ["seconds_per_craft", "time_remaining"]:
		if typeof(order[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(order[key])) or order[key] < 0: return false
	if order.seconds_per_craft <= 0 or order.time_remaining > order.seconds_per_craft:
		return false
	if not order.ingredients is Dictionary or order.ingredients.is_empty() or not order.reservations is Array:
		return false
	for item_id in order.ingredients:
		if not is_id(item_id) or not is_integer(order.ingredients[item_id], 1): return false
	# Valida o contrato da receita, não a descoberta pessoal atual após load.
	var recipe: Dictionary = Resolver.new().get_recipe(order.recipe_id)
	if recipe.is_empty() or recipe.get("resultado_item") != order.result_item or int(recipe.get("resultado_quantidade", 0)) != int(order.result_quantity) or float(recipe.get("tempo_producao", 0)) != float(order.seconds_per_craft):
		return false
	var expected_ingredients := {}
	for item_id in recipe.get("ingredientes", []):
		expected_ingredients[item_id] = int(expected_ingredients.get(item_id, 0)) + 1
	if expected_ingredients.size() != order.ingredients.size(): return false
	for item_id in expected_ingredients:
		if not order.ingredients.has(item_id) or int(order.ingredients[item_id]) != int(expected_ingredients[item_id]): return false
	if order.delivered > order.converted or order.converted > order.total or order.refunded > order.total - order.converted:
		return false
	var outstanding := int(order.converted) - int(order.delivered)
	if outstanding not in [0, 1] or order.reservations.size() != int(order.total) - int(order.converted) - int(order.refunded):
		return false
	for receipt in order.reservations:
		if not receipt_is_valid(receipt, order.ingredients): return false
	if not order.cancelled and order.refunded != 0: return false
	if order.phase == "brewing":
		return not order.cancelled and outstanding == 0 and not order.reservations.is_empty() and order.output == null
	if order.time_remaining != 0: return false
	if order.phase == "ready":
		return outstanding == 1 and payloads_match(order.output, expected_payload(order))
	if order.phase == "carried":
		return outstanding == 1 and order.output == null
	return order.cancelled and outstanding == 0 and not order.reservations.is_empty() and order.output == null

static func matches_cargo(order: Variant, cargo: Variant) -> bool:
	if order == null: return cargo == null
	if not is_valid(order): return false
	return payloads_match(expected_payload(order), cargo) if order.phase == "carried" else cargo == null
