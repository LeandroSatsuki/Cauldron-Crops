extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SEED := "semente_basica"
var main: Node
var golem: CharacterBody2D
var chest: VillageChest
var plot: Node2D
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("GolemSowerPhysicalSmokeTest: exige APPDATA em Builds/QA.")
		get_tree().quit(1)
		return
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().physics_frame
	await get_tree().physics_frame
	golem = main.get_node("Golem")
	chest = main.get_node("VillageChest")
	plot = main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	(golem.get("_think_timer") as Timer).stop()
	golem.set("move_speed_pixels_per_second", 600.0)
	golem.set("harvest_duration", 0.04)
	golem.set("deposit_duration", 0.04)
	GlobalInventory.set_inventory_contents({SEED: 7, "agua": 2})
	GlobalInventory.semente_selecionada = SEED
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
	_check(not golem.call("set_seeding_enabled", true) and not golem.get("seeding_enabled"), "sem marco não habilita")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	_reset()
	_check(golem.call("set_seeding_enabled", true), "marco permite API, sem UI nova")
	# Quatro viagens reais e nenhuma célula extra, mesmo que preparada.
	for cell in GolemSeedCargo.PILOT_CELLS:
		_reset()
		var live: Node2D = main.call("obter_farm_plot_por_grid_position", cell)
		_prepare(live)
		var extra: Node2D = main.call("obter_farm_plot_por_grid_position", Vector2i(2, 0))
		_prepare(extra)
		golem.call("_on_think_timer_timeout")
		_check(golem.get("state") == "MOVING_TO_SEED_CHEST" and chest.get_item_quantity(SEED) == 3 and not _cargo().has_seed(), "estoque não reservado durante ida " + str(cell))
		if not await _wait(func(): return _cargo().has_seed(), "retirada física " + str(cell)):
			return _finish()
		_check(golem.global_position.distance_to(chest.global_position) <= 62.0 and chest.get_item_quantity(SEED) == 2, "retirada só próximo do baú")
		_check(_cargo().get_target_cell() == cell, "identidade fixa do alvo")
		await get_tree().process_frame
		_check((golem.get_node("SeedCargoVisual") as Sprite2D).visible, "carga visível em trânsito")
		if not await _wait(func(): return golem.get("state") == "IDLE", "plantio físico " + str(cell)):
			return _finish()
		_check(live.get("estado_atual") == 1 and not _cargo().has_seed() and chest.get_item_quantity(SEED) == 2, "uma semente virou uma cultura")
		_check(golem.global_position.distance_to(live.call("get_golem_harvest_position")) <= 14.0, "plantio próximo do lote real")
		_check(extra.get("estado_atual") == 0, "não planta fora do piloto")
		_check(GlobalInventory.get_item_quantity(SEED) == 7 and GlobalInventory.semente_selecionada == "" and ToolManager.get_active_tool() == ToolManager.ToolType.HOE, "Mochila/seleção/ferramenta intactas (enxada limpa seleção no setup)")
	# Saldo e alvo são revalidados antes da retirada.
	_reset()
	_prepare(plot)
	golem.call("_on_think_timer_timeout")
	chest.withdraw_item(SEED, 3)
	if not await _wait(func(): return golem.get("state") == "IDLE", "saldo esgotado"):
		return _finish()
	_check(not _cargo().has_seed() and plot.get("estado_atual") == 0, "saldo esgotado não usa Mochila")
	_reset()
	_prepare(plot)
	golem.call("_on_think_timer_timeout")
	plot.call("set_expansion_blocked", true)
	if not await _wait(func(): return golem.get("state") == "IDLE", "alvo bloqueado antes da retirada"):
		return _finish()
	_check(chest.get_item_quantity(SEED) == 3 and not _cargo().has_seed(), "bloqueio conserva estoque antes da retirada")
	# Concorrência, estação e alvo oculto depois da retirada: devolução real.
	for interference in ["player", "season", "hidden"]:
		_reset()
		_prepare(plot)
		golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return _cargo().has_seed(), "prepara interferência"):
			return _finish()
		if interference == "player":
			_check(plot.call("try_plant_from_personal_inventory", SEED)["success"], "jogador planta primeiro")
		elif interference == "season":
			SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO
		else:
			plot.hide()
		if not await _wait(func(): return golem.get("state") == "IDLE" and not _cargo().has_seed(), "devolução " + interference):
			return _finish()
		_check(chest.get_item_quantity(SEED) == 3 and golem.global_position.distance_to(chest.global_position) <= 62.0, "devolução única no baú real " + interference)
		_check(plot.get("estado_atual") == (1 if interference == "player" else 0), "não sobrescreve alvo " + interference)
		GlobalInventory.set_inventory_contents({SEED: 7, "agua": 2})
		GlobalInventory.semente_selecionada = SEED
	await _test_pause_disable_and_load()
	await _test_return_wait_and_priority()
	await _test_failures_and_cache()
	_test_priorities()
	await _test_continuous_scheduler()
	_finish()

func _test_pause_disable_and_load() -> void:
	_reset()
	_prepare(plot)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return _cargo().has_seed(), "carga para pausa"):
		return
	var old_callback: Callable = golem.get("_movement_callback")
	golem.call("set_work_priority", 4)
	var position := golem.global_position
	old_callback.call()
	await get_tree().create_timer(0.12).timeout
	_check(_cargo().has_seed() and golem.global_position == position and plot.get("estado_atual") == 0 and chest.get_item_quantity(SEED) == 2, "pausa congela carga e invalida movimento")
	golem.call("set_seeding_enabled", false)
	_check(_cargo().is_return_pending() and chest.get_item_quantity(SEED) == 2, "OFF não devolve remotamente")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	_check(SaveManager.call("_apply_save_data", saved) and SaveManager.call("_apply_save_data", saved), "replay de carga pausada")
	_check(_cargo().has_seed() and chest.get_item_quantity(SEED) == 2, "replay não duplica/deposita")
	golem.call("set_work_priority", 0)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "retoma devolução após load"):
		return
	_check(chest.get_item_quantity(SEED) == 3, "retorno físico após load sem nova retirada")
	# Timer de plantio antigo não termina num estado homônimo do snapshot novo.
	_reset()
	_prepare(plot)
	golem.set("harvest_duration", 0.3)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "PLANTING_SEED", "espera de plantio"):
		return
	var work: Dictionary = golem.call("get_work_save_data")
	_check(golem.call("load_work_save_data", work, true), "load invalida espera antiga")
	golem.set("state", "PLANTING_SEED")
	await get_tree().create_timer(0.4).timeout
	_check(_cargo().has_seed() and plot.get("estado_atual") == 0, "timer obsoleto não planta no estado novo")
	golem.call("set_work_priority", 4)
	golem.call("set_work_priority", 0)
	golem.set("harvest_duration", 0.04)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return plot.get("estado_atual") == 1 and golem.get("state") == "IDLE", "rota reconstruída pós-load"):
		return
	_check(chest.get_item_quantity(SEED) == 2 and not _cargo().has_seed(), "carga carregada planta sem outra retirada")

func _test_failures_and_cache() -> void:
	_reset()
	_prepare(plot)
	# Falsa chegada e nav sem caminho nunca autorizam retirar/plantar.
	golem.call("_on_think_timer_timeout")
	golem.call("_arrive_seed_chest")
	_check(chest.get_item_quantity(SEED) == 3 and not _cargo().has_seed(), "callback de chegada remoto não retira")
	_check(_cargo().take_from_chest(chest, Vector2i(0, 0)), "fixture instala custódia de uma unidade")
	golem.call("_resume_seed_cargo")
	golem.call("_arrive_seed_plot")
	_check(_cargo().has_seed() and plot.get("estado_atual") == 0, "callback remoto não planta")
	golem.call("_resume_seed_cargo")
	var agent := golem.get_node("NavigationAgent2D") as NavigationAgent2D
	agent.navigation_layers = 0
	if not await _wait(func(): return golem.get("state") == "IDLE", "caminho impossível"):
		return
	_check(_cargo().has_seed() and chest.get_item_quantity(SEED) == 2, "falha de navegação conserva carga")
	agent.navigation_layers = 1
	golem.call("set_seeding_enabled", false)
	main.remove_child(chest)
	golem.call("_on_think_timer_timeout")
	_check(_cargo().is_return_pending() and golem.get("state") == "IDLE", "baú ausente mantém devolução pendente")
	main.add_child(chest)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "baú volta e recebe devolução"):
		return
	_check(chest.get_item_quantity(SEED) == 3, "retorno após baú ausente único")
	_reset()
	_prepare(plot)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return _cargo().has_seed(), "carga antes do Bosque"):
		return
	var stale: Callable = golem.get("_movement_callback")
	var before: Dictionary = golem.call("get_work_save_data")
	main.call("request_region_transition", &"foraging_grove", &"from_farm")
	for _frame in range(180):
		await get_tree().process_frame
		if not main.is_inside_tree() and not RegionTravelCoordinator.is_transition_in_progress():
			break
	_check(not main.is_inside_tree(), "viagem cacheia vila")
	stale.call()
	await get_tree().create_timer(0.12).timeout
	_check(SaveManager.call("_build_save_data")["golem_work"] == before and plot.get("estado_atual") == 0 and chest.get_item_quantity(SEED) == 2, "vila ausente não transporta/planta")
	_check(SaveManager.save_game() and SaveManager.load_game(), "save QA externo retorna com carga")
	_check(get_tree().current_scene == main and _cargo().has_seed(), "retorno preserva custódia")
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return plot.get("estado_atual") == 1 and golem.get("state") == "IDLE", "retoma rota da vila"):
		return
	_check(chest.get_item_quantity(SEED) == 2 and not _cargo().has_seed(), "retorno planta uma vez, sem retirada extra")

func _test_return_wait_and_priority() -> void:
	# Trocar para modo exclusivo com carga manda devolver, não plantar.
	_reset()
	_prepare(plot)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return _cargo().has_seed(), "carga antes de modo exclusivo"):
		return
	golem.call("set_work_priority", 2)
	_check(_cargo().is_return_pending() and plot.get("estado_atual") == 0, "modo só colher solicita devolução")
	golem.set("deposit_duration", 0.3)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "RETURNING_SEED", "espera de devolução"):
		return
	golem.call("set_work_priority", 4)
	await get_tree().create_timer(0.4).timeout
	_check(_cargo().has_seed() and chest.get_item_quantity(SEED) == 2, "pausa invalida timer de devolução")
	golem.call("set_work_priority", 0)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "RETURNING_SEED", "nova espera de devolução"):
		return
	main.remove_child(chest)
	if not await _wait(func(): return golem.get("state") == "IDLE", "baú some durante espera"):
		return
	_check(_cargo().is_return_pending() and chest.get_item_quantity(SEED) == 2, "baú desaparecido durante depósito conserva semente")
	main.add_child(chest)
	golem.set("deposit_duration", 0.04)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "IDLE" and not _cargo().has_seed(), "baú restaurado"):
		return
	_check(chest.get_item_quantity(SEED) == 3 and plot.get("estado_atual") == 0, "devolução após extremos não duplica/plantou")
	# Desativar durante espera de plantio cancela commit e devolve fisicamente.
	_reset()
	_prepare(plot)
	golem.set("harvest_duration", 0.3)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "PLANTING_SEED", "plantio antes de OFF"):
		return
	golem.call("set_seeding_enabled", false)
	await get_tree().create_timer(0.4).timeout
	_check(_cargo().is_return_pending() and plot.get("estado_atual") == 0 and chest.get_item_quantity(SEED) == 2, "OFF durante plantio mantém carga, invalida timer")
	golem.set("harvest_duration", 0.04)
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return golem.get("state") == "IDLE" and not _cargo().has_seed(), "devolve após OFF"):
		return
	_check(chest.get_item_quantity(SEED) == 3 and plot.get("estado_atual") == 0, "OFF não consome nem duplica")

func _test_priorities() -> void:
	for priority in [2, 3, 4]:
		_reset()
		_prepare(plot)
		golem.call("set_work_priority", priority)
		golem.call("_on_think_timer_timeout")
		_check(not _cargo().has_seed() and chest.get_item_quantity(SEED) == 3 and golem.get("state") not in golem.SEED_MOVEMENT_STATES, "modo exclusivo/pausado não inicia plantio")
	_reset()
	_prepare(plot)
	var mature: Node = main.call("obter_farm_plot_por_grid_position", Vector2i(3, 0))
	mature.call("load_save_data", {"estado_atual": 2, "semente_id_plantada": SEED, "arado": true, "pronto_para_colher": true, "tempo_restante": 0.0, "tempo_total_crescimento": 10.0})
	golem.call("_on_think_timer_timeout")
	_check(golem.get("state") == "MOVING_TO_PLOT" and not _cargo().has_seed(), "colheita tem precedência sobre plantio")
	golem.call("set_work_priority", 4)
	_reset()
	_prepare(plot)
	GlobalInventory.skills_desbloqueadas.append("skill_golem_irrigador")
	var dry: Node = main.call("obter_farm_plot_por_grid_position", Vector2i(3, 0))
	dry.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": SEED, "arado": true, "regado": false, "pronto_para_colher": false, "tempo_restante": 60.0, "tempo_total_crescimento": 60.0})
	golem.call("set_work_priority", 1)
	golem.call("_on_think_timer_timeout")
	_check(golem.get("state") == "MOVING_TO_PLOT" and not _cargo().has_seed() and chest.get_item_quantity(SEED) == 3, "rega elegível precede plantio em modo regar primeiro")
	golem.call("set_work_priority", 4)
	GlobalInventory.skills_desbloqueadas.erase("skill_golem_irrigador")

func _reset() -> void:
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	golem.call("set_seeding_enabled", true)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	chest.set_contents({SEED: 3})
	for live in get_tree().get_nodes_in_group("lotes_terra"):
		_prepare(live, false)
	golem.global_position = chest.global_position + Vector2(220, 48)

func _test_continuous_scheduler() -> void:
	_reset()
	chest.set_contents({SEED: 4})
	golem.set("move_speed_pixels_per_second", 128.0)
	golem.call("set_work_priority", 1)
	for cell in GolemSeedCargo.PILOT_CELLS:
		var live: Node = main.call("obter_farm_plot_por_grid_position", cell)
		_prepare(live)
		live.connect("estado_alterado", _keep_test_crop_growing.bind(live))
	# Velocidade real do jogo; relógio QA acelerado, culturas longas apenas no fixture.
	Engine.time_scale = 3.0
	(golem.get("_think_timer") as Timer).start(0.1)
	var completed := await _wait(func():
		for cell in GolemSeedCargo.PILOT_CELLS:
			if main.call("obter_farm_plot_por_grid_position", cell).get("estado_atual") != 1:
				return false
		return golem.get("state") == "IDLE", "scheduler contínuo a 128 pixels/s planta quatro lotes")
	(golem.get("_think_timer") as Timer).stop()
	Engine.time_scale = 1.0
	_check(completed and chest.get_item_quantity(SEED) == 0 and not _cargo().has_seed(), "quatro sementes em quatro culturas sem reserva/carga residual")
	_check(GlobalInventory.get_item_quantity(SEED) == 7, "scheduler contínuo não utiliza Mochila")
	golem.call("set_work_priority", 4)

func _keep_test_crop_growing(live: Node) -> void:
	if live.get("estado_atual") == 1:
		live.set("tempo_total_crescimento", 120.0)
		(live.get_node("Timer") as Timer).start(120.0)

func _prepare(live: Node, tilled: bool = true) -> void:
	live.show()
	live.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": tilled, "regado": false, "expansion_blocked": false, "pronto_para_colher": false, "tempo_restante": 0.0, "tempo_total_crescimento": 0.0})

func _cargo() -> GolemSeedCargo:
	return golem.get("seed_cargo") as GolemSeedCargo

func _wait(condition: Callable, message: String) -> bool:
	for _frame in range(1200):
		await get_tree().physics_frame
		if bool(condition.call()):
			_check(true, message)
			return true
	_check(false, "timeout: " + message + "; estado=" + str(golem.get("state")) + "; posição=" + str(golem.global_position))
	return false

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("GolemSowerPhysicalSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("GolemSowerPhysicalSmokeTest: PASS - %d verificações de navegação, custódia, concorrência, pausa/load e viagem." % checks)
	get_tree().quit(1 if failed else 0)
