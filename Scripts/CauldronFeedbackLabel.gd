extends Label
const HUDLayoutScript := preload("res://Scripts/HUDLayout.gd")

# Aviso de tela: resize contém o texto sem capturar input ou alterar a animação.
func _process(_delta: float) -> void:
	var screen := get_viewport().get_visible_rect().size
	size.x = minf(380.0, maxf(1.0, screen.x - 40.0))
	size.y = get_minimum_size().y
	position = Vector2(
		clampf(position.x, 20.0, maxf(20.0, screen.x - size.x - 20.0)),
		clampf(position.y, 70.0, maxf(70.0, screen.y - size.y - 20.0))
	)
	var occupied := HUDLayoutScript.get_occupied_hud_rects(get_parent())
	var scene := get_tree().current_scene
	var production := scene.get_node_or_null("CauldronUI/StatusLayer/BatchProgressPanel") as Control if scene != null else null
	if production != null and production.is_visible_in_tree():
		occupied.append(production.get_global_rect())
	var tracker: Control = GroveExpedition.get("_tracker")
	if tracker != null and tracker.is_visible_in_tree():
		occupied.append(tracker.get_global_rect())
	var protected := HUDLayoutScript.get_protected_hud_rects(get_parent())
	var toggle: Control = GroveExpedition.get("_tracker_toggle")
	if toggle != null and toggle.is_visible_in_tree():
		protected.append(toggle.get_global_rect())
	if production != null and production.is_visible_in_tree():
		var cancel := scene.get_node_or_null("CauldronUI/StatusLayer/BatchProgressPanel/MarginContainer/VBoxBatch/BtnCancelarProducao") as Control
		if cancel != null and cancel.is_visible_in_tree():
			protected.append(cancel.get_global_rect())
	for rectangle in occupied:
		if get_global_rect().intersects(rectangle.grow(6.0)):
			# Reserva vertical para a saída animada; não move os painéis do jogador.
			position = HUDLayoutScript.find_free_panel_position(size + Vector2(0, 50), screen, occupied, protected) + Vector2(0, 50)
			break
