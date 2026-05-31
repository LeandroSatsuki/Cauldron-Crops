extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	if not has_save():
		print("SaveManager: nenhum save encontrado para apagar.")
		return true

	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	var result := DirAccess.remove_absolute(absolute_path)
	if result != OK:
		push_error("SaveManager: nao foi possivel apagar o save. Erro: %s" % result)
		return false

	print("SaveManager: save apagado em %s" % SAVE_PATH)
	return true

func save_game() -> bool:
	var data := _build_save_data()
	var json_text := JSON.stringify(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: nao foi possivel abrir o arquivo para salvar em %s" % SAVE_PATH)
		return false

	file.store_string(json_text)
	file.close()

	print("SaveManager: jogo salvo em %s" % SAVE_PATH)
	return true

func load_game() -> bool:
	if not has_save():
		print("SaveManager: nenhum save encontrado em %s" % SAVE_PATH)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: nao foi possivel abrir o arquivo de save em %s" % SAVE_PATH)
		return false

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: JSON invalido em %s" % SAVE_PATH)
		return false

	_apply_save_data(parsed)
	_refresh_ui_after_load()
	print("SaveManager: jogo carregado de %s" % SAVE_PATH)
	return true

func _build_save_data() -> Dictionary:
	var inventory_copy: Dictionary = GlobalInventory.inventario.duplicate(true)

	return {
		"version": SAVE_VERSION,
		"inventory": {
			"inventario": inventory_copy,
			"cargas_crescimento": GlobalInventory.cargas_crescimento,
			"semente_selecionada": GlobalInventory.semente_selecionada,
			"receitas_descobertas": GlobalInventory.receitas_descobertas.duplicate(true),
			"pontos_alquimia": GlobalInventory.pontos_alquimia,
			"skills_desbloqueadas": GlobalInventory.skills_desbloqueadas.duplicate(true)
		},
		"economy": {
			"moedas": EconomyManager.moedas
		},
		"season": {
			"estacao_atual": SeasonManager.estacao_atual,
			"ano": SeasonManager.ano
		},
		"poco": {
			"agua_atual": inventory_copy.get("agua", 0),
			"capacidade_maxima": EconomyManager.poco_capacidade_maxima
		},
		"quests": {
			"quests_ativas": QuestManager.quests_ativas.duplicate(true),
			"max_quests": QuestManager.max_quests
		}
	}

func _apply_save_data(data: Dictionary) -> void:
	var inventory_data: Dictionary = _safe_dictionary(data.get("inventory", {}))
	var saved_inventory: Dictionary = _safe_dictionary(inventory_data.get("inventario", {}))
	var current_inventory: Dictionary = GlobalInventory.inventario.duplicate(true)

	for key in saved_inventory.keys():
		current_inventory[key] = int(saved_inventory.get(key, 0))

	GlobalInventory.inventario = current_inventory
	GlobalInventory.cargas_crescimento = int(inventory_data.get("cargas_crescimento", GlobalInventory.cargas_crescimento))
	GlobalInventory.semente_selecionada = str(inventory_data.get("semente_selecionada", GlobalInventory.semente_selecionada))
	GlobalInventory.receitas_descobertas = _safe_array(inventory_data.get("receitas_descobertas", GlobalInventory.receitas_descobertas)).duplicate(true)
	GlobalInventory.pontos_alquimia = int(inventory_data.get("pontos_alquimia", GlobalInventory.pontos_alquimia))
	GlobalInventory.skills_desbloqueadas = _safe_array(inventory_data.get("skills_desbloqueadas", GlobalInventory.skills_desbloqueadas)).duplicate(true)

	var economy_data: Dictionary = _safe_dictionary(data.get("economy", {}))
	EconomyManager.moedas = int(economy_data.get("moedas", EconomyManager.moedas))

	var season_data: Dictionary = _safe_dictionary(data.get("season", {}))
	SeasonManager.estacao_atual = _safe_estacao(int(season_data.get("estacao_atual", SeasonManager.estacao_atual)))
	SeasonManager.ano = int(season_data.get("ano", SeasonManager.ano))

	var poco_data: Dictionary = _safe_dictionary(data.get("poco", {}))
	var agua_atual = int(poco_data.get("agua_atual", GlobalInventory.inventario.get("agua", 0)))
	if agua_atual < 0:
		agua_atual = 0
	GlobalInventory.inventario["agua"] = agua_atual
	EconomyManager.poco_capacidade_maxima = int(poco_data.get("capacidade_maxima", EconomyManager.poco_capacidade_maxima))

	var quests_data: Dictionary = _safe_dictionary(data.get("quests", {}))
	QuestManager.quests_ativas = _safe_array(quests_data.get("quests_ativas", QuestManager.quests_ativas)).duplicate(true)
	QuestManager.max_quests = int(quests_data.get("max_quests", QuestManager.max_quests))
	QuestManager.quest_atualizada.emit()

func _refresh_ui_after_load() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var ui = scene.get_node_or_null("UI")
	if ui and ui.has_method("verificar_e_atualizar_inventario"):
		ui.verificar_e_atualizar_inventario()

func _safe_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}

func _safe_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []

func _safe_estacao(value: int) -> int:
	if value < SeasonManager.Estacao.PRIMAVERA or value > SeasonManager.Estacao.INVERNO:
		return SeasonManager.estacao_atual
	return value
