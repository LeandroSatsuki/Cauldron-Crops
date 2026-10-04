extends Node

signal well_improvement_changed

const WellState = preload("res://Scripts/data/VillageWellState.gd")
const ResourceAccess = preload("res://Scripts/VillageResourceAccess.gd")

var moedas : int = 0
var total_golems: int = 1
var max_golems: int = 5
var poco_capacidade_maxima: int = 10
var well_improved_by_project: bool = false
var _well_transaction_in_progress: bool = false

func is_well_transaction_in_progress() -> bool:
	return _well_transaction_in_progress

func is_well_improved() -> bool:
	return well_improved_by_project or poco_capacidade_maxima >= WellState.IMPROVED_CAPACITY

func get_well_project_status() -> Dictionary:
	if is_well_improved():
		return {"code": "completed", "missing": {}}
	if not GroveExpedition.restored:
		return {"code": "locked", "missing": {}}
	var storage := _get_live_well_storage()
	if storage == null:
		return {"code": "home_unavailable", "missing": {}}
	var missing: Dictionary = ResourceAccess.new(storage).get_missing(WellState.PROJECT_REQUIREMENTS)
	return {"code": "ready" if missing.is_empty() else "missing", "missing": missing}

# API de domínio; o objeto físico só a acionará no incremento seguinte.
func try_improve_village_well() -> bool:
	if _well_transaction_in_progress or SaveManager.is_applying_snapshot():
		return false
	if get_well_project_status()["code"] != "ready":
		return false
	var storage := _get_live_well_storage()
	if storage == null:
		return false
	_well_transaction_in_progress = true
	var receipt: Dictionary = ResourceAccess.new(storage).consume(WellState.PROJECT_REQUIREMENTS)
	if not bool(receipt.get("success", false)):
		_well_transaction_in_progress = false
		return false
	well_improved_by_project = true
	poco_capacidade_maxima = maxi(poco_capacidade_maxima, WellState.IMPROVED_CAPACITY)
	_well_transaction_in_progress = false
	well_improvement_changed.emit()
	return true

func try_unlock_water_skill() -> bool:
	if _well_transaction_in_progress or SaveManager.is_applying_snapshot() or is_well_improved():
		return false
	if GlobalInventory.pontos_alquimia < 1 or WellState.WATER_SKILL in GlobalInventory.skills_desbloqueadas:
		return false
	GlobalInventory.pontos_alquimia -= 1
	GlobalInventory.skills_desbloqueadas.append(WellState.WATER_SKILL)
	poco_capacidade_maxima = maxi(poco_capacidade_maxima, WellState.IMPROVED_CAPACITY)
	well_improvement_changed.emit()
	return true

func _get_live_well_storage() -> Node:
	var scene := get_tree().current_scene
	if scene == null or RegionTravelCoordinator.is_transition_in_progress() or not scene.has_method("get_current_region_identity"):
		return null
	if scene.call("get_current_region_identity").get("region_id", "") != "farm_village":
		return null
	var storage := scene.get_node_or_null("VillageChest")
	return storage if storage != null and not storage.is_queued_for_deletion() and storage.is_in_group("village_chest") else null

func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	print("Moedas adicionadas: ", quantidade, " (Total: ", moedas, ")")

func remover_moedas(quantidade: int) -> bool:
	if moedas >= quantidade:
		moedas -= quantidade
		print("Moedas removidas: ", quantidade, " (Restam: ", moedas, ")")
		return true
	return false
