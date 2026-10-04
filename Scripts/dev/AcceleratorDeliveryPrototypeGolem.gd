extends "res://Scripts/Golem.gd"

# ADAPTER DEV: não referenciado por Main/Golem.tscn nem incluído no save.
# O parâmetro 1,5 é experimental e não representa balanceamento homologado.
const PROTOTYPE_FACTOR := 1.5
const PROTOTYPE_ITEM := "pocao_aceleradora"
const PROTOTYPE_DISTANCE := 46.0
var prototype_boost_active := false
var prototype_application_armed := false
var prototype_generation := 0
var prototype_completed_deliveries := 0
var prototype_consumed_bottles := 0
var prototype_metrics: Dictionary = {}
var prototype_obstacle_observed := false
var prototype_obstacle_center := Vector2.ZERO
var _prototype_measuring := false

func prototype_can_apply(actor: Node2D) -> bool:
	return is_inside_tree() and get_tree().current_scene != null \
		and get_tree().current_scene.is_ancestor_of(self) \
		and not RegionTravelCoordinator.is_transition_in_progress() \
		and not SaveManager.is_applying_snapshot() \
		and actor != null and is_instance_valid(actor) and actor.is_inside_tree() \
		and get_tree().current_scene.is_ancestor_of(actor) \
		and actor.global_position.distance_to(global_position) <= PROTOTYPE_DISTANCE \
		and state == "IDLE" and work_priority == PRIORITY_PAUSED \
		and not carried_rewards.is_empty() and not seed_cargo.has_seed() \
		and not prototype_boost_active and GlobalInventory.get_item_quantity(PROTOTYPE_ITEM) >= 1

func prototype_arm_application() -> int:
	prototype_generation += 1
	prototype_application_armed = true
	return prototype_generation

func prototype_cancel_application() -> void:
	prototype_generation += 1
	prototype_application_armed = false

func prototype_apply(actor: Node2D, generation: int) -> bool:
	if not prototype_application_armed or generation != prototype_generation or not prototype_can_apply(actor):
		return false
	# remover_item é síncrono/sem sinais: gasto e benefício antes de observação.
	if not GlobalInventory.remover_item(PROTOTYPE_ITEM, 1):
		return false
	prototype_boost_active = true
	prototype_consumed_bottles += 1
	prototype_cancel_application()
	return true

func prototype_effective_speed() -> float:
	return move_speed_pixels_per_second * PROTOTYPE_FACTOR if prototype_boost_active and not carried_rewards.is_empty() and state == "MOVING_TO_CHEST" else move_speed_pixels_per_second

func prototype_begin_delivery() -> bool:
	if state != "IDLE" or carried_rewards.is_empty() or seed_cargo.has_seed():
		return false
	prototype_metrics = {"physics_frame_start": Engine.get_physics_frames(), "physics_frame_end": Engine.get_physics_frames(), "physics_frames": 0, "physics_seconds": 0.0, "walk_frames": 0, "walk_seconds": 0.0, "path_length": 0.0, "maximum_step": 0.0, "maximum_requested_speed": 0.0, "minimum_obstacle_distance": 1.0e30, "saw_detour": false, "completed": false}
	_prototype_measuring = true
	set_work_priority(PRIORITY_HARVEST_FIRST)
	_think_timer.stop()
	_procurar_bau()
	return state == "MOVING_TO_CHEST"

func _physics_process(delta: float) -> void:
	var before := global_position
	var before_state := state
	var base_speed := move_speed_pixels_per_second
	var agent_speed := navigation_agent.max_speed if navigation_agent != null else base_speed
	var requested_speed := prototype_effective_speed()
	# Só durante esta chamada do algoritmo original; não aumenta semeadura,
	# ida ao lote, rega/descanso, duração de colheita ou duração do depósito.
	move_speed_pixels_per_second = requested_speed
	if navigation_agent != null:
		navigation_agent.max_speed = requested_speed
	super._physics_process(delta)
	move_speed_pixels_per_second = base_speed
	if navigation_agent != null:
		navigation_agent.max_speed = agent_speed
	if _prototype_measuring and before_state in ["MOVING_TO_CHEST", "DEPOSITING"]:
		prototype_metrics["physics_frames"] += 1
		prototype_metrics["physics_frame_end"] = Engine.get_physics_frames()
		prototype_metrics["physics_seconds"] += delta
		var step := before.distance_to(global_position)
		prototype_metrics["path_length"] += step
		prototype_metrics["maximum_step"] = maxf(float(prototype_metrics["maximum_step"]), step)
		prototype_metrics["maximum_requested_speed"] = maxf(float(prototype_metrics["maximum_requested_speed"]), requested_speed)
		prototype_metrics["saw_detour"] = prototype_metrics["saw_detour"] or _is_avoiding_obstacle
		if prototype_obstacle_observed:
			var closest := Geometry2D.get_closest_point_to_segment(prototype_obstacle_center, before, global_position)
			prototype_metrics["minimum_obstacle_distance"] = minf(float(prototype_metrics["minimum_obstacle_distance"]), closest.distance_to(prototype_obstacle_center))
		if before_state == "MOVING_TO_CHEST":
			prototype_metrics["walk_frames"] += 1
			prototype_metrics["walk_seconds"] += delta

func _chegar_ao_bau() -> void:
	var had_cargo := not carried_rewards.is_empty()
	await super._chegar_ao_bau()
	if had_cargo and carried_rewards.is_empty():
		prototype_completed_deliveries += 1
		prototype_boost_active = false
		_prototype_measuring = false
		if not prototype_metrics.is_empty():
			prototype_metrics["completed"] = true
			prototype_metrics["physics_frame_end"] = Engine.get_physics_frames()

func prototype_reset_for_fixture() -> void:
	prototype_cancel_application()
	prototype_boost_active = false
	_prototype_measuring = false
	prototype_completed_deliveries = 0
	prototype_consumed_bottles = 0
	prototype_metrics.clear()
	prototype_obstacle_observed = false
	super.load_work_save_data(GolemWorkState.default_data(), false)
	set_work_priority(PRIORITY_PAUSED)
	_think_timer.stop()
	velocity = Vector2.ZERO
