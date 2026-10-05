extends Node

# Um único proprietário de estado/relógio local, independente do Bosque.
signal progress_changed

const State = preload("res://Scripts/data/HerbariumProductionState.gd")
const ResourceAccess = preload("res://Scripts/VillageResourceAccess.gd")
const PROJECT_REQUIREMENTS := {"trigo": 8, "tomate_sol": 2, "mistura_restauradora": 1}
const ROOT_ITEM_ID := "raiz_gelida"
const RENEWAL_SECONDS := 90.0
const INTERACTION_DISTANCE := 62.0

var activated: bool = false
var renewal_remaining: float = 0.0
var _generation: int = 0
var _transaction_in_progress: bool = false

func _process(delta: float) -> void:
	advance_session_time(delta)

func get_save_data() -> Dictionary:
	return {"activated": activated, "renewal_remaining": renewal_remaining}

func load_save_data(value: Dictionary) -> bool:
	if _transaction_in_progress or not State.is_valid(value):
		return false
	# Os gates efetivos são resolvidos pelo preflight do SaveManager antes do load.
	activated = value["activated"]
	renewal_remaining = float(value["renewal_remaining"])
	_generation += 1
	if not SaveManager.is_applying_snapshot():
		progress_changed.emit()
	return true

func reset_progress() -> void:
	load_save_data(State.default_data())

func get_generation() -> int:
	return _generation

func is_transaction_in_progress() -> bool:
	return _transaction_in_progress

func get_status(site: Node2D = null) -> Dictionary:
	var result := {"code": "home_unavailable", "missing": {}, "amount": GlobalInventory.get_item_quantity(ROOT_ITEM_ID), "activated": activated, "renewal_remaining": renewal_remaining}
	var home := _get_live_home()
	if home == null or _transaction_in_progress:
		return result
	var live_site: Node2D = home.get_node_or_null("ProductiveHerbarium") as Node2D
	if not _site_is_current(home, live_site if site == null else site):
		return result
	if not _gates_available(home):
		result["code"] = "locked"
		return result
	if activated:
		result["code"] = "renewing" if renewal_remaining > 0.0 else "available"
		return result
	var chest := _get_live_storage(home)
	if chest == null:
		return result
	var missing: Dictionary = ResourceAccess.new(chest).get_missing(PROJECT_REQUIREMENTS)
	result["missing"] = missing
	result["code"] = "ready" if missing.is_empty() else "missing"
	return result

func try_activate(site: Node2D) -> bool:
	if _transaction_in_progress or activated or get_status(site)["code"] != "ready":
		return false
	var home := _get_live_home()
	if not _commit_context_valid(home, site):
		return false
	var chest := _get_live_storage(home)
	if chest == null:
		return false
	_transaction_in_progress = true
	var access := ResourceAccess.new(chest)
	var receipt: Dictionary = access.consume(PROJECT_REQUIREMENTS)
	if not bool(receipt.get("success", false)):
		_transaction_in_progress = false
		return false
	# Mesmo retirada sintética/reentrante não pode publicar uma ativação inválida.
	if activated or not _commit_context_valid(home, site) or not _gates_available(home) or _get_live_storage(home) != chest:
		if not access.refund(receipt):
			push_error("HerbariumProduction: falha no rollback da melhoria; recibo não confirmado.")
		_transaction_in_progress = false
		return false
	activated = true
	renewal_remaining = 0.0 # Disponível no ponto, nunca prêmio de ativação.
	_generation += 1
	progress_changed.emit()
	_transaction_in_progress = false
	return true

func try_collect(site: Node2D) -> bool:
	if _transaction_in_progress or not activated or renewal_remaining > 0.0 or get_status(site)["code"] != "available":
		return false
	var home := _get_live_home()
	if not _commit_context_valid(home, site):
		return false
	_transaction_in_progress = true
	var insertion: Dictionary = GlobalInventory.try_add_items({ROOT_ITEM_ID: 1})
	if not bool(insertion.get("success", false)):
		_transaction_in_progress = false
		return false
	renewal_remaining = RENEWAL_SECONDS
	_generation += 1
	progress_changed.emit()
	_transaction_in_progress = false
	return true

func advance_session_time(delta: float) -> void:
	if _transaction_in_progress or SaveManager.is_applying_snapshot() or not activated or renewal_remaining <= 0.0 or not is_finite(delta) or delta <= 0.0:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("get_current_region_identity"):
		return
	var region_id: String = str(scene.call("get_current_region_identity").get("region_id", ""))
	if region_id not in ["farm_village", "foraging_grove"]:
		return
	renewal_remaining = maxf(renewal_remaining - delta, 0.0)
	if renewal_remaining == 0.0:
		_generation += 1
		progress_changed.emit()

func _get_live_home() -> Node:
	if SaveManager.is_applying_snapshot() or RegionTravelCoordinator.is_transition_in_progress():
		return null
	var scene := get_tree().current_scene
	if scene == null or not scene.is_inside_tree() or scene.is_queued_for_deletion() or not scene.has_method("get_current_region_identity"):
		return null
	if scene.call("get_current_region_identity").get("region_id", "") != "farm_village" or bool(scene.get("_region_being_cached")):
		return null
	return scene

func _site_is_current(home: Node, site: Node2D) -> bool:
	return home != null and is_instance_valid(site) and site.is_inside_tree() and not site.is_queued_for_deletion() and site.is_visible_in_tree() and home.get_node_or_null("ProductiveHerbarium") == site

func _gates_available(home: Node) -> bool:
	if home == null or not GroveExpedition.restored:
		return false
	var projects: Variant = home.get("restoration_projects")
	if not projects is Dictionary:
		return false
	var project: Variant = projects.get("first_obstacle")
	if not (project is Node and is_instance_valid(project) and project.is_inside_tree() and not project.is_queued_for_deletion() and home.is_ancestor_of(project)):
		return false
	if project.get("restored_state") != true or project.get("area_purified") != true or project.get("required_purification_obstacle_id") != "first_obstacle":
		return false
	# A flag derivada do projeto não substitui o obstáculo real da purificação.
	for obstacle in get_tree().get_nodes_in_group("purification_obstacle"):
		if home.is_ancestor_of(obstacle) and not obstacle.is_queued_for_deletion() and obstacle.get("obstacle_id") == "first_obstacle":
			return obstacle.get("purified_state") == true
	return false

func _get_live_storage(home: Node) -> VillageChest:
	if home == null:
		return null
	var chest := home.get_node_or_null("VillageChest") as VillageChest
	return chest if is_instance_valid(chest) and chest.is_inside_tree() and not chest.is_queued_for_deletion() and chest.is_in_group("village_chest") else null

func _commit_context_valid(home: Node, site: Node2D) -> bool:
	if home != _get_live_home() or not _site_is_current(home, site) or not _gates_available(home):
		return false
	var player := home.get_node_or_null("PlayerAvatar") as PlayerAvatar
	if player == null or player.is_queued_for_deletion():
		return false
	var distance := INTERACTION_DISTANCE
	if home.has_method("_resolve_safe_interaction_distance"):
		distance = float(home.call("_resolve_safe_interaction_distance", site, site.global_position, INTERACTION_DISTANCE))
	return player.global_position.distance_to(site.global_position) <= distance
