extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const EXPECTED_INITIAL_PLOT_COUNT := 34


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame

	if main.has_node("FarmBlockoutV0") or main.has_node("FreeFarmingPilotArea"):
		_fail("sessao de release ainda possui guias visuais de desenvolvimento")
		return
	if get_tree().get_nodes_in_group("lotes_terra").size() != EXPECTED_INITIAL_PLOT_COUNT:
		_fail("sessao inicial nao possui os %d FarmPlots esperados" % EXPECTED_INITIAL_PLOT_COUNT)
		return
	if main.get_node_or_null("CauldronUI") == null or main.get_node_or_null("FishingSpot") == null:
		_fail("loop ativo da V0 perdeu caldeirao ou pesca")
		return
	if main.get_node_or_null("Golem") == null or get_tree().get_first_node_in_group("golem_rest_point") == null:
		_fail("golem vivo ou ponto de descanso nao estao presentes")
		return
	if main.get_node_or_null("PurificationObstacle") == null:
		_fail("obstaculo de purificacao nao esta presente")
		return
	var lore: Node = main.get_node_or_null("LoreDiscovery_FirstPurifiedArea")
	var restoration: Node = main.get_node_or_null("RestorationProject_FirstHerbarium")
	if lore == null or restoration == null or lore.visible or restoration.visible:
		_fail("conteudo da area purificada nao respeita o bloqueio inicial")
		return

	var snapshot: Dictionary = SaveManager.call("_build_save_data")
	if int(snapshot.get("version", -1)) != SaveManager.SAVE_VERSION:
		_fail("snapshot de release nao usa a versao atual do save")
		return
	var farm_grid: Dictionary = snapshot.get("farm_grid", {})
	if farm_grid.is_empty():
		_fail("snapshot de release nao possui grid agricola")
		return
	var expansion: Dictionary = snapshot.get("farm_expansion", {})
	if not expansion.has("purification_obstacles") or not expansion.has("restoration_projects"):
		_fail("snapshot de release nao possui estados de expansao e restauracao")
		return
	var inventory: Dictionary = snapshot.get("inventory", {})
	if not inventory.has("colecao_pesca_descobertas") or not inventory.has("lore_descobertas"):
		_fail("snapshot de release nao preserva progresso opcional")
		return

	main.queue_free()
	await get_tree().process_frame
	print("V0ReleaseSmokeTest: PASS - sessao inicial, loops da V0 e contrato de save estao prontos para validacao manual.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("V0ReleaseSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
