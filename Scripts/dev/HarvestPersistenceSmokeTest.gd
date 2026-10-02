extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
var _main: Node
var _plot: Node
var _chest: VillageChest

func _ready() -> void:
	_run.call_deferred()

func _create_world() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = MAIN_SCENE.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().process_frame
	await get_tree().process_frame
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	_plot = _main.call("obter_farm_plot_por_grid_position", Vector2i.ZERO)
	_chest = _main.get_node("VillageChest")

func _run() -> void:
	PocoManager.set_process(false)
	await _create_world()
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_inventory_contents({"trigo": 1188})
	_chest.set_contents({"tomate_sol": 5})
	_plot.call("load_save_data", {"estado_atual": 2, "semente_id_plantada": "semente_basica", "arado": true, "pronto_para_colher": true})
	if not _expect(not _plot.call("_colher_manualmente", false), "colheita coube na mochila cheia"):
		return
	var expected: Dictionary = _plot.call("get_save_data").get("pending_harvest_rewards", {})
	if not _expect(not expected.is_empty() and expected.has("trigo"), "recusa nao preservou sorteio"):
		return
	# Acrescentar raridades conhecidas exercita todos os resultados sem depender de RNG.
	var pending: Array = _plot.get("_pending_manual_harvest_rewards")
	_plot.call("_adicionar_recompensa_colheita", pending, "palha_rara", 1)
	_plot.call("_adicionar_recompensa_colheita", pending, "semente_inverno", 1)
	_plot.call("_notificar_estado_alterado")
	_plot.call("_colher_manualmente", false)
	expected = _plot.call("get_save_data")["pending_harvest_rewards"]
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.call("_build_save_data")))
	var serialized_rewards: Dictionary = _target_tile(saved).get("pending_harvest_rewards", {})
	for item_id in serialized_rewards:
		serialized_rewards[item_id] = int(serialized_rewards[item_id])
	if not _expect(serialized_rewards == expected, "bridge do grid omitiu sorteio recusado"):
		return
	await _create_world()
	seed(89712)
	if not _expect(SaveManager.call("_apply_save_data", saved) and _plot.call("get_save_data")["pending_harvest_rewards"] == expected, "JSON/cena recriada perdeu recompensas"):
		return
	if not _expect(not _plot.call("_colher_manualmente", false) and _plot.call("get_save_data")["pending_harvest_rewards"] == expected, "retry cheio repetiu RNG"):
		return
	GlobalInventory.set_inventory_contents({})
	if not _expect(_plot.call("_colher_manualmente", false) and GlobalInventory.inventario == expected, "retry livre perdeu ou trocou quantidade"):
		return
	if not _expect(not _plot.call("_colher_manualmente", false) and GlobalInventory.inventario == expected and _plot.call("get_save_data")["pending_harvest_rewards"].is_empty(), "colheita concluida repetiu recompensa"):
		return
	for replay in range(2):
		if not _expect(SaveManager.call("_apply_save_data", saved), "replay recusou snapshot"):
			return
		var golem_rewards: Array = _plot.call("harvest_by_golem")
		if not _expect(_totals(golem_rewards) == expected and GlobalInventory.get_item_quantity("trigo") == 1188, "golem repetiu sorteio ou entregou na mochila"):
			return
		for reward in golem_rewards:
			_chest.deposit_item(reward["item_id"], reward["quantidade"])
		if not _expect(_plot.call("harvest_by_golem").is_empty() and _chest.get_item_quantity("palha_rara") == expected["palha_rara"], "golem duplicou colheita"):
			return
	if not _test_invalid_snapshots(saved):
		return
	var legacy := saved.duplicate(true)
	legacy["version"] = 3
	legacy.erase("farm_grid")
	if not _expect(SaveManager.call("_apply_save_data", legacy) and _plot.call("get_save_data")["pending_harvest_rewards"] == expected, "v3 com campo aditivo perdeu pendencia"):
		return
	for tile in saved["farm_grid"]["tiles"]:
		tile.erase("pending_harvest_rewards")
	if not _expect(SaveManager.call("_apply_save_data", saved) and _plot.call("get_save_data")["pending_harvest_rewards"].is_empty() and _plot.get("pronto_para_colher"), "v4 antigo nao limpou pendencia posterior ou perdeu cultura"):
		return
	var tile_data := FarmTileData.new()
	tile_data.pending_harvest_rewards = expected.duplicate()
	tile_data.clear_crop()
	if not _expect(tile_data.pending_harvest_rewards.is_empty(), "clear_crop manteve recompensa orfa"):
		return
	_main.free()
	print("HarvestPersistenceSmokeTest: PASS - sorteio preservado em JSON/grid/v3, retry manual/golem unico, compatibilidade e recusa atomica.")
	get_tree().quit(0)

func _test_invalid_snapshots(saved: Dictionary) -> bool:
	GlobalInventory.set_inventory_contents({"carvao": 3})
	GlobalInventory.award_backpack_milestone("first_herbarium")
	var chest_before: Dictionary = _chest.get_contents()
	var plot_before: Dictionary = _plot.call("get_save_data")
	for invalid_rewards in [null, [], {"trigo": 0}, {"trigo": -1}, {"trigo": true}, {"trigo": 1.5}, {"unknown": 1}]:
		var invalid := saved.duplicate(true)
		_target_tile(invalid)["pending_harvest_rewards"] = invalid_rewards
		if not _expect(not SaveManager.call("_apply_save_data", invalid) and GlobalInventory.inventario == {"carvao": 3} and GlobalInventory.get_slot_capacity() == 16 and _chest.get_contents() == chest_before and _plot.call("get_save_data") == plot_before, "payload invalido alterou estoque/progresso/lote"):
			return false
	for patch in [{"crop_id": ""}, {"remaining_growth_time": 3.0}, {"tile_state": 4}]:
		var invalid := saved.duplicate(true)
		_target_tile(invalid).merge(patch, true)
		if not _expect(not SaveManager.call("_apply_save_data", invalid), "recompensa orfa foi aceita"):
			return false
	return true

func _target_tile(data: Dictionary) -> Dictionary:
	for tile in data["farm_grid"]["tiles"]:
		if int(tile["grid_position"]["x"]) == 0 and int(tile["grid_position"]["y"]) == 0:
			return tile
	return {}

func _totals(rewards: Array) -> Dictionary:
	var result: Dictionary = {}
	for reward in rewards:
		result[reward["item_id"]] = int(result.get(reward["item_id"], 0)) + int(reward["quantidade"])
	return result

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error("HarvestPersistenceSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
