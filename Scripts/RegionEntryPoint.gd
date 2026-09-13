extends Marker2D
class_name RegionEntryPoint


@export var entry_id: StringName = &""


func _ready() -> void:
	add_to_group("region_entry_point")


func is_valid_entry_point() -> bool:
	return not String(entry_id).strip_edges().is_empty()
