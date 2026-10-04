extends SceneTree

func _initialize() -> void:
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "CauldronCropsPlaytest":
		_fail("save do playtest não está isolado")
		return
	if not _inspect("res://"):
		return
	for path in ["res://Scenes/Main.tscn", "res://Scenes/UI.tscn", "res://Scenes/ForagingGroveRegion.tscn", "res://Scenes/PrototypeExternalRegion.tscn", "res://Data/recipes/semente_basica_tomate_sol.tres", "res://Scripts/Golem.gd", "res://Scripts/GolemPanel.gd", "res://Scripts/data/GolemSeedCargo.gd", "res://Scripts/data/GolemWorkState.gd", "res://Assets/Tools/tool_seed.png"]:
		if not ResourceLoader.exists(path) or ResourceLoader.load(path) == null:
			_fail("recurso necessário ausente: " + path)
			return
	if not _check_seed_recipe("res://Data/recipes/semente_trigo_recuperacao.tres", "semente_trigo_recuperacao", ["carvao", "agua"], 1):
		return
	if not _check_seed_recipe("res://Data/recipes/semente_trigo_replantio.tres", "semente_trigo_replantio", ["trigo", "trigo"], 3):
		return
	print("PlaytestPackAudit: PASS - recursos, receitas sustentáveis, exclusões e save separado.")
	quit(0)

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
		if full.begins_with("res://Scripts/dev/") or full.begins_with("res://Scenes/dev/") or file.begins_with("savegame"):
			return _fail("arquivo interno/pessoal no pacote: " + full)
	for folder in directory.get_directories():
		var full := path.path_join(folder)
		if full in ["res://docs", "res://tools", "res://Builds", "res://.git"]:
			return _fail("diretório interno no pacote: " + full)
		if not _inspect(full):
			return false
	return true

func _fail(message: String) -> bool:
	push_error("PlaytestPackAudit: FAIL - " + message)
	quit(1)
	return false
