extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SKILL_TREE := preload("res://Scenes/SkillTree.tscn")
var home: Node
var chest: VillageChest
var skills: Node
var checks := 0
var failed := false
var notifications := 0
var blocked_calls: Array[bool] = []

# Falha/reentrada sintéticas somente no fixture; não é um baú de gameplay.
class ProbeChest extends Node:
	var inventory := {"trigo": 8, "mistura_restauradora": 1}
	var fail_item := ""
	var probe: Callable
	func _ready() -> void:
		add_to_group("village_chest")
	func get_contents() -> Dictionary:
		return inventory.duplicate(true)
	func get_item_quantity(id: String) -> int:
		return int(inventory.get(id, 0))
	func withdraw_item(id: String, amount: int) -> bool:
		probe.call()
		if id == fail_item or get_item_quantity(id) < amount:
			return false
		inventory[id] -= amount
		return true
	func deposit_item(id: String, amount: int) -> void:
		inventory[id] = get_item_quantity(id) + amount

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA em Builds/QA; não toca no save pessoal")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await get_tree().process_frame
	await get_tree().physics_frame
	home.process_mode = Node.PROCESS_MODE_DISABLED
	chest = home.get_node("VillageChest")
	var golem: Node = home.get_node("Golem")
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	skills = SKILL_TREE.instantiate()
	add_child(skills)
	if "--verify-well-reopen" in OS.get_cmdline_user_args():
		_verify_reopen()
		return _finish()
	if "--prepare-water-skill-save" in OS.get_cmdline_user_args():
		_reset({"agua": 7, "trigo": 3}, {}, false)
		_check(EconomyManager.try_unlock_water_skill(), "fixture obtém benefício por habilidade sem exigir Clareira")
		_check(SaveManager.save_game(), "fixture salva habilidade, não projeto")
		return _finish()
	EconomyManager.well_improvement_changed.connect(func(): notifications += 1)
	_contracts_and_paths()
	_fault_and_reentry()
	_snapshots()
	_regeneration()
	await _travel_and_file()
	_finish()

func _reset(personal: Dictionary, stored: Dictionary, restored: bool = true) -> void:
	EconomyManager.well_improved_by_project = false
	EconomyManager.poco_capacidade_maxima = 10
	GlobalInventory.skills_desbloqueadas = []
	GlobalInventory.pontos_alquimia = 3
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_inventory_contents(personal)
	chest.set_contents(stored)
	GroveExpedition.load_save_data({"discovered": restored, "restored": restored, "forage_sources": {}})

func _contracts_and_paths() -> void:
	_check(VillageWellState.PROJECT_REQUIREMENTS == {"trigo": 8, "mistura_restauradora": 1}, "custos aprovados")
	_reset({"trigo": 8, "mistura_restauradora": 1, "agua": 7}, {}, false)
	var before := _domain()
	_check(EconomyManager.get_well_project_status()["code"] == "locked", "projeto exige Clareira restaurada")
	_check(not EconomyManager.try_improve_village_well() and _domain() == before, "bloqueio não cobra ou concede água")
	GlobalInventory.pontos_alquimia = 0
	before = _domain()
	_check(not EconomyManager.try_unlock_water_skill() and _domain() == before, "habilidade sem ponto não concede benefício")
	_reset({"trigo": 2, "agua": 7}, {"trigo": 5, "mistura_restauradora": 1})
	before = _domain()
	_check(EconomyManager.get_well_project_status() == {"code": "missing", "missing": {"trigo": 1}}, "consulta combina estoques")
	_check(EconomyManager.get_well_project_status()["code"] == "missing" and _domain() == before, "consultar é puro")
	_check(not EconomyManager.try_improve_village_well() and _domain() == before, "falta de um trigo não consome parcialmente")
	_reset({"trigo": 5, "mistura_restauradora": 2, "agua": 7}, {"trigo": 5, "mistura_restauradora": 1})
	var count_before := notifications
	_check(EconomyManager.get_well_project_status()["code"] == "ready", "projeto disponível com recursos")
	_check(EconomyManager.try_improve_village_well(), "API consome requisitos e melhora")
	_check(chest.get_contents().is_empty() and GlobalInventory.get_item_quantity("trigo") == 2 and GlobalInventory.get_item_quantity("mistura_restauradora") == 2, "baú primeiro, Mochila só complementa")
	_check(EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20, "capacidade mínima 20 pelo projeto")
	_check(GlobalInventory.get_item_quantity("agua") == 7 and GlobalInventory.pontos_alquimia == 3 and GlobalInventory.skills_desbloqueadas.is_empty(), "projeto não entrega água/XP/habilidade")
	_check(notifications == count_before + 1 and EconomyManager.get_well_project_status()["code"] == "completed", "notificação única após estado consistente")
	before = _domain()
	_check(not EconomyManager.try_improve_village_well() and not EconomyManager.try_unlock_water_skill() and _domain() == before, "projeto impede segunda cobrança por materiais ou ponto")
	skills.call("_process", 0.0)
	_check(skills.get_node("TeiaSkills/BtnSkillAgua").disabled, "habilidade desabilitada após projeto")
	skills.get_node("TeiaSkills/BtnSkillAgua").pressed.emit()
	_check(_domain() == before, "callback da UI não contorna bloqueio")
	_reset({"trigo": 8, "mistura_restauradora": 1, "agua": 7}, {}, false)
	skills.get_node("TeiaSkills/BtnSkillAgua").pressed.emit()
	_check(EconomyManager.poco_capacidade_maxima == 20 and not EconomyManager.well_improved_by_project and GlobalInventory.pontos_alquimia == 2 and GlobalInventory.skills_desbloqueadas == ["skill_agua"], "habilidade existente continua alternativa de um ponto")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	before = _domain()
	_check(not EconomyManager.try_improve_village_well() and not EconomyManager.try_unlock_water_skill() and _domain() == before, "habilidade impede gastar materiais depois")
	_reset({"agua": 35}, {})
	EconomyManager.poco_capacidade_maxima = 30
	before = _domain()
	_check(not EconomyManager.try_improve_village_well() and not EconomyManager.try_unlock_water_skill() and _domain() == before, "capacidade legada maior não é rebaixada/cobrada")

func _fault_and_reentry() -> void:
	_reset({"agua": 7}, {})
	_check(SaveManager.save_game(), "baseline real de arquivo QA antes da reentrada")
	var file_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	home.remove_child(chest)
	var probe := ProbeChest.new()
	probe.name = "VillageChest"
	probe.fail_item = "mistura_restauradora"
	probe.probe = func():
		blocked_calls.append(not EconomyManager.try_improve_village_well())
		blocked_calls.append(not EconomyManager.try_unlock_water_skill())
		blocked_calls.append(not SaveManager.save_game())
		blocked_calls.append(not SaveManager.call("_apply_save_data", snapshot))
	home.add_child(probe)
	_check(not EconomyManager.try_improve_village_well(), "falha simulada na segunda retirada recusa projeto")
	_check(probe.inventory == {"trigo": 8, "mistura_restauradora": 1}, "rollback devolve trigo à origem")
	_check(not EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 10 and not EconomyManager.is_well_transaction_in_progress(), "falha libera guarda sem conceder melhoria")
	_check(blocked_calls.size() == 8 and false not in blocked_calls, "reentrada de projeto/habilidade/save/load bloqueada durante consumo")
	_check(FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == file_before and GlobalInventory.get_item_quantity("agua") == 7 and GlobalInventory.pontos_alquimia == 3, "arquivo/água/pontos intactos durante falha")
	home.remove_child(probe)
	probe.queue_free()
	home.add_child(chest)

func _snapshots() -> void:
	_reset({"agua": 7, "trigo": 3}, {"trigo": 8, "mistura_restauradora": 1})
	_check(EconomyManager.try_improve_village_well(), "prepara projeto para snapshot")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	_check(saved["version"] == 4 and saved["poco"]["melhoria_projeto"] == true and saved["poco"]["agua_atual"] == 7, "campo aditivo mantém schema v4 e água")
	_reset({"agua": 99}, {})
	_check(SaveManager.call("_apply_save_data", saved), "JSON substitui estado do projeto")
	var before := _domain()
	_check(EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20 and GlobalInventory.get_item_quantity("agua") == 7, "load restaura sem encher água")
	_check(SaveManager.call("_apply_save_data", saved) and _domain() == before, "replay não soma capacidade/recursos")
	_check(SaveManager.call("_apply_save_data", {"version": 4}) and EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20, "payload parcial sem poço preserva marco")
	for version in [3, 4]:
		var legacy := saved.duplicate(true)
		legacy["version"] = version
		legacy["poco"].erase("melhoria_projeto")
		legacy["poco"]["capacidade_maxima"] = 10
		legacy["inventory"]["skills_desbloqueadas"] = []
		_check(SaveManager.call("_apply_save_data", legacy) and not EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 10, "legado completo desfaz marco runtime, v%d" % version)
		legacy["inventory"]["skills_desbloqueadas"] = ["skill_agua"]
		_check(SaveManager.call("_apply_save_data", legacy) and not EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20, "legado com habilidade reconcilia mínimo 20, v%d" % version)
		legacy["inventory"]["skills_desbloqueadas"] = []
		legacy["poco"]["capacidade_maxima"] = 30
		legacy["poco"]["agua_atual"] = 35
		_check(SaveManager.call("_apply_save_data", legacy) and EconomyManager.poco_capacidade_maxima == 30 and GlobalInventory.get_item_quantity("agua") == 35, "legado maior/excesso preservados, v%d" % version)
	_check(SaveManager.call("_apply_save_data", saved), "retorna ao snapshot novo antes de recusas")
	for invalid_flag in [1, "true", null]:
		var invalid := saved.duplicate(true)
		invalid["poco"]["melhoria_projeto"] = invalid_flag
		_expect_rejected(invalid)
	for invalid_capacity in [0, -1, 1.5, "20", true, NAN, INF]:
		var invalid := saved.duplicate(true)
		invalid["poco"]["capacidade_maxima"] = invalid_capacity
		_expect_rejected(invalid)
	for invalid_water in [-1, 0.5, "7", null, true]:
		var invalid := saved.duplicate(true)
		invalid["poco"]["agua_atual"] = invalid_water
		_expect_rejected(invalid)
	var contradiction := saved.duplicate(true)
	contradiction["grove_expedition"]["restored"] = false
	_expect_rejected(contradiction)
	var wrong_shape := saved.duplicate(true)
	wrong_shape["poco"] = []
	_expect_rejected(wrong_shape)
	_check(SaveManager.save_game(), "baseline de arquivo válido antes da recusa de gravação")
	var file_before := FileAccess.get_file_as_string(SaveManager.SAVE_PATH)
	GroveExpedition.load_save_data({"discovered": true, "restored": false, "forage_sources": {}})
	_check(not SaveManager.save_game() and FileAccess.get_file_as_string(SaveManager.SAVE_PATH) == file_before, "estado contraditório não sobrescreve arquivo anterior")
	for child in get_tree().root.get_children():
		if child is AcceptDialog:
			child.queue_free()
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})

func _regeneration() -> void:
	GlobalInventory.set_inventory_contents({"agua": 19})
	PocoManager.tempo_acumulado = 0.0
	PocoManager.call("_process", 1.0)
	_check(GlobalInventory.get_item_quantity("agua") == 20 and GlobalInventory.get_used_slot_count() == 0, "regeneração existente de uma água/segundo até 20, sem slots")
	PocoManager.call("_process", 1.0)
	_check(GlobalInventory.get_item_quantity("agua") == 20, "reserva cheia não cresce")

func _travel_and_file() -> void:
	_reset({"agua": 7, "trigo": 3}, {"trigo": 8, "mistura_restauradora": 1})
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "viaja pelo coordenador real")
	await _wait_transition()
	_check(get_tree().current_scene != home and not home.is_inside_tree(), "vila fica em cache fora da árvore")
	var before := _domain()
	_check(EconomyManager.get_well_project_status()["code"] == "home_unavailable" and not EconomyManager.try_improve_village_well() and _domain() == before, "projeto não consome baú remoto no Bosque")
	_check(RegionTravelCoordinator.return_home_for_load(), "retorno seguro à vila")
	_check(EconomyManager.try_improve_village_well(), "projeto melhora após retorno")
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "segunda viagem com melhoria")
	await _wait_transition()
	_check(SaveManager.save_game(), "save real externo inclui poço melhorado")
	_check(SaveManager.load_game() and get_tree().current_scene == home, "load externo retorna HOME")
	before = _domain()
	_check(EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20 and GlobalInventory.get_item_quantity("agua") == 7, "arquivo externo conserva marco/capacidade/água")
	_check(SaveManager.load_game() and _domain() == before, "replay do arquivo sem nova cobrança")
	_check(SaveManager.save_game(), "deixa arquivo QA para reabertura em outro processo")

func _verify_reopen() -> void:
	_check(SaveManager.has_save(), "arquivo QA do processo anterior")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.SAVE_PATH))
	_check(SaveManager.load_game(), "novo processo carrega")
	_check(EconomyManager.well_improved_by_project == bool(saved["poco"]["melhoria_projeto"]) and EconomyManager.poco_capacidade_maxima == 20, "origem e capacidade restauradas")
	_check(GlobalInventory.get_item_quantity("agua") == int(saved["poco"]["agua_atual"]) and GlobalInventory.pontos_alquimia == int(saved["inventory"]["pontos_alquimia"]), "load não concede água/XP")
	var before := _domain()
	_check(SaveManager.load_game() and _domain() == before, "replay em novo processo não soma estado")
	_check(not EconomyManager.try_improve_village_well() and not EconomyManager.try_unlock_water_skill() and _domain() == before, "reabertura não autoriza benefício duplicado")
	skills.call("_process", 0.0)
	_check(skills.get_node("TeiaSkills/BtnSkillAgua").disabled, "UI mostra benefício já obtido")
	_check(chest.get_contents() == saved["village_chest_inventory"], "estoque do baú preservado")

func _wait_transition() -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while RegionTravelCoordinator.is_transition_in_progress() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(not RegionTravelCoordinator.is_transition_in_progress(), "transição termina")

func _expect_rejected(data: Dictionary) -> void:
	var before := _domain()
	_check(not SaveManager.call("_apply_save_data", data), "preflight recusa poço inválido")
	_check(_domain() == before, "recusa antes de trocar região/estoque/progresso")

func _domain() -> Dictionary:
	return {"personal": GlobalInventory.inventario.duplicate(true), "stored": chest.get_contents(), "water_capacity": EconomyManager.poco_capacidade_maxima, "project": EconomyManager.well_improved_by_project, "xp": GlobalInventory.pontos_alquimia, "skills": GlobalInventory.skills_desbloqueadas.duplicate(), "grove": GroveExpedition.get_save_data(), "scene": get_tree().current_scene.get_instance_id()}

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("VillageWellProgressSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("VillageWellProgressSmokeTest: PASS - %d verificações de contrato, custos, caminhos alternativos, legado, preflight e arquivo QA." % checks)
	get_tree().quit(1 if failed else 0)
