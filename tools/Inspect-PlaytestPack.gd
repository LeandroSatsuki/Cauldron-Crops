extends SceneTree

func _initialize() -> void:
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "CauldronCropsPlaytest":
		_fail("save do playtest não está isolado")
		return
	if not _inspect("res://"):
		return
	for path in ["res://Scenes/Main.tscn", "res://Scenes/UI.tscn", "res://Scenes/ForagingGroveRegion.tscn", "res://Scenes/PrototypeExternalRegion.tscn", "res://Data/recipes/semente_basica_tomate_sol.tres", "res://Scripts/Golem.gd", "res://Scripts/GolemPanel.gd", "res://Scripts/data/GolemSeedCargo.gd", "res://Scripts/data/GolemWorkState.gd", "res://Assets/Tools/tool_seed.png", "res://Scenes/VillageWell.tscn", "res://Scripts/VillageWell.gd", "res://Scripts/VillageWellPanel.gd", "res://Scripts/data/VillageWellState.gd"]:
		if not ResourceLoader.exists(path) or ResourceLoader.load(path) == null:
			_fail("recurso necessário ausente: " + path)
			return
	if not _check_seed_recipe("res://Data/recipes/semente_trigo_recuperacao.tres", "semente_trigo_recuperacao", ["carvao", "agua"], 1):
		return
	if not _check_seed_recipe("res://Data/recipes/semente_trigo_replantio.tres", "semente_trigo_replantio", ["trigo", "trigo"], 3):
		return
	if not _check_well_contract():
		return
	if not _check_living_soil_contract():
		return
	if not _check_accelerator_contract():
		return
	if not _check_root_contract():
		return
	if not _check_tomato_contract():
		return
	if not _check_selective_sower_contract():
		return
	if not _check_flame_fertilizer_contract():
		return
	print("PlaytestPackAudit: PASS - recursos, receitas sustentáveis, Poço, Solo Vivo, Aceleradora, Raiz renovável, tomate Primavera/Verão, semeadura seletiva, Adubo Flamejante, aplicação, exclusões e save separado.")
	quit(0)

func _check_flame_fertilizer_contract() -> bool:
	var plot: GDScript = ResourceLoader.load("res://Scripts/FarmPlot.gd")
	var tile: GDScript = ResourceLoader.load("res://Scripts/data/FarmTileData.gd")
	if plot == null or tile == null:
		return _fail("domínio do Adubo ausente")
	var names: Array = []
	for method in plot.get_script_method_list():
		names.append(str(method["name"]))
	for method in ["can_apply_flame_fertilizer", "apply_flame_fertilizer", "get_crop_generation"]:
		if method not in names:
			return _fail("API do Adubo ausente: " + method)
	if plot.get_script_constant_map().get("FLAME_FERTILIZER_BONUS") != 2:
		return _fail("bônus do Adubo fora do contrato")
	var recipe: Resource = ResourceLoader.load("res://Data/recipes/tomate_sol_trigo.tres")
	if recipe == null or recipe.get("id") != "tomate_sol_trigo" or recipe.get("ingredientes") != ["tomate_sol", "trigo"] or recipe.get("resultado_item") != "adubo_flamejante" or recipe.get("resultado_quantidade") != 1 or recipe.get("tempo_producao") != 2.0 or recipe.get("recompensa_pontos_alquimia") != 1 or recipe.get("desbloqueada_por_padrao") or recipe.get("exige_descoberta"):
		return _fail("receita experimental do Adubo alterada")
	names.clear()
	for method in tile.get_script_method_list():
		names.append(str(method["name"]))
	if "is_flame_fertilizer_valid" not in names:
		return _fail("preflight do Adubo ausente")
	var valid := {"flame_fertilizer_applied": true, "crop_id": "semente_verao", "tile_state": 3, "remaining_growth_time": 0.0, "pending_harvest_rewards": {"tomate_sol": 3}}
	if not tile.call("is_flame_fertilizer_valid", valid):
		return _fail("snapshot de tomate adubado recusado")
	for value in [null, 1, "true", [], {}]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["flame_fertilizer_applied"] = value
		if tile.call("is_flame_fertilizer_valid", invalid):
			return _fail("flag do Adubo não é estrita")
	var invalid: Dictionary = valid.duplicate(true)
	invalid["pending_harvest_rewards"] = {"tomate_sol": 2}
	if tile.call("is_flame_fertilizer_valid", invalid):
		return _fail("snapshot adubado sem bônus aceito")
	invalid = valid.duplicate(true)
	invalid["crop_id"] = "semente_basica"
	if tile.call("is_flame_fertilizer_valid", invalid):
		return _fail("Adubo aceito em outro cultivo")
	valid.erase("flame_fertilizer_applied")
	if not tile.call("is_flame_fertilizer_valid", valid):
		return _fail("snapshot antigo recusado por ausência do campo opcional")
	return true

func _check_selective_sower_contract() -> bool:
	# Scripts carregados exclusivamente do PCK, sem instanciar mundo/ready/save.
	var cargo: GDScript = ResourceLoader.load("res://Scripts/data/GolemSeedCargo.gd")
	var work: GDScript = ResourceLoader.load("res://Scripts/data/GolemWorkState.gd")
	var golem: GDScript = ResourceLoader.load("res://Scripts/Golem.gd")
	var cells: Array = cargo.get_script_constant_map().get("PILOT_CELLS", [])
	if cells != [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		return _fail("lotes do semeador alterados")
	var names: Array = []
	for method in golem.get_script_method_list():
		names.append(str(method["name"]))
	for method in ["set_selected_seed_id", "get_selected_seed_id", "get_seed_selection_status"]:
		if method not in names:
			return _fail("API da semeadura seletiva ausente: " + method)
	var defaults: Dictionary = work.call("default_data")
	if defaults.get("selected_seed_id") != "semente_basica" or defaults.get("seeding_enabled", true) or not work.call("is_valid", defaults, false):
		return _fail("padrão do semeador fora do contrato")
	for id in ["semente_basica", "semente_verao", "semente_outono", "semente_inverno", "tomate_sol", ""]:
		var allowed: bool = id in ["semente_basica", "semente_verao"]
		var candidate: Dictionary = defaults.duplicate(true)
		candidate["selected_seed_id"] = id
		if bool(work.call("is_valid", candidate, true)) != allowed:
			return _fail("whitelist de escolha inválida: " + id)
		var payload := {"item_id": id, "quantity": 1, "target_cell": {"x": 0, "y": 0}, "intent": "transport"}
		if bool(cargo.call("is_save_data_valid", payload)) != allowed:
			return _fail("whitelist de cargo inválida: " + id)
		candidate["seeding_enabled"] = true
		candidate["seed_cargo"] = payload
		candidate.erase("selected_seed_id")
		if bool(work.call("is_valid", candidate, true)) != allowed:
			return _fail("cargo sem escolha não conserva identidade/validade: " + id)
		if allowed and work.call("is_valid", candidate, false):
			return _fail("cargo/ON aceitos sem Clareira restaurada")
	var mismatch: Dictionary = defaults.duplicate(true)
	mismatch["seeding_enabled"] = true
	mismatch["seed_cargo"] = {"item_id": "semente_verao", "quantity": 1, "target_cell": {"x": 0, "y": 0}, "intent": "transport"}
	if not work.call("is_valid", mismatch, true):
		return _fail("escolha futura Trigo rejeita cargo válido de tomate")
	for invalid in [null, false, 0, [], {}]:
		var candidate: Dictionary = defaults.duplicate(true)
		candidate["selected_seed_id"] = invalid
		if work.call("is_valid", candidate, true):
			return _fail("escolha aceita tipo inválido")
	var scene: PackedScene = ResourceLoader.load("res://Scenes/UI.tscn")
	var state := scene.get_state()
	var controls: Dictionary = {}
	for index in state.get_node_count():
		var name: String = str(state.get_node_name(index))
		if name in ["SeedSelection", "WheatButton", "TomatoButton", "SeedSelectionStatus"]:
			controls[name] = str(state.get_node_type(index))
	if controls != {"SeedSelection": "HBoxContainer", "WheatButton": "Button", "TomatoButton": "Button", "SeedSelectionStatus": "Label"}:
		return _fail("seletor funcional do semeador ausente")
	return true

func _check_tomato_contract() -> bool:
	var path := "res://Data/recipes/semente_tomate_recuperacao.tres"
	if not ResourceLoader.exists(path):
		return _fail("bootstrap de tomate ausente")
	var recipe: Resource = ResourceLoader.load(path)
	if recipe == null or recipe.get("id") != "semente_tomate_recuperacao" or recipe.get("ingredientes") != ["trigo", "agua"] or recipe.get("resultado_item") != "semente_verao" or recipe.get("resultado_quantidade") != 1 or recipe.get("tempo_producao") != 2.0 or recipe.get("recompensa_pontos_alquimia") != 0 or not recipe.get("desbloqueada_por_padrao") or recipe.get("exige_descoberta"):
		return _fail("bootstrap de tomate fora do contrato")
	# Catálogo do próprio PCK, fora da árvore: não executar ready ou progresso.
	var script: GDScript = ResourceLoader.load("res://Scripts/Database.gd")
	var catalog: Node = script.new()
	var seed: Dictionary = catalog.get("semente_verao")
	var valid: bool = seed.get("estacao_ideal") == 1 and seed.get("tempo_crescimento_segundos") == 5.0 and seed.get("produto_colheita") == "tomate_sol" and seed.get("estacoes_permitidas") == [0, 1]
	for season in range(4):
		valid = valid and catalog.call("semente_permite_estacao", seed, season) == (season in [0, 1])
		valid = valid and catalog.call("semente_permite_estacao", catalog.get("semente_basica"), season) == (season == 0)
	catalog.free()
	if not valid:
		return _fail("política de estações do tomate/trigo alterada")
	return true

func _check_root_contract() -> bool:
	var expedition: GDScript = ResourceLoader.load("res://Scripts/GroveExpedition.gd")
	var constants := expedition.get_script_constant_map()
	if constants.get("ROOT_SOURCE") != "grove_root" or constants.get("CHARCOAL_RENEWAL_SECONDS") != 45.0:
		return _fail("Raiz renovável ausente/intervalo diferente do contrato")
	if "grove_root" not in constants.get("SOURCE_IDS", []):
		return _fail("ID de Raiz ausente no domínio persistente")
	var scene: PackedScene = ResourceLoader.load("res://Scenes/ForagingGroveRegion.tscn")
	var state := scene.get_state()
	var found := false
	for index in state.get_node_count():
		if state.get_node_name(index) != &"RenewableRoot":
			continue
		var properties := {}
		for property_index in state.get_node_property_count(index):
			properties[str(state.get_node_property_name(index, property_index))] = state.get_node_property_value(index, property_index)
		# O export omite overrides iguais ao padrão. Ler a instância base do
		# próprio PCK, fora da árvore, sem executar ready/coleta/progresso.
		var template_scene := state.get_node_instance(index)
		if template_scene == null:
			return _fail("cena base da fonte de Raiz ausente no pacote")
		var template := template_scene.instantiate()
		var quantity: Variant = properties.get("quantity", template.get("quantity"))
		var milestone: Variant = properties.get("backpack_milestone_id", template.get("backpack_milestone_id"))
		template.free()
		if properties.get("position") != Vector2(960, 630) or properties.get("resource_id") != "raiz_gelida" or quantity != 1 or properties.get("expedition_source_id") != "grove_root" or milestone != "":
			return _fail("fonte de Raiz fora do contrato de posição/quantidade/ID/sem marco")
		found = true
	if not found:
		return _fail("fonte física de Raiz ausente no Bosque")
	for pair in [["pocao_crescimento_basica", "trigo_raiz_gelida", ["raiz_gelida", "trigo"], "pocao_crescimento"], ["raiz_gelida_peixe_comum", "raiz_gelida_peixe_comum", ["raiz_gelida", "peixe_comum"], "pocao_purificadora_fraca"]]:
		var recipe: Resource = ResourceLoader.load("res://Data/recipes/%s.tres" % pair[0])
		if recipe == null or recipe.get("id") != pair[1] or recipe.get("ingredientes") != pair[2] or recipe.get("resultado_item") != pair[3] or recipe.get("resultado_quantidade") != 1 or recipe.get("tempo_producao") != 2.0 or recipe.get("recompensa_pontos_alquimia") != 1 or recipe.get("exige_descoberta"):
			return _fail("receita existente da Raiz alterada: " + str(pair[0]))
	return true

func _check_accelerator_contract() -> bool:
	var golem: GDScript = ResourceLoader.load("res://Scripts/Golem.gd")
	if golem.get_script_constant_map().get("ACCELERATOR_FACTOR") != 1.5:
		return _fail("Aceleradora ausente/fator diferente do contrato")
	var names: Array = []
	for method in golem.get_script_method_list():
		names.append(str(method["name"]))
	for method in ["prepare_accelerator_delivery", "cancel_accelerator_preparation", "get_accelerator_status", "get_delivery_move_speed"]:
		if method not in names:
			return _fail("API da Aceleradora ausente: " + method)
	var work: GDScript = ResourceLoader.load("res://Scripts/data/GolemWorkState.gd")
	var payload: Dictionary = work.call("default_data")
	if not payload.has_all(["accelerator_prepared", "accelerator_active", "harvest_delivery_started"]) or not work.call("is_valid", payload, false):
		return _fail("schema da Aceleradora ausente/inválido")
	payload["accelerator_active"] = true
	if work.call("is_valid", payload, false):
		return _fail("schema aceita benefício sem carga")
	var scene: PackedScene = ResourceLoader.load("res://Scenes/UI.tscn")
	var state := scene.get_state()
	var found := false
	for index in state.get_node_count():
		if state.get_node_name(index) == &"AcceleratorAction":
			found = true
	if not found:
		return _fail("comando contextual da Aceleradora ausente")
	for pair in [["carvao_trigo", ["carvao", "trigo"]], ["peixe_comum_trigo", ["peixe_comum", "trigo"]]]:
		var recipe: Resource = ResourceLoader.load("res://Data/recipes/%s.tres" % pair[0])
		if recipe == null or recipe.get("ingredientes") != pair[1] or recipe.get("resultado_item") != "pocao_aceleradora" or recipe.get("resultado_quantidade") != 1 or recipe.get("tempo_producao") != 2.0 or recipe.get("recompensa_pontos_alquimia") != 1:
			return _fail("receita da Aceleradora alterada: " + str(pair[0]))
	return true

func _check_living_soil_contract() -> bool:
	for path in ["res://Scripts/LivingSoilState.gd", "res://Scripts/ItemUsePanel.gd", "res://Data/recipes/solo_vivo_retencao.tres"]:
		if not ResourceLoader.exists(path) or ResourceLoader.load(path) == null:
			return _fail("Solo Vivo/aplicação ausente: " + path)
	var recipe: Resource = ResourceLoader.load("res://Data/recipes/solo_vivo_retencao.tres")
	if recipe.get("id") != "solo_vivo_retencao" or recipe.get("ingredientes") != ["trigo", "mistura_restauradora"] or recipe.get("resultado_item") != "preparo_solo_vivo" or recipe.get("resultado_quantidade") != 1 or recipe.get("recompensa_pontos_alquimia") != 0 or recipe.get("tempo_producao") != 2.0 or not recipe.get("exige_descoberta") or recipe.get("desbloqueada_por_padrao"):
		return _fail("receita do Solo Vivo diverge do contrato")
	var contract: GDScript = ResourceLoader.load("res://Scripts/LivingSoilState.gd")
	if contract.get_script_constant_map().get("PILOT_CELL") != Vector2i(2, 2):
		return _fail("célula piloto alterada")
	var data := {"living_soil_treated": true, "living_soil_moisture": true, "crop_id": "", "is_watered": true, "tile_state": 2}
	if not contract.call("validate_flags", data, Vector2i(2, 2)) or contract.call("validate_flags", data, Vector2i(0, 0)):
		return _fail("preflight aceita tratamento fora do piloto ou recusa estado válido")
	data["crop_id"] = "semente_basica"
	if contract.call("validate_flags", data, Vector2i(2, 2)):
		return _fail("umidade herdada aceita cultura ocupada")
	return true

func _check_well_contract() -> bool:
	# Carregar do PCK, sem preload que mascare a ausência numa build antiga.
	var contract: GDScript = ResourceLoader.load("res://Scripts/data/VillageWellState.gd")
	var constants := contract.get_script_constant_map()
	if constants.get("BASE_CAPACITY") != 10 or constants.get("IMPROVED_CAPACITY") != 20 or constants.get("WATER_SKILL") != "skill_agua" or constants.get("PROJECT_REQUIREMENTS") != {"trigo": 8, "mistura_restauradora": 1}:
		return _fail("contrato de capacidade/custo/alternativa do Poço alterado")
	var project := {"inventory": {"inventario": {}, "skills_desbloqueadas": []}, "poco": {"capacidade_maxima": 10, "agua_atual": 7, "melhoria_projeto": true}, "grove_expedition": {"restored": true}}
	var resolved: Dictionary = contract.call("resolve_snapshot", project, 10, false, [], false)
	if not resolved.get("valid", false) or resolved.get("capacity") != 20 or resolved.get("water") != 7 or not resolved.get("project", false):
		return _fail("preflight do projeto não conserva benefício/reserva")
	project["grove_expedition"]["restored"] = false
	resolved = contract.call("resolve_snapshot", project, 10, false, [], false)
	if resolved.get("valid", false):
		return _fail("projeto aceita snapshot sem Clareira restaurada")
	var legacy := {"inventory": {"inventario": {}, "skills_desbloqueadas": ["skill_agua"]}, "poco": {"capacidade_maxima": 30, "agua_atual": 35}}
	resolved = contract.call("resolve_snapshot", legacy, 10, false, [], false)
	if not resolved.get("valid", false) or resolved.get("capacity") != 30 or resolved.get("water") != 35 or resolved.get("project", true):
		return _fail("preflight legado altera capacidade/reserva/projeto")
	legacy["poco"]["capacidade_maxima"] = 10
	resolved = contract.call("resolve_snapshot", legacy, 10, false, [], false)
	if not resolved.get("valid", false) or resolved.get("capacity") != 20:
		return _fail("habilidade antiga não concede o mesmo benefício")
	# Inspecionar instância declarada, sem criar objetos ou conceder progresso.
	var main: PackedScene = ResourceLoader.load("res://Scenes/Main.tscn")
	var well: PackedScene = ResourceLoader.load("res://Scenes/VillageWell.tscn")
	var state := main.get_state()
	for index in state.get_node_count():
		if state.get_node_name(index) != &"VillageWell" or state.get_node_instance(index) != well:
			continue
		for property_index in state.get_node_property_count(index):
			if state.get_node_property_name(index, property_index) == &"position" and state.get_node_property_value(index, property_index) == Vector2(540, 280):
				return true
	return _fail("Poço físico ausente/fora da posição aprovada na cena principal")

func _check_seed_recipe(path: String, id: String, ingredients: Array, quantity: int) -> bool:
	if not ResourceLoader.exists(path):
		return _fail("receita ausente: " + path)
	var recipe: Resource = ResourceLoader.load(path)
	if recipe == null:
		return _fail("receita não carregável: " + path)
	if recipe.get("id") != id or recipe.get("ingredientes") != ingredients or recipe.get("resultado_item") != "semente_basica" or recipe.get("resultado_quantidade") != quantity:
		return _fail("contrato de ingredientes/resultado alterado: " + path)
	if recipe.get("categoria") != "semente" or not recipe.get("desbloqueada_por_padrao") or recipe.get("exige_descoberta") or recipe.get("recompensa_pontos_alquimia") != 0 or not is_equal_approx(float(recipe.get("tempo_producao")), 2.0):
		return _fail("contrato de disponibilidade/XP/tempo alterado: " + path)
	return true

func _inspect(path: String) -> bool:
	var directory := DirAccess.open(path)
	if directory == null:
		return _fail("diretório indisponível: " + path)
	for file in directory.get_files():
		var full := path.path_join(file)
		if full.begins_with("res://Scripts/dev/") or full.begins_with("res://Scenes/dev/") or file.begins_with("savegame") or full == "res://AGENTS.md":
			return _fail("arquivo interno/pessoal no pacote: " + full)
	for folder in directory.get_directories():
		var full := path.path_join(folder)
		if full in ["res://docs", "res://tools", "res://Builds", "res://.git", "res://.codex"]:
			return _fail("diretório interno no pacote: " + full)
		if not _inspect(full):
			return false
	return true

func _fail(message: String) -> bool:
	push_error("PlaytestPackAudit: FAIL - " + message)
	quit(1)
	return false
