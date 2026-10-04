extends Node

# Protótipo isolado, não SmokeTest da suíte/build de produção.
# Não salva/carrega progresso. JSON contém somente medidas/fixtures sintéticos.
const MAIN := preload("res://Scenes/Main.tscn")
const GOLEM := preload("res://Scenes/Golem.tscn")
const ADAPTER := preload("res://Scripts/dev/AcceleratorDeliveryPrototypeGolem.gd")
const CARGO := {"trigo": 2, "palha_rara": 1}
const MAX_ROUTE_FRAMES := 2400
var home: Node2D
var golem: CharacterBody2D
var chest: VillageChest
var player: PlayerAvatar
var checks := 0
var failed := false
var samples: Array[Dictionary] = []
var comparisons: Array[Dictionary] = []
var original_chest_position := Vector2.ZERO
var report_directory := ""

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("AcceleratorDeliveryPrototypeTest: exige APPDATA em Builds/QA antes de instanciar Main.")
		get_tree().quit(1)
		return
	report_directory = ProjectSettings.globalize_path("res://Builds/QA/AcceleratorDeliveryPrototype/").replace("\\", "/")
	if not report_directory.begins_with(sandbox):
		push_error("AcceleratorDeliveryPrototypeTest: destino de relatório fora de QA.")
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	var old_golem: Node = home.get_node("Golem")
	old_golem.call("set_work_priority", 4)
	(old_golem.get("_think_timer") as Timer).stop()
	for plot in home.get("farm_plot_registry").values():
		plot.process_mode = Node.PROCESS_MODE_DISABLED
	# PROCESS_MODE_DISABLED propagaria disable_mode REMOVE ao StaticBody filho,
	# retirando justamente o obstáculo físico que o ensaio pretende medir.
	home.get_node("CauldronUI").set_process(false)
	home.get_node("CauldronUI").set_physics_process(false)
	await _settle()
	home.remove_child(old_golem)
	old_golem.free()
	golem = GOLEM.instantiate()
	golem.set_script(ADAPTER)
	golem.name = "Golem"
	home.add_child(golem)
	chest = home.get_node("VillageChest")
	player = home.get_node("PlayerAvatar")
	player.stop_moving()
	original_chest_position = chest.global_position
	golem.call("prototype_reset_for_fixture")
	await _settle()
	_check(is_equal_approx(golem.get("move_speed_pixels_per_second"), 128.0) and is_equal_approx(golem.get("deposit_duration"), 0.3), "velocidade/timer originais, sem aceleração global")
	_check(is_equal_approx(Engine.time_scale, 1.0), "TimeManager/time_scale não acelerados pelo fixture")
	await _application_contracts()
	await _pause_and_retry()
	for route in ["short", "long", "detour"]:
		for pair in range(3):
			var normal := {}
			var accelerated := {}
			for boosted in ([false, true] if pair % 2 == 0 else [true, false]):
				var sample: Dictionary = await _measure(route, pair, boosted)
				samples.append(sample)
				if boosted:
					accelerated = sample
				else:
					normal = sample
			var comparison := {"route": route, "pair": pair, "both_completed": bool(normal.get("completed", false)) and bool(accelerated.get("completed", false))}
			if comparison["both_completed"]:
				comparison["walk_seconds_saved"] = float(normal["walk_seconds"]) - float(accelerated["walk_seconds"])
				comparison["total_seconds_saved"] = float(normal["physics_seconds"]) - float(accelerated["physics_seconds"])
				comparison["total_reduction_fraction"] = 1.0 - float(accelerated["physics_seconds"]) / maxf(float(normal["physics_seconds"]), 0.001)
				print("AcceleratorDeliveryPrototypeTest: MEASURE %s pair=%d normal=%.3fs boosted=%.3fs saved=%.3fs" % [route, pair, normal["physics_seconds"], accelerated["physics_seconds"], comparison["total_seconds_saved"]])
			comparisons.append(comparison)
			_check(comparison["both_completed"], "par físico concluiu: %s/%d" % [route, pair])
	# Sem exigir ganho exato/33%: todas as amostras, inclusive falhas, ficam no JSON.
	_write_report()
	_finish()

func _setup(start: Vector2, destination: Vector2, cargo: bool = true, stock: int = 2) -> void:
	golem.call("prototype_reset_for_fixture")
	chest.global_position = destination
	chest.set_contents({})
	golem.global_position = start
	player.stop_moving()
	player.global_position = start + Vector2(0, 35)
	GlobalInventory.set_inventory_contents({"pocao_aceleradora": stock, "agua": 7, "semente_basica": 3})
	GlobalInventory.cargas_crescimento = 2
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	if cargo:
		golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))

func _application_contracts() -> void:
	_setup(original_chest_position + Vector2(200, 0), original_chest_position)
	var before := _domain()
	var generation: int = golem.call("prototype_arm_application")
	_check(_domain() == before, "armar intenção não consome nem altera custódia")
	golem.call("prototype_cancel_application")
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "cancelar invalida callback mesmo próximo")
	generation = golem.call("prototype_arm_application")
	player.global_position += Vector2(250, 0)
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "longe recusa sem consumir")
	player.global_position = golem.global_position + Vector2(0, 35)
	_check(golem.call("prototype_apply", player, generation), "proximidade real ao alvo parado permite aplicação")
	_check(GlobalInventory.get_item_quantity("pocao_aceleradora") == 1 and golem.get("prototype_boost_active") and _cargo() == CARGO and chest.get_contents().is_empty(), "um frasco beneficia só carga existente, sem teleporte/prêmio")
	before = _domain()
	generation = golem.call("prototype_arm_application")
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "reaplicação não empilha nem cobra")
	var snapshot: Dictionary = golem.call("get_work_save_data")
	_check(snapshot.size() == 5 and not snapshot.has("prototype_boost_active"), "efeito não integra schema/save de produção")
	for state in ["IDLE", "MOVING_TO_PLOT", "MOVING_TO_REST", "MOVING_TO_SEED_PLOT", "WATERING", "HARVESTING", "DEPOSITING"]:
		golem.set("state", state)
		_check(is_equal_approx(golem.call("prototype_effective_speed"), 128.0), "sem bônus de velocidade fora da entrega: " + state)
	golem.set("state", "MOVING_TO_CHEST")
	_check(is_equal_approx(golem.call("prototype_effective_speed"), 192.0), "fator experimental só no transporte ao baú")
	_setup(original_chest_position + Vector2(200, 0), original_chest_position, true, 0)
	chest.set_contents({"pocao_aceleradora": 2})
	before = _domain()
	generation = golem.call("prototype_arm_application")
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "sem frasco pessoal recusa, não retira do baú")
	_setup(original_chest_position + Vector2(200, 0), original_chest_position, false)
	before = _domain()
	generation = golem.call("prototype_arm_application")
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "sem carga não prepara ganho futuro silencioso")
	_setup(original_chest_position + Vector2(200, 0), original_chest_position)
	golem.call("set_work_priority", 0)
	generation = golem.call("prototype_arm_application")
	before = _domain()
	_check(not golem.call("prototype_apply", player, generation) and _domain() == before, "fixture recusa alvo não pausado, sem alegar UX móvel")
	await _settle()

func _pause_and_retry() -> void:
	_setup(original_chest_position + Vector2(700, 0), original_chest_position)
	var generation: int = golem.call("prototype_arm_application")
	_check(golem.call("prototype_apply", player, generation) and golem.call("prototype_begin_delivery"), "começa entrega beneficiada real para interrupções")
	player.global_position = Vector2(1500, 1400)
	await _frames(12)
	var old_callback: Callable = golem.get("_movement_callback")
	golem.call("set_work_priority", 4)
	var paused_position := golem.global_position
	old_callback.call()
	await _frames(24)
	_check(golem.global_position == paused_position and _cargo() == CARGO and golem.get("prototype_boost_active") and chest.get_contents().is_empty(), "pausa/callback obsoleto não desperdiçam custódia/benefício")
	# Interrupção de rota usa cancelamento original, sem trocar sua navegação.
	golem.call("set_work_priority", 0)
	golem.call("_procurar_bau")
	await _frames(12)
	golem.call("_parar_execucao_atual")
	_check(_cargo() == CARGO and golem.get("prototype_boost_active"), "rota interrompida conserva entrega para retry")
	golem.call("_procurar_bau")
	var completed: bool = await _wait_delivery()
	_check(completed and chest.get_contents() == CARGO and golem.get("prototype_completed_deliveries") == 1 and not golem.get("prototype_boost_active"), "retry entrega uma vez e só então encerra bônus")
	_check(GlobalInventory.get_item_quantity("pocao_aceleradora") == 1 and GlobalInventory.cargas_crescimento == 2, "retry não consome segundo frasco nem dose de Crescimento")
	# Falha de destino real somente no fixture: não há fallback/teleporte.
	_setup(original_chest_position + Vector2(160, 0), original_chest_position)
	generation = golem.call("prototype_arm_application")
	_check(golem.call("prototype_apply", player, generation) and golem.call("prototype_begin_delivery"), "prepara entrega para destino removido")
	golem.call("_parar_execucao_atual")
	home.remove_child(chest)
	golem.set("target_chest", null)
	golem.set("state", "MOVING_TO_CHEST")
	# Golem original emite aviso esperado de baú inválido neste controle negativo.
	golem.call("_chegar_ao_bau")
	await _frames(24)
	_check(_cargo() == CARGO and golem.get("prototype_boost_active") and golem.get("prototype_completed_deliveries") == 0 and chest.get_contents().is_empty(), "baú ausente conserva custódia e benefício sem concluir")
	home.add_child(chest)
	golem.call("_procurar_bau")
	completed = await _wait_delivery()
	_check(completed and chest.get_contents() == CARGO and golem.get("prototype_completed_deliveries") == 1, "retry com baú reinserido conclui uma única entrega")
	# Segunda entrega real: benefício não migra para a nova custódia.
	golem.call("set_work_priority", 4)
	golem.global_position = original_chest_position + Vector2(160, 0)
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_check(golem.call("prototype_begin_delivery") and is_equal_approx(golem.call("prototype_effective_speed"), 128.0), "próxima entrega começa em velocidade original")
	completed = await _wait_delivery()
	_check(completed and chest.get_item_quantity("trigo") == 4 and chest.get_item_quantity("palha_rara") == 2 and golem.get("prototype_completed_deliveries") == 2, "duas entregas físicas, sem duplicação/colheita extra")
	golem.call("_on_think_timer_timeout")
	await _frames(12)
	_check(chest.get_item_quantity("trigo") == 4 and chest.get_item_quantity("palha_rara") == 2, "scheduler sem nova carga não repete depósito")

func _measure(route: String, pair: int, boosted: bool) -> Dictionary:
	var start := original_chest_position + Vector2(160, 0)
	var destination := original_chest_position
	var body: StaticBody2D = home.get_node("CauldronUI/BaseAnchor/ObstacleBody")
	var collider: CollisionShape2D = body.get_node("CollisionShape2D")
	if route == "long":
		start = destination + Vector2(700, 0)
	elif route == "detour":
		start = collider.global_position + Vector2(210, 0)
		destination = collider.global_position - Vector2(210, 0)
	_setup(start, destination)
	await _settle()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = collider.global_position
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF
	var obstacle_active := false
	for hit in home.get_world_2d().direct_space_state.intersect_point(query, 32):
		if hit.collider == body:
			obstacle_active = true
	var obstacle_radius: float = (collider.shape as CircleShape2D).radius * maxf(absf(collider.global_scale.x), absf(collider.global_scale.y))
	var golem_shape: CollisionShape2D = golem.get_node("CollisionShape2D")
	var golem_radius: float = (golem_shape.shape as CircleShape2D).radius * maxf(absf(golem_shape.global_scale.x), absf(golem_shape.global_scale.y))
	golem.set("prototype_obstacle_center", collider.global_position)
	golem.set("prototype_obstacle_observed", true)
	_check(obstacle_active and not collider.disabled, "obstáculo real ativo na física antes da medição")
	if boosted:
		var generation: int = golem.call("prototype_arm_application")
		_check(golem.call("prototype_apply", player, generation), "aplica frasco no fixture parado: %s/%d" % [route, pair])
	player.global_position = Vector2(1500, 1400)
	var started: bool = golem.call("prototype_begin_delivery")
	var completed := false
	if started:
		completed = await _wait_delivery()
	var result: Dictionary = golem.get("prototype_metrics").duplicate(true)
	result["obstacle_active_before"] = obstacle_active
	result["golem_body_radius"] = golem_radius
	result["minimum_required_center_distance"] = obstacle_radius + golem_radius
	result.merge({"route": route, "pair": pair, "variant": "accelerated" if boosted else "normal", "boosted": boosted, "factor": 1.5 if boosted else 1.0, "completed": completed, "started": started, "start": {"x": start.x, "y": start.y}, "destination": {"x": destination.x, "y": destination.y}, "cargo": CARGO.duplicate(true), "obstacle_center": {"x": collider.global_position.x, "y": collider.global_position.y}, "obstacle_radius": collider.shape.radius, "base_speed": golem.get("move_speed_pixels_per_second"), "agent_max_speed_after": golem.get_node("NavigationAgent2D").max_speed, "deposit_duration": golem.get("deposit_duration"), "final_state": golem.get("state"), "final_cargo": _cargo(), "final_chest": chest.get_contents(), "final_boost_active": golem.get("prototype_boost_active"), "completed_deliveries": golem.get("prototype_completed_deliveries"), "consumed_bottles": golem.get("prototype_consumed_bottles"), "personal_stock_after": GlobalInventory.inventario.duplicate(true)}, true)
	_check(completed and _cargo().is_empty() and chest.get_contents() == CARGO and golem.get("prototype_completed_deliveries") == 1, "custódia/conclusão única: %s/%d/%s" % [route, pair, boosted])
	_check(GlobalInventory.get_item_quantity("pocao_aceleradora") == (1 if boosted else 2) and GlobalInventory.cargas_crescimento == 2 and GlobalInventory.get_item_quantity("agua") == 7, "gasto exato/estoques alheios preservados")
	_check(not completed or float(result.get("maximum_step", 0.0)) <= 192.0 / float(Engine.physics_ticks_per_second) + 2.0, "sem deslocamento instantâneo no trecho medido")
	_check(not completed or golem.global_position.distance_to(destination) <= 16.0, "entrega termina no baú físico")
	_check(is_equal_approx(golem.get("move_speed_pixels_per_second"), 128.0) and is_equal_approx(golem.get_node("NavigationAgent2D").max_speed, 128.0) and is_equal_approx(golem.get("deposit_duration"), 0.3), "export/agent/timer restaurados após entrega")
	# 0,25 px cobre margem numérica do move_and_slide, não passagem pelo corpo.
	_check(float(result.get("minimum_obstacle_distance", 0.0)) >= obstacle_radius + golem_radius - 0.25, "centro/corpo do golem não atravessam o collider em nenhum segmento medido")
	if route == "detour":
		_check(result.get("saw_detour", false), "percurso realmente exercitou desvio do obstáculo")
	golem.call("set_work_priority", 4)
	return result

func _wait_delivery() -> bool:
	for index in range(MAX_ROUTE_FRAMES):
		if golem.get("prototype_completed_deliveries") > 0 and _cargo().is_empty():
			return true
		if golem.get("state") == "IDLE" and not _cargo().is_empty():
			return false # preserva falha de rota, não corrige runtime para PASS.
		await get_tree().physics_frame
	return false

func _cargo() -> Dictionary:
	var totals: Variant = GolemWorkState.harvest_totals(golem.get("carried_rewards"))
	return {} if totals == null else totals

func _domain() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "growth_doses": GlobalInventory.cargas_crescimento, "cargo": _cargo(), "chest": chest.get_contents(), "boost": golem.get("prototype_boost_active")}

func _settle() -> void:
	await _frames(4)

func _frames(count: int) -> void:
	for index in range(count):
		await get_tree().physics_frame

func _write_report() -> void:
	var mkdir_error := DirAccess.make_dir_recursive_absolute(report_directory)
	_check(mkdir_error == OK, "diretório de relatório QA disponível")
	var backend := DisplayServer.get_name().to_lower().replace(" ", "_")
	var file := FileAccess.open(report_directory + "/results_" + backend + ".json", FileAccess.WRITE)
	_check(file != null, "arquivo de medições QA disponível")
	if file == null:
		return
	file.store_string(JSON.stringify({"prototype_only": true, "production_save_changed": false, "factor": 1.5, "physics_ticks_per_second": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale, "backend": backend, "checks": checks, "failed": failed, "samples": samples, "comparisons": comparisons, "limits": ["Velocidade solicitada não prova avoidance seguro.", "Aplicação próxima a golem pausado é fixture, não UX final.", "Sem persistência do bônus; nenhuma chamada de SaveManager.save_game/load_game.", "Sem promessa de redução exata de 33% ou aceite manual de conforto.", "walk_seconds mede o estado MOVING_TO_CHEST, inclusive espera por desvio.", "Pausa em movimento e baú ausente cobertos; pausa durante DEPOSITING não exercitada.", "Baú real é ilimitado; ausência do alvo não é teste de recusa por capacidade."]}, "\t"))
	file.close()
	print("AcceleratorDeliveryPrototypeTest: REPORT " + report_directory + "/results_" + backend + ".json")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("AcceleratorDeliveryPrototypeTest: FAIL - " + label)

func _finish() -> void:
	if not failed:
		print("AcceleratorDeliveryPrototypeTest: PASS - %d verificações; 18 entregas medidas/9 pares; sem integração de produção." % checks)
	get_tree().quit(1 if failed else 0)
