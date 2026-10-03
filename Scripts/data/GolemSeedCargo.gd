extends RefCounted
class_name GolemSeedCargo

# Domínio do piloto. Persistido pelo golem, com scheduler físico separado.
# O chamador físico deve validar chegada/alvo antes de retirada/devolução.
const SEED_ITEM_ID := "semente_basica"
const INTENT_TRANSPORT := "transport"
const INTENT_RETURN := "return"
const PILOT_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

var _payload: Dictionary = {}


func has_seed() -> bool:
	return not _payload.is_empty()


func get_target_cell() -> Vector2i:
	if not has_seed():
		return Vector2i(-1, -1)
	var target: Dictionary = _payload["target_cell"]
	return Vector2i(int(target["x"]), int(target["y"]))


func is_return_pending() -> bool:
	return has_seed() and _payload["intent"] == INTENT_RETURN


func take_from_chest(chest: VillageChest, target_cell: Vector2i) -> bool:
	if has_seed() or target_cell not in PILOT_CELLS or not _chest_is_available(chest):
		return false
	# VillageChest.withdraw_item não emite sinais nem aguarda: custódia síncrona.
	if not chest.withdraw_item(SEED_ITEM_ID, 1):
		return false
	_payload = {
		"item_id": SEED_ITEM_ID,
		"quantity": 1,
		"target_cell": {"x": target_cell.x, "y": target_cell.y},
		"intent": INTENT_TRANSPORT,
	}
	return true


func can_consume_for_plant(seed_id: String, target_cell: Vector2i) -> bool:
	return has_seed() and not is_return_pending() and seed_id == SEED_ITEM_ID and target_cell == get_target_cell()


func consume_for_plant(seed_id: String, target_cell: Vector2i) -> bool:
	if not can_consume_for_plant(seed_id, target_cell):
		return false
	_payload.clear()
	return true


func mark_return_pending() -> bool:
	if not has_seed():
		return false
	_payload["intent"] = INTENT_RETURN
	return true


func return_to_chest(chest: VillageChest) -> bool:
	if not is_return_pending() or not _chest_is_available(chest):
		return false
	# Destino atual ilimitado: deposit_item é síncrono e não pode recusar 1 semente.
	# Se Storage ganhar capacidade, este contrato deve mudar antes da integração.
	chest.deposit_item(SEED_ITEM_ID, 1)
	_payload.clear()
	return true


func get_save_data() -> Variant:
	return _payload.duplicate(true) if has_seed() else null


func apply_save_data(value: Variant) -> bool:
	if not is_save_data_valid(value):
		return false
	# Substituição, não restituição: aplicar duas vezes nunca altera o baú.
	_payload = {} if value == null else (value as Dictionary).duplicate(true)
	if has_seed():
		_payload["quantity"] = 1
		_payload["target_cell"] = {"x": int(_payload["target_cell"]["x"]), "y": int(_payload["target_cell"]["y"])}
	return true


static func is_save_data_valid(value: Variant) -> bool:
	if value == null:
		return true
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if data.size() != 4 or not data.has_all(["item_id", "quantity", "target_cell", "intent"]):
		return false
	if typeof(data["item_id"]) != TYPE_STRING or data["item_id"] != SEED_ITEM_ID:
		return false
	if not _is_exact_number(data["quantity"], 1):
		return false
	if typeof(data["intent"]) != TYPE_STRING or data["intent"] not in [INTENT_TRANSPORT, INTENT_RETURN]:
		return false
	if not data["target_cell"] is Dictionary:
		return false
	var target: Dictionary = data["target_cell"]
	if target.size() != 2 or not target.has_all(["x", "y"]):
		return false
	for axis in ["x", "y"]:
		if not _is_exact_number(target[axis], 0) and not _is_exact_number(target[axis], 1):
			return false
	return true


static func _is_exact_number(value: Variant, expected: int) -> bool:
	# JSON pode representar inteiros como float; frações, bool e coerções não passam.
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value == expected


func _chest_is_available(chest: VillageChest) -> bool:
	return is_instance_valid(chest) and chest.is_inside_tree() and not chest.is_queued_for_deletion()
