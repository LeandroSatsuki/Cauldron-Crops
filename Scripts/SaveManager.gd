extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 4
const LEGACY_SAVE_VERSION := 3
const ProtectedSaveFileScript := preload("res://Scripts/data/ProtectedSaveFile.gd")
const DefaultRecipeResolverScript := preload("res://Scripts/data/RecipeResolver.gd")
var last_file_error := ""
var _applying_snapshot := false

func is_applying_snapshot() -> bool:
	return _applying_snapshot

enum FarmSaveSource {
	NONE,
	LEGACY_PLOTS,
	GRID_V4,
}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	last_file_error = ""
	# Novo jogo explícito também remove artefatos associados, sem recuperação futura.
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		var path: String = SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			var result := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if result != OK:
				last_file_error = "Não foi possível apagar o save ou sua cópia de segurança."
				push_error(last_file_error)
				return false

	print("SaveManager: save apagado em %s" % SAVE_PATH)
	return true

func save_game() -> bool:
	last_file_error = ""
	if not _is_growth_charges_valid(GlobalInventory.cargas_crescimento):
		last_file_error = "Doses de crescimento inválidas. O save anterior não foi alterado."
		return false
	if _applying_snapshot or EconomyManager.is_well_transaction_in_progress() or HerbariumProduction.is_transaction_in_progress() or _seed_delivery_transaction_in_progress():
		last_file_error = "Aguarde o fim do carregamento antes de salvar."
		return false
	var home: Node = _get_save_scene()
	if home == null or not home.has_method("obter_farm_grid_save_data"):
		last_file_error = "Fazenda indisponível. O save anterior não foi alterado."
		push_warning("SaveManager: Fazenda/Vila indisponivel; arquivo pessoal nao sobrescrito.")
		return false
	if RegionTravelCoordinator.is_transition_in_progress():
		last_file_error = "Aguarde o fim da viagem antes de salvar."
		return false
	if _get_save_golem() == null:
		last_file_error = "Golem indisponível. O save anterior não foi alterado."
		return false
	if not _seed_delivery_snapshot_valid({}):
		last_file_error = "Encomenda de sementes inválida. O save anterior não foi alterado."
		return false
	# Validar o domínio vivo antes de reconstruir índices ou abrir arquivos.
	if not _resolve_herbarium_snapshot({"herbarium_production": HerbariumProduction.get_save_data()}).get("valid", false):
		last_file_error = "Estado do Herbário produtivo inválido. O save anterior não foi alterado."
		return false
	for plot in _get_save_group_nodes("lotes_terra"):
		if plot.has_method("is_flame_fertilizer_runtime_valid") and not bool(plot.call("is_flame_fertilizer_runtime_valid")):
			last_file_error = "Estado de Adubo Flamejante inválido. O save anterior não foi alterado."
			return false
		if plot.has_method("get_save_data") and not FarmTileData.is_flame_fertilizer_valid(plot.get_save_data()):
			last_file_error = "Estado de Adubo Flamejante inválido. O save anterior não foi alterado."
			return false
		if plot.has_method("get_save_data") and not LivingSoilState.validate_flags(plot.get_save_data(), _living_soil_plot_cell(plot)):
			last_file_error = "Estado de Solo Vivo inválido. O save anterior não foi alterado."
			return false
	var data := _build_save_data()
	if not _resolve_herbarium_snapshot(data).get("valid", false):
		last_file_error = "Estado do Herbário produtivo inválido. O save anterior não foi alterado."
		return false
	if not _is_flame_fertilizer_save_valid(data, _resolve_farm_save_source(data, SAVE_VERSION)):
		last_file_error = "Estado de Adubo Flamejante inválido. O save anterior não foi alterado."
		return false
	if not GroveExpedition.is_save_data_valid(data.get("grove_expedition")):
		last_file_error = "Estado da expedição inválido. O save anterior não foi alterado."
		return false
	if not _is_living_soil_save_valid(data, _resolve_farm_save_source(data, SAVE_VERSION)):
		last_file_error = "Estado de Solo Vivo inválido. O save anterior não foi alterado."
		return false
	if not _resolve_well_snapshot(data).get("valid", false):
		last_file_error = "Estado do poço inválido. O save anterior não foi alterado."
		_show_file_error("Não foi possível salvar", last_file_error)
		return false
	if not _is_golem_save_payload_valid(data):
		last_file_error = "Carga do golem inválida. O save anterior não foi alterado."
		_show_file_error("Não foi possível salvar", last_file_error)
		return false
	if not _is_cauldron_save_payload_valid(data) or not _seed_delivery_snapshot_valid(data):
		last_file_error = "Produção ou custódia do caldeirão inválida. O save anterior não foi alterado."
		return false
	var result: Dictionary = ProtectedSaveFileScript.new().write(SAVE_PATH, data)
	if not result.success:
		last_file_error = result.message
		push_warning("SaveManager: %s (erro %s)" % [last_file_error, result.error])
		_show_file_error("Não foi possível salvar", last_file_error)
		return false

	print("SaveManager: jogo salvo em %s" % SAVE_PATH)
	return true

func load_game() -> bool:
	last_file_error = ""
	if _applying_snapshot or EconomyManager.is_well_transaction_in_progress() or HerbariumProduction.is_transaction_in_progress() or _seed_delivery_transaction_in_progress():
		last_file_error = "Aguarde o fim da transação antes de carregar."
		return false
	if not has_save():
		print("SaveManager: nenhum save encontrado em %s" % SAVE_PATH)
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			_show_file_error("Não foi possível carregar", "O arquivo principal não foi encontrado. A cópia de segurança não foi carregada automaticamente.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: nao foi possivel abrir o arquivo de save em %s" % SAVE_PATH)
		_show_file_error("Não foi possível carregar", "O arquivo não pôde ser lido. Nenhuma cópia foi carregada automaticamente.")
		return false

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: JSON invalido em %s" % SAVE_PATH)
		_show_file_error("Não foi possível carregar", "O arquivo está incompleto ou inválido. Nenhuma cópia foi carregada automaticamente.")
		return false

	if not _apply_save_data(parsed):
		_show_file_error("Não foi possível carregar", "O conteúdo do save foi recusado. Nenhuma cópia foi carregada automaticamente.")
		return false
	_refresh_ui_after_load()
	print("SaveManager: jogo carregado de %s" % SAVE_PATH)
	return true

func _show_file_error(title: String, message: String) -> void:
	last_file_error = message
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message + ("\nExiste uma cópia de segurança em savegame.json.bak. Preserve os arquivos para recuperação assistida." if FileAccess.file_exists(SAVE_PATH + ".bak") else "")
	get_tree().root.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(520, 180))

func _build_save_data() -> Dictionary:
	var home: Node = _get_save_scene()
	if home != null and home.has_method("_reconstruir_farm_grid_manager"):
		# FarmPlot é a autoridade: incluir tempo/efeitos atuais, não o índice antigo.
		home.call("_reconstruir_farm_grid_manager")
	var inventory_copy: Dictionary = GlobalInventory.inventario.duplicate(true)
	var village_chest_inventory: Dictionary = {}
	var village_chest := _get_village_chest()
	if village_chest and village_chest.has_method("get_contents"):
		village_chest_inventory = village_chest.get_contents()

	var farm_plots: Array = []
	var farm_grid: Dictionary = {}
	var tree: SceneTree = get_tree()
	if tree != null:
		var lotes_terra: Array = _get_save_group_nodes("lotes_terra")
		for lote_variant in lotes_terra:
			var lote: Node = lote_variant
			if lote and lote.has_method("get_save_data"):
				farm_plots.append(lote.get_save_data())
			else:
				farm_plots.append({})

		var scene: Node = _get_save_scene()
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
		var obstacles: Array = _get_save_group_nodes("purification_obstacle")
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
		var projects: Array = _get_save_group_nodes("restoration_project")
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

	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"herbarium_production": HerbariumProduction.get_save_data(),
		"grove_expedition": GroveExpedition.get_save_data(),
		"home_inactive_seconds": RegionTravelCoordinator.get_inactive_region_elapsed_seconds(&"farm_village"),
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
			"capacidade_maxima": EconomyManager.poco_capacidade_maxima,
			"melhoria_projeto": EconomyManager.well_improved_by_project
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
	# Fixtures/contratos sem vila não inventam um golem no payload parcial.
	if _get_save_golem() != null:
		save_data["golem_work"] = _build_golem_save_data()
	return save_data

func _apply_save_data(data: Dictionary) -> bool:
	if _applying_snapshot or EconomyManager.is_well_transaction_in_progress() or HerbariumProduction.is_transaction_in_progress() or _seed_delivery_transaction_in_progress():
		return false
	if not _seed_delivery_snapshot_valid(data):
		push_warning("SaveManager: encomenda/carga de sementes incoerente; save não aplicado.")
		return false
	var herbarium_snapshot := _resolve_herbarium_snapshot(data)
	if not herbarium_snapshot.get("valid", false):
		push_warning("SaveManager: Herbário produtivo inválido; save não aplicado.")
		return false
	var well_snapshot := _resolve_well_snapshot(data)
	if not bool(well_snapshot.get("valid", false)):
		push_warning("SaveManager: estado do poço invalido; save nao aplicado.")
		return false
	# Pré-validar os campos opcionais antes de mudar região, recursos ou flags.
	if data.has("grove_expedition") and not GroveExpedition.is_save_data_valid(data["grove_expedition"]):
		push_warning("SaveManager: expedicao invalida; save nao aplicado.")
		return false
	if not _is_golem_save_payload_valid(data):
		push_warning("SaveManager: trabalho/carga do golem invalidos; save nao aplicado.")
		return false
	var inactive_seconds: Variant = data.get("home_inactive_seconds", 0.0)
	if not (inactive_seconds is float or inactive_seconds is int) or not is_finite(float(inactive_seconds)) or float(inactive_seconds) < 0.0:
		push_warning("SaveManager: intervalo de ausencia invalido; save nao aplicado.")
		return false
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
	if not _is_flame_fertilizer_save_valid(data, farm_save_source):
		push_warning("SaveManager: Adubo Flamejante invalido; save nao aplicado.")
		return false
	data = _with_living_soil_partial_defaults(data, farm_save_source)
	if not _is_living_soil_save_valid(data, farm_save_source):
		push_warning("SaveManager: Solo Vivo invalido; save nao aplicado.")
		return false
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
	if inventory_data.has("cargas_crescimento"):
		var charges: Variant = inventory_data["cargas_crescimento"]
		if not _is_growth_charges_valid(charges):
			push_warning("SaveManager: doses de crescimento invalidas; save nao aplicado.")
			return false
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
		var quantity: Variant = saved_inventory[key]
		if str(key).strip_edges() == "" or not (quantity is float or quantity is int) or not is_finite(float(quantity)) or float(quantity) < 0.0 or float(int(quantity)) != float(quantity):
			push_warning("SaveManager: inventario pessoal invalido; save nao aplicado.")
			return false
		current_inventory[key] = int(quantity)

	var home: Node = _get_save_scene()
	var delivery_snapshot := _effective_seed_delivery_snapshot(data)
	_applying_snapshot = true
	if home != null and home.has_method("cancel_consumable_application"):
		home.cancel_consumable_application()
	var item_panel := home.get_node_or_null("UI/ItemUsePanel") if home != null else null
	if item_panel != null:
		item_panel.close_card()
	if home != null and home != get_tree().current_scene and home.has_method("obter_farm_grid_save_data"):
		if not RegionTravelCoordinator.return_home_for_load():
			_applying_snapshot = false
			return false
	# Invalidar callbacks e substituir carga antes dos sinais de progresso/lotes.
	# Legado completo limpa runtime sem refund; contratos parciais não o substituem.
	if data.has("golem_work") or inventory_data.get("inventario") is Dictionary or delivery_snapshot["has_delivery"]:
		var golem := _get_save_golem()
		if golem != null:
			golem.call("load_work_save_data", delivery_snapshot["golem"], delivery_snapshot["grove_restored"])

	if not GlobalInventory.set_inventory_contents(current_inventory):
		_applying_snapshot = false
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
	if data.has("grove_expedition"):
		GroveExpedition.load_save_data(data["grove_expedition"])
	elif inventory_data.get("inventario") is Dictionary:
		# Saves completos anteriores à clareira começam o recorte intacto.
		GroveExpedition.reset_progress()
	else:
		# Payload parcial pode substituir a lista do Livro, mas não os marcos.
		GroveExpedition.reconcile_recipe_discoveries()
	_reconcile_default_recipe_discoveries()
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

	var agua_atual := int(well_snapshot["water"]) if well_snapshot["has_water"] else int(GlobalInventory.inventario.get("agua", 0))
	GlobalInventory.inventario["agua"] = agua_atual
	EconomyManager.poco_capacidade_maxima = int(well_snapshot["capacity"])
	EconomyManager.well_improved_by_project = bool(well_snapshot["project"])

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
	# Substituição sem pagamento/entrega; geração invalida callbacks, inclusive
	# em parciais que preservam exatamente a disponibilidade anterior.
	HerbariumProduction.load_save_data(herbarium_snapshot["state"])

	if data.has("cauldrons") or inventory_data.get("inventario") is Dictionary or delivery_snapshot["has_delivery"]:
		# Save antigo completo nao contem producao: limpar o runtime sem refund.
		# Payload parcial de contratos agricolas continua sem tocar no caldeirao.
		var cauldron_states: Dictionary = delivery_snapshot["cauldrons"]
		var cauldron_nodes: Dictionary = _get_cauldron_nodes()
		for cauldron_id in cauldron_nodes:
			cauldron_nodes[cauldron_id].call("load_save_data", cauldron_states.get(cauldron_id, {"state": "IDLE"}))
	# Intenção de interface nunca sobrevive a um apply aceito, mesmo se o
	# parcial preserva o caldeirão IDLE. Não substitui nem cancela a produção.
	for cauldron_node in _get_cauldron_nodes().values():
		var book: Node = cauldron_node.get_node_or_null("PopupLayer/RecipeBookUI")
		if book != null and book.has_method("fechar"):
			book.call("fechar")
	var current_ui: Node = current_scene.get_node_or_null("UI") if current_scene != null else null
	var fallback_book: Node = current_ui.get_node_or_null("RecipeBookUI") if current_ui != null else null
	if fallback_book != null and fallback_book.has_method("fechar"):
		fallback_book.call("fechar")
	if data.has("fishing_pending_capture") or inventory_data.get("inventario") is Dictionary:
		var fishing: Node = _get_fishing_minigame()
		if fishing != null:
			fishing.call("load_save_data", data.get("fishing_pending_capture", {}))
		for spot in get_tree().get_nodes_in_group("fishing_spot"):
			if current_scene != null and current_scene.is_ancestor_of(spot) and spot.has_method("reset_after_load"):
				spot.call("reset_after_load")
	if float(inactive_seconds) > 0.0 and current_scene != null and current_scene.has_method("advance_inactive_time"):
		current_scene.call("advance_inactive_time", float(inactive_seconds))
	if current_scene != null and current_scene.has_method("_reconstruir_farm_grid_manager"):
		current_scene.call("_reconstruir_farm_grid_manager")
	_applying_snapshot = false
	var well := get_tree().current_scene.get_node_or_null("VillageWell") if get_tree().current_scene != null else null
	if well != null:
		well.close_panel()
	var site := get_tree().current_scene.get_node_or_null("ProductiveHerbarium") if get_tree().current_scene != null else null
	if site != null and site.has_method("close_panel"):
		site.call("close_panel")
	HerbariumProduction.progress_changed.emit()
	EconomyManager.well_improvement_changed.emit()
	return true

func _resolve_herbarium_snapshot(data: Dictionary) -> Dictionary:
	var complete := _safe_dictionary(data.get("inventory", {})).get("inventario") is Dictionary
	var state: Variant = data.get("herbarium_production", HerbariumProductionState.default_data() if complete else HerbariumProduction.get_save_data())
	if not HerbariumProductionState.is_valid(state):
		return {"valid": false}
	if state["activated"] and not _effective_herbarium_gates(data, complete):
		return {"valid": false}
	return {"valid": true, "state": state.duplicate(true)}

func _effective_herbarium_gates(data: Dictionary, complete: bool) -> bool:
	# Refletir a aplicação existente: farm_expansion presente SUBSTITUI mapas,
	# ausente preserva nós; Grove ausente reseta só no inventário completo.
	var grove: Variant = data.get("grove_expedition")
	var grove_restored: Variant = grove.get("restored", false) if grove is Dictionary and data.has("grove_expedition") else (false if complete else GroveExpedition.restored)
	if not (grove_restored is bool and grove_restored):
		return false
	var project: Node = null
	for candidate in _get_save_group_nodes("restoration_project"):
		if candidate.has_method("get_save_data") and str(candidate.call("get_save_data").get("restoration_id", "")) == "first_herbarium":
			project = candidate
			break
	if project == null:
		return false
	var restored: Variant = project.get("restored_state")
	var purified: Variant = project.get("area_purified")
	if data.has("farm_expansion"):
		var expansion := _safe_dictionary(data.get("farm_expansion"))
		restored = _safe_dictionary(expansion.get("restoration_projects")).get("first_herbarium", false)
		purified = _safe_dictionary(expansion.get("purification_obstacles")).get(str(project.get("required_purification_obstacle_id")), false)
	else:
		# O writer agrega o obstáculo real; uma flag derivada fora de sincronia
		# não pode só falhar depois da reconstrução do GRID no _build_save_data.
		var obstacle_purified: Variant = false
		for obstacle in _get_save_group_nodes("purification_obstacle"):
			if not obstacle.has_method("get_save_data"):
				continue
			var obstacle_state: Dictionary = obstacle.call("get_save_data")
			if str(obstacle_state.get("obstacle_id", "")) == str(project.get("required_purification_obstacle_id")):
				obstacle_purified = obstacle_state.get("purified", false)
				break
		if not (obstacle_purified is bool and obstacle_purified):
			return false
	return restored is bool and restored and purified is bool and purified

func _reconcile_default_recipe_discoveries() -> void:
	# Aprendizado padrão é política do catálogo, não recompensa de load.
	# Independe do Livro estar aberto e não concede itens, XP ou marcos.
	var resolver := DefaultRecipeResolverScript.new()
	for recipe_id in resolver.get_default_unlocked_recipe_ids():
		if not GlobalInventory.receitas_descobertas.has(recipe_id):
			GlobalInventory.receitas_descobertas.append(recipe_id)


func _resolve_well_snapshot(data: Dictionary) -> Dictionary:
	return VillageWellState.resolve_snapshot(data, EconomyManager.poco_capacidade_maxima, EconomyManager.well_improved_by_project, GlobalInventory.skills_desbloqueadas, GroveExpedition.restored)


func _get_save_golem() -> Node:
	var home := _get_save_scene()
	var golem: Node = home.get_node_or_null("Golem") if home != null else null
	return golem if golem != null and not golem.is_queued_for_deletion() and golem.has_method("get_work_save_data") and golem.has_method("load_work_save_data") else null

func _build_golem_save_data() -> Dictionary:
	var golem := _get_save_golem()
	return golem.call("get_work_save_data") if golem != null else GolemWorkState.default_data()

func _saved_grove_restored(data: Dictionary) -> bool:
	# Elegibilidade do snapshot recebido, nunca do progresso atual da sessão.
	var grove: Variant = data.get("grove_expedition")
	return grove is Dictionary and grove.get("restored", false) == true

func _is_golem_save_payload_valid(data: Dictionary) -> bool:
	if not data.has("golem_work"):
		return true
	var work: Variant = data["golem_work"]
	var has_logistics := work is Dictionary and work.get("logistics_cargo") != null
	var grove_restored := _effective_grove_restored(data) if has_logistics else _saved_grove_restored(data)
	if not GolemWorkState.is_valid(work, grove_restored):
		return false
	# Não carregar/descartar carga numa vila sem o seu único golem físico.
	return _get_save_golem() != null


func _seed_delivery_transaction_in_progress() -> bool:
	var golem := _get_save_golem()
	if golem != null and golem.has_method("is_logistics_transaction_in_progress") and bool(golem.call("is_logistics_transaction_in_progress")):
		return true
	for cauldron in _get_cauldron_nodes().values():
		if cauldron.has_method("is_seed_delivery_transaction_in_progress") and bool(cauldron.call("is_seed_delivery_transaction_in_progress")):
			return true
	return false


func _effective_grove_restored(data: Dictionary) -> bool:
	if data.has("grove_expedition"):
		return _saved_grove_restored(data)
	var inventory: Variant = data.get("inventory")
	if inventory is Dictionary and inventory.get("inventario") is Dictionary:
		return false
	return GroveExpedition.restored


func _effective_seed_delivery_snapshot(data: Dictionary) -> Dictionary:
	var inventory: Variant = data.get("inventory")
	var complete := inventory is Dictionary and inventory.get("inventario") is Dictionary
	var states: Dictionary = {}
	var nodes := _get_cauldron_nodes()
	var incoming: Variant = data.get("cauldrons", {})
	for key in nodes:
		if data.has("cauldrons") or complete:
			states[key] = incoming.get(key, {"state": "IDLE"}) if incoming is Dictionary else null
		else:
			states[key] = nodes[key].call("get_save_data")
	var work: Variant = data.get("golem_work", GolemWorkState.default_data() if complete else _build_golem_save_data())
	var has_delivery := work is Dictionary and work.get("logistics_cargo") != null
	for state in states.values():
		if state is Dictionary and (state.get("state") == "SEED_DELIVERY" or state.get("delivery") != null):
			has_delivery = true
	return {"cauldrons": states, "golem": work, "grove_restored": _effective_grove_restored(data), "has_delivery": has_delivery}


func _seed_delivery_snapshot_valid(data: Dictionary) -> bool:
	if data.has("grove_expedition") and not GroveExpedition.is_save_data_valid(data["grove_expedition"]):
		return false
	if not _is_cauldron_save_payload_valid(data):
		return false
	var resolved := _effective_seed_delivery_snapshot(data)
	if not resolved["has_delivery"]:
		return true
	if not resolved["grove_restored"] or _get_save_golem() == null or not GolemWorkState.is_valid(resolved["golem"], true):
		return false
	var nodes := _get_cauldron_nodes()
	var active_order: Variant = null
	for key in resolved["cauldrons"]:
		var state: Variant = resolved["cauldrons"][key]
		if not state is Dictionary or not bool(nodes[key].call("is_save_data_valid", state)):
			return false
		if state.get("state") == "SEED_DELIVERY":
			if active_order != null:
				return false
			active_order = state.get("delivery")
	var cargo: Variant = resolved["golem"].get("logistics_cargo")
	if active_order == null:
		return cargo == null
	return SeedDeliveryOrder.matches_cargo(active_order, cargo)

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
	var scene: Node = _get_save_scene()
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
	var scene: Node = _get_save_scene()
	if scene == null:
		return nodes
	for cauldron in _get_save_group_nodes("cauldrons"):
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


func _is_flame_fertilizer_save_valid(data: Dictionary, source: FarmSaveSource) -> bool:
	if source == FarmSaveSource.NONE:
		return true
	var entries: Variant = _safe_dictionary(data.get("farm_grid", {})).get("tiles", []) if source == FarmSaveSource.GRID_V4 else data.get("farm_plots", [])
	if not entries is Array:
		return false
	var seen_cells := {}
	for entry in entries:
		if not entry is Dictionary:
			continue
		if not FarmTileData.is_flame_fertilizer_valid(entry):
			return false
		if source == FarmSaveSource.GRID_V4:
			var cell := _living_soil_cell(entry)
			var applied: bool = entry.get("flame_fertilizer_applied", false)
			if applied and cell == Vector2i(-1, -1):
				return false
			if seen_cells.has(cell) and (applied or seen_cells[cell]):
				return false
			seen_cells[cell] = applied
	return true


func _living_soil_cell(entry: Dictionary) -> Vector2i:
	var position: Variant = entry.get("grid_position", {})
	if position is Vector2i:
		return position
	if position is Dictionary:
		var x: Variant = position.get("x")
		var y: Variant = position.get("y")
		if typeof(x) in [TYPE_INT, TYPE_FLOAT] and typeof(y) in [TYPE_INT, TYPE_FLOAT] \
			and is_finite(float(x)) and is_finite(float(y)) and float(x) == float(int(x)) and float(y) == float(int(y)):
			return Vector2i(int(x), int(y))
	return Vector2i(-1, -1)


func _is_growth_charges_valid(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0 and float(value) == float(int(value))


func _living_soil_plot_cell(plot: Node) -> Vector2i:
	var home := _get_save_scene()
	return Vector2i(2, 2) if home != null and home.has_method("is_living_soil_pilot_plot") and home.is_living_soil_pilot_plot(plot) else Vector2i(-1, -1)


func _is_living_soil_save_valid(data: Dictionary, source: FarmSaveSource) -> bool:
	var entries: Variant = _safe_dictionary(data.get("farm_grid", {})).get("tiles", []) if source == FarmSaveSource.GRID_V4 else data.get("farm_plots", [])
	if source == FarmSaveSource.NONE:
		return true
	if not entries is Array:
		return false
	var plots := _get_save_group_nodes("lotes_terra")
	var seen_treated := false
	var seen_pilot := false
	for index in range(entries.size()):
		var entry: Variant = entries[index]
		if not entry is Dictionary:
			continue
		var cell := _living_soil_cell(entry) if source == FarmSaveSource.GRID_V4 else (_living_soil_plot_cell(plots[index]) if index < plots.size() else Vector2i(-1, -1))
		if source == FarmSaveSource.GRID_V4 and cell == Vector2i(2, 2):
			if seen_pilot:
				return false
			seen_pilot = true
		if not LivingSoilState.validate_flags(entry, cell):
			return false
		if entry.get("living_soil_treated", false):
			if seen_treated:
				return false
			seen_treated = true
	return true


func _with_living_soil_partial_defaults(data: Dictionary, source: FarmSaveSource) -> Dictionary:
	# Completo legado começa comum; payload parcial preserva flags ausentes.
	if _safe_dictionary(data.get("inventory", {})).get("inventario") is Dictionary or source == FarmSaveSource.NONE:
		return data
	var result := data.duplicate(true)
	var entries: Variant = _safe_dictionary(result.get("farm_grid", {})).get("tiles", []) if source == FarmSaveSource.GRID_V4 else result.get("farm_plots", [])
	if not entries is Array:
		return result
	var plots := _get_save_group_nodes("lotes_terra")
	var home := _get_save_scene()
	for index in range(entries.size()):
		if not entries[index] is Dictionary:
			continue
		var entry: Dictionary = entries[index]
		var plot: Node = home.call("obter_farm_plot_por_grid_position", _living_soil_cell(entry)) if source == FarmSaveSource.GRID_V4 and home != null and home.has_method("obter_farm_plot_por_grid_position") else (plots[index] if source == FarmSaveSource.LEGACY_PLOTS and index < plots.size() else null)
		if plot == null or not plot.has_method("get_save_data"):
			continue
		var current: Dictionary = plot.get_save_data()
		for flag in ["living_soil_treated", "living_soil_moisture"]:
			if not entry.has(flag):
				entry[flag] = current.get(flag, false)
	return result

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

	var chests: Array = _get_save_group_nodes("village_chest")
	for chest in chests:
		if is_instance_valid(chest):
			return chest

	return null


func _get_save_scene() -> Node:
	var current: Node = get_tree().current_scene
	if current != null and current.has_method("obter_farm_grid_save_data"):
		return current
	var home: Node = RegionTravelCoordinator.get_cached_region_scene(&"farm_village")
	return home if home != null else current


func _get_save_group_nodes(group_name: String) -> Array:
	var scene: Node = _get_save_scene()
	if scene == null:
		return get_tree().get_nodes_in_group(group_name)
	var nodes: Array = []
	_collect_group_nodes(scene, group_name, nodes)
	return nodes


func _collect_group_nodes(parent: Node, group_name: String, nodes: Array) -> void:
	# get_nodes_in_group não inclui os filhos da vila em cache fora da árvore.
	if parent.is_in_group(group_name):
		nodes.append(parent)
	for child in parent.get_children():
		_collect_group_nodes(child, group_name, nodes)

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
			"pronto_para_colher": false,
			"flame_fertilizer_applied": tile.flame_fertilizer_applied
		}

	var regado: bool = tile.is_watered or tile.tile_state == FarmTileData.TileState.MOLHADO
	if tile.crop_id == "":
		return {
			"estado_atual": 0,
			"semente_id_plantada": "",
			"regado": regado,
			"arado": tile.tile_state != FarmTileData.TileState.GRAMA,
			"tempo_restante": 0.0,
			"tempo_total_crescimento": 0.0,
			"pronto_para_colher": false,
			"living_soil_treated": tile.living_soil_treated,
			"living_soil_moisture": tile.living_soil_moisture,
			"flame_fertilizer_applied": tile.flame_fertilizer_applied
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
		"pending_harvest_rewards": tile.pending_harvest_rewards.duplicate(true),
		"living_soil_treated": tile.living_soil_treated,
		"living_soil_moisture": tile.living_soil_moisture,
		"flame_fertilizer_applied": tile.flame_fertilizer_applied
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
