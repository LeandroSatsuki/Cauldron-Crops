extends Node

# Domínio/arquivos sintéticos somente QA. Mouse/arte/ritmo são validações
# separadas; chegada sintética abaixo testa cancelamento de await, não picking.
const MAIN := preload("res://Scenes/Main.tscn")
const ITEM := "pocao_aceleradora"
const CARGO := {"trigo": 2, "palha_rara": 1}
var home: Node2D
var golem: CharacterBody2D
var chest: VillageChest
var player: PlayerAvatar
var checks := 0
var failed := false
var notices := 0
var original_chest_position := Vector2.ZERO

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("AcceleratorDeliverySmokeTest: exige APPDATA sob Builds/QA antes de instanciar Main.")
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	await _new_home()
	var args := OS.get_cmdline_user_args()
	for mode in ["prepared", "active"]:
		if ("--write-accelerator-%s-fixture" % mode) in args:
			_write_fixture(mode)
			return _finish("fixture " + mode)
		if ("--verify-accelerator-%s-reopen" % mode) in args:
			await _verify_reopen(mode)
			return _finish("reabertura " + mode)
	_test_configuration()
	await _test_preexit_guards()
	await _test_normal_context_retry()
	await _test_deliveries()
	await _test_physical_detour()
	await _test_midroute_and_pause()
	await _test_missing_chest()
	await _test_harvest_custody()
	_test_persistence()
	await _test_reentrant_and_stale()
	await _test_cache()
	_write_fixture("active")
	_finish("domínio, custódia, arquivos QA, replay e cache")

func _new_home() -> void:
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	player = home.get_node("PlayerAvatar")
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	for plot in home.get("farm_plot_registry").values():
		plot.process_mode = Node.PROCESS_MODE_DISABLED
	# Conservar collider real do caldeirão; não desabilitar a árvore inteira.
	home.get_node("CauldronUI").set_process(false)
	home.get_node("CauldronUI").set_physics_process(false)
	player.stop_moving()
	player.global_position = Vector2(1500, 1400)
	original_chest_position = chest.global_position
	await _frames(4)

func _reset(stock: int = 3) -> void:
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	golem.set_physics_process(true)
	chest.global_position = original_chest_position
	chest.set_contents({ITEM: 7})
	golem.global_position = chest.global_position + Vector2(250, 0)
	player.stop_moving()
	player.global_position = Vector2(1500, 1400)
	GlobalInventory.set_inventory_contents({ITEM: stock, "agua": 7, "semente_basica": 3})
	GlobalInventory.cargas_crescimento = 2
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	home.set("_region_being_cached", false)

func _cargo() -> Dictionary:
	var totals: Variant = GolemWorkState.harvest_totals(golem.get("carried_rewards"))
	return {} if totals == null else totals

func _work() -> Dictionary:
	return golem.call("get_work_save_data")

func _status() -> Dictionary:
	return golem.call("get_accelerator_status")

func _domain() -> Dictionary:
	return {"work": _work(), "inventory": GlobalInventory.inventario.duplicate(true),
		"chest": chest.get_contents(), "generation": golem.get("_task_generation"),
		"tool": ToolManager.get_active_tool(), "seed": GlobalInventory.semente_selecionada,
		"scene": get_tree().current_scene.get_instance_id()}

func _open_delivery() -> void:
	golem.call("set_work_priority", 0)
	golem.call("_procurar_bau")

func _test_configuration() -> void:
	_reset()
	var before := _domain()
	_check(_status()["state"] == "none" and _status()["can_prepare"] and _status()["stock"] == 3, "consulta disponível na vila")
	_check(_domain() == before, "consultar não muda estoque/trabalho")
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var tool := ToolManager.get_active_tool()
	_check(golem.call("prepare_accelerator_delivery"), "preparo remoto sem carga/sem aproximação")
	_check(_status()["state"] == "prepared" and _status()["can_cancel"] and GlobalInventory.get_item_quantity(ITEM) == 3 and ToolManager.get_active_tool() == tool, "preparo não reserva/gasta/limpa ferramenta")
	before = _domain()
	_check(not golem.call("prepare_accelerator_delivery") and _domain() == before, "preparo repetido não empilha")
	_check(golem.call("cancel_accelerator_preparation") and _status()["state"] == "none" and GlobalInventory.get_item_quantity(ITEM) == 3, "cancelar antes de gasto é gratuito")
	before = _domain()
	_check(not golem.call("cancel_accelerator_preparation") and _domain() == before, "cancelamento repetido não muda nada")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = "semente_basica"
	_check(golem.call("prepare_accelerator_delivery") and GlobalInventory.semente_selecionada == "semente_basica", "preparo preserva seleção de semente")
	golem.call("cancel_accelerator_preparation")
	_reset(0)
	before = _domain()
	_check(_status()["reason"] == "no_stock" and not golem.call("prepare_accelerator_delivery") and _domain() == before, "frasco somente no baú não arma nem é retirado")
	_reset()
	for guard in ["load", "travel", "cached"]:
		if guard == "load": SaveManager.set("_applying_snapshot", true)
		if guard == "travel": RegionTravelCoordinator.set("_transition_in_progress", true)
		if guard == "cached": home.set("_region_being_cached", true)
		before = _domain()
		_check(not _status()["can_prepare"] and not golem.call("prepare_accelerator_delivery") and _domain() == before, "configuração recusada em " + guard)
		SaveManager.set("_applying_snapshot", false)
		RegionTravelCoordinator.set("_transition_in_progress", false)
		home.set("_region_being_cached", false)
	_reset()
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	golem.call("set_work_priority", 0)
	for guard in ["load", "travel", "cached"]:
		if guard == "load": SaveManager.set("_applying_snapshot", true)
		if guard == "travel": RegionTravelCoordinator.set("_transition_in_progress", true)
		if guard == "cached": home.set("_region_being_cached", true)
		before = _domain()
		golem.call("_procurar_bau")
		_check(not golem.call("cancel_accelerator_preparation") and _domain() == before, "abertura/cancelamento durante %s preserva preparo/cargo/estoque" % guard)
		SaveManager.set("_applying_snapshot", false)
		RegionTravelCoordinator.set("_transition_in_progress", false)
		home.set("_region_being_cached", false)
	_reset()
	var impostor: Node = preload("res://Scenes/Golem.tscn").instantiate()
	impostor.name = "OtherGolem"
	home.add_child(impostor)
	impostor.call("set_work_priority", 4)
	_check(not impostor.call("prepare_accelerator_delivery"), "golem sem identidade registrada não configura")
	home.remove_child(impostor)
	_check(not impostor.call("prepare_accelerator_delivery"), "golem fora da árvore não configura")
	impostor.free()
	# Carga de semente pode aguardar uma entrega futura, nunca ser beneficiada.
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	chest.set_contents({ITEM: 7, "semente_basica": 2})
	golem.set("seeding_enabled", true)
	var seed: GolemSeedCargo = golem.get("seed_cargo")
	_check(seed.take_from_chest(chest, Vector2i(0, 0)), "fixture de semente usa retirada real exclusiva do baú")
	_check(golem.call("prepare_accelerator_delivery"), "preparo durante semeadura aguarda futura colheita")
	_open_delivery()
	_check(_status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 3 and not golem.get("harvest_delivery_started"), "semente não abre entrega nem gasta frasco")
	_check(is_equal_approx(golem.call("get_delivery_move_speed"), 128.0), "semente conserva velocidade-base")
	_check(GolemWorkState.is_valid(_work(), true), "preparo com semente é snapshot válido sem benefício na carga")
	_reset()
	golem.call("prepare_accelerator_delivery")
	golem.set("carried_rewards", [{"item_id": "item_desconhecido", "quantidade": 1}])
	golem.call("set_work_priority", 0)
	before = _domain()
	golem.call("_procurar_bau")
	_check(_domain() == before and _status()["state"] == "prepared" and not golem.get("harvest_delivery_started"), "cargo inválido antes do commit não cobra nem inicia")

func _test_deliveries() -> void:
	_reset()
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_check(not golem.get("harvest_delivery_started") and not golem.get("accelerator_active") and GlobalInventory.get_item_quantity(ITEM) == 3, "receber cargo não consome/ativa")
	golem.call("_procurar_bau")
	_check(golem.get("state") == "IDLE" and _status()["state"] == "prepared", "golem pausado não abre rota nem consome")
	_open_delivery()
	_check(golem.get("state") == "MOVING_TO_CHEST" and _status()["state"] == "active" and golem.get("harvest_delivery_started"), "primeira rota válida ativa uma entrega lógica")
	_check(GlobalInventory.get_item_quantity(ITEM) == 2 and chest.get_item_quantity(ITEM) == 7 and _cargo() == CARGO, "commit retira somente um frasco pessoal, conserva carga/baú")
	_check(is_equal_approx(golem.call("get_delivery_move_speed"), 192.0) and is_equal_approx(golem.get("move_speed_pixels_per_second"), 128.0), "velocidade derivada 1,5× sem alterar base")
	_check(not golem.call("prepare_accelerator_delivery") and not golem.call("cancel_accelerator_preparation"), "ativa não admite fila/cancelamento/refund")
	var stock := GlobalInventory.inventario.duplicate(true)
	var phase: String = golem.get("state")
	for other in ["IDLE", "MOVING_TO_PLOT", "WATERING", "HARVESTING", "DEPOSITING", "MOVING_TO_REST", "MOVING_TO_SEED_PLOT"]:
		golem.set("state", other)
		_check(is_equal_approx(golem.call("get_delivery_move_speed"), 128.0), "nenhuma outra tarefa acelerada: " + other)
	golem.set("state", phase)
	await _delivered()
	_check(_cargo().is_empty() and not golem.get("accelerator_active") and not golem.get("harvest_delivery_started"), "depósito efetivo limpa carga/benefício/fase")
	_check(chest.get_item_quantity("trigo") == 2 and chest.get_item_quantity("palha_rara") == 1 and GlobalInventory.inventario == stock, "entrega física única sem recursos extras/custo por item")
	_check(is_equal_approx(golem.get_node("NavigationAgent2D").max_speed, 128.0) and is_equal_approx(golem.get("deposit_duration"), 0.3) and is_equal_approx(Engine.time_scale, 1.0), "base/agente/depósito/tempo global intactos")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	_check(not golem.get("accelerator_active") and is_equal_approx(golem.call("get_delivery_move_speed"), 128.0), "próxima carga volta à velocidade normal")
	await _delivered()
	_check(chest.get_item_quantity("trigo") == 4 and chest.get_item_quantity("palha_rara") == 2 and GlobalInventory.get_item_quantity(ITEM) == 2, "segundo depósito não autorrepete poção")
	# Estoque pode sair entre preparo e primeira rota: desarmar uma vez.
	_reset()
	golem.call("prepare_accelerator_delivery")
	GlobalInventory.remover_item(ITEM, 3)
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	notices = 0
	var counter := func(): notices += 1
	golem.connect("accelerator_status_changed", counter)
	_open_delivery()
	_check(_status()["state"] == "none" and golem.get("harvest_delivery_started") and notices == 1 and GlobalInventory.get_item_quantity(ITEM) == 0, "estoque perdido desarma/avisa uma vez e entrega normal")
	golem.call("_parar_execucao_atual")
	GlobalInventory.try_add_items({ITEM: 2})
	_open_delivery()
	_check(not golem.get("accelerator_active") and GlobalInventory.get_item_quantity(ITEM) == 2 and notices == 1, "retry/reposição não cobram ordem encerrada")
	golem.disconnect("accelerator_status_changed", counter)
	await _delivered()

func _toggle_context_guard(kind: String, value: bool) -> void:
	if kind == "load": SaveManager.set("_applying_snapshot", value)
	if kind == "travel": RegionTravelCoordinator.set("_transition_in_progress", value)

func _test_preexit_guards() -> void:
	# A árvore/geração ainda existem: contexto, não só off-tree, deve recusar.
	for guard in ["load", "travel"]:
		_reset()
		golem.call("prepare_accelerator_delivery")
		golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
		golem.call("set_work_priority", 0)
		var probe := {"calls": 0}
		golem.call("_iniciar_deslocamento", golem.global_position, func(): probe.calls += 1)
		var callback: Callable = golem.get("_movement_callback")
		var generation: int = golem.get("_task_generation")
		_toggle_context_guard(guard, true)
		var before := _domain()
		callback.call()
		_check(home.is_inside_tree() and not golem.call("_task_is_current", generation) and probe.calls == 0 and _domain() == before, "callback com geração atual recusado antes de off-tree em " + guard)
		golem.call("_on_think_timer_timeout")
		_check(not golem.call("prepare_accelerator_delivery") and not golem.call("cancel_accelerator_preparation") and _domain() == before, "timer/configuração não abrem trabalho em " + guard)
		golem.set("life_state", "LOOKING")
		(golem.get("_life_timer") as Timer).start(60.0)
		golem.call("_physics_process", 1.0 / 60.0)
		_check(golem.get("life_state") == "IDLE" and (golem.get("_life_timer") as Timer).is_stopped() and _cargo() == CARGO and _status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 3, "guarda física cancela vida ociosa sem perder preparo/cargo em " + guard)
		_toggle_context_guard(guard, false)
		callback.call()
		_check(probe.calls == 0, "retorno do contexto não revalida callback cancelado")
		# Manter geração/estado nominal e impedir tick físico de invalidá-los:
		# o await real precisa reconhecer a guarda de contexto por si próprio.
		_reset()
		golem.call("prepare_accelerator_delivery")
		var plot: Node = home.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
		plot.call("load_save_data", {"estado_atual": 2, "semente_id_plantada": "semente_basica", "regado": false, "arado": true, "tempo_restante": 0.0, "tempo_total_crescimento": 3.0, "pronto_para_colher": true, "pending_harvest_rewards": {"trigo": 1}})
		golem.call("set_work_priority", 0)
		golem.set("target_plot", plot)
		golem.set("state", "MOVING_TO_PLOT")
		golem.call("_chegar_ao_lote")
		golem.set_physics_process(false)
		var crop_before: Dictionary = plot.call("get_save_data")
		_toggle_context_guard(guard, true)
		await get_tree().create_timer(0.6).timeout
		_check(plot.call("get_save_data") == crop_before and _cargo().is_empty() and _status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 3, "await de colheita não entrega/consome durante " + guard)
		_toggle_context_guard(guard, false)
		_reset()
		golem.call("prepare_accelerator_delivery")
		golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
		_open_delivery()
		golem.set_physics_process(false)
		golem.call("_chegar_ao_bau")
		_toggle_context_guard(guard, true)
		await get_tree().create_timer(0.4).timeout
		_check(chest.get_item_quantity("trigo") == 0 and _cargo() == CARGO and _status()["state"] == "active" and GlobalInventory.get_item_quantity(ITEM) == 2, "await de depósito conserva custódia/benefício durante " + guard)
		_toggle_context_guard(guard, false)
		_reset()

func _test_normal_context_retry() -> void:
	for guard in ["load", "travel"]:
		_reset()
		golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
		_open_delivery()
		golem.set_physics_process(false)
		golem.call("_chegar_ao_bau")
		_check(golem.get("state") == "DEPOSITING" and not golem.get("accelerator_active") and golem.get("harvest_delivery_started"), "depósito normal inicia sem preparo/benefício")
		_toggle_context_guard(guard, true)
		await get_tree().create_timer(0.4).timeout
		_check(home.is_inside_tree() and golem.get("state") == "IDLE" and _cargo() == CARGO and golem.get("harvest_delivery_started") and chest.get_item_quantity("trigo") == 0 and GlobalInventory.get_item_quantity(ITEM) == 3, "depósito normal recusado em %s volta IDLE com custódia/fase intactas" % guard)
		_toggle_context_guard(guard, false)
		golem.set_physics_process(true)
		_open_delivery()
		await _delivered()
		_check(_cargo().is_empty() and chest.get_item_quantity("trigo") == 2 and chest.get_item_quantity("palha_rara") == 1 and GlobalInventory.get_item_quantity(ITEM) == 3 and not golem.get("harvest_delivery_started"), "contexto normal restaurado entrega única sem custo")
		golem.call("_chegar_ao_bau")
		await _frames(24)
		_check(chest.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity(ITEM) == 3, "depósito normal retomado não repete entrega/custo")

func _test_midroute_and_pause() -> void:
	_reset()
	golem.global_position = chest.global_position + Vector2(700, 0)
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	_check(golem.get("harvest_delivery_started") and not golem.get("accelerator_active"), "entrega normal também marca primeira abertura")
	_check(golem.call("prepare_accelerator_delivery"), "preparo aceito durante entrega normal")
	var old: Callable = golem.get("_movement_callback")
	await _frames(10)
	golem.call("set_work_priority", 4)
	var position_before := golem.global_position
	old.call()
	await _frames(22)
	_check(golem.global_position == position_before and _cargo() == CARGO and chest.get_item_quantity("trigo") == 0, "pausa/callback obsoleto conserva cargo sem depósito")
	var incoming: Dictionary = SaveManager.call("_build_save_data")
	_check(SaveManager.call("_apply_save_data", JSON.parse_string(JSON.stringify(incoming))), "load durante preparo midroute aceita snapshot")
	_open_delivery()
	_check(_status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 3 and is_equal_approx(golem.call("get_delivery_move_speed"), 128.0), "retry/load não tornam entrega antiga elegível")
	await _delivered()
	_check(_status()["state"] == "prepared" and not golem.get("harvest_delivery_started"), "depósito normal preserva preparo para próxima custódia")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	_check(_status()["state"] == "active" and GlobalInventory.get_item_quantity(ITEM) == 2, "nova custódia consome o preparo pendente")
	await _frames(8)
	golem.call("set_work_priority", 4)
	position_before = golem.global_position
	await _frames(22)
	_check(golem.global_position == position_before and _status()["state"] == "active" and _cargo() == CARGO, "pausa ativa não expira nem desperdiça benefício")
	golem.call("set_work_priority", 0)
	golem.call("_abortar_movimento", "Accelerator QA: interrupção sintética esperada.")
	_open_delivery()
	_check(_status()["state"] == "active" and GlobalInventory.get_item_quantity(ITEM) == 2, "retry por interrupção preserva bônus sem cobrança")
	# Chegada sintética instrumenta exatamente o await de depósito, sem
	# acelerar timer. Desabilitar movimento impede chegada física concorrente.
	golem.set_physics_process(false)
	golem.call("_chegar_ao_bau")
	_check(golem.get("state") == "DEPOSITING" and is_equal_approx(golem.get_node("NavigationAgent2D").max_speed, 128.0), "depósito usa duração/base originais")
	golem.call("set_work_priority", 4)
	await get_tree().create_timer(0.4).timeout
	_check(_status()["state"] == "active" and _cargo() == CARGO and chest.get_item_quantity("trigo") == 2, "pausa durante DEPOSITING invalida await sem perder bônus")
	golem.set_physics_process(true)
	_open_delivery()
	await _delivered()
	_check(chest.get_item_quantity("trigo") == 4 and GlobalInventory.get_item_quantity(ITEM) == 2, "retomada após pausa no depósito conclui uma vez")

func _test_physical_detour() -> void:
	_reset()
	var body: StaticBody2D = home.get_node("CauldronUI/BaseAnchor/ObstacleBody")
	var collider: CollisionShape2D = body.get_node("CollisionShape2D")
	var center := collider.global_position
	var destination := center - Vector2(210, 0)
	chest.global_position = destination
	golem.global_position = center + Vector2(210, 0)
	await _frames(4)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = center
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF
	var obstacle_active := false
	for hit in home.get_world_2d().direct_space_state.intersect_point(query, 32):
		if hit.collider == body: obstacle_active = true
	_check(obstacle_active and not collider.disabled, "desvio de produção usa collider real ativo na física")
	var obstacle_radius: float = (collider.shape as CircleShape2D).radius * maxf(absf(collider.global_scale.x), absf(collider.global_scale.y))
	var shape: CollisionShape2D = golem.get_node("CollisionShape2D")
	var golem_radius: float = (shape.shape as CircleShape2D).radius * maxf(absf(shape.global_scale.x), absf(shape.global_scale.y))
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	var minimum := 1.0e30
	var previous := golem.global_position
	var max_step := 0.0
	var path_length := 0.0
	var saw_detour := false
	var retained := true
	var completed := false
	for _frame in range(1000):
		await get_tree().physics_frame
		var point := golem.global_position
		var step := previous.distance_to(point)
		path_length += step
		max_step = maxf(max_step, step)
		minimum = minf(minimum, Geometry2D.get_closest_point_to_segment(center, previous, point).distance_to(center))
		saw_detour = saw_detour or bool(golem.get("_is_avoiding_obstacle"))
		previous = point
		if _cargo().is_empty():
			completed = true
			break
		retained = retained and bool(golem.get("accelerator_active")) and bool(golem.get("harvest_delivery_started")) and GlobalInventory.get_item_quantity(ITEM) == 2
	_check(completed and _cargo().is_empty() and chest.get_item_quantity("trigo") == 2 and chest.get_item_quantity("palha_rara") == 1, "desvio real conclui custódia única sem recursos extras")
	_check(retained and GlobalInventory.get_item_quantity(ITEM) == 2 and not golem.get("accelerator_active"), "obstáculo/travamento mantêm uma dose até depósito efetivo")
	_check(minimum >= obstacle_radius + golem_radius - 0.25, "segmentos do corpo não atravessam collider (margem numérica 0,25 px)")
	_check(saw_detour, "rota de produção realmente exercita fallback de desvio")
	_check(max_step <= 192.0 / float(Engine.physics_ticks_per_second) + 2.0 and golem.global_position.distance_to(destination) <= 16.0, "trajeto termina no baú sem teleporte")
	_check(is_equal_approx(golem.get("move_speed_pixels_per_second"), 128.0) and is_equal_approx(golem.get_node("NavigationAgent2D").max_speed, 128.0) and is_equal_approx(golem.get("deposit_duration"), 0.3), "desvio não altera base/agente/timer após entrega")
	print("AcceleratorDeliverySmokeTest: DETOUR path=%.3f minimum=%.3f required=%.3f max_step=%.3f observed=%s" % [path_length, minimum, obstacle_radius + golem_radius, max_step, saw_detour])

func _test_missing_chest() -> void:
	_reset()
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	home.remove_child(chest)
	_open_delivery()
	_check(_status()["state"] == "prepared" and not golem.get("harvest_delivery_started") and GlobalInventory.get_item_quantity(ITEM) == 3, "sem baú antes do commit não inicia/cobra")
	home.add_child(chest)
	_open_delivery()
	_check(_status()["state"] == "active" and GlobalInventory.get_item_quantity(ITEM) == 2, "baú devolvido permite primeira abertura elegível")
	golem.set_physics_process(false)
	golem.call("_chegar_ao_bau")
	home.remove_child(chest)
	await get_tree().create_timer(0.4).timeout
	_check(_cargo() == CARGO and _status()["state"] == "active" and golem.get("harvest_delivery_started"), "baú removido após commit preserva cargo/benefício")
	_check(not golem.call("cancel_accelerator_preparation") and GlobalInventory.get_item_quantity(ITEM) == 2, "ausência de baú não autoriza refund/cancelamento ativo")
	home.add_child(chest)
	golem.set_physics_process(true)
	_open_delivery()
	await _delivered()
	_check(chest.get_item_quantity("trigo") == 2 and chest.get_item_quantity("palha_rara") == 1 and GlobalInventory.get_item_quantity(ITEM) == 2, "retry com baú real deposita uma vez sem nova retirada")

func _test_harvest_custody() -> void:
	_reset()
	golem.call("prepare_accelerator_delivery")
	var plot: Node = home.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	plot.call("load_save_data", {"estado_atual": 2, "semente_id_plantada": "semente_basica", "regado": false, "arado": true, "tempo_restante": 0.0, "tempo_total_crescimento": 3.0, "pronto_para_colher": true, "pending_harvest_rewards": {"trigo": 2}})
	var observed := {"valid": false}
	var inspect := func():
		if plot.get("estado_atual") == 0:
			var work := _work()
			observed.valid = work["harvest_cargo"] == {"trigo": 2} and not work["harvest_delivery_started"] and work["accelerator_prepared"] and GolemWorkState.is_valid(work, true) and GlobalInventory.get_item_quantity(ITEM) == 3
	plot.connect("estado_alterado", inspect)
	# Instrumenta chegada ao lote, mas executa timer/callback/abertura reais.
	# Não encurta harvest_duration para obter benefício.
	golem.call("set_work_priority", 0)
	golem.set("target_plot", plot)
	golem.set("state", "MOVING_TO_PLOT")
	golem.call("_chegar_ao_lote")
	await get_tree().create_timer(0.6).timeout
	plot.disconnect("estado_alterado", inspect)
	_check(observed.valid, "sinal FarmPlot recebe custódia/fase coerentes antes de qualquer custo")
	_check(golem.get("state") == "MOVING_TO_CHEST" and _status()["state"] == "active", "HARVESTING abre rota real após instalar custódia")
	await _delivered()
	_check(chest.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity(ITEM) == 2, "colheita real existente usa uma entrega sem prêmio extra")

func _test_persistence() -> void:
	_reset()
	golem.call("prepare_accelerator_delivery")
	var prepared: Dictionary = SaveManager.call("_build_save_data")
	_check(SaveManager.call("_apply_save_data", JSON.parse_string(JSON.stringify(prepared))) and _status()["state"] == "prepared" and GlobalInventory.get_item_quantity(ITEM) == 3, "round-trip preparada não consome")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	golem.call("set_work_priority", 4)
	var active: Dictionary = SaveManager.call("_build_save_data")
	_check(SaveManager.call("_apply_save_data", JSON.parse_string(JSON.stringify(active))) and _status()["state"] == "active" and _cargo() == CARGO and GlobalInventory.get_item_quantity(ITEM) == 2, "round-trip ativa restaura custo já pago sem retirada/refund")
	var before := _domain()
	_check(SaveManager.call("_apply_save_data", active) and _work() == before.work and GlobalInventory.inventario == before.inventory and chest.get_contents() == before.chest, "replay ativo substitui sem duplicação")
	_check(not _work().has("position") and not _work().has("state") and not _work().has("timer"), "snapshot conserva custódia/flags, não posição/tempo offline")
	var partial := {"version": 4, "farm_plots": []}
	before = _domain()
	_check(SaveManager.call("_apply_save_data", partial) and _work() == before.work, "payload parcial omitindo domínio conserva flags/cargo")
	var replacement: Dictionary = active.duplicate(true)
	for key in GolemWorkState.ACCELERATOR_KEYS:
		replacement["golem_work"].erase(key)
	_check(SaveManager.call("_apply_save_data", replacement) and _status()["state"] == "none" and golem.get("harvest_delivery_started") and _cargo() == CARGO, "cargo legado igual não herda bônus; iniciado conservadoramente")
	_open_delivery()
	_check(golem.call("prepare_accelerator_delivery") and not golem.get("accelerator_active") and GlobalInventory.get_item_quantity(ITEM) == 2, "preparo após legado não é retroativo")
	golem.call("set_work_priority", 4)
	for version in [3, 4]:
		var legacy: Dictionary = active.duplicate(true)
		legacy["version"] = version
		legacy.erase("golem_work")
		if version == 3: legacy.erase("farm_grid")
		_check(SaveManager.call("_apply_save_data", legacy) and _work() == GolemWorkState.default_data(), "legado completo v%d limpa flags/cargo sem refund" % version)
	var invalid: Array[Dictionary] = []
	for key in GolemWorkState.ACCELERATOR_KEYS:
		for value in [null, 0, 1, "true", {}, []]:
			var bad: Dictionary = active.duplicate(true)
			bad["golem_work"][key] = value
			invalid.append(bad)
	for rule in ["both", "no_started", "empty", "seed", "unknown", "started_empty"]:
		var bad: Dictionary = active.duplicate(true)
		match rule:
			"both": bad["golem_work"]["accelerator_prepared"] = true
			"no_started": bad["golem_work"]["harvest_delivery_started"] = false
			"empty": bad["golem_work"]["harvest_cargo"] = {}
			"seed": bad["golem_work"]["seed_cargo"] = {"item_id": "semente_basica", "quantity": 1, "target_cell": {"x": 0, "y": 0}, "intent": "return"}
			"unknown": bad["golem_work"]["accelerator_queue"] = true
			"started_empty":
				bad["golem_work"]["harvest_cargo"] = {}
				bad["golem_work"]["accelerator_active"] = false
		invalid.append(bad)
	for bad in invalid:
		before = _domain()
		_check(not SaveManager.call("_apply_save_data", bad), "payload contraditório/tipo não booleano recusado")
		_check(_domain() == before, "preflight negativo preserva estoque/cargo/geração/região")
	# Writer real isolado: contradição runtime nunca sobrescreve arquivo anterior.
	_check(SaveManager.call("_apply_save_data", active) and SaveManager.save_game(), "writer real grava snapshot ativo QA válido")
	var disk_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	golem.set("accelerator_prepared", true)
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk_before, "writer preparada+ativa recusa e preserva bytes anteriores")
	_dismiss_test_dialogs()
	golem.set("accelerator_prepared", false)
	golem.set("carried_rewards", [])
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk_before, "writer ativa sem cargo recusa e preserva arquivo")
	_dismiss_test_dialogs()
	_check(SaveManager.load_game() and _status()["state"] == "active" and _cargo() == CARGO, "arquivo preservado restaura estado válido")

func _dismiss_test_dialogs() -> void:
	# Fechar imediatamente libera a janela exclusiva antes do próximo controle
	# negativo; queue_free sozinho só a removeria ao final do frame.
	for node in get_tree().root.get_children():
		if node is AcceptDialog:
			node.hide()
			if not node.is_queued_for_deletion(): node.queue_free()

func _test_reentrant_and_stale() -> void:
	_reset()
	var observed := {"valid": false, "blocked": false}
	var inspect := func():
		var work := _work()
		observed.valid = GolemWorkState.is_valid(work, true) and (not work["accelerator_active"] or GlobalInventory.get_item_quantity(ITEM) == 2)
		observed.blocked = not golem.call("cancel_accelerator_preparation") and not golem.call("prepare_accelerator_delivery")
	golem.connect("accelerator_status_changed", inspect)
	golem.call("prepare_accelerator_delivery")
	_check(observed.valid and observed.blocked and _status()["state"] == "prepared", "sinal de preparo observa commit e bloqueia reentrada")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	_check(observed.valid and observed.blocked and _status()["state"] == "active", "sinal de ativação observa estoque pago/custódia/rota coerentes")
	golem.disconnect("accelerator_status_changed", inspect)
	var stale: Callable = golem.get("_movement_callback")
	golem.call("set_work_priority", 4)
	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	_check(SaveManager.call("_apply_save_data", snapshot), "load substitui ativa e invalida callback antigo")
	var before := _domain()
	stale.call()
	_check(_domain() == before, "callback obsoleto não deposita nem reativa após load")
	_open_delivery()
	golem.set_physics_process(false)
	golem.call("_chegar_ao_bau")
	_check(golem.get("state") == "DEPOSITING", "fixture inicia await real de depósito")
	_check(SaveManager.call("_apply_save_data", snapshot), "load durante depósito substitui geração/cargo/flags")
	# Mesmo estado nominal da espera antiga: geração é indispensável.
	golem.set("state", "DEPOSITING")
	golem.set("target_chest", chest)
	await get_tree().create_timer(0.4).timeout
	_check(chest.get_item_quantity("trigo") == 0 and _cargo() == CARGO and _status()["state"] == "active", "await obsoleto não limpa/deposita nova custódia")
	golem.call("_parar_execucao_atual")
	golem.set_physics_process(true)
	_open_delivery()
	await _delivered()
	_check(chest.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity(ITEM) == 2, "rota reconstruída encerra uma entrega sem repetir custo")
	# Sinal final permite ler um snapshot íntegro sem flag ativa e com depósito.
	_reset()
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	var final_seen := {"valid": false}
	var inspect_final := func():
		var work := _work()
		final_seen.valid = work["harvest_cargo"].is_empty() and not work["accelerator_active"] and not work["harvest_delivery_started"] and chest.get_item_quantity("trigo") == 2 and GolemWorkState.is_valid(work, true)
	golem.connect("accelerator_status_changed", inspect_final)
	await _delivered()
	golem.disconnect("accelerator_status_changed", inspect_final)
	_check(final_seen.valid, "sinal pós-depósito não expõe cargo/benefício antigos com estoque creditado")
	_reset()
	var replacement: Dictionary = SaveManager.call("_build_save_data")
	golem.call("prepare_accelerator_delivery")
	golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	var loaded := {"success": false}
	var replace_on_signal := func():
		if _status()["state"] == "active":
			loaded.success = SaveManager.call("_apply_save_data", replacement)
	golem.connect("accelerator_status_changed", replace_on_signal)
	_open_delivery()
	golem.disconnect("accelerator_status_changed", replace_on_signal)
	_check(loaded.success and _status()["state"] == "none" and _cargo().is_empty() and golem.get("state") == "IDLE", "load reentrante no sinal substitui geração/cargo/flags sem escrita antiga posterior")
	_check(GlobalInventory.get_item_quantity(ITEM) == 3 and chest.get_item_quantity("trigo") == 0, "snapshot reentrante restaura seu estoque sem depósito/cobrança adicional")

func _test_cache() -> void:
	for mode in ["prepared", "active"]:
		_reset()
		golem.call("prepare_accelerator_delivery")
		if mode == "active":
			golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
			_open_delivery()
		golem.call("set_work_priority", 4)
		var work := _work()
		var probe := {"calls": 0}
		golem.call("_iniciar_deslocamento", golem.global_position, func(): probe.calls += 1)
		var stale: Callable = golem.get("_movement_callback")
		home.call("request_region_transition", &"foraging_grove", &"from_farm")
		for _frame in range(180):
			await get_tree().process_frame
			if get_tree().current_scene != home and not RegionTravelCoordinator.is_transition_in_progress(): break
		_check(not home.is_inside_tree() and get_tree().current_scene != home, "viagem %s remove vila física para cache" % mode)
		_check(not golem.call("prepare_accelerator_delivery") and not golem.call("cancel_accelerator_preparation"), "vila cacheada não configura ordens")
		stale.call()
		await get_tree().create_timer(0.35).timeout
		var cached: Dictionary = SaveManager.call("_build_save_data")
		var stock := 2 if mode == "active" else 3
		_check(cached["golem_work"] == work and probe.calls == 0 and GlobalInventory.get_item_quantity(ITEM) == stock and chest.get_item_quantity("trigo") == 0, "cache conserva flags/cargo sem callbacks/logística/tempo offline")
		_check(SaveManager.save_game(), "save externo captura ordem/custódia congelada da vila")
		_check(SaveManager.load_game() and get_tree().current_scene == home and _work() == work, "load externo retorna à vila com flags sem nova retirada")
		_check(SaveManager.load_game() and GlobalInventory.get_item_quantity(ITEM) == stock, "replay externo não refaz consumo")
		if mode == "prepared": golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
		_open_delivery()
		await _delivered()
		_check(chest.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity(ITEM) == 2, "retorno reconstrói entrega única beneficiada")

func _write_fixture(mode: String) -> void:
	_reset()
	chest.set_contents({ITEM: 7, "trigo": 5})
	golem.call("prepare_accelerator_delivery")
	if mode == "active":
		golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
		_open_delivery()
		golem.call("set_work_priority", 4)
	_check(_status()["state"] == mode and GlobalInventory.get_item_quantity(ITEM) == (2 if mode == "active" else 3) and golem.get("work_priority") == 4, "fixture %s conserva flags/custo e pausa" % mode)
	_check(SaveManager.save_game(), "fixture %s salva somente arquivo QA" % mode)

func _verify_reopen(mode: String) -> void:
	_check(SaveManager.has_save(), "arquivo do processo produtor disponível")
	_check(SaveManager.load_game(), "novo processo lê snapshot real")
	_check(_status()["state"] == mode and golem.get("work_priority") == 4 and _cargo() == (CARGO if mode == "active" else {}), "novo processo restaura flags/cargo/pausa")
	var stock := 2 if mode == "active" else 3
	_check(GlobalInventory.get_item_quantity(ITEM) == stock and chest.get_item_quantity(ITEM) == 7 and chest.get_item_quantity("trigo") == 5, "fontes/custo previamente pago preservados")
	_check(is_equal_approx(golem.get("move_speed_pixels_per_second"), 128.0) and is_equal_approx(golem.get("deposit_duration"), 0.3) and not _work().has("position"), "sem velocidade-base/timer/posição persistidos")
	var work := _work()
	_check(SaveManager.load_game() and _work() == work and GlobalInventory.get_item_quantity(ITEM) == stock, "replay em novo processo não cobra/refunda")
	if mode == "prepared": golem.call("_receive_harvest_cargo", GolemWorkState.harvest_rewards(CARGO))
	_open_delivery()
	await _delivered(false)
	_check(_cargo().is_empty() and _status()["state"] == "none" and GlobalInventory.get_item_quantity(ITEM) == 2 and chest.get_item_quantity("trigo") == 7 and chest.get_item_quantity("palha_rara") == 1, "entrega reconstruída conclui única com custo final correto")
	golem.call("_chegar_ao_bau")
	golem.call("_procurar_bau")
	await _frames(24)
	_check(chest.get_item_quantity("trigo") == 7 and chest.get_item_quantity("palha_rara") == 1 and GlobalInventory.get_item_quantity(ITEM) == 2, "repetição não entrega/gasta de novo")

func _delivered(count_check: bool = true) -> void:
	for _frame in range(1000):
		await get_tree().physics_frame
		if _cargo().is_empty():
			if count_check: _check(true, "rota física/deposito concluiu dentro do limite QA")
			return
	if count_check: _check(false, "rota física/deposito não concluiu dentro do limite QA")

func _frames(count: int) -> void:
	for _frame in range(count): await get_tree().physics_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("AcceleratorDeliverySmokeTest: " + message)

func _finish(label: String) -> void:
	if not failed: print("AcceleratorDeliverySmokeTest: PASS - %d verificações de %s." % [checks, label])
	get_tree().quit(1 if failed else 0)
