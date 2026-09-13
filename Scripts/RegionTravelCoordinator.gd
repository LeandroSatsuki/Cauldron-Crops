extends Node


signal transition_started(request: Dictionary)
signal transition_completed(request: Dictionary)
signal transition_failed(request: Dictionary, reason: String)


const REGION_SCENE_PATHS: Dictionary = {
	"farm_village": "res://Scenes/Main.tscn",
	"transition_test_region": "res://Scenes/PrototypeExternalRegion.tscn",
	"foraging_grove": "res://Scenes/ForagingGroveRegion.tscn",
}
const DEFAULT_FADE_DURATION_SECONDS: float = 0.2


var _active_scene: Node = null
var _active_region_id: String = ""
var _cached_region_scenes: Dictionary = {}
var _transition_in_progress: bool = false
var _transition_overlay: ColorRect = null
var _transition_label: Label = null
var _fade_tween: Tween = null


func _ready() -> void:
	_create_transition_overlay()


func _input(_event: InputEvent) -> void:
	if _transition_in_progress and get_viewport() != null:
		get_viewport().set_input_as_handled()


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


func is_input_blocked() -> bool:
	return _transition_overlay != null and _transition_overlay.mouse_filter == Control.MOUSE_FILTER_STOP


func get_transition_overlay_alpha() -> float:
	return _transition_overlay.modulate.a if _transition_overlay != null else 0.0


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
	_set_transition_overlay_blocking(true)
	var safe_request: Dictionary = request.duplicate(true)
	transition_started.emit(safe_request.duplicate(true))
	_run_transition.call_deferred(safe_request)


func _run_transition(request: Dictionary) -> void:
	_set_transition_message("Cruzando o caminho...")
	await _fade_overlay_to(1.0)
	_perform_transition(request)


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

	_complete_transition(request)


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
	_set_transition_message("O caminho não respondeu")
	await _fade_overlay_to(0.0)
	_transition_in_progress = false
	_set_transition_overlay_blocking(false)
	transition_failed.emit(request.duplicate(true), reason)


func _complete_transition(request: Dictionary) -> void:
	# Um frame totalmente coberto permite que câmera e navegação da nova região
	# estabilizem antes de ela ser revelada.
	await get_tree().process_frame
	_set_transition_message("Chegando...")
	await _fade_overlay_to(0.0)
	_transition_in_progress = false
	_set_transition_overlay_blocking(false)
	transition_completed.emit(request.duplicate(true))


func _create_transition_overlay() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "RegionTransitionLayer"
	canvas_layer.layer = 10000
	add_child(canvas_layer)

	_transition_overlay = ColorRect.new()
	_transition_overlay.name = "Fade"
	_transition_overlay.color = Color(0.035, 0.055, 0.04, 1.0)
	_transition_overlay.modulate.a = 0.0
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(_transition_overlay)
	_transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_transition_label = Label.new()
	_transition_label.name = "Message"
	_transition_label.text = "Cruzando o caminho..."
	_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_label.add_theme_font_size_override("font_size", 22)
	_transition_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.78, 1.0))
	_transition_label.add_theme_color_override("font_outline_color", Color(0.02, 0.035, 0.025, 0.95))
	_transition_label.add_theme_constant_override("outline_size", 6)
	_transition_overlay.add_child(_transition_label)
	_transition_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_transition_label.position = Vector2(-210.0, -30.0)
	_transition_label.size = Vector2(420.0, 60.0)


func _set_transition_message(message: String) -> void:
	if _transition_label != null:
		_transition_label.text = message


func _set_transition_overlay_blocking(blocking: bool) -> void:
	if _transition_overlay == null:
		return
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE


func _fade_overlay_to(target_alpha: float) -> void:
	if _transition_overlay == null:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(
		_transition_overlay,
		"modulate:a",
		clampf(target_alpha, 0.0, 1.0),
		DEFAULT_FADE_DURATION_SECONDS
	)
	await _fade_tween.finished


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
		if not is_instance_valid(scene_variant):
			continue
		var scene: Node = scene_variant as Node
		if scene != null and scene.get_parent() == null:
			scene.free()
	_cached_region_scenes.clear()
