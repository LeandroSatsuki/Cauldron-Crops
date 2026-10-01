extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const TARGET_POSITION := Vector2i(0, 0)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame

	var target_variant: Variant = main.call("obter_farm_plot_por_grid_position", TARGET_POSITION)
	if not (target_variant is Node2D) or not is_instance_valid(target_variant):
		_fail("plot alvo %s nao foi encontrado" % TARGET_POSITION)
		return
	var target: Node2D = target_variant
	var legacy_tilled: Array = _build_legacy_plots(target, true)
	var grass_grid: Dictionary = _build_single_tile_grid(FarmTileData.TileState.GRAMA)
	if int(SaveManager.call("_read_save_version", {})) != 3:
		_fail("save sem versao nao foi classificado como v3 legado")
		return
	if int(SaveManager.call("_read_save_version", {"version": 4.0})) != 4:
		_fail("numero JSON inteiro nao foi reconhecido como versao 4")
		return
	if int(SaveManager.call("_read_save_version", {"version": "4"})) != -1:
		_fail("versao textual malformada foi aceita")
		return
	if bool(SaveManager.call("_is_save_version_supported", 5)):
		_fail("versao futura foi marcada como suportada")
		return
	var grid_source: int = int(SaveManager.call("_resolve_farm_save_source", {"farm_grid": []}, 4))
	if bool(SaveManager.call("_is_farm_save_payload_valid", {"farm_grid": []}, grid_source)):
		_fail("payload farm_grid malformado foi marcado como valido")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 3,
		"farm_grid": grass_grid,
		"farm_plots": legacy_tilled,
	})):
		_fail("save v3 valido foi recusado")
		return
	if not _is_plot_tilled(target):
		_fail("save v3 nao priorizou o fallback legado")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 4,
		"farm_grid": {},
		"farm_plots": legacy_tilled,
	})):
		_fail("save v4 com grid vazio foi recusado")
		return
	if _is_plot_tilled(target):
		_fail("grid v4 presente e vazio acionou fallback legado")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 4,
		"farm_grid": {"width": 0, "height": 0, "tiles": []},
		"farm_plots": legacy_tilled,
	})):
		_fail("save v4 com lista de tiles vazia foi recusado")
		return
	if _is_plot_tilled(target):
		_fail("grid v4 sem tiles acionou fallback legado")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 4,
		"farm_plots": legacy_tilled,
	})):
		_fail("save v4 sem farm_grid nao aceitou fallback legado")
		return
	if not _is_plot_tilled(target):
		_fail("save v4 sem farm_grid nao aplicou fallback legado")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"version": 4,
		"farm_grid": grass_grid,
		"farm_plots": legacy_tilled,
	})):
		_fail("save v4 com grid foi recusado")
		return
	if _is_plot_tilled(target):
		_fail("save v4 com grid presente aplicou dados legados conflitantes")
		return

	_set_plot_tilled(target, false)
	if not bool(SaveManager.call("_apply_save_data", {
		"farm_plots": legacy_tilled,
	})):
		_fail("save sem versao nao foi reconhecido como legado")
		return
	if not _is_plot_tilled(target):
		_fail("save sem versao nao aplicou fallback legado")
		return

	if get_tree().get_nodes_in_group("lotes_terra").size() != 34:
		_fail("testes de contrato alteraram a quantidade de plots")
		return
	if not _test_backpack_round_trips(main.get_node("UI")):
		return

	print(
		"SaveContractSmokeTest: PASS - grid v4, legado e Mochila vazia/parcial/cheia preservam o contrato."
	)
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _test_backpack_round_trips(ui: Node) -> bool:
	var original_save: Dictionary = SaveManager.call("_build_save_data")
	var original_tool: int = ToolManager.get_active_tool()
	var original_capacity: bool = GlobalInventory.is_capacity_enforced()
	var full: Dictionary = {"semente_basica": 100, "agua": 7}
	for index in range(10):
		full["item_teste_%02d" % index] = 99
	var cases: Array[Dictionary] = [
		{"name": "vazia", "contents": {}, "slots": 0, "seed": ""},
		{"name": "parcial", "contents": {"semente_basica": 100, "trigo": 1, "agua": 7}, "slots": 3, "seed": "semente_basica"},
		{"name": "cheia", "contents": full, "slots": 12, "seed": "semente_basica"},
	]
	for test_case in cases:
		ToolManager.clear_tool()
		GlobalInventory.set_inventory_contents(test_case["contents"])
		GlobalInventory.semente_selecionada = test_case["seed"]
		var entries_before: Array[Dictionary] = GlobalInventory.get_personal_slot_entries()
		# JSON pode ordenar as chaves; posicoes fisicas nao fazem parte do save v4.
		entries_before.sort_custom(_slot_entry_less)
		var save_data: Dictionary = SaveManager.call("_build_save_data")
		if int(save_data["version"]) != 4 or not (save_data["inventory"]["inventario"] is Dictionary):
			_fail("pilhas visuais alteraram o formato do save v4")
			return false
		# Serializacao real em memoria, sem tocar no save pessoal do jogador.
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(save_data))
		GlobalInventory.set_inventory_contents({"item_adicionado_apos_save": 42, "agua": 99})
		ToolManager.force_select_fishing_rod()
		if not bool(SaveManager.call("_apply_save_data", parsed)):
			_fail("round-trip de Mochila %s foi recusado" % test_case["name"])
			return false
		var expected: Dictionary = test_case["contents"].duplicate(true)
		# O contrato legado restaura a reserva do poco, inclusive quando zero.
		expected["agua"] = int(expected.get("agua", 0))
		var entries_after: Array[Dictionary] = GlobalInventory.get_personal_slot_entries()
		entries_after.sort_custom(_slot_entry_less)
		if GlobalInventory.inventario != expected or entries_after != entries_before:
			_fail("round-trip %s perdeu, duplicou ou redistribuiu quantidades" % test_case["name"])
			return false
		if GlobalInventory.semente_selecionada != test_case["seed"]:
			_fail("round-trip %s nao preservou selecao valida" % test_case["name"])
			return false
		if test_case["seed"] != "" and ToolManager.get_active_tool() != ToolManager.ToolType.NONE:
			_fail("load deixou semente e ferramenta simultaneamente selecionadas")
			return false
		ui.call("atualizar_inventario_visual")
		var bar: HBoxContainer = ui.get("inventory_bar")
		var label: Label = ui.get("inventory_capacity_label")
		if bar.get_child_count() != 12 or label.text != "%d/12" % int(test_case["slots"]):
			_fail("round-trip %s deixou a ocupacao visual incorreta" % test_case["name"])
			return false
		if GlobalInventory.is_capacity_enforced() != original_capacity:
			_fail("load ativou a capacidade da Mochila")
			return false
	for invalid_seed in ["semente_ausente", "semente_basica", "trigo"]:
		if not bool(SaveManager.call("_apply_save_data", {
			"version": 4,
			"inventory": {"inventario": {"semente_basica": 0, "trigo": 1}, "semente_selecionada": invalid_seed},
		})) or GlobalInventory.semente_selecionada != "":
			_fail("load manteve selecao ausente, esgotada ou nao-semente")
			return false
	SaveManager.call("_apply_save_data", original_save)
	ToolManager.force_select_tool(original_tool)
	ui.call("atualizar_inventario_visual")
	return true


func _slot_entry_less(first: Dictionary, second: Dictionary) -> bool:
	if first["item_id"] != second["item_id"]:
		return str(first["item_id"]) < str(second["item_id"])
	return int(first["stack_index"]) < int(second["stack_index"])


func _build_legacy_plots(target: Node2D, tilled: bool) -> Array:
	var result: Array = []
	for plot_variant in get_tree().get_nodes_in_group("lotes_terra"):
		result.append(_plot_save_data(tilled if plot_variant == target else false))
	return result


func _build_single_tile_grid(tile_state: FarmTileData.TileState) -> Dictionary:
	var manager := FarmGridManager.new()
	var tile := FarmTileData.new()
	tile.tile_state = tile_state
	manager.set_tile(TARGET_POSITION, tile)
	return manager.to_save_data()


func _set_plot_tilled(plot: Node2D, tilled: bool) -> void:
	plot.call("load_save_data", _plot_save_data(tilled))


func _is_plot_tilled(plot: Node2D) -> bool:
	var save_data_variant: Variant = plot.call("get_save_data")
	if typeof(save_data_variant) != TYPE_DICTIONARY:
		return false
	return bool((save_data_variant as Dictionary).get("arado", false))


func _plot_save_data(tilled: bool) -> Dictionary:
	return {
		"estado_atual": 0,
		"semente_id_plantada": "",
		"regado": false,
		"arado": tilled,
		"tempo_restante": 0.0,
		"tempo_total_crescimento": 0.0,
		"pronto_para_colher": false,
	}


func _fail(message: String) -> void:
	push_error("SaveContractSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
