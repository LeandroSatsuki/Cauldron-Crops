extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 4
const LEGACY_SAVE_VERSION := 3

enum FarmSaveSource {
	NONE,
	LEGACY_PLOTS,
	GRID_V4,
}

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

	if not _apply_save_data(parsed):
		return false
	_refresh_ui_after_load()
	print("SaveManager: jogo carregado de %s" % SAVE_PATH)
	return true

func _build_save_data() -> Dictionary:
	var inventory_copy: Dictionary = GlobalInventory.inventario.duplicate(true)
	var village_chest_inventory: Dictionary = {}
	var village_chest := _get_village_chest()
	if village_chest and village_chest.has_method("get_contents"):
		village_chest_inventory = village_chest.get_contents()

	var farm_plots: Array = []
	var farm_grid: Dictionary = {}
	var tree: SceneTree = get_tree()
	if tree != null:
		var lotes_terra: Array = tree.get_nodes_in_group("lotes_terra")
		for lote_variant in lotes_terra:
			var lote: Node = lote_variant
			if lote and lote.has_method("get_save_data"):
				farm_plots.append(lote.get_save_data())
			else:
				farm_plots.append({})

		var scene: Node = tree.current_scene
		if scene != null and scene.has_method("obter_farm_grid_save_data"):
			var farm_grid_variant: Variant = scene.call("obter_farm_grid_save_data")
			if typeof(farm_grid_variant) == TYPE_DICTIONARY:
				farm_grid = (farm_grid_variant as Dictionary).duplicate(true)
		elif scene != null and scene.has_method("obter_farm_grid_manager"):
			var grid_manager_variant: Variant = scene.call("obter_farm_grid_manager")
			if grid_manager_variant is FarmGridManager:
				farm_grid = (grid_manager_variant as FarmGridManager).to_save_data()

	var purification_obstacles: Dictionary = {}
	var purification_progress: Dictionary = {}
	if tree != null:
		var obstacles: Array = tree.get_nodes_in_group("purification_obstacle")
		for obstacle_variant in obstacles:
			var obstacle: Node = obstacle_variant
			if obstacle and obstacle.has_method("get_save_data"):
				var obstacle_data_variant: Variant = obstacle.get_save_data()
				if typeof(obstacle_data_variant) == TYPE_DICTIONARY:
					var obstacle_data: Dictionary = obstacle_data_variant
					var obstacle_id: String = str(obstacle_data.get("obstacle_id", obstacle.name))
					purification_obstacles[obstacle_id] = bool(obstacle_data.get("purified", false))
					var obstacle_progress: Dictionary = _safe_dictionary(obstacle_data.get("purification_progress", {}))
					purification_progress[obstacle_id] = obstacle_progress.duplicate(true)

	return {
		"version": SAVE_VERSION,
		"inventory": {
			"inventario": inventory_copy,
			"cargas_crescimento": GlobalInventory.cargas_crescimento,
			"semente_selecionada": GlobalInventory.semente_selecionada,
			"receitas_descobertas": GlobalInventory.receitas_descobertas.duplicate(true),
			"pontos_alquimia": GlobalInventory.pontos_alquimia,
			"skills_desbloqueadas": GlobalInventory.skills_desbloqueadas.duplicate(true),
			"colecao_pesca_descobertas": GlobalInventory.colecao_pesca_descobertas.duplicate(),
			"colecao_pesca_concluida": GlobalInventory.colecao_pesca_concluida,
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
		},
		"village_chest_inventory": village_chest_inventory,
		"farm_plots": farm_plots,
		"farm_grid": farm_grid,
		"farm_expansion": {
			"purification_obstacles": purification_obstacles,
			"purification_progress": purification_progress
		}
	}

func _apply_save_data(data: Dictionary) -> bool:
	var save_version: int = _read_save_version(data)
	if not _is_save_version_supported(save_version):
		if save_version > SAVE_VERSION:
			push_error(
				"SaveManager: save da versao %d nao pode ser carregado pela versao atual %d."
				% [save_version, SAVE_VERSION]
			)
			return false
		push_error("SaveManager: versao de save invalida.")
		return false
	var farm_save_source: FarmSaveSource = _resolve_farm_save_source(data, save_version)
	if not _is_farm_save_payload_valid(data, farm_save_source):
		push_error("SaveManager: dados agricolas invalidos para o contrato do save.")
		return false

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
	GlobalInventory.aplicar_colecao_pesca_save(
		_safe_array(inventory_data.get("colecao_pesca_descobertas", GlobalInventory.colecao_pesca_descobertas)),
		bool(inventory_data.get("colecao_pesca_concluida", GlobalInventory.colecao_pesca_concluida))
	)

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

	if data.has("village_chest_inventory"):
		var village_chest_inventory: Dictionary = _safe_dictionary(data.get("village_chest_inventory", {}))
		var village_chest := _get_village_chest()
		if village_chest and village_chest.has_method("set_contents"):
			village_chest.set_contents(village_chest_inventory)

	if data.has("farm_expansion"):
		var farm_expansion_data: Dictionary = _safe_dictionary(data.get("farm_expansion", {}))
		var purification_obstacles_data: Dictionary = _safe_dictionary(farm_expansion_data.get("purification_obstacles", {}))
		var purification_progress_data: Dictionary = _safe_dictionary(farm_expansion_data.get("purification_progress", {}))
		_aplicar_estado_obstaculos_purificados(purification_obstacles_data, purification_progress_data)

	var current_scene: Node = get_tree().current_scene if get_tree() != null else null
	if current_scene != null and current_scene.has_method("sincronizar_area_bloqueada_v0"):
		current_scene.call("sincronizar_area_bloqueada_v0")

	if farm_save_source == FarmSaveSource.GRID_V4:
		var saved_grid: Dictionary = _safe_dictionary(data.get("farm_grid", {}))
		_aplicar_farm_grid_aos_plots(saved_grid)
	elif farm_save_source == FarmSaveSource.LEGACY_PLOTS:
		var saved_plots: Array = _safe_array(data.get("farm_plots", []))
		var tree: SceneTree = get_tree()
		if tree != null:
			var lotes_terra: Array = tree.get_nodes_in_group("lotes_terra")
			var quantidade_aplicavel: int = min(lotes_terra.size(), saved_plots.size())
			for index in range(quantidade_aplicavel):
				var lote: Node = lotes_terra[index]
				var plot_data_variant: Variant = saved_plots[index]
				if lote and lote.has_method("load_save_data") and typeof(plot_data_variant) == TYPE_DICTIONARY:
					var plot_data: Dictionary = (plot_data_variant as Dictionary).duplicate(true)
					plot_data.erase("expansion_blocked")
					lote.load_save_data(plot_data)

	if current_scene != null and current_scene.has_method("sincronizar_area_bloqueada_v0"):
		current_scene.call("sincronizar_area_bloqueada_v0")

	return true

func _read_save_version(data: Dictionary) -> int:
	if not data.has("version"):
		return LEGACY_SAVE_VERSION

	var version_variant: Variant = data.get("version")
	if typeof(version_variant) == TYPE_INT:
		return int(version_variant)
	if typeof(version_variant) == TYPE_FLOAT:
		var float_version: float = float(version_variant)
		var int_version: int = int(float_version)
		if float(int_version) == float_version:
			return int_version

	return -1

func _is_save_version_supported(save_version: int) -> bool:
	return save_version > 0 and save_version <= SAVE_VERSION

func _resolve_farm_save_source(data: Dictionary, save_version: int) -> FarmSaveSource:
	if save_version >= SAVE_VERSION and data.has("farm_grid"):
		return FarmSaveSource.GRID_V4
	if data.has("farm_plots"):
		return FarmSaveSource.LEGACY_PLOTS
	return FarmSaveSource.NONE

func _is_farm_save_payload_valid(data: Dictionary, farm_save_source: FarmSaveSource) -> bool:
	if farm_save_source == FarmSaveSource.GRID_V4:
		return typeof(data.get("farm_grid")) == TYPE_DICTIONARY
	if farm_save_source == FarmSaveSource.LEGACY_PLOTS:
		return typeof(data.get("farm_plots")) == TYPE_ARRAY
	return true

func _refresh_ui_after_load() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var ui = scene.get_node_or_null("UI")
	if ui and ui.has_method("verificar_e_atualizar_inventario"):
		ui.verificar_e_atualizar_inventario()
	if ui and ui.has_method("atualizar_painel_purificacao"):
		ui.call("atualizar_painel_purificacao")

	var village_chest := _get_village_chest()
	if ui and village_chest and ui.has_method("_atualizar_painel_bau_vila"):
		ui.call("_atualizar_painel_bau_vila")

func _get_village_chest() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null

	var chests: Array = tree.get_nodes_in_group("village_chest")
	for chest in chests:
		if is_instance_valid(chest):
			return chest

	return null

func _aplicar_estado_obstaculos_purificados(purification_obstacles_data: Dictionary, purification_progress_data: Dictionary = {}) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var obstacles: Array = tree.get_nodes_in_group("purification_obstacle")
	for obstacle_variant in obstacles:
		var obstacle: Node = obstacle_variant
		if obstacle == null or not is_instance_valid(obstacle):
			continue
		if not obstacle.has_method("load_save_data"):
			continue

		var obstacle_id: String = obstacle.name
		if obstacle.has_method("get_save_data"):
			var obstacle_data_variant: Variant = obstacle.call("get_save_data")
			if typeof(obstacle_data_variant) == TYPE_DICTIONARY:
				obstacle_id = str((obstacle_data_variant as Dictionary).get("obstacle_id", obstacle_id))

		var purified := bool(purification_obstacles_data.get(obstacle_id, false))
		var progress_data: Dictionary = _safe_dictionary(purification_progress_data.get(obstacle_id, {}))
		obstacle.call("load_save_data", {
			"obstacle_id": obstacle_id,
			"purified": purified,
			"purification_progress": progress_data
		})

func _aplicar_farm_grid_aos_plots(farm_grid_data: Dictionary) -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return

	var scene: Node = tree.current_scene
	if not scene.has_method("obter_farm_plot_por_grid_position"):
		return

	var grid_manager: FarmGridManager = FarmGridManager.new()
	grid_manager.load_save_data(farm_grid_data)
	for tile_variant in grid_manager.get_all_tiles():
		if tile_variant is not FarmTileData:
			continue

		var tile: FarmTileData = tile_variant
		var plot_variant: Variant = scene.call("obter_farm_plot_por_grid_position", tile.grid_position)
		if not (plot_variant is Node2D) and tile.tile_state != FarmTileData.TileState.GRAMA:
			if scene.has_method("garantir_farm_plot_por_grid_position"):
				plot_variant = scene.call("garantir_farm_plot_por_grid_position", tile.grid_position)
		if plot_variant is Node2D and is_instance_valid(plot_variant):
			var plot: Node2D = plot_variant
			if plot.has_method("load_save_data"):
				plot.load_save_data(_converter_farm_tile_para_plot_save_data(tile))

func _converter_farm_tile_para_plot_save_data(tile: FarmTileData) -> Dictionary:
	if tile == null:
		return {}

	if tile.tile_state == FarmTileData.TileState.BLOQUEADO:
		return {
			"estado_atual": 0,
			"semente_id_plantada": "",
			"regado": false,
			"arado": false,
			"tempo_restante": 0.0,
			"tempo_total_crescimento": 0.0,
			"pronto_para_colher": false
		}

	var regado: bool = tile.is_watered or tile.tile_state == FarmTileData.TileState.MOLHADO
	if tile.crop_id == "":
		if tile.tile_state == FarmTileData.TileState.GRAMA:
			return {}

		return {
			"estado_atual": 0,
			"semente_id_plantada": "",
			"regado": regado,
			"arado": true,
			"tempo_restante": 0.0,
			"tempo_total_crescimento": 0.0,
			"pronto_para_colher": false
		}

	var tempo_restante: float = maxf(tile.remaining_growth_time, 0.0)
	var estado_atual: int = 2 if tempo_restante <= 0.0 else 1
	return {
		"estado_atual": estado_atual,
		"semente_id_plantada": tile.crop_id,
		"regado": regado,
		"arado": true,
		"tempo_restante": tempo_restante,
		"tempo_total_crescimento": maxf(tile.total_growth_time, tempo_restante),
		"pronto_para_colher": tempo_restante <= 0.0
	}

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
