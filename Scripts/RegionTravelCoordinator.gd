extends Node


signal transition_started(request: Dictionary)
signal transition_completed(request: Dictionary)
signal transition_failed(request: Dictionary, reason: String)


const REGION_SCENE_PATHS: Dictionary = {
	"farm_village": "res://Scenes/Main.tscn",
	"transition_test_region": "res://Scenes/PrototypeExternalRegion.tscn",
}


var _active_scene: Node = null
var _active_region_id: String = ""
var _cached_region_scenes: Dictionary = {}
var _transition_in_progress: bool = false


func register_region_scene(scene: Node) -> bool:
	var tree: SceneTree = get_tree()
	if scene == null or not is_instance_valid(scene) or tree == null or tree.current_scene != scene:
		return false
	if not scene.has_method("get_current_region_identity") or not scene.has_signal("region_transition_requested"):
		return false

	var identity_variant: Variant = scene.call("get_current_region_identity")
	if typeof(identity_variant) != TYPE_DICTIONARY:
		return false
	var identity: Dictionary = identity_variant
	var region_id: String = str(identity.get("region_id", "")).strip_edges()
	if region_id.is_empty():
		return false

	_disconnect_active_scene()
	_active_scene = scene
	_active_region_id = region_id
	_cached_region_scenes[region_id] = scene
	var transition_callable := Callable(self, "_on_region_transition_requested")
	if not scene.is_connected("region_transition_requested", transition_callable):
		scene.connect("region_transition_requested", transition_callable)
	return true


func get_active_region_id() -> String:
	return _active_region_id


func is_transition_in_progress() -> bool:
	return _transition_in_progress


func get_cached_region_scene(region_id: StringName) -> Node:
	var scene_variant: Variant = _cached_region_scenes.get(String(region_id))
	if scene_variant is Node and is_instance_valid(scene_variant):
		return scene_variant
	return null


func _on_region_transition_requested(request: Dictionary) -> void:
	if _transition_in_progress or _active_scene == null or not is_instance_valid(_active_scene):
		return
	if get_tree() == null or get_tree().current_scene != _active_scene:
		return

	_transition_in_progress = true
	var safe_request: Dictionary = request.duplicate(true)
	transition_started.emit(safe_request.duplicate(true))
	_perform_transition.call_deferred(safe_request)


func _perform_transition(request: Dictionary) -> void:
	var tree: SceneTree = get_tree()
	var source_scene: Node = _active_scene
	if tree == null or source_scene == null or not is_instance_valid(source_scene) or tree.current_scene != source_scene:
		_fail_transition(request, "source_scene_unavailable")
		return
	if source_scene.has_method("consume_pending_region_transition"):
		source_scene.call("consume_pending_region_transition")

	var source_region_id: String = str(request.get("source_region_id", "")).strip_edges()
	var target_region_id: String = str(request.get("target_region_id", "")).strip_edges()
	var target_entry_id: String = str(request.get("target_entry_id", "")).strip_edges()
	if source_region_id != _active_region_id:
		_fail_transition(request, "source_region_mismatch")
		return
	if target_region_id.is_empty() or target_entry_id.is_empty():
		_fail_transition(request, "invalid_target")
		return

	var target_scene: Node = _get_or_create_region_scene(target_region_id)
	if target_scene == null:
		_fail_transition(request, "unknown_target_region")
		return
	if not _region_scene_has_entry(target_scene, target_entry_id):
		if not _cached_region_scenes.has(target_region_id):
			target_scene.free()
		_fail_transition(request, "unknown_target_entry")
		return

	_disconnect_active_scene()
	_cached_region_scenes[source_region_id] = source_scene
	tree.current_scene = null
	var source_parent: Node = source_scene.get_parent()
	if source_parent != null:
		source_parent.remove_child(source_scene)

	if target_scene.get_parent() == null:
		tree.root.add_child(target_scene)
	tree.current_scene = target_scene
	if not register_region_scene(target_scene):
		_rollback_to_source(source_scene, source_region_id, target_scene)
		_fail_transition(request, "target_registration_failed")
		return
	if not target_scene.has_method("enter_region_at") or not bool(target_scene.call("enter_region_at", StringName(target_entry_id))):
		_rollback_to_source(source_scene, source_region_id, target_scene)
		_fail_transition(request, "target_entry_failed")
		return

	_transition_in_progress = false
	transition_completed.emit(request.duplicate(true))


func _get_or_create_region_scene(region_id: String) -> Node:
	var cached_scene: Node = get_cached_region_scene(StringName(region_id))
	if cached_scene != null:
		return cached_scene

	var scene_path: String = str(REGION_SCENE_PATHS.get(region_id, ""))
	if scene_path.is_empty():
		return null
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _region_scene_has_entry(scene: Node, entry_id: String) -> bool:
	var region_context: WorldRegion = scene.get_node_or_null("RegionContext") as WorldRegion
	if region_context == null:
		return false
	region_context.refresh_entry_points()
	return bool(region_context.resolve_entry(StringName(entry_id)).get("found", false))


func _rollback_to_source(source_scene: Node, source_region_id: String, failed_target: Node) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	_disconnect_active_scene()
	if failed_target != null and is_instance_valid(failed_target) and failed_target.get_parent() != null:
		failed_target.get_parent().remove_child(failed_target)
	if source_scene != null and is_instance_valid(source_scene) and source_scene.get_parent() == null:
		tree.root.add_child(source_scene)
	tree.current_scene = source_scene
	register_region_scene(source_scene)
	_active_region_id = source_region_id


func _fail_transition(request: Dictionary, reason: String) -> void:
	_transition_in_progress = false
	transition_failed.emit(request.duplicate(true), reason)


func _disconnect_active_scene() -> void:
	if _active_scene == null or not is_instance_valid(_active_scene):
		return
	var transition_callable := Callable(self, "_on_region_transition_requested")
	if _active_scene.has_signal("region_transition_requested") and _active_scene.is_connected("region_transition_requested", transition_callable):
		_active_scene.disconnect("region_transition_requested", transition_callable)


func _exit_tree() -> void:
	# Cenas inativas não possuem parent e precisam ser liberadas. A cena atual ainda
	# pertence ao root e será liberada pelo próprio SceneTree durante o encerramento.
	for scene_variant in _cached_region_scenes.values():
		if scene_variant is Node and is_instance_valid(scene_variant):
			var scene: Node = scene_variant
			if scene.get_parent() == null:
				scene.free()
	_cached_region_scenes.clear()
