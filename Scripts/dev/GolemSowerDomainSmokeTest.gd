extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const CHEST_SCENE := preload("res://Scenes/VillageChest.tscn")
const PLOT_SCENE := preload("res://Scenes/FarmPlot.tscn")
const SEED := "semente_basica"
const CELL := Vector2i(0, 0)

var _main: Node = null
var _plot: Node2D = null
var _other_plot: Node2D = null
var _chest: VillageChest = null
var _cargo := GolemSeedCargo.new()
var _checks := 0
var _failed := false
var _signals := 0
var _observe_source := ""
var _original_inventory: Dictionary = {}
var _original_selection := ""
var _original_season := 0
var _original_tool := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_original_selection = GlobalInventory.semente_selecionada
	_original_season = SeasonManager.estacao_atual
	_original_tool = ToolManager.get_active_tool()
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	for golem in _main.find_children("*", "CharacterBody2D", true, false):
		if golem.has_method("set_work_priority"):
			golem.call("set_work_priority", 4)
	_plot = _main.call("obter_farm_plot_por_grid_position", CELL)
	_other_plot = _main.call("obter_farm_plot_por_grid_position", Vector2i(1, 0))
	_chest = get_tree().get_first_node_in_group("village_chest") as VillageChest
	if _plot == null or _other_plot == null or _chest == null:
		_check(false, "fixture sem lote/baú")
		return _finish()
	_plot.connect("estado_alterado", _on_plot_changed)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	ToolManager.clear_tool()
	_main.get_node("UI").set("item_focado_id", "")
	GlobalInventory.set_inventory_contents({SEED: 10, "semente_inverno": 2, "agua": 5})
	GlobalInventory.semente_selecionada = SEED
	_chest.set_contents({SEED: 3, "trigo": 4})

	_test_manual_refusals()
	_test_manual_commit()
	_test_custody_and_planting()
	_test_serialization()
	_test_returns()
	var detached_plot := PLOT_SCENE.instantiate() as Node2D
	add_child(detached_plot)
	remove_child(detached_plot)
	_expect_refused(detached_plot, SEED, "unavailable")
	detached_plot.free()
	_plot.queue_free()
	_expect_refused(_plot, SEED, "unavailable")
	_finish()


func _test_manual_refusals() -> void:
	_reset_plot(_plot, false)
	_expect_refused(_plot, SEED, "untilled")
	_check((_plot.get("semente_atual") as Dictionary).is_empty(), "recusa não instala metadados de semente")
	_reset_plot(_plot)
	_expect_refused(_plot, "", "no_seed")
	_expect_refused(_plot, "trigo", "invalid_seed")
	_expect_refused(_plot, "semente_desconhecida", "invalid_seed")
	_expect_refused(_plot, "semente_inverno", "wrong_season")
	_plot.call("set_expansion_blocked", true)
	_expect_refused(_plot, SEED, "blocked")
	_plot.call("set_expansion_blocked", false)
	_plot.hide()
	_expect_refused(_plot, SEED, "hidden")
	_plot.show()
	_main.hide()
	_expect_refused(_plot, SEED, "hidden")
	_main.show()
	GlobalInventory.set_inventory_contents({SEED: 0})
	_expect_refused(_plot, SEED, "no_stock")
	GlobalInventory.set_inventory_contents({SEED: 10})
	var before := _plot_snapshot(_plot)
	var inventory_before := GlobalInventory.inventario.duplicate(true)
	var signal_before := _signals
	var evaluation: Dictionary = _plot.call("validate_seed_planting", SEED)
	_check(bool(evaluation["success"]), "consulta aceita alvo preparado")
	_check(before == _plot_snapshot(_plot) and inventory_before == GlobalInventory.inventario and signal_before == _signals, "consulta pura não muda lote/estoque/sinais")


func _test_manual_commit() -> void:
	var seeds := [SEED, "semente_verao", "semente_outono", "semente_inverno"]
	var seasons := [SeasonManager.Estacao.PRIMAVERA, SeasonManager.Estacao.VERAO, SeasonManager.Estacao.OUTONO, SeasonManager.Estacao.INVERNO]
	var durations := [3.0, 5.0, 6.0, 4.0]
	for index in range(seeds.size()):
		for watered in [false, true]:
			_reset_plot(_plot, true, watered)
			SeasonManager.estacao_atual = seasons[index]
			GlobalInventory.set_inventory_contents({seeds[index]: 2})
			GlobalInventory.semente_selecionada = seeds[index]
			_observe_source = "personal"
			var before_signals := _signals
			var chest_before := _chest.get_contents()
			var result: Dictionary = _plot.call("try_plant_from_personal_inventory", seeds[index])
			_observe_source = ""
			_check(bool(result["success"]), "plantio manual da estação %d, regado=%s" % [index, watered])
			_check(GlobalInventory.get_item_quantity(seeds[index]) == 1 and _chest.get_contents() == chest_before, "manual consome uma unidade só da Mochila")
			_check(_signals == before_signals + 1, "commit publica uma única alteração")
			var expected: float = durations[index] * (0.8 if watered else 1.0) * (0.8 if index == 1 else 1.0)
			_check(is_equal_approx(float(_plot.get("tempo_total_crescimento")), expected), "crescimento conserva modificadores de rega/verão")
			_check(_plot.get("semente_id_plantada") == seeds[index] and _plot.get("estado_atual") == 1, "cultura correta em crescimento")
			_check(GlobalInventory.semente_selecionada == seeds[index], "seleção manual preservada com saldo")
			_expect_refused(_plot, seeds[index], "occupied")
			_plot.call("debug_force_ready_to_harvest")
			_expect_refused(_plot, seeds[index], "occupied")
	_reset_plot(_plot)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GlobalInventory.set_inventory_contents({SEED: 1})
	GlobalInventory.semente_selecionada = SEED
	_plot.call("_on_plot_clicked")
	_check(GlobalInventory.get_item_quantity(SEED) == 0 and GlobalInventory.semente_selecionada == "", "clique manual usa commit comum e limpa última semente selecionada")
	_check(_plot.get("estado_atual") == 1, "clique inicia crescimento")
	(_plot.get("semente_atual") as Dictionary)["tempo_crescimento_segundos"] = 99.0
	_check(Database.semente_basica["tempo_crescimento_segundos"] == 3.0, "cultura não compartilha dicionário mutável do catálogo")
	_reset_plot(_plot, false)
	GlobalInventory.set_inventory_contents({SEED: 1})
	GlobalInventory.semente_selecionada = SEED
	var before := _plot_snapshot(_plot)
	_plot.call("_on_plot_clicked")
	_check(before == _plot_snapshot(_plot) and GlobalInventory.get_item_quantity(SEED) == 1, "clique recusado também preserva metadados")


func _test_custody_and_planting() -> void:
	_reset_plot(_plot)
	_reset_plot(_other_plot)
	GlobalInventory.set_inventory_contents({SEED: 10, "semente_inverno": 2, "agua": 5})
	GlobalInventory.semente_selecionada = "semente_inverno"
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	GlobalInventory.semente_selecionada = "semente_inverno"
	_chest.set_contents({"trigo": 4})
	_check(not _cargo.has_seed() and _cargo.get_save_data() == null, "carga inicial ausente")
	var personal_before := GlobalInventory.inventario.duplicate(true)
	_check(not _cargo.take_from_chest(_chest, CELL), "baú vazio não complementa na Mochila")
	_check(GlobalInventory.inventario == personal_before and not _cargo.has_seed(), "recusa de retirada conserva Mochila/carga")
	_chest.set_contents({SEED: 3, "trigo": 4})
	_check(not _cargo.take_from_chest(_chest, Vector2i(2, 0)) and _chest.get_item_quantity(SEED) == 3, "alvo fora do piloto não retira")
	_check(not _cargo.take_from_chest(null, CELL), "baú ausente não retira")
	_check(_cargo.take_from_chest(_chest, CELL), "retirada exclusiva instala uma carga")
	_check(_cargo.has_seed() and _chest.get_item_quantity(SEED) == 2, "custódia baú menos um, carga mais um")
	_check(not _cargo.take_from_chest(_chest, CELL) and _chest.get_item_quantity(SEED) == 2, "carga existente impede segunda retirada")
	_expect_refused(_other_plot, SEED, "target_mismatch", _cargo)
	_expect_refused(_plot, "", "no_cargo", GolemSeedCargo.new())
	_plot.call("set_expansion_blocked", true)
	_expect_refused(_plot, SEED, "blocked", _cargo)
	_plot.call("set_expansion_blocked", false)
	_plot.hide()
	_expect_refused(_plot, SEED, "hidden", _cargo)
	_plot.show()
	SeasonManager.estacao_atual = SeasonManager.Estacao.OUTONO
	_expect_refused(_plot, SEED, "wrong_season", _cargo)
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	_reset_plot(_plot, false)
	_expect_refused(_plot, SEED, "untilled", _cargo)
	_reset_plot(_plot)
	_check(not _cargo.consume_for_plant("semente_inverno", CELL), "ID incorreto não consome carga")
	_check(not _cargo.consume_for_plant(SEED, Vector2i(1, 1)), "célula incorreta não consome carga")
	_check(_cargo.has_seed(), "recusas diretas conservam carga")
	_check(bool((_plot.call("try_plant_from_personal_inventory", SEED) as Dictionary)["success"]), "jogador pode plantar no alvo sem reserva")
	_expect_refused(_plot, SEED, "occupied", _cargo)
	_reset_plot(_plot)
	var chest_before := _chest.get_contents()
	personal_before = GlobalInventory.inventario.duplicate(true)
	var selection_before := GlobalInventory.semente_selecionada
	var tool_before := ToolManager.get_active_tool()
	_observe_source = "cargo"
	var signal_before := _signals
	var result: Dictionary = _plot.call("try_plant_from_golem_cargo", _cargo)
	_observe_source = ""
	_check(bool(result["success"]) and not _cargo.has_seed(), "commit transforma carga em trigo uma vez")
	_check(_chest.get_contents() == chest_before and GlobalInventory.inventario == personal_before, "plantio transportado não retira novamente nem usa Mochila")
	_check(selection_before == GlobalInventory.semente_selecionada and tool_before == ToolManager.get_active_tool(), "fonte de golem não altera seleção/ferramenta")
	_check(_signals == signal_before + 1, "commit de carga publica uma única alteração")
	_expect_refused(_plot, SEED, "no_cargo", _cargo)
	_chest.set_contents({SEED: 5, "trigo": 4})
	for cell in GolemSeedCargo.PILOT_CELLS:
		var target: Node2D = _main.call("obter_farm_plot_por_grid_position", cell)
		_reset_plot(target)
		_check(_cargo.take_from_chest(_chest, cell), "retira para célula piloto %s" % cell)
		var planted: Dictionary = target.call("try_plant_from_golem_cargo", _cargo)
		_check(bool(planted["success"]) and not _cargo.has_seed(), "registro resolve e planta na célula piloto %s" % cell)
	_check(_chest.get_item_quantity(SEED) == 1, "quatro cultivos consomem quatro sementes, sem retirada extra")
	_reset_plot(_plot)
	_check(_cargo.take_from_chest(_chest, CELL), "próxima carga pode ser retirada após plantio")
	_check(_cargo.mark_return_pending(), "carga entra em devolução pendente")
	_expect_refused(_plot, SEED, "return_pending", _cargo)


func _test_serialization() -> void:
	var original: Dictionary = _cargo.get_save_data()
	var exported: Dictionary = _cargo.get_save_data()
	exported["target_cell"]["x"] = 99
	exported["quantity"] = 99
	_check(_cargo.get_save_data() == original, "snapshot exportado é cópia profunda")
	var round_trip: Variant = JSON.parse_string(JSON.stringify(original))
	_check(GolemSeedCargo.is_save_data_valid(round_trip), "payload JSON conserva números integrais")
	var restored := GolemSeedCargo.new()
	_check(restored.apply_save_data(round_trip) and restored.is_return_pending(), "restaura intenção de devolução")
	round_trip["target_cell"]["x"] = 99
	_check(restored.get_target_cell() == CELL, "aplicação também copia dados recebidos")
	var chest_before := _chest.get_contents()
	_check(restored.apply_save_data(original) and restored.apply_save_data(original), "reaplicar snapshot válido é substitutivo")
	_check(_chest.get_contents() == chest_before, "load de domínio não faz retirada/refund")
	for cell in GolemSeedCargo.PILOT_CELLS:
		var data := original.duplicate(true)
		data["target_cell"] = {"x": cell.x, "y": cell.y}
		data["intent"] = GolemSeedCargo.INTENT_TRANSPORT
		_check(restored.apply_save_data(data) and restored.get_target_cell() == cell and not restored.is_return_pending(), "serializa célula piloto %s" % cell)
	var invalid_values: Array = [false, 1, "cargo", [], {}, {"quantity": 1}]
	for key in ["item_id", "quantity", "target_cell", "intent"]:
		var missing := original.duplicate(true)
		missing.erase(key)
		invalid_values.append(missing)
	for item_id in ["trigo", "semente_inverno", "", 1, true]:
		var data := original.duplicate(true)
		data["item_id"] = item_id
		invalid_values.append(data)
	for quantity in [0, -1, 2, 1.5, "1", true, null, INF, NAN]:
		var data := original.duplicate(true)
		data["quantity"] = quantity
		invalid_values.append(data)
	for target in [null, [], Vector2i.ZERO, {"x": 0}, {"x": 0, "y": 0, "z": 0}, {"x": -1, "y": 0}, {"x": 2, "y": 0}, {"x": 0.5, "y": 0}, {"x": "0", "y": 0}, {"x": false, "y": 0}, {"x": INF, "y": 0}]:
		var data := original.duplicate(true)
		data["target_cell"] = target
		invalid_values.append(data)
	for intent in ["", "planting", true, 1, null]:
		var data := original.duplicate(true)
		data["intent"] = intent
		invalid_values.append(data)
	var extra := original.duplicate(true)
	extra["extra"] = 1
	invalid_values.append(extra)
	for index in range(invalid_values.size()):
		var before: Variant = restored.get_save_data()
		_check(not GolemSeedCargo.is_save_data_valid(invalid_values[index]), "preflight recusa payload inválido %d" % index)
		_check(not restored.apply_save_data(invalid_values[index]) and restored.get_save_data() == before, "aplicação inválida %d não muda carga" % index)
	_check(restored.apply_save_data(null) and not restored.has_seed() and restored.get_save_data() == null, "ausência substitui carga sem inventar/refund")
	_check(not restored.consume_for_plant(SEED, CELL) and not restored.mark_return_pending(), "carga ausente não produz semente")
	_check(_chest.get_contents() == chest_before, "toda serialização preserva estoque")


func _test_returns() -> void:
	var cargo_before: Variant = _cargo.get_save_data()
	var chest_before := _chest.get_contents()
	_check(not _cargo.return_to_chest(null) and _cargo.get_save_data() == cargo_before, "baú ausente conserva devolução pendente")
	var disappearing_chest := CHEST_SCENE.instantiate() as VillageChest
	add_child(disappearing_chest)
	disappearing_chest.queue_free()
	_check(not _cargo.return_to_chest(disappearing_chest) and _cargo.get_save_data() == cargo_before, "baú aguardando exclusão não perde carga")
	_check(_cargo.return_to_chest(_chest) and not _cargo.has_seed(), "devolução aceita libera custódia")
	_check(_chest.get_item_quantity(SEED) == int(chest_before.get(SEED, 0)) + 1, "devolve exatamente uma unidade")
	var after := _chest.get_contents()
	_check(not _cargo.return_to_chest(_chest) and _chest.get_contents() == after, "devolução repetida não duplica")
	_check(_cargo.take_from_chest(_chest, CELL), "nova carga após devolução")
	_check(not _cargo.return_to_chest(_chest) and _cargo.has_seed(), "transporte não devolve sem intenção explícita")
	_cargo.mark_return_pending()
	_cargo.return_to_chest(_chest)
	_check(_chest.get_contents() == after, "ciclo retirada/devolução conserva estoque")


func _expect_refused(plot: Node2D, seed_id: String, reason: String, cargo: GolemSeedCargo = null) -> void:
	var before := _plot_snapshot(plot)
	var personal_before := GlobalInventory.inventario.duplicate(true)
	var selection_before := GlobalInventory.semente_selecionada
	var tool_before := ToolManager.get_active_tool()
	var chest_before := _chest.get_contents()
	var cargo_before: Variant = cargo.get_save_data() if cargo != null else null
	var signal_before := _signals
	var result: Dictionary = plot.call("try_plant_from_golem_cargo", cargo) if cargo != null else plot.call("try_plant_from_personal_inventory", seed_id)
	_check(not bool(result["success"]) and result["reason"] == reason, "recusa estruturada: %s" % reason)
	_check(before == _plot_snapshot(plot), "recusa %s conserva cultura/metadados/timer/solo" % reason)
	_check(personal_before == GlobalInventory.inventario and chest_before == _chest.get_contents(), "recusa %s conserva estoques" % reason)
	_check(selection_before == GlobalInventory.semente_selecionada and tool_before == ToolManager.get_active_tool() and signal_before == _signals, "recusa %s não muda seleção/ferramenta/sinais" % reason)
	if cargo != null:
		_check(cargo_before == cargo.get_save_data(), "recusa %s conserva carga" % reason)


func _reset_plot(plot: Node2D, tilled: bool = true, watered: bool = false) -> void:
	plot.show()
	plot.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": tilled, "regado": watered, "expansion_blocked": false, "pronto_para_colher": false, "tempo_restante": 0.0, "tempo_total_crescimento": 0.0})


func _plot_snapshot(plot: Node2D) -> Dictionary:
	var timer: Timer = plot.get("timer")
	return {"save": plot.call("get_save_data"), "seed_data": (plot.get("semente_atual") as Dictionary).duplicate(true), "timer_stopped": timer.is_stopped(), "timer_wait": timer.wait_time}


func _on_plot_changed() -> void:
	_signals += 1
	if _observe_source == "":
		return
	_check(_plot.get("estado_atual") == 1 and not (_plot.get("timer") as Timer).is_stopped(), "observador vê cultura e timer completos")
	if _observe_source == "personal":
		_check(GlobalInventory.get_item_quantity(str(_plot.get("semente_id_plantada"))) == 1, "observador vê consumo pessoal concluído")
	else:
		_check(not _cargo.has_seed(), "observador vê carga já consumida")
	var snapshot: FarmGridManager = _main.call("obter_farm_grid_snapshot")
	_check(snapshot.get_tile(CELL).crop_id == _plot.get("semente_id_plantada"), "bridge agrícola atualizado no sinal")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("GolemSowerDomainSmokeTest: FAIL - %s" % message)


func _finish() -> void:
	GlobalInventory.set_inventory_contents(_original_inventory)
	ToolManager.active_tool = _original_tool as ToolManager.ToolType
	GlobalInventory.semente_selecionada = _original_selection
	SeasonManager.estacao_atual = _original_season as SeasonManager.Estacao
	if is_instance_valid(_main):
		_main.queue_free()
	if not _failed:
		print("GolemSowerDomainSmokeTest: PASS - %d verificações de commit comum, custódia exclusiva e serialização sem automação viva." % _checks)
	get_tree().quit(1 if _failed else 0)
