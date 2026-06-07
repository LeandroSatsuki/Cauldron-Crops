extends RefCounted

class_name UIDragHelper



var target: Control

var handle: Control

var clamp_to_viewport: bool = true

var drag_offset: Vector2 = Vector2.ZERO

var _dragging: bool = false



func attach(target_control: Control, handle_control: Control, should_clamp_to_viewport: bool = true) -> void:

	target = target_control

	handle = handle_control

	clamp_to_viewport = should_clamp_to_viewport

	if target:
		target.top_level = true
		target.mouse_filter = Control.MOUSE_FILTER_STOP

	if handle:
		handle.mouse_filter = Control.MOUSE_FILTER_STOP


		handle.mouse_default_cursor_shape = Control.CURSOR_MOVE

		if not handle.gui_input.is_connected(_on_handle_gui_input):

			handle.gui_input.connect(_on_handle_gui_input)



func _on_handle_gui_input(event: InputEvent) -> void:

	if target == null or handle == null:

		return

	if not is_instance_valid(target) or not is_instance_valid(handle):

		return

	if not target.visible:

		return



	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:

			_dragging = true

			drag_offset = target.global_position - handle.get_global_mouse_position()

			target.move_to_front()

			handle.accept_event()

		else:

			_dragging = false

			handle.accept_event()

		return



	if event is InputEventMouseMotion and _dragging:

		var new_position: Vector2 = handle.get_global_mouse_position() + drag_offset

		if clamp_to_viewport:

			new_position = _clamp_to_viewport(new_position)

		target.global_position = new_position

		handle.accept_event()



func _clamp_to_viewport(candidate_position: Vector2) -> Vector2:

	if target == null or target.get_viewport() == null:

		return candidate_position



	var visible_rect: Rect2 = target.get_viewport().get_visible_rect()

	var target_size: Vector2 = target.size

	var max_position: Vector2 = visible_rect.size - target_size

	return Vector2(

		clamp(candidate_position.x, visible_rect.position.x, max_position.x),

		clamp(candidate_position.y, visible_rect.position.y, max_position.y)

	)
