extends Node

var automation_enabled: bool = false
var tempo_acumulado: float = 0.0

func _process(delta: float) -> void:
	if not automation_enabled:
		return

	if EconomyManager.total_golems > 0:
		tempo_acumulado += delta
		if tempo_acumulado >= 4.0:
			tempo_acumulado = 0.0
			_colher_automaticamente()

func _colher_automaticamente() -> void:
	var colheitas_permitidas: int = EconomyManager.total_golems * 2
	var colheitas_feitas: int = 0
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var scene: Node = tree.current_scene
	if scene != null and scene.has_method("obter_farm_grid_manager") and scene.has_method("obter_farm_plot_por_grid_position"):
		var grid_manager_variant: Variant = scene.call("obter_farm_grid_manager")
		if grid_manager_variant is FarmGridManager:
			var grid_manager: FarmGridManager = grid_manager_variant
			for tile_variant in grid_manager.get_all_tiles():
				if colheitas_feitas >= colheitas_permitidas:
					break
				if tile_variant is not FarmTileData:
					continue
				var tile: FarmTileData = tile_variant
				if tile.crop_id == "" or tile.remaining_growth_time > 0.0:
					continue
				var plot_variant: Variant = scene.call("obter_farm_plot_por_grid_position", tile.grid_position)
				if plot_variant is Node2D and is_instance_valid(plot_variant):
					var plot: Node2D = plot_variant
					if plot.has_method("harvest_by_golem"):
						var recompensas: Array = plot.call("harvest_by_golem")
						if not recompensas.is_empty():
							colheitas_feitas += 1
							continue

	var lotes: Array = tree.get_nodes_in_group("lotes_terra")
	for lote_variant in lotes:
		if colheitas_feitas >= colheitas_permitidas:
			break
		if lote_variant is not Node:
			continue
		var lote: Node = lote_variant
		if lote.has_method("harvest_by_golem") and lote.has_method("get_save_data"):
			var lote_dados_variant: Variant = lote.call("get_save_data")
			if typeof(lote_dados_variant) == TYPE_DICTIONARY:
				var lote_dados: Dictionary = lote_dados_variant
				if str(lote_dados.get("semente_id_plantada", "")) == "":
					continue
				if float(lote_dados.get("tempo_restante", 0.0)) > 0.0:
					continue
				var recompensas_legacy: Array = lote.call("harvest_by_golem")
				if not recompensas_legacy.is_empty():
					colheitas_feitas += 1
