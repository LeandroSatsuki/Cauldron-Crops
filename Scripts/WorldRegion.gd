extends Node2D
class_name WorldRegion


signal transition_requested(request: Dictionary)


@export var region_id: StringName = &""
@export var display_name: String = ""
@export var is_home_region: bool = false
@export var default_entry_id: StringName = &""


var _entry_points: Dictionary = {}
var _pending_transition: Dictionary = {}


func _ready() -> void:
	add_to_group("world_region")
	refresh_entry_points()


func refresh_entry_points() -> void:
	_entry_points.clear()
	_collect_entry_points(self)


func _collect_entry_points(parent: Node) -> void:
	for child in parent.get_children():
		if child is RegionEntryPoint:
			var entry_point: RegionEntryPoint = child
			if entry_point.is_valid_entry_point():
				_entry_points[String(entry_point.entry_id)] = entry_point
		_collect_entry_points(child)


func get_identity() -> Dictionary:
	return {
		"region_id": String(region_id),
		"display_name": display_name,
		"is_home_region": is_home_region,
		"default_entry_id": String(default_entry_id)
	}


func resolve_entry(entry_id_to_resolve: StringName = &"") -> Dictionary:
	var normalized_entry_id: String = String(entry_id_to_resolve).strip_edges()
	if normalized_entry_id.is_empty():
		normalized_entry_id = String(default_entry_id).strip_edges()

	var entry_variant: Variant = _entry_points.get(normalized_entry_id)
	if entry_variant is not RegionEntryPoint or not is_instance_valid(entry_variant):
		return {"found": false, "entry_id": normalized_entry_id}

	var entry_point: RegionEntryPoint = entry_variant
	return {
		"found": true,
		"entry_id": normalized_entry_id,
		"global_position": entry_point.global_position
	}


func request_transition(
	target_region_id: StringName,
	target_entry_id: StringName,
	source_exit_id: StringName = &""
) -> bool:
	var normalized_target_region: String = String(target_region_id).strip_edges()
	var normalized_target_entry: String = String(target_entry_id).strip_edges()
	if normalized_target_region.is_empty() or normalized_target_entry.is_empty():
		return false
	if normalized_target_region == String(region_id):
		return false

	_pending_transition = {
		"source_region_id": String(region_id),
		"source_exit_id": String(source_exit_id).strip_edges(),
		"target_region_id": normalized_target_region,
		"target_entry_id": normalized_target_entry
	}
	transition_requested.emit(peek_pending_transition())
	return true


func peek_pending_transition() -> Dictionary:
	return _pending_transition.duplicate(true)


func consume_pending_transition() -> Dictionary:
	var request: Dictionary = peek_pending_transition()
	_pending_transition.clear()
	return request
