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
	var restoration_projects: Dictionary = {}
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
		var projects: Array = tree.get_nodes_in_group("restoration_project")
		for project_variant in projects:
			var project: Node = project_variant
			if project == null or not project.has_method("get_save_data"):
				continue
			var project_data_variant: Variant = project.call("get_save_data")
			if typeof(project_data_variant) != TYPE_DICTIONARY:
				continue
			var project_data: Dictionary = project_data_variant
			var restoration_id: String = str(project_data.get("restoration_id", project.name))
			restoration_projects[restoration_id] = bool(project_data.get("restored", false))

	return {
		"version": SAVE_VERSION,
		"cauldrons": _build_cauldron_save_data(),
		"fishing_pending_capture": _build_fishing_save_data(),
		"inventory": {
			"inventario": inventory_copy,
			"backpack_milestones": GlobalInventory.get_backpack_milestones(),
			"cargas_crescimento": GlobalInventory.cargas_crescimento,
			"semente_selecionada": GlobalInventory.semente_selecionada,
			"receitas_descobertas": GlobalInventory.receitas_descobertas.duplicate(true),
			"pontos_alquimia": GlobalInventory.pontos_alquimia,
			"skills_desbloqueadas": GlobalInventory.skills_desbloqueadas.duplicate(true),
			"colecao_pesca_descobertas": GlobalInventory.colecao_pesca_descobertas.duplicate(),
			"colecao_pesca_concluida": GlobalInventory.colecao_pesca_concluida,
			"lore_descobertas": GlobalInventory.lore_descobertas.duplicate(),
		},
		"economy": {
			"moedas": EconomyManager.moedas,
			"total_golems": EconomyManager.total_golems,
			"max_golems": EconomyManager.max_golems,
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
			"purification_progress": purification_progress,
			"restoration_projects": restoration_projects
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
	if not _is_pending_harvest_save_valid(data, farm_save_source):
		push_warning("SaveManager: colheita pendente invalida; save nao aplicado.")
		return false
	# Validar o novo payload antes de substituir estoques ou qualquer produtor.
	if not _is_cauldron_save_payload_valid(data):
		push_warning("SaveManager: dados de producao do caldeirao invalidos; save nao aplicado.")
		return false
	if not _is_fishing_save_payload_valid(data):
		push_warning("SaveManager: captura pendente invalida; save nao aplicado.")
		return false

	var inventory_data: Dictionary = _safe_dictionary(data.get("inventory", {}))
	var backpack_progress: Variant = _resolve_backpack_progress(data, inventory_data)
	if not GlobalInventory.is_backpack_progress_valid(backpack_progress):
		push_warning("SaveManager: marcos da Mochila invalidos; save nao aplicado.")
		return false
	var saved_inventory: Dictionary = _safe_dictionary(inventory_data.get("inventario", {}))
	# Um inventario salvo completo substitui o estado atual; mesclar preservaria
	# itens retirados do bau depois do save, duplicando-os ao carregar.
	# Payloads legados/parciais sem o campo ainda mantem o inventario atual.
	var current_inventory: Dictionary = {} if inventory_data.get("inventario") is Dictionary else GlobalInventory.inventario.duplicate(true)

	for key in saved_inventory.keys():
		current_inventory[key] = int(saved_inventory.get(key, 0))

	if not GlobalInventory.set_inventory_contents(current_inventory):
		push_error("SaveManager: inventario pessoal invalido no save.")
		return false
	GlobalInventory.apply_backpack_progress(backpack_progress)
	GlobalInventory.cargas_crescimento = int(inventory_data.get("cargas_crescimento", GlobalInventory.cargas_crescimento))
	GlobalInventory.semente_selecionada = str(inventory_data.get("semente_selecionada", GlobalInventory.semente_selecionada))
	if not GlobalInventory.semente_selecionada.begins_with("semente_") or GlobalInventory.get_item_quantity(GlobalInventory.semente_selecionada) == 0:
		GlobalInventory.semente_selecionada = ""
	else:
		# Restaurar o plantio deve manter a mesma exclusividade do clique na UI.
		ToolManager.clear_tool()
	GlobalInventory.receitas_descobertas = _safe_array(inventory_data.get("receitas_descobertas", GlobalInventory.receitas_descobertas)).duplicate(true)
	GlobalInventory.pontos_alquimia = int(inventory_data.get("pontos_alquimia", GlobalInventory.pontos_alquimia))
	GlobalInventory.skills_desbloqueadas = _safe_array(inventory_data.get("skills_desbloqueadas", GlobalInventory.skills_desbloqueadas)).duplicate(true)
	GlobalInventory.aplicar_colecao_pesca_save(
		_safe_array(inventory_data.get("colecao_pesca_descobertas", GlobalInventory.colecao_pesca_descobertas)),
		bool(inventory_data.get("colecao_pesca_concluida", GlobalInventory.colecao_pesca_concluida))
	)
	GlobalInventory.apply_lore_discoveries_save(
		_safe_array(inventory_data.get("lore_descobertas", GlobalInventory.lore_descobertas))
	)

	var economy_data: Dictionary = _safe_dictionary(data.get("economy", {}))
	EconomyManager.moedas = int(economy_data.get("moedas", EconomyManager.moedas))
	# Resultado legado de golem usa contagem, nao slots. Restaurar o mesmo
	# snapshot tambem precisa desfazer entregas feitas depois dele.
	EconomyManager.total_golems = maxi(int(economy_data.get("total_golems", EconomyManager.total_golems)), 0)
	EconomyManager.max_golems = maxi(int(economy_data.get("max_golems", EconomyManager.max_golems)), 0)

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
		_aplicar_estado_projetos_restauracao(_safe_dictionary(farm_expansion_data.get("restoration_projects", {})))

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
	if data.has("farm_expansion"):
		var farm_expansion_data: Dictionary = _safe_dictionary(data.get("farm_expansion", {}))
		_aplicar_estado_projetos_restauracao(_safe_dictionary(farm_expansion_data.get("restoration_projects", {})))

	if data.has("cauldrons") or inventory_data.get("inventario") is Dictionary:
		# Save antigo completo nao contem producao: limpar o runtime sem refund.
		# Payload parcial de contratos agricolas continua sem tocar no caldeirao.
		var cauldron_states: Dictionary = data.get("cauldrons", {})
		var cauldron_nodes: Dictionary = _get_cauldron_nodes()
		for cauldron_id in cauldron_nodes:
			cauldron_nodes[cauldron_id].call("load_save_data", cauldron_states.get(cauldron_id, {"state": "IDLE"}))
	if data.has("fishing_pending_capture") or inventory_data.get("inventario") is Dictionary:
		var fishing: Node = _get_fishing_minigame()
		if fishing != null:
			fishing.call("load_save_data", data.get("fishing_pending_capture", {}))
		for spot in get_tree().get_nodes_in_group("fishing_spot"):
			if current_scene != null and current_scene.is_ancestor_of(spot) and spot.has_method("reset_after_load"):
				spot.call("reset_after_load")
	return true


func _resolve_backpack_progress(data: Dictionary, inventory_data: Dictionary) -> Variant:
	if inventory_data.has("backpack_milestones"):
		return inventory_data["backpack_milestones"]
	# Save antigo completo substitui progresso; payload parcial preserva runtime.
	# O Herbário já era persistido, portanto seu marco pode ser recuperado.
	var milestones: Array = [] if inventory_data.get("inventario") is Dictionary else GlobalInventory.get_backpack_milestones()
	var expansion: Dictionary = _safe_dictionary(data.get("farm_expansion", {}))
	var restorations: Dictionary = _safe_dictionary(expansion.get("restoration_projects", {}))
	if restorations.get("first_herbarium", false) == true and "first_herbarium" not in milestones:
		milestones.append("first_herbarium")
	return milestones


func _get_fishing_minigame() -> Node:
	var scene: Node = get_tree().current_scene
	var ui: Node = scene.get_node_or_null("UI") if scene != null else null
	if ui == null:
		return null
	var fishing: Variant = ui.get("fishing_minigame_ui")
	return fishing if is_instance_valid(fishing) and fishing is Node else null


func _build_fishing_save_data() -> Dictionary:
	var fishing: Node = _get_fishing_minigame()
	return fishing.call("get_save_data") if fishing != null else {}


func _is_fishing_save_payload_valid(data: Dictionary) -> bool:
	if not data.has("fishing_pending_capture"):
		return true
	var pending: Variant = data["fishing_pending_capture"]
	if not (pending is Dictionary):
		return false
	var fishing: Node = _get_fishing_minigame()
	return bool(fishing.call("is_save_data_valid", pending)) if fishing != null else pending.is_empty()


func _get_cauldron_nodes() -> Dictionary:
	var nodes: Dictionary = {}
	var scene: Node = get_tree().current_scene
	if scene == null:
		return nodes
	for cauldron in get_tree().get_nodes_in_group("cauldrons"):
		if scene.is_ancestor_of(cauldron) and cauldron.has_method("get_save_data") and cauldron.has_method("load_save_data"):
			nodes[str(scene.get_path_to(cauldron))] = cauldron
	return nodes


func _build_cauldron_save_data() -> Dictionary:
	var states: Dictionary = {}
	var nodes: Dictionary = _get_cauldron_nodes()
	for cauldron_id in nodes:
		states[cauldron_id] = nodes[cauldron_id].call("get_save_data")
	return states


func _is_cauldron_save_payload_valid(data: Dictionary) -> bool:
	if not data.has("cauldrons"):
		return true
	if not (data["cauldrons"] is Dictionary):
		return false
	var nodes: Dictionary = _get_cauldron_nodes()
	for cauldron_id in data["cauldrons"]:
		var state: Variant = data["cauldrons"][cauldron_id]
		if not nodes.has(cauldron_id) or not (state is Dictionary):
			return false
		if not bool(nodes[cauldron_id].call("is_save_data_valid", state)):
			return false
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

func _is_pending_harvest_save_valid(data: Dictionary, source: FarmSaveSource) -> bool:
	var entries: Array = []
	if source == FarmSaveSource.GRID_V4:
		entries = _safe_array(_safe_dictionary(data.get("farm_grid", {})).get("tiles", []))
	elif source == FarmSaveSource.LEGACY_PLOTS:
		entries = _safe_array(data.get("farm_plots", []))
	for entry in entries:
		if not entry is Dictionary or not entry.has("pending_harvest_rewards"):
			continue
		var rewards: Variant = entry["pending_harvest_rewards"]
		if not FarmTileData.is_pending_harvest_valid(rewards):
			return false
		if rewards.is_empty():
			continue
		if source == FarmSaveSource.GRID_V4:
			if str(entry.get("crop_id", "")) == "" or float(entry.get("remaining_growth_time", 0.0)) > 0.0 or int(entry.get("tile_state", 0)) == FarmTileData.TileState.BLOQUEADO:
				return false
		else:
			var state: int = int(entry.get("estado_atual", 0))
			var ready: bool = state == 2 or (state == 1 and float(entry.get("tempo_restante", 0.0)) <= 0.0) or (state == 0 and bool(entry.get("pronto_para_colher", false)))
			if str(entry.get("semente_id_plantada", "")) == "" or not ready:
				return false
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


func _aplicar_estado_projetos_restauracao(restoration_projects_data: Dictionary) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var projects: Array = tree.get_nodes_in_group("restoration_project")
	for project_variant in projects:
		var project: Node = project_variant
		if project == null or not is_instance_valid(project) or not project.has_method("load_save_data"):
			continue
		var restoration_id: String = project.name
		if project.has_method("get_save_data"):
			var project_data_variant: Variant = project.call("get_save_data")
			if typeof(project_data_variant) == TYPE_DICTIONARY:
				restoration_id = str((project_data_variant as Dictionary).get("restoration_id", restoration_id))
		project.call("load_save_data", {
			"restoration_id": restoration_id,
			"restored": bool(restoration_projects_data.get(restoration_id, false))
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
		"pronto_para_colher": tempo_restante <= 0.0,
		"pending_harvest_rewards": tile.pending_harvest_rewards.duplicate(true)
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
