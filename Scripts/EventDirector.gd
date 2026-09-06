extends Node

signal world_event_spawned(event_id: String)
signal world_event_collected(event_id: String)

const RARE_FISH_EVENT_ID := "mare_cintilante"
const HARVEST_EVENT_ID := "colheita_dourada"
const WORLD_EVENT_ID := "fragmento_celestial"
const RARE_FISH_FIRST_WINDOW_DELAY := 10.0
const RARE_FISH_WINDOW_DURATION := 20.0
const RARE_FISH_WINDOW_CYCLE := 90.0
const HARVEST_EVENT_CHANCE := 0.12
const HARVEST_EVENT_COOLDOWN := 45.0
const WORLD_EVENT_MIN_HARVESTS := 3
const WORLD_EVENT_CHANCE := 0.30
const WORLD_EVENT_COOLDOWN := 75.0
const WORLD_EVENT_DURATION := 45.0
const WORLD_EVENT_SPAWN_OFFSET := Vector2(-160.0, 90.0)

var _session_elapsed := 0.0
var _last_harvest_event_at := -HARVEST_EVENT_COOLDOWN
var _last_world_event_at := -WORLD_EVENT_COOLDOWN
var _successful_harvests := 0
var _world_event_marker: Area2D = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	_session_elapsed += maxf(delta, 0.0)
	if _world_event_marker != null and is_instance_valid(_world_event_marker):
		_world_event_marker.rotation = sin(_session_elapsed * 2.0) * 0.04
		if _session_elapsed - float(_world_event_marker.get_meta("spawned_at", _session_elapsed)) >= WORLD_EVENT_DURATION:
			_despawn_world_event()


func is_rare_fish_window_active() -> bool:
	if _session_elapsed < RARE_FISH_FIRST_WINDOW_DELAY:
		return false
	var cycle_position := fmod(_session_elapsed - RARE_FISH_FIRST_WINDOW_DELAY, RARE_FISH_WINDOW_CYCLE)
	return cycle_position >= 0.0 and cycle_position < RARE_FISH_WINDOW_DURATION


func get_rare_fish_window_label() -> String:
	if is_rare_fish_window_active():
		return "Maré Cintilante ativa — boa sincronia também rende uma Escama Brilhante."
	var remaining := maxf(0.0, RARE_FISH_FIRST_WINDOW_DELAY - _session_elapsed)
	if _session_elapsed >= RARE_FISH_FIRST_WINDOW_DELAY:
		var cycle_position := fmod(_session_elapsed - RARE_FISH_FIRST_WINDOW_DELAY, RARE_FISH_WINDOW_CYCLE)
		remaining = RARE_FISH_WINDOW_CYCLE - cycle_position
	return "Próxima Maré Cintilante em %ds." % ceili(remaining)


func reward_rare_fish_window() -> bool:
	if not is_rare_fish_window_active():
		return false
	GlobalInventory.adicionar_item("escama_brilhante", 1)
	GlobalInventory.registrar_item_colecao_pesca("escama_brilhante")
	return true


func notify_harvest(origin_global: Vector2) -> Dictionary:
	_successful_harvests += 1
	var result := {
		"harvest_event": false,
		"world_event": false,
	}
	if _session_elapsed - _last_harvest_event_at >= HARVEST_EVENT_COOLDOWN and _rng.randf() <= HARVEST_EVENT_CHANCE:
		_last_harvest_event_at = _session_elapsed
		GlobalInventory.pontos_alquimia += 1
		_announce("Colheita Dourada! +1 Ponto de Alquimia", origin_global, Color(1.0, 0.82, 0.35, 1.0))
		result["harvest_event"] = true
	if _can_try_world_event() and _rng.randf() <= WORLD_EVENT_CHANCE:
		result["world_event"] = _spawn_world_event(origin_global + WORLD_EVENT_SPAWN_OFFSET)
	return result


func debug_trigger_harvest_event(origin_global: Vector2) -> bool:
	_last_harvest_event_at = _session_elapsed
	GlobalInventory.pontos_alquimia += 1
	_announce("Colheita Dourada! +1 Ponto de Alquimia", origin_global, Color(1.0, 0.82, 0.35, 1.0))
	return true


func debug_trigger_world_event(origin_global: Vector2) -> bool:
	return _spawn_world_event(origin_global)


func has_active_world_event() -> bool:
	return _world_event_marker != null and is_instance_valid(_world_event_marker)


func collect_world_event() -> bool:
	if not has_active_world_event():
		return false
	GlobalInventory.adicionar_item(WORLD_EVENT_ID, 1)
	_announce("Fragmento Celestial coletado", _world_event_marker.global_position, Color(0.7, 0.88, 1.0, 1.0))
	_despawn_world_event()
	world_event_collected.emit(WORLD_EVENT_ID)
	return true


func debug_reset_for_test() -> void:
	_session_elapsed = 0.0
	_last_harvest_event_at = -HARVEST_EVENT_COOLDOWN
	_last_world_event_at = -WORLD_EVENT_COOLDOWN
	_successful_harvests = 0
	_despawn_world_event()


func _can_try_world_event() -> bool:
	return _successful_harvests >= WORLD_EVENT_MIN_HARVESTS \
		and not has_active_world_event() \
		and _session_elapsed - _last_world_event_at >= WORLD_EVENT_COOLDOWN


func _spawn_world_event(origin_global: Vector2) -> bool:
	if has_active_world_event():
		return false
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	var marker := Area2D.new()
	marker.name = "FragmentoCelestial"
	marker.global_position = origin_global
	marker.z_index = 90
	marker.set_meta("spawned_at", _session_elapsed)
	marker.input_pickable = true
	marker.input_event.connect(_on_world_event_input.bind(marker))
	marker.add_child(_create_world_event_visual())
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 26.0
	collision.shape = shape
	marker.add_child(collision)
	tree.current_scene.add_child(marker)
	_world_event_marker = marker
	_last_world_event_at = _session_elapsed
	world_event_spawned.emit(WORLD_EVENT_ID)
	return true


func _create_world_event_visual() -> Node2D:
	var visual := Node2D.new()
	var glow := Polygon2D.new()
	glow.color = Color(0.36, 0.7, 1.0, 0.26)
	glow.polygon = PackedVector2Array([Vector2(0, -30), Vector2(26, 0), Vector2(0, 30), Vector2(-26, 0)])
	visual.add_child(glow)
	var crystal := Polygon2D.new()
	crystal.color = Color(0.68, 0.9, 1.0, 0.96)
	crystal.polygon = PackedVector2Array([Vector2(0, -16), Vector2(12, -2), Vector2(6, 17), Vector2(-8, 15), Vector2(-13, -2)])
	visual.add_child(crystal)
	var label := Label.new()
	label.text = "Fragmento Celestial\nClique para coletar"
	label.position = Vector2(-95, -66)
	label.size = Vector2(190, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(label)
	return visual


func _on_world_event_input(_viewport: Viewport, event: InputEvent, _shape_index: int, marker: Area2D) -> void:
	if marker != _world_event_marker:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect_world_event()
		get_viewport().set_input_as_handled()


func _despawn_world_event() -> void:
	if _world_event_marker != null and is_instance_valid(_world_event_marker):
		_world_event_marker.queue_free()
	_world_event_marker = null


func _announce(text: String, origin_global: Vector2, color: Color) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var ui := tree.current_scene.get_node_or_null("UI")
	if ui != null and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", text, origin_global + Vector2(0.0, -48.0), color)
	else:
		print(text)
