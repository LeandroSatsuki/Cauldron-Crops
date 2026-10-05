extends Node

# Fixture sintética isolada; não é aceite manual de mouse/arte/ritmo.
const MAIN := preload("res://Scenes/Main.tscn")
const GROVE := preload("res://Scenes/ForagingGroveRegion.tscn")
const STATE := preload("res://Scripts/data/HerbariumProductionState.gd")
var home: Node
var site: Node2D
var chest: VillageChest
var project: Node
var obstacle: Node
var player: PlayerAvatar
var checks := 0
var failed := false
var notifications := 0
var probe_signal := false
var nested_calls: Array = []
var observed: Dictionary = {}

class ProbeChest extends VillageChest:
	var fail_item := ""
	var probe: Callable
	func _ready() -> void:
		add_to_group("village_chest")
	func withdraw_item(id: String, amount: int = 1) -> bool:
		if probe.is_valid(): probe.call()
		if id == fail_item or get_item_quantity(id) < amount: return false
		inventory[id] = get_item_quantity(id) - amount
		return true

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
	HerbariumProduction.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	for _frame in range(4): await get_tree().process_frame
	home.process_mode = Node.PROCESS_MODE_DISABLED
	site = home.get_node("ProductiveHerbarium")
	chest = home.get_node("VillageChest")
	project = home.get("restoration_projects")["first_obstacle"]
	obstacle = home.get_node("PurificationObstacle")
	player = home.get_node("PlayerAvatar")
	var golem: Node = home.get_node("Golem")
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	HerbariumProduction.progress_changed.connect(_on_progress)
	_schema()
	_eligibility()
	_payment()
	_faults()
	_collection()
	await _clock()
	_snapshots()
	_finish()

func _reset(personal: Dictionary = {"trigo": 4, "tomate_sol": 1, "mistura_restauradora": 1, "agua": 7}, stored: Dictionary = {"trigo": 4, "tomate_sol": 1}) -> void:
	probe_signal = false
	get_tree().current_scene = home
	home.set("_region_being_cached", false)
	home.call("_cancel_pending_player_interaction", true)
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents(personal)
	GlobalInventory.pontos_alquimia = 13
	chest.set_contents(stored)
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	obstacle.call("load_save_data", {"purified": true})
	project.set("restored_state", true)
	project.call("set_area_purified", true)
	site.show()
	player.global_position = site.global_position + Vector2(0, 45)
	HerbariumProduction.reset_progress()
	notifications = 0
	nested_calls.clear()
	observed.clear()

func _resources() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "chest": chest.get_contents(), "xp": GlobalInventory.pontos_alquimia, "slots": GlobalInventory.get_slot_capacity(), "milestones": GlobalInventory.get_backpack_milestones(), "recipes": GlobalInventory.receitas_descobertas.duplicate(true), "tool": ToolManager.active_tool, "selection": GlobalInventory.semente_selecionada}

func _refused(label: String, code: String) -> void:
	var saved := HerbariumProduction.get_save_data()
	var resources := _resources()
	var generation := HerbariumProduction.get_generation()
	_check(HerbariumProduction.get_status(site).code == code, label + ": status")
	_check(not HerbariumProduction.try_activate(site) and not HerbariumProduction.try_collect(site) and HerbariumProduction.get_save_data() == saved and _resources() == resources and HerbariumProduction.get_generation() == generation, label + ": recusa sem mutação")

func _schema() -> void:
	_check(STATE.default_data() == {"activated": false, "renewal_remaining": 0.0}, "padrão desativado")
	for value in [{"activated": false, "renewal_remaining": 0}, {"activated": true, "renewal_remaining": 0}, {"activated": true, "renewal_remaining": 0.5}, {"activated": true, "renewal_remaining": 90.0}]:
		_check(STATE.is_valid(value), "estado válido")
	for value in [null, [], {}, {"activated": false}, {"renewal_remaining": 0}, {"activated": 1, "renewal_remaining": 0}, {"activated": "true", "renewal_remaining": 0}, {"activated": null, "renewal_remaining": 0}, {"activated": true, "renewal_remaining": true}, {"activated": true, "renewal_remaining": "0"}, {"activated": true, "renewal_remaining": -1}, {"activated": true, "renewal_remaining": 90.01}, {"activated": true, "renewal_remaining": INF}, {"activated": true, "renewal_remaining": NAN}, {"activated": false, "renewal_remaining": 1}, {"activated": true, "renewal_remaining": 0, "unknown": true}]:
		_check(not STATE.is_valid(value), "estado estrito inválido")

func _eligibility() -> void:
	_reset()
	project.set("restored_state", false)
	_refused("Herbário não restaurado", "locked")
	project.set("restored_state", true)
	project.call("set_area_purified", false)
	_refused("área não purificada", "locked")
	project.call("set_area_purified", true)
	obstacle.set("purified_state", false)
	_refused("obstáculo real contradiz flag derivada", "locked")
	obstacle.set("purified_state", true)
	GroveExpedition.restored = false
	_refused("Clareira não restaurada", "locked")
	GroveExpedition.restored = true
	GlobalInventory.set_inventory_contents({})
	chest.set_contents({})
	_refused("materiais ausentes", "missing")
	_check(HerbariumProduction.get_status(site).missing == HerbariumProduction.PROJECT_REQUIREMENTS, "consulta mostra custo integral")
	_reset()
	var resources := _resources()
	_check(HerbariumProduction.get_status().code == "ready" and _resources() == resources, "consulta pura resolve ponto vivo")
	player.global_position = site.global_position + Vector2(250, 0)
	_refused("longe", "ready")
	player.global_position = site.global_position + Vector2(0, 45)
	site.hide()
	_refused("oculto", "home_unavailable")
	site.show()
	home.set("_region_being_cached", true)
	_refused("cache ainda na árvore", "home_unavailable")
	home.set("_region_being_cached", false)
	get_tree().current_scene = self
	_refused("fora da vila", "home_unavailable")
	get_tree().current_scene = home
	var fake := Node2D.new()
	home.add_child(fake)
	fake.global_position = site.global_position
	_check(not HerbariumProduction.try_activate(fake) and HerbariumProduction.get_status(fake).code == "home_unavailable", "identidade não é posição/nome")
	fake.queue_free()
	SaveManager.set("_applying_snapshot", true)
	_refused("load em curso", "home_unavailable")
	SaveManager.set("_applying_snapshot", false)
	RegionTravelCoordinator.set("_transition_in_progress", true)
	_refused("viagem em curso", "home_unavailable")
	RegionTravelCoordinator.set("_transition_in_progress", false)
	home.remove_child(chest)
	_refused("sem baú vivo", "home_unavailable")
	home.add_child(chest)
	_reset()

func _payment() -> void:
	for path in range(3):
		if path == 0: _reset()
		elif path == 1: _reset(HerbariumProduction.PROJECT_REQUIREMENTS, {})
		else: _reset({"trigo": 5, "tomate_sol": 3, "mistura_restauradora": 2, "agua": 7}, HerbariumProduction.PROJECT_REQUIREMENTS)
		var before := _resources()
		var generation := HerbariumProduction.get_generation()
		ToolManager.force_select_tool(ToolManager.ToolType.HOE)
		GlobalInventory.semente_selecionada = "semente_verao"
		_check(HerbariumProduction.try_activate(site), "pagamento combinado/pessoal/baú")
		_check(HerbariumProduction.get_save_data() == {"activated": true, "renewal_remaining": 0.0} and HerbariumProduction.get_generation() > generation and notifications == 1, "ativação disponibiliza ponto uma vez")
		for id in HerbariumProduction.PROJECT_REQUIREMENTS:
			var expected: int = int(before.personal.get(id, 0)) - maxi(0, int(HerbariumProduction.PROJECT_REQUIREMENTS[id]) - int(before.chest.get(id, 0)))
			_check(GlobalInventory.get_item_quantity(id) == expected, "baú prioritário: " + id)
			var total: int = int(before.personal.get(id, 0)) + int(before.chest.get(id, 0)) - int(HerbariumProduction.PROJECT_REQUIREMENTS[id])
			_check(GlobalInventory.get_item_quantity(id) + chest.get_item_quantity(id) == total, "custo exato: " + id)
		_check(GlobalInventory.get_item_quantity("raiz_gelida") == 0 and GlobalInventory.pontos_alquimia == before.xp and GlobalInventory.get_slot_capacity() == before.slots and GlobalInventory.receitas_descobertas == before.recipes, "sem entrega direta/XP/slots/receitas")
		var resources := _resources()
		_check(not HerbariumProduction.try_activate(site) and _resources() == resources and notifications == 1, "ativação não repetida")
	_reset()

func _faults() -> void:
	var original := chest
	home.remove_child(original)
	var probe := ProbeChest.new()
	probe.name = "VillageChest"
	var probe_area := Area2D.new()
	probe_area.name = "ClickableArea"
	probe.add_child(probe_area)
	home.add_child(probe)
	chest = probe
	_reset({}, HerbariumProduction.PROJECT_REQUIREMENTS)
	probe.fail_item = "mistura_restauradora"
	probe.probe = _during_withdrawal
	var resources := _resources()
	var saved := HerbariumProduction.get_save_data()
	_check(not HerbariumProduction.try_activate(site), "falha na última retirada")
	_check(_resources() == resources and HerbariumProduction.get_save_data() == saved and notifications == 0, "rollback integral nas origens")
	_check(not nested_calls.is_empty() and not true in nested_calls, "reentrada/load/reset recusados na retirada")
	probe.fail_item = ""
	probe.probe = func(): GroveExpedition.restored = false
	_check(not HerbariumProduction.try_activate(site) and _resources() == resources and not HerbariumProduction.activated, "gate perdido causa rollback")
	GroveExpedition.restored = true
	probe.probe = Callable()
	probe_signal = true
	nested_calls.clear()
	_check(HerbariumProduction.try_activate(site), "ativação consistente antes do sinal")
	probe_signal = false
	_check(observed.get("activated") == true and float(observed.get("renewal_remaining", -1)) == 0.0 and not true in nested_calls, "observador vê estado coerente sem reentrar")
	home.remove_child(probe)
	probe.queue_free()
	chest = original
	home.add_child(chest)
	_reset()

func _during_withdrawal() -> void:
	nested_calls.append(HerbariumProduction.try_activate(site))
	nested_calls.append(HerbariumProduction.try_collect(site))
	nested_calls.append(HerbariumProduction.load_save_data({"activated": true, "renewal_remaining": 0.0}))
	HerbariumProduction.reset_progress()
	nested_calls.append(HerbariumProduction.activated)

func _on_progress() -> void:
	notifications += 1
	if probe_signal:
		observed = HerbariumProduction.get_save_data()
		nested_calls.append(HerbariumProduction.try_activate(site))
		nested_calls.append(HerbariumProduction.try_collect(site))
		nested_calls.append(HerbariumProduction.load_save_data(STATE.default_data()))

func _collection() -> void:
	_check(HerbariumProduction.try_activate(site), "ativa para ciclo")
	obstacle.set("purified_state", false)
	_refused("fonte ativa com obstáculo real não purificado", "locked")
	obstacle.set("purified_state", true)
	var full := {"agua": 7}
	for index in range(12): full["capacity_probe_%d" % index] = 99
	GlobalInventory.set_inventory_contents(full)
	var resources := _resources()
	var generation := HerbariumProduction.get_generation()
	_check(not HerbariumProduction.try_collect(site) and HerbariumProduction.renewal_remaining == 0.0 and _resources() == resources and HerbariumProduction.get_generation() == generation, "capacidade cheia conserva disponibilidade")
	GlobalInventory.set_inventory_contents({"agua": 7})
	_check(HerbariumProduction.try_collect(site) and GlobalInventory.get_item_quantity("raiz_gelida") == 1 and HerbariumProduction.renewal_remaining == 90.0, "uma Raiz pessoal inicia noventa segundos")
	_check(chest.get_item_quantity("raiz_gelida") == 0 and HerbariumProduction.get_status(site).code == "renewing", "não deposita no baú")
	resources = _resources()
	_check(not HerbariumProduction.try_collect(site) and _resources() == resources, "duplo commit não duplica")
	for delta in [-1.0, 0.0, INF, NAN]:
		HerbariumProduction.advance_session_time(delta)
		_check(HerbariumProduction.renewal_remaining == 90.0, "delta inválido/nulo não avança")
	HerbariumProduction.advance_session_time(89.0)
	_check(HerbariumProduction.renewal_remaining == 1.0 and not HerbariumProduction.try_collect(site), "antes do prazo recusa")
	HerbariumProduction.advance_session_time(1.0)
	_check(HerbariumProduction.get_status(site).code == "available", "prazo exato libera")
	HerbariumProduction.advance_session_time(900.0)
	_check(HerbariumProduction.renewal_remaining == 0.0 and GlobalInventory.get_item_quantity("raiz_gelida") == 1, "não acumula ciclos/itens")
	_check(HerbariumProduction.try_collect(site) and GlobalInventory.get_item_quantity("raiz_gelida") == 2 and not HerbariumProduction.try_collect(site), "próxima coleta também unitária")

func _clock() -> void:
	GroveExpedition.record_collection(GroveExpedition.ROOT_SOURCE)
	var grove := GROVE.instantiate()
	get_tree().root.add_child(grove)
	grove.process_mode = Node.PROCESS_MODE_DISABLED
	home.call("on_region_became_inactive")
	home.get_parent().remove_child(home)
	get_tree().current_scene = grove
	var resources := _resources()
	_check(HerbariumProduction.get_status(site).code == "home_unavailable" and not HerbariumProduction.try_collect(site) and _resources() == resources, "vila fora da árvore não entrega remotamente")
	HerbariumProduction.advance_session_time(45.0)
	GroveExpedition.call("_process", 45.0)
	_check(HerbariumProduction.renewal_remaining == 45.0 and float(GroveExpedition.get_forage_state(GroveExpedition.ROOT_SOURCE).renewal_remaining) == 0.0, "relógios90/45 independentes no Bosque")
	HerbariumProduction.advance_session_time(45.0)
	_check(HerbariumProduction.renewal_remaining == 0.0 and GlobalInventory.get_item_quantity("raiz_gelida") == 2, "renew externo libera sem entregar")
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	home.call("on_region_became_active")
	_check(HerbariumProduction.try_collect(site), "retorno permite coleta próxima")
	home.call("advance_inactive_time", 89.0)
	_check(HerbariumProduction.renewal_remaining == 90.0, "catch-up agrícola não avança fonte novamente")
	get_tree().current_scene = self
	HerbariumProduction.advance_session_time(45.0)
	_check(HerbariumProduction.renewal_remaining == 90.0, "cena dev não avança relógio")
	get_tree().current_scene = home
	grove.queue_free()
	await get_tree().process_frame

func _snapshots() -> void:
	HerbariumProduction.advance_session_time(12.25)
	var saved := HerbariumProduction.get_save_data()
	var resources := _resources()
	var generation := HerbariumProduction.get_generation()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(saved))
	_check(HerbariumProduction.load_save_data(parsed) and HerbariumProduction.get_save_data() == saved and HerbariumProduction.get_generation() > generation and _resources() == resources, "JSON preserva intervalo/itens e invalida intenção")
	generation = HerbariumProduction.get_generation()
	_check(HerbariumProduction.load_save_data(parsed) and HerbariumProduction.get_generation() > generation and _resources() == resources, "replay sem cobrança/entrega/reset do intervalo")
	for bad in [{"activated": false, "renewal_remaining": 1.0}, {"activated": true, "renewal_remaining": 91.0}, {"activated": 1, "renewal_remaining": 0.0}, {"activated": true, "renewal_remaining": NAN}, {"activated": true, "renewal_remaining": 0.0, "extra": true}]:
		generation = HerbariumProduction.get_generation()
		_check(not HerbariumProduction.load_save_data(bad) and HerbariumProduction.get_save_data() == saved and HerbariumProduction.get_generation() == generation and _resources() == resources, "load inválido não muta")
	var count := notifications
	SaveManager.set("_applying_snapshot", true)
	_check(HerbariumProduction.load_save_data(parsed) and notifications == count, "load global sem sinal intermediário")
	HerbariumProduction.reset_progress()
	_check(not HerbariumProduction.activated and notifications == count, "reset global sem sinal intermediário")
	SaveManager.set("_applying_snapshot", false)
	_check(_resources() == resources, "load/reset não repete prêmio/refund/XP/slots")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("HerbariumProductionSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed: print("HerbariumProductionSmokeTest: PASS - %d verificações de domínio/transação/coleta/relógio." % checks)
	get_tree().quit(1 if failed else 0)
