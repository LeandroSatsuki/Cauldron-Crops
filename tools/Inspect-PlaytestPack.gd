extends SceneTree

func _initialize() -> void:
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "CauldronCropsPlaytest":
		_fail("save do playtest não está isolado")
		return
	if not _inspect("res://"):
		return
	for path in ["res://Scenes/Main.tscn", "res://Scenes/ForagingGroveRegion.tscn", "res://Scenes/PrototypeExternalRegion.tscn", "res://Data/recipes/semente_basica_tomate_sol.tres"]:
		if not ResourceLoader.exists(path) or ResourceLoader.load(path) == null:
			_fail("recurso necessário ausente: " + path)
			return
	print("PlaytestPackAudit: PASS - recursos, exclusões e save separado.")
	quit(0)

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
