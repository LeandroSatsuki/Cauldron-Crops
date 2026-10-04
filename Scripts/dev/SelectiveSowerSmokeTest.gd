extends Node

# QA sintético/isolado. Default domínio; flags separam física, persistência,
# fixture e reabertura real sem depender do save pessoal ou simular offline.
const MAIN := preload("res://Scenes/Main.tscn")
const WHEAT := "semente_basica"
const TOMATO := "semente_verao"
const CELL := Vector2i.ZERO
var home: Node
var golem: CharacterBody2D
var chest: VillageChest
var plot: Node2D
var checks := 0
var failed := false
var mode := "domínio"

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA sob Builds/QA antes de instanciar Main")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	EventDirector.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	golem = home.get_node("Golem")
	chest = home.get_node("VillageChest")
	plot = home.call("obter_farm_plot_por_grid_position", CELL)
	home.process_mode = Node.PROCESS_MODE_DISABLED
	(golem.get("_think_timer") as Timer).stop()
	var args := OS.get_cmdline_user_args()
	if "--verify-selective-sower-reopen" in args:
		mode = "reabertura"
		_verify_reopen()
	elif "--write-selective-sower-fixture" in args:
		mode = "fixture"
		_write_fixture()
	elif "--selective-sower-physical" in args:
		mode = "física"
		await _physical()
	elif "--selective-sower-persistence" in args:
		mode = "persistência"
		await _persistence()
	else:
		_domain()
	_finish()

func _reset(seed_id: String = TOMATO) -> void:
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	(golem.get("_think_timer") as Timer).stop()
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GlobalInventory.set_inventory_contents({WHEAT: 7, TOMATO: 9, "agua": 4})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	GlobalInventory.semente_selecionada = "semente_inverno"
	chest.set_contents({WHEAT: 3, TOMATO: 3})
	for live in home.get_tree().get_nodes_in_group("lotes_terra"):
		_blank(live, false)
	_blank(plot)
	golem.call("set_selected_seed_id", seed_id)
	golem.global_position = chest.global_position + Vector2(220, 48)
	golem.set("move_speed_pixels_per_second", 600.0)
	golem.set("harvest_duration", 0.04)
	golem.set("deposit_duration", 0.04)

func _blank(live: Node, tilled: bool = true) -> void:
	live.show()
	live.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": tilled, "regado": false, "expansion_blocked": false, "living_soil_treated": false, "living_soil_moisture": false})

func _cargo() -> GolemSeedCargo:
	return golem.get("seed_cargo") as GolemSeedCargo

func _work() -> Dictionary:
	return golem.call("get_work_save_data")

func _resources() -> Dictionary:
	return {"chest": chest.get_contents(), "personal": GlobalInventory.inventario.duplicate(true), "selection": GlobalInventory.semente_selecionada, "tool": ToolManager.get_active_tool()}

func _chest_matches(expected: Dictionary) -> bool:
	# JSON reabre inteiros como float; comparar IDs e unidades integrais,
	# nunca arredondar frações, aceitar chaves extras ou ignorar o conteúdo.
	var current := chest.get_contents()
	if current.size() != expected.size() or not current.has_all(expected.keys()):
		return false
	for item_id in expected:
		for quantity in [current[item_id], expected[item_id]]:
			if typeof(quantity) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(quantity)) or float(quantity) != float(int(quantity)):
				return false
		if chest.get_item_quantity(item_id) != int(expected[item_id]):
			return false
	return true

func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))

func _domain() -> void:
	_reset(WHEAT)
	_check(_work()["selected_seed_id"] == WHEAT and not golem.get("seeding_enabled"), "novo domínio OFF/Trigo")
	var resources := _resources()
	var priority: int = golem.get("work_priority")
	for id in [TOMATO, WHEAT]:
		_check(golem.call("set_selected_seed_id", id) == {"ok": true, "reason": ""}, "seleção permitida " + id)
		_check(golem.call("get_selected_seed_id") == id and _resources() == resources and golem.get("work_priority") == priority and not golem.get("seeding_enabled"), "selecionar não muda fontes/ferramenta/ON/prioridade")
		var before := _work()
		_check(golem.call("get_seed_selection_status")["can_change"] and golem.call("get_seeding_status")["selected_seed_id"] == id and _work() == before, "consultas puras expõem escolha")
	for id in ["", "trigo", "semente_outono", "semente_inverno", "desconhecida"]:
		var before := _work()
		_check(golem.call("set_selected_seed_id", id) == {"ok": false, "reason": "invalid_seed"} and _work() == before, "setter recusa ID " + id)
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
	_check(golem.call("get_seed_selection_status")["reason"] == "locked" and not golem.call("set_selected_seed_id", TOMATO)["ok"] and not golem.call("set_seeding_enabled", true), "gate não é concedido pela seleção")
	_reset()
	for state in ["MOVING_TO_SEED_CHEST", "MOVING_TO_SEED_PLOT", "PLANTING_SEED", "MOVING_TO_SEED_RETURN", "RETURNING_SEED"]:
		golem.set("state", state)
		_check(golem.call("get_seed_selection_status")["reason"] == "seed_job" and not golem.call("set_selected_seed_id", WHEAT)["ok"], "bloqueio de tarefa sem carga " + state)
	golem.call("load_work_save_data", GolemWorkState.default_data(), true)
	_reset()
	_check(_cargo().take_from_chest(chest, CELL, TOMATO), "retirada de tomate")
	for returning in [false, true]:
		if returning: _cargo().mark_return_pending()
		for paused in [false, true]:
			golem.call("set_work_priority", 4 if paused else 0)
			var before := _work()
			_check(golem.call("get_seed_selection_status")["reason"] == "seed_cargo" and not golem.call("set_selected_seed_id", WHEAT)["ok"] and _work() == before, "cargo bloqueia troca inclusive pausa/devolução")
	for id in [WHEAT, TOMATO]:
		for season in range(4):
			_reset(id)
			SeasonManager.estacao_atual = season
			var cargo := GolemSeedCargo.new()
			_check(cargo.take_from_chest(chest, CELL, id) and cargo.get_item_id() == id, "cargo retira exatamente o ID escolhido")
			var source := _resources()
			_check(not cargo.consume_for_plant(TOMATO if id == WHEAT else WHEAT, CELL) and cargo.has_seed(), "ID diferente não converte/consome cargo")
			var result: Dictionary = plot.call("try_plant_from_golem_cargo", cargo)
			var allowed: bool = season == 0 or (id == TOMATO and season == 1)
			_check(result["success"] == allowed and _resources() == source, "matriz sazonal sem retirada adicional %s/%d" % [id, season])
			if allowed:
				var expected := (3.0 if id == WHEAT else 5.0) * (0.8 if season == 1 else 1.0)
				_check(plot.get("semente_id_plantada") == id and not cargo.has_seed() and is_equal_approx(plot.get("tempo_total_crescimento"), expected), "cargo governa cultura e mantém timer/modificador")
			else:
				_check(result["reason"] == "wrong_season" and cargo.get_item_id() == id and plot.get("estado_atual") == 0, "recusa preserva unidade original")
				cargo.mark_return_pending()
				_check(cargo.return_to_chest(chest) and chest.get_item_quantity(id) == 3 and chest.get_item_quantity(TOMATO if id == WHEAT else WHEAT) == 3, "devolve uma unidade do ID original")
	_reset()
	var before := _resources()
	for id in ["semente_outono", "semente_inverno", "trigo", ""]:
		_check(not _cargo().take_from_chest(chest, CELL, id) and _resources() == before, "cargo não retira ID fora da whitelist")
	for value in [null, true, 1, {}, [], "", "semente_inverno", "trigo"]:
		var work := GolemWorkState.default_data()
		work["selected_seed_id"] = value
		_check(not GolemWorkState.is_valid(work, true), "campo opcional presente exige String whitelist: " + str(value))
	var work := GolemWorkState.default_data()
	work.erase("selected_seed_id")
	_check(GolemWorkState.is_valid(work, false) and golem.call("load_work_save_data", work, false) and golem.call("get_selected_seed_id") == WHEAT, "work legado sem seleção resolve Trigo mantendo v1")
	_reset()
	_check(golem.call("set_seeding_enabled", true), "liga explicitamente")
	chest.set_contents({WHEAT: 3})
	_check(not golem.call("_start_seeding") and chest.get_item_quantity(WHEAT) == 3 and not _cargo().has_seed() and golem.call("get_seeding_status")["code"] == "no_seeds", "tomate ausente nunca usa trigo nem Mochila")
	chest.set_contents({WHEAT: 3, TOMATO: 3})
	for priority_mode in [2, 3, 4]:
		golem.call("set_work_priority", priority_mode)
		_check(not golem.call("_start_seeding") and not _cargo().has_seed(), "prioridades exclusivas/pausa intactas")
	golem.call("set_work_priority", 0)
	var old_scene := get_tree().current_scene
	get_tree().current_scene = self
	var old_work := _work()
	_check(golem.call("get_seed_selection_status")["reason"] == "inactive_context" and not golem.call("set_selected_seed_id", WHEAT)["ok"] and not golem.call("set_seeding_enabled", false) and not golem.call("_start_seeding") and _work() == old_work, "comandos recusados fora da vila ativa")
	get_tree().current_scene = old_scene

func _physical() -> void:
	golem.process_mode = Node.PROCESS_MODE_ALWAYS
	for id in [WHEAT, TOMATO]:
		for cell in GolemSeedCargo.PILOT_CELLS:
			_reset(id)
			_blank(plot, false)
			var live: Node2D = home.call("obter_farm_plot_por_grid_position", cell)
			_blank(live)
			var extra: Node = home.call("obter_farm_plot_por_grid_position", Vector2i(2, 2))
			_blank(extra)
			var source := _resources()
			golem.call("set_seeding_enabled", true)
			_check(golem.call("_start_seeding") and golem.get("state") == "MOVING_TO_SEED_CHEST" and not _cargo().has_seed() and chest.get_item_quantity(id) == 3, "ida real sem reserva " + id + str(cell))
			_check(not golem.call("set_selected_seed_id", TOMATO if id == WHEAT else WHEAT)["ok"], "troca bloqueada na ida antes de retirar")
			if not await _wait(func(): return _cargo().has_seed(), "retirada física"): return
			_check(_cargo().get_item_id() == id and _cargo().get_target_cell() == cell and chest.get_item_quantity(id) == 2 and golem.global_position.distance_to(chest.global_position) <= 62.0, "retirada única e próxima do baú")
			await get_tree().process_frame
			_check((golem.get_node("SeedCargoVisual") as Sprite2D).visible, "unidade transportada visível")
			if not await _wait(func(): return golem.get("state") == "IDLE", "plantio físico"): return
			_check(live.get("semente_id_plantada") == id and live.get("estado_atual") == 1 and not _cargo().has_seed() and chest.get_item_quantity(id) == 2 and extra.get("estado_atual") == 0, "uma cultura correta sem célula extra/fallback")
			_check(GlobalInventory.inventario == source["personal"] and GlobalInventory.semente_selecionada == source["selection"] and ToolManager.get_active_tool() == source["tool"], "ciclo físico não altera Mochila/ferramenta/seleção")
	for interference in ["off", "occupied", "season", "hidden", "paused_return", "chest_absent"]:
		_reset()
		golem.call("set_seeding_enabled", true)
		golem.call("_start_seeding")
		if not await _wait(func(): return _cargo().has_seed(), "cargo para interferência"): return
		var before_callback: Callable = golem.get("_movement_callback")
		golem.call("set_work_priority", 4)
		var stopped := golem.global_position
		before_callback.call()
		await get_tree().create_timer(0.08).timeout
		_check(_cargo().get_item_id() == TOMATO and golem.global_position == stopped and not golem.call("set_selected_seed_id", WHEAT)["ok"], "pausa/token/identidade preservados " + interference)
		if interference == "occupied":
			plot.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": WHEAT, "arado": true, "tempo_restante": 60.0, "tempo_total_crescimento": 60.0})
		elif interference == "season": SeasonManager.estacao_atual = SeasonManager.Estacao.INVERNO
		elif interference == "hidden": plot.hide()
		else: golem.call("set_seeding_enabled", false)
		if interference == "paused_return":
			_check(_cargo().is_return_pending() and chest.get_item_quantity(TOMATO) == 2 and not golem.call("set_selected_seed_id", WHEAT)["ok"], "OFF pausado não refunda nem libera seleção")
		golem.call("set_work_priority", 0)
		if interference == "chest_absent":
			home.remove_child(chest)
			golem.call("_on_think_timer_timeout")
			_check(_cargo().is_return_pending() and _cargo().get_item_id() == TOMATO and golem.get("state") == "IDLE", "baú ausente conserva cargo tomate")
			home.add_child(chest)
		golem.call("_on_think_timer_timeout")
		if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "retorno físico " + interference): return
		_check(chest.get_item_quantity(TOMATO) == 3 and chest.get_item_quantity(WHEAT) == 3 and golem.global_position.distance_to(chest.global_position) <= 62.0, "retorno físico único do tomate; trigo intacto")
		_check(plot.get("semente_id_plantada") == (WHEAT if interference == "occupied" else ""), "não sobrescreve cultivo na devolução")
	# Seleção restaurada diferente do cargo governa só a próxima retirada.
	_reset(WHEAT)
	golem.call("set_seeding_enabled", true)
	_check(_cargo().take_from_chest(chest, CELL, TOMATO), "fixture obtém cargo tomate com futura escolha trigo")
	var work := _work()
	_check(golem.call("load_work_save_data", work, true), "substitui work sem converter cargo")
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "cargo carregado diferente da seleção"): return
	_check(plot.get("semente_id_plantada") == TOMATO and golem.call("get_selected_seed_id") == WHEAT and chest.get_item_quantity(WHEAT) == 3 and chest.get_item_quantity(TOMATO) == 2, "planta cargo tomate apesar da futura escolha trigo")
	# OFF durante espera de plantio invalida o timer e devolve a unidade.
	_reset()
	golem.set("harvest_duration", 0.3)
	golem.call("set_seeding_enabled", true)
	golem.call("_start_seeding")
	if not await _wait(func(): return golem.get("state") == "PLANTING_SEED", "espera antes de OFF"): return
	_check(not golem.call("set_selected_seed_id", WHEAT)["ok"] and golem.call("set_seeding_enabled", false), "OFF permitido mesmo com troca bloqueada no plantio")
	await get_tree().create_timer(0.4).timeout
	_check(_cargo().get_item_id() == TOMATO and _cargo().is_return_pending() and plot.get("estado_atual") == 0 and chest.get_item_quantity(TOMATO) == 2, "timer obsoleto não planta/devolve remotamente")
	golem.call("_on_think_timer_timeout")
	if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "retorno após OFF na espera"): return
	_check(chest.get_item_quantity(TOMATO) == 3 and golem.call("get_seed_selection_status")["can_change"], "fim real da custódia libera seleção")
	await _timer_interleavings()

func _timer_interleavings() -> void:
	# O personagem está próximo do destino real antes de abrir cada espera.
	# Só o fixture posiciona/encurta timers; o commit e retry são de produção.
	for phase in ["plant", "return"]:
		for interruption in ["cache", "load"]:
			_reset()
			golem.call("set_seeding_enabled", true)
			_cargo().take_from_chest(chest, CELL, TOMATO)
			golem.set("harvest_duration", 0.25)
			golem.set("deposit_duration", 0.25)
			var waiting_state := "PLANTING_SEED" if phase == "plant" else "RETURNING_SEED"
			if phase == "plant":
				golem.global_position = plot.call("get_golem_harvest_position")
				golem.set("target_plot", plot)
				golem.set("state", "MOVING_TO_SEED_PLOT")
				golem.call("_arrive_seed_plot")
			else:
				golem.call("set_seeding_enabled", false)
				golem.global_position = chest.global_position + Vector2(0, 48)
				golem.set("target_chest", chest)
				golem.set("state", "MOVING_TO_SEED_RETURN")
				golem.call("_arrive_seed_return")
			var entered_wait: bool = golem.get("state") == waiting_state
			var generation: int = golem.get("_task_generation")
			var source := _resources()
			var interruption_applied := true
			if interruption == "cache":
				# Contexto inválido ainda dentro da árvore: o tick físico precisa
				# invalidar a geração antes de o timer antigo poder fazer commit.
				home.set("_region_being_cached", true)
				await get_tree().physics_frame
			else:
				interruption_applied = SaveManager.call("_apply_save_data", _snapshot())
				# Mesmo nome de estado/alvo no runtime novo: a string sozinha
				# não protege a nova custódia contra o await do snapshot antigo.
				golem.set("target_plot", plot if phase == "plant" else null)
				golem.set("target_chest", chest if phase == "return" else null)
				golem.set("state", waiting_state)
			var after_interruption := _resources()
			await get_tree().create_timer(0.32).timeout
			var label: String = phase + "/" + interruption
			_check(entered_wait and interruption_applied and home.is_inside_tree() and int(golem.get("_task_generation")) > generation and golem.get("state") == ("IDLE" if interruption == "cache" else waiting_state), "contexto/load invalida geração da espera antiga " + label)
			_check(_cargo().get_item_id() == TOMATO and _cargo().is_return_pending() == (phase == "return") and plot.get("estado_atual") == 0, "timer antigo não planta/converte/devolve custódia " + label)
			_check(_resources() == after_interruption, "timer antigo não muda fontes/seleções pós-interrupção " + label)
			_check(_chest_matches(source["chest"]) and after_interruption["personal"] == source["personal"], "load/contexto conserva mesmos IDs e unidades integrais nas fontes " + label)
			if interruption == "cache":
				home.set("_region_being_cached", false)
			else:
				golem.call("_parar_execucao_atual") # Limpar só o estado homônimo sintético.
			golem.set("harvest_duration", 0.04)
			golem.set("deposit_duration", 0.04)
			golem.call("_on_think_timer_timeout")
			if not await _wait(func(): return not _cargo().has_seed() and golem.get("state") == "IDLE", "retry físico após espera interrompida " + phase + "/" + interruption): return
			_check(chest.get_item_quantity(TOMATO) == (2 if phase == "plant" else 3) and chest.get_item_quantity(WHEAT) == 3 and plot.get("semente_id_plantada") == (TOMATO if phase == "plant" else "") and GlobalInventory.inventario == source["personal"] and GlobalInventory.semente_selecionada == after_interruption["selection"] and ToolManager.get_active_tool() == after_interruption["tool"], "retry conclui uma única cultura/devolução original sem novo gasto " + phase + "/" + interruption)

func _persistence() -> void:
	_reset()
	golem.call("set_seeding_enabled", true)
	_check(_cargo().take_from_chest(chest, CELL, TOMATO), "custódia real inicial")
	var saved := _snapshot()
	_check(saved["version"] == 4 and saved["golem_work"]["version"] == 1 and saved["golem_work"]["selected_seed_id"] == TOMATO, "extensão opcional mantém savev4/workv1")
	for selection in [WHEAT, TOMATO]:
		var incoming := saved.duplicate(true)
		incoming["golem_work"]["selected_seed_id"] = selection
		_check(SaveManager.call("_apply_save_data", incoming) and golem.call("get_selected_seed_id") == selection and _cargo().get_item_id() == TOMATO and chest.get_item_quantity(TOMATO) == 2, "load valida seleção/cargo independentemente")
		var before := _work()
		_check(SaveManager.call("_apply_save_data", incoming) and _work() == before and chest.get_item_quantity(TOMATO) == 2, "replay não retira/planta/deposita")
	var old := saved.duplicate(true)
	old["golem_work"].erase("selected_seed_id")
	_check(SaveManager.call("_apply_save_data", old) and golem.call("get_selected_seed_id") == WHEAT and _cargo().get_item_id() == TOMATO, "campo ausente resolve Trigo sem converter tomate transportado")
	var before := _work()
	_check(SaveManager.call("_apply_save_data", {"version": 4}) and _work() == before, "domínio parcial ausente conserva seleção/cargo")
	_check(SaveManager.call("_apply_save_data", saved), "restaura seleção de tomate antes de completo legado")
	for version in [3, 4]:
		old = saved.duplicate(true)
		old["version"] = version
		old.erase("golem_work")
		_check(SaveManager.call("_apply_save_data", old) and _work() == GolemWorkState.default_data() and chest.get_item_quantity(TOMATO) == 2, "completo v%d sem domínio OFF/Trigo sem refund" % version)
	for value in [null, true, 1, {}, [], "", "semente_inverno", "trigo"]:
		var incoming := saved.duplicate(true)
		incoming["golem_work"]["selected_seed_id"] = value
		before = _work()
		var resources := _resources()
		_check(not SaveManager.call("_apply_save_data", incoming) and _work() == before and _resources() == resources, "preflight recusa seleção inválida atomicamente")
	_check(SaveManager.call("_apply_save_data", saved) and SaveManager.save_game(), "arquivo real QA com tomate")
	var disk_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	golem.set("selected_seed_id", "semente_inverno")
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == disk_before, "writer inválido preserva arquivo anterior")
	for node in get_tree().root.get_children():
		if node is AcceptDialog: node.queue_free()
	_check(SaveManager.load_game() and golem.call("get_selected_seed_id") == TOMATO and _cargo().get_item_id() == TOMATO, "arquivo válido substitui seleção runtime inválida")
	var stale: Callable
	golem.call("_iniciar_deslocamento", Vector2.ZERO, func(): _check(false, "callback obsoleto executou"))
	stale = golem.get("_movement_callback")
	_check(SaveManager.call("_apply_save_data", saved), "load invalida callback")
	stale.call()
	_check(golem.get("state") == "IDLE" and _cargo().get_item_id() == TOMATO and chest.get_item_quantity(TOMATO) == 2, "callback antigo não toca nova custódia")
	# Transição real, vila cacheada não aceita comando nem modifica a unidade.
	home.process_mode = Node.PROCESS_MODE_INHERIT
	golem.call("set_work_priority", 4)
	before = _work()
	home.call("request_region_transition", &"foraging_grove", &"from_farm")
	for _frame in range(180):
		await get_tree().process_frame
		if not home.is_inside_tree() and not RegionTravelCoordinator.is_transition_in_progress(): break
	_check(not home.is_inside_tree() and golem.call("get_seed_selection_status")["reason"] == "inactive_context", "vila cacheada sem comando")
	_check(not golem.call("set_selected_seed_id", WHEAT)["ok"] and not golem.call("set_seeding_enabled", false) and _work() == before, "cache conserva escolha e cargo sem benefício novo")
	_check(SaveManager.save_game() and SaveManager.load_game(), "save externo QA retorna à vila")
	home.process_mode = Node.PROCESS_MODE_DISABLED
	(golem.get("_think_timer") as Timer).stop()
	_check(get_tree().current_scene == home and _work() == before and _cargo().get_item_id() == TOMATO and chest.get_item_quantity(TOMATO) == 2, "retorno do cache/load conserva sem duplicação")

func _write_fixture() -> void:
	_reset(TOMATO)
	golem.call("set_seeding_enabled", true)
	_check(_cargo().take_from_chest(chest, CELL, TOMATO), "fixture retira uma unidade de tomate no baú")
	golem.call("set_work_priority", 4)
	golem.call("set_seeding_enabled", false)
	_check(SaveManager.save_game(), "fixture grava escolha tomate OFF/pausa/cargo devolução em QA")

func _verify_reopen() -> void:
	_check(SaveManager.has_save(), "arquivo do produtor existe")
	_check(SaveManager.load_game(), "novo processo lê snapshot")
	_check(golem.call("get_selected_seed_id") == TOMATO and not golem.get("seeding_enabled") and golem.get("work_priority") == 4, "novo processo conserva escolha independente de OFF/pausa")
	_check(_cargo().get_item_id() == TOMATO and _cargo().is_return_pending(), "novo processo preserva unidade original em devolução")
	_check(chest.get_item_quantity(TOMATO) == 2 and chest.get_item_quantity(WHEAT) == 3 and GlobalInventory.get_item_quantity(TOMATO) == 9, "novo processo conserva custódia/fontes")
	_check(GroveExpedition.restored and not golem.call("get_seed_selection_status")["can_change"], "gate e bloqueio do cargo persistem")
	var before := _work()
	_check(SaveManager.load_game() and _work() == before and chest.get_item_quantity(TOMATO) == 2, "replay novo processo sem refund/plantio/retirada")
	_check(not golem.call("set_selected_seed_id", WHEAT)["ok"] and _work() == before, "comando não converte tomate após reabrir")

func _wait(condition: Callable, label: String) -> bool:
	for _frame in range(1200):
		await get_tree().physics_frame
		if bool(condition.call()):
			_check(true, label)
			return true
	_check(false, "timeout: " + label + "; state=" + str(golem.get("state")))
	return false

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SelectiveSowerSmokeTest: FAIL - " + message)

func _finish() -> void:
	if is_instance_valid(home): home.queue_free()
	if not failed:
		print("SelectiveSowerSmokeTest: PASS - %d verificações de %s." % [checks, mode])
	get_tree().quit(1 if failed else 0)
