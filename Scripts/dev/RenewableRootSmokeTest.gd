extends Node

# Fixtures e arquivos exclusivamente QA. O relógio do domínio é avançado
# explicitamente; nenhum timer de receita/cultivo ou balanceamento é alterado.
const MAIN := preload("res://Scenes/Main.tscn")
const Resolver := preload("res://Scripts/data/RecipeResolver.gd")
const ROOT := "raiz_gelida"
var home: Node
var grove: Node
var source: ForageNode
var charcoal: ForageNode
var chest: VillageChest
var checks := 0
var failed := false
var _recipe_units_completed := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("RenewableRootSmokeTest: exige APPDATA sob Builds/QA antes de instanciar Main.")
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	chest = home.get_node("VillageChest")
	home.get_node("Golem").call("set_work_priority", 4)
	(home.get_node("Golem").get("_think_timer") as Timer).stop()
	for plot in home.get("farm_plot_registry").values():
		plot.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(4)
	if "--verify-renewable-root-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish("reabertura")
	if "--write-renewable-root-fixture" in OS.get_cmdline_user_args():
		_write_fixture()
		return _finish("fixture")
	_reset()
	if not await _travel(&"foraging_grove", &"from_farm"): return _finish("viagem")
	grove = get_tree().current_scene
	source = _find_source(GroveExpedition.ROOT_SOURCE)
	charcoal = _find_source(GroveExpedition.RENEWABLE_SOURCE)
	_check(source != null and charcoal != null, "duas fontes físicas com IDs estáveis")
	if source == null or charcoal == null: return _finish("fontes ausentes")
	_test_first_visit_and_capacity()
	_test_intervals()
	await _test_callbacks_and_context()
	await _test_physical_collection()
	await _test_cache()
	_test_snapshots()
	await _test_recipes()
	_check(_recipe_units_completed == 2, "ambos os fluxos de receita executaram até o fim")
	_test_writer()
	_write_fixture()
	_finish("coleta, renovação, contexto, receitas, cache e snapshots")

func _reset() -> void:
	GroveExpedition.reset_progress()
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({})
	GlobalInventory.receitas_descobertas = []
	GlobalInventory.pontos_alquimia = 0
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.semente_selecionada = ""
	ToolManager.clear_tool()
	chest.set_contents({ROOT: 7, "carvao": 9})

func _find_source(id: String) -> ForageNode:
	for node in grove.get_node("ForageNodes").get_children():
		if node is ForageNode and node.expedition_source_id == id: return node
	return null

func _domain() -> Dictionary:
	return {"grove": GroveExpedition.get_save_data(), "inventory": GlobalInventory.inventario.duplicate(true),
		"chest": chest.get_contents(), "recipes": GlobalInventory.receitas_descobertas.duplicate(),
		"xp": GlobalInventory.pontos_alquimia, "slots": GlobalInventory.get_backpack_milestones(),
		"tool": ToolManager.get_active_tool(), "seed": GlobalInventory.semente_selecionada}

func _remaining(id: String) -> float:
	return float(GroveExpedition.get_forage_state(id)["renewal_remaining"])

func _test_first_visit_and_capacity() -> void:
	_check(not GroveExpedition.discovered and not GroveExpedition.restored and not source.is_collected(), "raiz disponível antes de descobrir/restaurar clareira")
	_check(source.resource_id == ROOT and source.quantity == 1 and source.backpack_milestone_id.is_empty(), "contrato físico uma raiz sem prêmio de slots")
	var full := {}
	for index in range(GlobalInventory.get_slot_capacity()): full["capacity_probe_%d" % index] = 99
	GlobalInventory.set_inventory_contents(full)
	var before := _domain()
	_check(not source.collect() and _domain() == before and not source.is_collected(), "recusa de capacidade não gasta fonte/inicia intervalo/credita parcialmente")
	full.erase("capacity_probe_0")
	full[ROOT] = GlobalInventory.get_stack_limit(ROOT) - 1
	GlobalInventory.set_inventory_contents(full)
	_check(source.collect() and GlobalInventory.get_item_quantity(ROOT) == GlobalInventory.get_stack_limit(ROOT), "coleta usa espaço na pilha existente sem slot livre")
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 45.0 and source.is_collected(), "primeiro commit inicia exatamente 45s")
	before = _domain()
	_check(not source.collect() and _domain() == before, "duplo clique não duplica estoque nem reinicia intervalo")
	_check(GlobalInventory.get_backpack_milestones().is_empty() and GlobalInventory.pontos_alquimia == 0 and GlobalInventory.receitas_descobertas.is_empty() and not GroveExpedition.discovered, "coleta não aprende receita/XP/slots/marco novo")
	_check(chest.get_item_quantity(ROOT) == 7, "coleta somente pessoal, sem tocar estoque do baú")
	source.call("_process", 0.0)
	_check(source.prompt_label.text.contains(Database.obter_nome_item(ROOT)) and source.prompt_label.text.contains("45s"), "pista renovável usa item/intervalo da raiz")
	_reset()

func _test_intervals() -> void:
	_check(source.collect(), "raiz inicial para relógio")
	GroveExpedition._process(20.0)
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 25.0 and not charcoal.is_collected(), "fonte não coletada não recebe intervalo de outra")
	_check(charcoal.collect() and GlobalInventory.get_item_quantity("carvao") == 2, "carvão mantém duas unidades")
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 25.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 45.0, "intervalos separados por ID")
	GroveExpedition._process(24.0)
	_check(source.is_collected() and _remaining(GroveExpedition.ROOT_SOURCE) == 1.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 21.0, "antes do limiar raiz permanece esgotada")
	GroveExpedition._process(1.0)
	_check(not source.is_collected() and charcoal.is_collected() and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 20.0, "limiar exato renova somente raiz")
	_check(source.collect() and GlobalInventory.get_item_quantity(ROOT) == 2, "novo ciclo entrega exatamente mais uma")
	GroveExpedition._process(100.0)
	_check(not source.is_collected() and not charcoal.is_collected() and GlobalInventory.get_item_quantity(ROOT) == 2 and GlobalInventory.get_item_quantity("carvao") == 2, "tempo longo apenas disponibiliza, não gera estoque/ciclos acumulados")
	var original := _find_source("charcoal_entry")
	_check(original.collect() and not original.collect(), "fonte original mantém coleta única")
	GroveExpedition._process(100.0)
	_check(original.is_collected() and _remaining("charcoal_entry") == 0.0, "fonte original não passa a renovar")
	_reset()

func _test_callbacks_and_context() -> void:
	var stale := source.create_collection_callback()
	GroveExpedition.load_save_data(GroveExpedition.get_save_data())
	var before := _domain()
	_check(not stale.call() and _domain() == before, "load de mesmo snapshot invalida callback antigo")
	stale = source.create_collection_callback()
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	_check(not stale.call() and not source.is_collected(), "troca de ferramenta invalida callback")
	ToolManager.clear_tool()
	stale = source.create_collection_callback()
	GlobalInventory.semente_selecionada = "semente_basica"
	_check(not stale.call() and not source.is_collected(), "troca de semente invalida callback")
	GlobalInventory.semente_selecionada = ""
	stale = source.create_collection_callback()
	_check(source.collect(), "coleta válida para callback de ciclo anterior")
	GroveExpedition._process(45.0)
	before = _domain()
	_check(not stale.call() and _domain() == before and not source.is_collected(), "callback anterior não coleta fonte renovada")
	RegionTravelCoordinator.set("_transition_in_progress", true)
	before = _domain()
	_check(not source.collect() and _domain() == before, "fade de viagem bloqueia coleta antes de sair da árvore")
	RegionTravelCoordinator.set("_transition_in_progress", false)
	SaveManager.set("_applying_snapshot", true)
	_check(not source.collect() and _domain() == before, "snapshot em aplicação bloqueia coleta")
	SaveManager.set("_applying_snapshot", false)
	var source_id := source.expedition_source_id
	source.expedition_source_id = "unknown_probe"
	_check(not source.collect() and _domain() == before, "ID persistente desconhecido não insere item sem registrar origem")
	source.expedition_source_id = source_id
	var detached := ForageNode.new()
	detached.resource_id = ROOT
	_check(not detached.collect() and _domain() == before, "nó fora da árvore não coleta")
	detached.free()
	# Observador síncrono substitui o snapshot depois do commit. Não pode emitir
	# prêmio/feedback/resource_collected antigo em cima do novo estado.
	var replacement := GroveExpedition.get_save_data()
	var observations := {"collected": 0, "loaded": false}
	var resource_signal := func(_id: String, _qty: int): observations.collected += 1
	var load_on_signal := func(id: String):
		if id == GroveExpedition.ROOT_SOURCE and not observations.loaded:
			observations.loaded = true
			GroveExpedition.load_save_data(replacement)
	source.resource_collected.connect(resource_signal)
	GroveExpedition.forage_state_changed.connect(load_on_signal)
	_check(source.collect() and observations.loaded and observations.collected == 0 and not source.is_collected(), "load reentrante encerra efeitos pós-commit antigos")
	GroveExpedition.forage_state_changed.disconnect(load_on_signal)
	source.resource_collected.disconnect(resource_signal)
	_reset()

func _test_physical_collection() -> void:
	var player: PlayerAvatar = grove.get_node("PlayerAvatar")
	player.stop_moving()
	player.global_position = source.global_position + Vector2(-150, 0)
	_check(grove.call("request_player_interaction", source, source.global_position, source.interaction_distance, source.create_collection_callback()) and not (grove.get("_pending_player_interaction") as Dictionary).is_empty(), "pedido real pendente antes de alcançar raiz")
	# Exercita a API de movimento usada pelo clique no chão, sem alegar picking
	# de mouse/hover: ela deve cancelar a pendência, não coletar ao chegar.
	_check(grove.call("try_move_player_to", source.global_position + Vector2(-180, 0)) and (grove.get("_pending_player_interaction") as Dictionary).is_empty(), "movimento para chão substitui interação pendente")
	await _frames(90)
	_check(not source.is_collected() and GlobalInventory.get_item_quantity(ROOT) == 0 and _remaining(GroveExpedition.ROOT_SOURCE) == 0.0, "chegada ao chão após cancelamento não coleta/inicia renovação")
	player.stop_moving()
	player.global_position = source.global_position + Vector2(-150, 0)
	var old := source.create_collection_callback()
	_check(grove.call("request_player_interaction", source, source.global_position, source.interaction_distance, old), "primeiro pedido real no mesmo ciclo")
	var replacement := source.create_collection_callback()
	var before := _domain()
	_check(grove.call("request_player_interaction", source, source.global_position, source.interaction_distance, replacement) and not old.call() and _domain() == before, "segundo pedido na mesma fonte substitui callback anterior sem gasto")
	for _frame in range(300):
		await get_tree().physics_frame
		if source.is_collected(): break
	_check(source.is_collected() and GlobalInventory.get_item_quantity(ROOT) == 1 and player.global_position.distance_to(source.global_position) <= source.interaction_distance, "caminhada real só coleta após alcance, sem teleporte")
	_reset()

func _test_cache() -> void:
	source.collect()
	charcoal.collect()
	GroveExpedition._process(5.0)
	var stale := source.create_collection_callback()
	if not await _travel(&"farm_village", &"from_foraging_grove"): return
	var before := _domain()
	_check(not source.is_inside_tree() and not source.collect() and not stale.call() and _domain() == before, "Bosque em cache recusa coleta/callback antigo")
	GroveExpedition._process(10.0)
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 30.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 30.0, "relógio global avança as duas fontes na vila")
	if not await _travel(&"foraging_grove", &"from_farm"): return
	_check(get_tree().current_scene == grove and source.is_collected() and _remaining(GroveExpedition.ROOT_SOURCE) == 30.0, "retorno reusa cache sem segundo desconto de ausência")
	GroveExpedition._process(30.0)
	_check(not source.is_collected() and not charcoal.is_collected() and GlobalInventory.get_item_quantity(ROOT) == 1, "reconciliação disponibiliza fontes sem crédito automático")
	_reset()

func _test_snapshots() -> void:
	source.collect()
	charcoal.collect()
	GroveExpedition._process(15.0)
	var snapshot := _json(SaveManager.call("_build_save_data"))
	_check(snapshot["grove_expedition"]["forage_sources"].size() == 2 and snapshot["farm_grid"]["tiles"].size() == 34, "snapshot externo contém duas fontes e vila completa")
	_check(SaveManager.call("_apply_save_data", snapshot) and get_tree().current_scene == home, "load externo retorna vila preservando estado")
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 30.0 and GlobalInventory.get_item_quantity(ROOT) == 1 and chest.get_item_quantity(ROOT) == 7, "save não recupera tempo offline nem mistura fontes")
	var before := _domain()
	_check(SaveManager.call("_apply_save_data", snapshot) and _domain() == before, "replay restaura mesmo estado sem novo crédito/desconto")
	_check(SaveManager.call("_apply_save_data", {"inventory": {"pontos_alquimia": 0}}) and GroveExpedition.get_save_data() == before["grove"], "payload parcial sem expedição conserva fontes")
	for id in [GroveExpedition.ROOT_SOURCE, GroveExpedition.RENEWABLE_SOURCE]:
		for invalid in [{"collected": true, "renewal_remaining": 0.0}, {"collected": false, "renewal_remaining": 1.0}, {"collected": true, "renewal_remaining": 45.1}, {"collected": true, "renewal_remaining": -1.0}, {"collected": 1, "renewal_remaining": 45.0}, {"collected": true, "renewal_remaining": "45"}]:
			var corrupt := snapshot.duplicate(true)
			corrupt["grove_expedition"]["forage_sources"][id] = invalid
			corrupt["inventory"]["inventario"][ROOT] = 88
			before = _domain()
			_check(not SaveManager.call("_apply_save_data", corrupt) and _domain() == before, "preflight atômico %s rejeita %s" % [id, invalid])
	for invalid_sources in [{"unknown_source": {"collected": true, "renewal_remaining": 1.0}}, {"charcoal_entry": {"collected": true, "renewal_remaining": 1.0}}, {GroveExpedition.ROOT_SOURCE: false}]:
		var corrupt := snapshot.duplicate(true)
		corrupt["grove_expedition"]["forage_sources"] = invalid_sources
		before = _domain()
		_check(not SaveManager.call("_apply_save_data", corrupt) and _domain() == before, "origem/estado inválido não modifica recursos: %s" % invalid_sources)
	var old_sources := snapshot.duplicate(true)
	old_sources["grove_expedition"]["forage_sources"].erase(GroveExpedition.ROOT_SOURCE)
	_check(SaveManager.call("_apply_save_data", old_sources) and not GroveExpedition.get_forage_state(GroveExpedition.ROOT_SOURCE)["collected"] and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 30.0, "save anterior com carvão mas sem raiz começa raiz disponível")
	for version in [3, 4]:
		var legacy := snapshot.duplicate(true)
		legacy["version"] = version
		legacy.erase("grove_expedition")
		if version == 3: legacy.erase("farm_grid")
		_check(SaveManager.call("_apply_save_data", legacy) and GroveExpedition.get_save_data()["forage_sources"].is_empty() and not GroveExpedition.restored, "legado completo v%d inicia fontes disponíveis" % version)
	var default_data := {"discovered": false, "restored": false, "forage_sources": {}}
	_check(GroveExpedition.is_save_data_valid(default_data) and GroveExpedition.load_save_data(default_data), "estado vazio válido sem novos campos obrigatórios")
	for remaining in [NAN, INF]:
		var corrupt := default_data.duplicate(true)
		corrupt["forage_sources"][GroveExpedition.ROOT_SOURCE] = {"collected": true, "renewal_remaining": remaining}
		_check(not GroveExpedition.is_save_data_valid(corrupt), "preflight recusa intervalo não finito")

func _test_recipes() -> void:
	var cauldron: Node = home.get_node("CauldronUI")
	var resolver := Resolver.new()
	for ingredients in [[ROOT, "trigo"], [ROOT, "peixe_comum"]]:
		_reset()
		var recipe: Dictionary = resolver.find_recipe_for_ingredients(ingredients)
		_check(not recipe.is_empty() and int(recipe.get("resultado_quantidade", 0)) == 1 and float(recipe.get("tempo_producao", 0)) == 2.0 and int(recipe.get("recompensa_pontos_alquimia", 0)) == 1, "receita existente mantém 1 resultado/2s/1XP: %s" % [str(ingredients)])
		GlobalInventory.set_inventory_contents({ROOT: 1, ingredients[1]: 1})
		chest.set_contents({})
		cauldron.get("drop_slot_1").set("item_vinculado", ingredients[0])
		cauldron.get("drop_slot_2").set("item_vinculado", ingredients[1])
		cauldron.call("_on_misturar_button_pressed")
		_check(cauldron.get("estado_atual") == "BREWING" and GlobalInventory.get_item_quantity(ROOT) == 0 and GlobalInventory.get_item_quantity(ingredients[1]) == 0, "mistura manual consome os dois ingredientes existentes")
		_check(GlobalInventory.receitas_descobertas.has(recipe["id"]) and GlobalInventory.pontos_alquimia == 1 and not GroveExpedition.discovered, "aprendizado/XP ocorre na receita, não na coleta ou clareira")
		# Espera os 2s reais de receita; não reescreve/interrompe timer.
		await get_tree().create_timer(2.2).timeout
		_check(cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity(recipe["resultado_item"]) == 1, "receita entrega resultado normal uma vez")
		cauldron.call("_on_brew_timer_timeout")
		_check(GlobalInventory.get_item_quantity(recipe["resultado_item"]) == 1, "timeout duplicado não entrega duas vezes")
		if recipe["resultado_item"] == "pocao_crescimento":
			var plot: Node = home.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
			var original: Dictionary = plot.call("get_save_data")
			# Fixture no tempo real do trigo (3s), sem alongar o balanceamento.
			var duration: float = Database.semente_basica["tempo_crescimento_segundos"]
			plot.call("load_save_data", {"estado_atual": 1, "semente_id_plantada": "semente_basica", "arado": true, "regado": true, "tempo_restante": duration, "tempo_total_crescimento": duration})
			var timer: Timer = plot.get_node("Timer")
			var remaining := timer.time_left
			_check(plot.call("can_apply_growth_dose") and GlobalInventory.get_item_quantity("pocao_crescimento") == 1 and GlobalInventory.cargas_crescimento == 0, "frasco fabricado habilita alvo elegível sem gasto na consulta")
			_check(plot.call("apply_growth_dose") and GlobalInventory.get_item_quantity("pocao_crescimento") == 0 and GlobalInventory.cargas_crescimento == 2 and is_equal_approx(timer.time_left, remaining / 2.0), "resultado fabricado aplica efeito vigente: um frasco, três doses, uma usada e timer pela metade")
			plot.call("load_save_data", original)
		_recipe_units_completed += 1
	_reset()

func _test_writer() -> void:
	_check(SaveManager.save_game(), "writer válido grava somente sandbox QA")
	var bytes := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	var valid := GroveExpedition.get_save_data()
	GroveExpedition.set("_forage_states", {GroveExpedition.ROOT_SOURCE: {"collected": true, "renewal_remaining": -1.0}})
	_check(not SaveManager.save_game() and not SaveManager.last_file_error.is_empty() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == bytes, "writer inválido preserva bytes do arquivo anterior")
	GroveExpedition.load_save_data(valid)

func _write_fixture() -> void:
	_reset()
	GlobalInventory.set_inventory_contents({ROOT: 1, "carvao": 2})
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {
		GroveExpedition.ROOT_SOURCE: {"collected": true, "renewal_remaining": 30.0},
		GroveExpedition.RENEWABLE_SOURCE: {"collected": true, "renewal_remaining": 20.0}}})
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 30.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 20.0 and GlobalInventory.get_slot_capacity() == 12, "fixture fixa fontes distintas e Mochila sem expansão")
	_check(SaveManager.save_game(), "fixture grava save QA para novo processo")

func _verify_reopen() -> void:
	_check(SaveManager.has_save(), "arquivo do processo produtor disponível")
	_check(SaveManager.load_game(), "novo processo lê snapshot real")
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 30.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 20.0 and GroveExpedition.get_forage_state(GroveExpedition.ROOT_SOURCE)["collected"], "intervalos carregados sem tempo offline")
	_check(GlobalInventory.get_item_quantity(ROOT) == 1 and GlobalInventory.get_item_quantity("carvao") == 2 and chest.get_item_quantity(ROOT) == 7 and chest.get_item_quantity("carvao") == 9, "fontes pessoais/baú distintas sem duplicação")
	# Load reconcilia receitas padrão do catálogo; isso não é prêmio da coleta.
	var defaults: Array = Resolver.new().get_default_unlocked_recipe_ids()
	var learned := GlobalInventory.receitas_descobertas.duplicate()
	defaults.sort()
	learned.sort()
	_check(not GroveExpedition.discovered and not GroveExpedition.restored and GlobalInventory.get_slot_capacity() == 12 and GlobalInventory.pontos_alquimia == 0 and learned == defaults, "nenhum gate/XP/slots ou receita extra criado pela fonte; somente padrões reconciliados")
	var before := _domain()
	_check(SaveManager.load_game() and _domain() == before, "replay no novo processo não concede item/desconta intervalo")
	GroveExpedition._process(29.0)
	_check(_remaining(GroveExpedition.ROOT_SOURCE) == 1.0 and _remaining(GroveExpedition.RENEWABLE_SOURCE) == 0.0 and not GroveExpedition.get_forage_state(GroveExpedition.RENEWABLE_SOURCE)["collected"], "fontes renovam independentemente na sessão nova")
	GroveExpedition._process(1.0)
	_check(not GroveExpedition.get_forage_state(GroveExpedition.ROOT_SOURCE)["collected"] and GlobalInventory.get_item_quantity(ROOT) == 1 and chest.get_item_quantity(ROOT) == 7, "raiz disponível após limiar sem crédito automático")

func _travel(id: StringName, entry: StringName) -> bool:
	if not bool(get_tree().current_scene.call("request_region_transition", id, entry, &"root_test")):
		_check(false, "pedido de viagem recusado")
		return false
	for _frame in range(180):
		await get_tree().physics_frame
		if not RegionTravelCoordinator.is_transition_in_progress(): break
	var arrived := RegionTravelCoordinator.get_active_region_id() == String(id) and not RegionTravelCoordinator.is_input_blocked()
	_check(arrived, "viagem conclui: " + String(id))
	return arrived

func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value))

func _frames(count: int) -> void:
	for _frame in range(count): await get_tree().physics_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("RenewableRootSmokeTest: " + message)

func _finish(label: String) -> void:
	if not failed: print("RenewableRootSmokeTest: PASS - %d verificações de %s." % [checks, label])
	get_tree().quit(1 if failed else 0)
