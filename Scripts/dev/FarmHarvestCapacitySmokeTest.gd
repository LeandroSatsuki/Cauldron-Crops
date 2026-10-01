extends Node

const FARM_PLOT_SCENE := preload("res://Scenes/FarmPlot.tscn")

var _original_inventory: Dictionary = {}
var _original_seed: String = ""
var _original_enforcement: bool = false
var _original_season: int = 0
var _plot: Node = null


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	_original_seed = GlobalInventory.semente_selecionada
	_original_enforcement = GlobalInventory.is_capacity_enforced()
	_original_season = SeasonManager.estacao_atual
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA

	_plot = FARM_PLOT_SCENE.instantiate()
	add_child(_plot)
	await get_tree().process_frame
	_plot.call("load_save_data", {
		"estado_atual": 2,
		"semente_id_plantada": "semente_basica",
		"regado": true,
		"arado": true,
		"tempo_restante": 0.0,
		"tempo_total_crescimento": 3.0,
		"pronto_para_colher": true,
	})

	var full_inventory: Dictionary = {"agua": 5}
	for index in range(GlobalInventory.PERSONAL_SLOT_CAPACITY):
		full_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	GlobalInventory.set_inventory_contents(full_inventory)
	GlobalInventory.set_capacity_enforced(true)
	var before_attempt := GlobalInventory.inventario.duplicate(true)
	if bool(_plot.call("_colher_manualmente", false)):
		return _fail("colheita foi concluida sem espaco")
	if GlobalInventory.inventario != before_attempt:
		return _fail("colheita recusada alterou a Mochila")
	var blocked_state: Dictionary = _plot.call("get_save_data")
	if not bool(blocked_state.get("pronto_para_colher", false)) or str(blocked_state.get("semente_id_plantada", "")) != "semente_basica":
		return _fail("lote deixou de estar pronto apos recusa")
	var pending_before: Array = (_plot.get("_pending_manual_harvest_rewards") as Array).duplicate(true)
	if pending_before.is_empty():
		return _fail("recompensas recusadas nao ficaram pendentes")

	for index in range(GlobalInventory.PERSONAL_SLOT_CAPACITY):
		if not GlobalInventory.remover_item("item_teste_%02d" % index, GlobalInventory.DEFAULT_STACK_LIMIT):
			return _fail("nao foi possivel liberar slots do teste")
	if not bool(_plot.call("_colher_manualmente", false)):
		return _fail("colheita permaneceu bloqueada apos liberar espaco")
	var harvested_state: Dictionary = _plot.call("get_save_data")
	if bool(harvested_state.get("pronto_para_colher", true)) or str(harvested_state.get("semente_id_plantada", "")) != "":
		return _fail("colheita aceita nao concluiu o lote")
	for reward_variant in pending_before:
		if reward_variant is Dictionary:
			var reward: Dictionary = reward_variant
			var item_id := str(reward.get("item_id", ""))
			var quantity := int(reward.get("quantidade", 0))
			if item_id != "" and GlobalInventory.get_item_quantity(item_id) < quantity:
				return _fail("recompensa pendente nao foi entregue")

	_restore_state()
	print("FarmHarvestCapacitySmokeTest: PASS - colheita manual preserva lote e recompensa quando a Mochila nao comporta o lote inteiro.")
	get_tree().quit(0)


func _restore_state() -> void:
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.set_inventory_contents(_original_inventory)
	GlobalInventory.semente_selecionada = _original_seed
	GlobalInventory.set_capacity_enforced(_original_enforcement)
	SeasonManager.estacao_atual = _original_season as SeasonManager.Estacao
	if _plot != null and is_instance_valid(_plot):
		_plot.queue_free()


func _fail(message: String) -> void:
	_restore_state()
	push_error("FarmHarvestCapacitySmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
