extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const FREE_GRID_POSITION := Vector2i(6, 4)
const RESERVED_GRID_POSITION := Vector2i(7, 4)
const OUTSIDE_GRID_POSITION := Vector2i(40, 40)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _test_pure_policy():
		return

	var main: Node2D = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame

	if not _expect_main_reason(main, Vector2i(0, 0), true, SoilValidityPolicy.REASON_VALID, "plot existente"):
		return
	if not _expect_main_reason(main, Vector2i(6, 0), false, SoilValidityPolicy.REASON_CORRUPTED, "pocket bloqueado"):
		return
	var purification_obstacle: Node = main.get_node_or_null("PurificationObstacle")
	if purification_obstacle == null or not purification_obstacle.has_method("load_save_data"):
		_fail("PurificationObstacle nao encontrado para validar area purificada")
		return
	purification_obstacle.call("load_save_data", {"obstacle_id": "first_obstacle", "purified": true})
	await get_tree().process_frame
	if not _expect_main_reason(main, Vector2i(6, 0), true, SoilValidityPolicy.REASON_VALID, "pocket purificado"):
		return
	if not _expect_main_reason(main, FREE_GRID_POSITION, true, SoilValidityPolicy.REASON_VALID, "celula livre"):
		return
	if not _expect_main_reason(main, OUTSIDE_GRID_POSITION, false, SoilValidityPolicy.REASON_OUTSIDE_CULTIVABLE_BOUNDS, "fora do limite"):
		return

	var reserved_areas: Array[Rect2i] = [Rect2i(RESERVED_GRID_POSITION, Vector2i.ONE)]
	main.set("reserved_cultivation_grid_areas", reserved_areas)
	if not _expect_main_reason(main, RESERVED_GRID_POSITION, false, SoilValidityPolicy.REASON_RESERVED_ZONE, "zona reservada"):
		return

	main.set("cultivable_grid_bounds", Rect2i(Vector2i(-20, -20), Vector2i(50, 50)))
	var fishing_spot: Node2D = main.get_node_or_null("FishingSpot") as Node2D
	if fishing_spot == null:
		_fail("FishingSpot nao encontrado para validar agua")
		return
	var water_evaluation: Dictionary = main.call("avaliar_solo_para_arar", fishing_spot.global_position)
	if not _expect_evaluation(water_evaluation, false, SoilValidityPolicy.REASON_WATER, "agua"):
		return

	var village_chest: Node2D = main.get_node_or_null("VillageChest") as Node2D
	if village_chest == null:
		_fail("VillageChest nao encontrado para validar construcao")
		return
	var building_evaluation: Dictionary = main.call("avaliar_solo_para_arar", village_chest.global_position)
	if not _expect_evaluation(building_evaluation, false, SoilValidityPolicy.REASON_BUILDING, "construcao"):
		return

	var no_reserved_areas: Array[Rect2i] = []
	main.set("reserved_cultivation_grid_areas", no_reserved_areas)
	var obstacle := StaticBody2D.new()
	var obstacle_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 40)
	obstacle_shape.shape = rectangle
	obstacle.add_child(obstacle_shape)
	main.add_child(obstacle)
	obstacle.global_position = main.call("_converter_grid_em_posicao_global", FREE_GRID_POSITION)
	await get_tree().physics_frame
	if not _expect_main_reason(main, FREE_GRID_POSITION, false, SoilValidityPolicy.REASON_OBSTACLE, "obstaculo generico"):
		return
	obstacle.queue_free()
	await get_tree().physics_frame

	var transient_character := CharacterBody2D.new()
	var character_shape := CollisionShape2D.new()
	var character_circle := CircleShape2D.new()
	character_circle.radius = 20.0
	character_shape.shape = character_circle
	transient_character.add_child(character_shape)
	main.add_child(transient_character)
	transient_character.global_position = main.call("_converter_grid_em_posicao_global", FREE_GRID_POSITION)
	await get_tree().physics_frame
	if not _expect_main_reason(main, FREE_GRID_POSITION, true, SoilValidityPolicy.REASON_VALID, "personagem transitorio"):
		return
	transient_character.queue_free()
	await get_tree().physics_frame

	var legacy_plot_variant: Variant = main.call("garantir_farm_plot_por_grid_position", OUTSIDE_GRID_POSITION)
	if legacy_plot_variant is not Node2D:
		_fail("nao foi possivel criar plot de compatibilidade fora do limite")
		return
	if not _expect_main_reason(main, OUTSIDE_GRID_POSITION, true, SoilValidityPolicy.REASON_VALID, "plot legado fora do limite"):
		return

	print("SoilValidityPolicySmokeTest: PASS - limite, corrupcao, agua, construcao, obstaculo, reserva e compatibilidade estao centralizados.")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _test_pure_policy() -> bool:
	var base_context: Dictionary = {
		"farm_ready": true,
		"has_existing_plot": false,
		"inside_cultivable_bounds": true,
		"is_corrupted": false,
		"requires_purification": false,
		"is_area_purified": true,
		"has_water": false,
		"has_building": false,
		"has_obstacle": false,
		"is_reserved_zone": false,
	}
	if not _expect_evaluation(SoilValidityPolicy.evaluate(Vector2i.ZERO, base_context), true, SoilValidityPolicy.REASON_VALID, "politica base"):
		return false

	var cases: Array[Dictionary] = [
		{"field": "farm_ready", "value": false, "reason": SoilValidityPolicy.REASON_FARM_NOT_READY},
		{"field": "inside_cultivable_bounds", "value": false, "reason": SoilValidityPolicy.REASON_OUTSIDE_CULTIVABLE_BOUNDS},
		{"field": "is_corrupted", "value": true, "reason": SoilValidityPolicy.REASON_CORRUPTED},
		{"field": "has_water", "value": true, "reason": SoilValidityPolicy.REASON_WATER},
		{"field": "has_building", "value": true, "reason": SoilValidityPolicy.REASON_BUILDING},
		{"field": "has_obstacle", "value": true, "reason": SoilValidityPolicy.REASON_OBSTACLE},
		{"field": "is_reserved_zone", "value": true, "reason": SoilValidityPolicy.REASON_RESERVED_ZONE},
	]
	for case in cases:
		var context: Dictionary = base_context.duplicate(true)
		context[str(case.get("field", ""))] = case.get("value")
		var reason: String = str(case.get("reason", ""))
		if not _expect_evaluation(SoilValidityPolicy.evaluate(Vector2i.ZERO, context), false, reason, "politica %s" % reason):
			return false

	var unpurified_context: Dictionary = base_context.duplicate(true)
	unpurified_context["requires_purification"] = true
	unpurified_context["is_area_purified"] = false
	if not _expect_evaluation(SoilValidityPolicy.evaluate(Vector2i.ZERO, unpurified_context), false, SoilValidityPolicy.REASON_CORRUPTED, "area nao purificada"):
		return false

	var legacy_context: Dictionary = base_context.duplicate(true)
	legacy_context["has_existing_plot"] = true
	legacy_context["inside_cultivable_bounds"] = false
	legacy_context["is_reserved_zone"] = true
	if not _expect_evaluation(SoilValidityPolicy.evaluate(Vector2i.ZERO, legacy_context), true, SoilValidityPolicy.REASON_VALID, "compatibilidade de plot existente"):
		return false

	return true


func _expect_main_reason(main: Node, grid_position: Vector2i, expected_valid: bool, expected_reason: String, context: String) -> bool:
	var evaluation_variant: Variant = main.call("avaliar_grid_para_arar", grid_position)
	if typeof(evaluation_variant) != TYPE_DICTIONARY:
		_fail("%s nao retornou avaliacao" % context)
		return false
	return _expect_evaluation(evaluation_variant as Dictionary, expected_valid, expected_reason, context)


func _expect_evaluation(evaluation: Dictionary, expected_valid: bool, expected_reason: String, context: String) -> bool:
	var actual_valid: bool = bool(evaluation.get("valid", false))
	var actual_reason: String = str(evaluation.get("reason", ""))
	if actual_valid != expected_valid or actual_reason != expected_reason:
		_fail("%s: esperado valid=%s reason=%s; recebido valid=%s reason=%s" % [
			context,
			str(expected_valid),
			expected_reason,
			str(actual_valid),
			actual_reason,
		])
		return false
	return true


func _fail(message: String) -> void:
	push_error("SoilValidityPolicySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
