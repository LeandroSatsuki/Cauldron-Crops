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
	print("PlaytestPackAudit: PASS - recursos, receitas sustentáveis, Poço, Solo Vivo, aplicação, exclusões e save separado.")
	quit(0)

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
