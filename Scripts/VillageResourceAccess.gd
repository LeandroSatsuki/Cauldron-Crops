extends RefCounted
class_name VillageResourceAccess

const SOURCE_VILLAGE_STORAGE: StringName = &"village_storage"
const SOURCE_PERSONAL_INVENTORY: StringName = &"personal_inventory"

var _village_storage: Node = null


func _init(village_storage: Node = null) -> void:
	_village_storage = village_storage


func set_village_storage(village_storage: Node) -> void:
	_village_storage = village_storage


func get_available(item_id: String) -> int:
	var normalized_item_id: String = item_id.strip_edges()
	if normalized_item_id == "":
		return 0
	return _get_storage_quantity(normalized_item_id) + _get_personal_quantity(normalized_item_id)


func get_available_by_source(item_id: String) -> Dictionary:
	var normalized_item_id: String = item_id.strip_edges()
	if normalized_item_id == "":
		return {
			SOURCE_VILLAGE_STORAGE: 0,
			SOURCE_PERSONAL_INVENTORY: 0,
		}
	return {
		SOURCE_VILLAGE_STORAGE: _get_storage_quantity(normalized_item_id),
		SOURCE_PERSONAL_INVENTORY: _get_personal_quantity(normalized_item_id),
	}


func get_missing(requirements: Dictionary) -> Dictionary:
	var validation: Dictionary = _normalize_requirements(requirements)
	if not bool(validation.get("valid", false)):
		return {}
	var missing: Dictionary = {}
	var normalized: Dictionary = validation.get("requirements", {})
	for item_variant in normalized.keys():
		var item_id: String = str(item_variant)
		var required_quantity: int = int(normalized[item_variant])
		var missing_quantity: int = required_quantity - get_available(item_id)
		if missing_quantity > 0:
			missing[item_id] = missing_quantity
	return missing


func can_consume(requirements: Dictionary) -> bool:
	var validation: Dictionary = _normalize_requirements(requirements)
	if not bool(validation.get("valid", false)):
		return false
	return get_missing(validation.get("requirements", {})).is_empty()


func consume(requirements: Dictionary) -> Dictionary:
	var validation: Dictionary = _normalize_requirements(requirements)
	if not bool(validation.get("valid", false)):
		return _failure_receipt("invalid_requirements")
	var normalized: Dictionary = validation.get("requirements", {})
	var missing: Dictionary = get_missing(normalized)
	if not missing.is_empty():
		return _failure_receipt("insufficient_resources", missing)

	var entries: Array[Dictionary] = []
	for item_variant in normalized.keys():
		var item_id: String = str(item_variant)
		var remaining: int = int(normalized[item_variant])
		var storage_quantity: int = mini(_get_storage_quantity(item_id), remaining)
		if storage_quantity > 0:
			if not _withdraw_from_storage(item_id, storage_quantity):
				if not _restore_entries(entries):
					push_error("VillageResourceAccess: falha ao restaurar retirada parcial do Village Storage.")
				return _failure_receipt("storage_withdrawal_failed")
			entries.append(_entry(item_id, storage_quantity, SOURCE_VILLAGE_STORAGE))
			remaining -= storage_quantity

		if remaining > 0:
			if not GlobalInventory.remover_item(item_id, remaining):
				if not _restore_entries(entries):
					push_error("VillageResourceAccess: falha ao restaurar retirada parcial da Mochila.")
				return _failure_receipt("personal_withdrawal_failed")
			entries.append(_entry(item_id, remaining, SOURCE_PERSONAL_INVENTORY))

	return {
		"success": true,
		"reason": "",
		"requirements": normalized.duplicate(true),
		"entries": entries,
		"refunded": false,
	}


func refund(receipt: Dictionary) -> bool:
	if not bool(receipt.get("success", false)) or bool(receipt.get("refunded", false)):
		return false
	var entries_variant: Variant = receipt.get("entries", [])
	if not (entries_variant is Array):
		return false
	var entries: Array = entries_variant
	if _receipt_requires_storage(entries) and not _has_valid_storage():
		return false
	if not _restore_entries(entries):
		return false
	receipt["refunded"] = true
	return true


func _normalize_requirements(requirements: Dictionary) -> Dictionary:
	if requirements.is_empty():
		return {"valid": false, "requirements": {}}
	var normalized: Dictionary = {}
	for item_variant in requirements.keys():
		var item_id: String = str(item_variant).strip_edges()
		var quantity: int = int(requirements[item_variant])
		if item_id == "" or quantity <= 0:
			return {"valid": false, "requirements": {}}
		normalized[item_id] = int(normalized.get(item_id, 0)) + quantity
	return {"valid": true, "requirements": normalized}


func _failure_receipt(reason: String, missing: Dictionary = {}) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"missing": missing.duplicate(true),
		"requirements": {},
		"entries": [],
		"refunded": false,
	}


func _entry(item_id: String, quantity: int, source: StringName) -> Dictionary:
	return {
		"item_id": item_id,
		"quantity": quantity,
		"source": source,
	}


func _restore_entries(entries: Array) -> bool:
	var personal_restore: Dictionary = {}
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var item_id: String = str(entry.get("item_id", ""))
		var quantity: int = int(entry.get("quantity", 0))
		var source: StringName = StringName(str(entry.get("source", "")))
		if item_id != "" and quantity > 0 and source == SOURCE_PERSONAL_INVENTORY:
			personal_restore[item_id] = int(personal_restore.get(item_id, 0)) + quantity
	if not personal_restore.is_empty() and not GlobalInventory.can_accept_items(personal_restore):
		return false
	if not personal_restore.is_empty():
		var insertion: Dictionary = GlobalInventory.try_add_items(personal_restore)
		if not bool(insertion.get("success", false)):
			return false

	for index in range(entries.size() - 1, -1, -1):
		var entry_variant: Variant = entries[index]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var item_id: String = str(entry.get("item_id", ""))
		var quantity: int = int(entry.get("quantity", 0))
		var source: StringName = StringName(str(entry.get("source", "")))
		if item_id == "" or quantity <= 0:
			continue
		if source == SOURCE_VILLAGE_STORAGE:
			_deposit_to_storage(item_id, quantity)
	return true


func _receipt_requires_storage(entries: Array) -> bool:
	for entry_variant in entries:
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			if StringName(str(entry.get("source", ""))) == SOURCE_VILLAGE_STORAGE:
				return true
	return false


func _has_valid_storage() -> bool:
	return (
		_village_storage != null
		and is_instance_valid(_village_storage)
		and _village_storage.has_method("get_item_quantity")
		and _village_storage.has_method("withdraw_item")
		and _village_storage.has_method("deposit_item")
	)


func _get_storage_quantity(item_id: String) -> int:
	if not _has_valid_storage():
		return 0
	return maxi(int(_village_storage.call("get_item_quantity", item_id)), 0)


func _get_personal_quantity(item_id: String) -> int:
	return maxi(int(GlobalInventory.inventario.get(item_id, 0)), 0)


func _withdraw_from_storage(item_id: String, quantity: int) -> bool:
	return _has_valid_storage() and bool(_village_storage.call("withdraw_item", item_id, quantity))


func _deposit_to_storage(item_id: String, quantity: int) -> void:
	if _has_valid_storage():
		_village_storage.call("deposit_item", item_id, quantity)
