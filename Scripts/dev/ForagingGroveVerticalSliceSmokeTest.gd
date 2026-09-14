extends Node


const MAIN_SCENE := preload("res://Scenes/Main.tscn")


var _inventory_before: Dictionary = {}
var _chest_before: Dictionary = {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var coordinator: Node = get_tree().root.get_node_or_null("RegionTravelCoordinator")
	if coordinator == null:
		_fail("coordenador de viagens nao foi carregado")
		return
	var farm: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(farm)
	get_tree().current_scene = farm
	await get_tree().process_frame
	await get_tree().physics_frame
	_inventory_before = GlobalInventory.inventario.duplicate(true)
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var chest: VillageChest = farm.get_node_or_null("VillageChest") as VillageChest
	if chest == null:
		_fail("Village Storage nao foi encontrado na Fazenda/Vila")
		return
	_chest_before = chest.get_contents()
	farm.set_meta("foraging_vertical_slice_probe", 91)
	var farm_instance_id := farm.get_instance_id()
	var initial_charcoal := int(GlobalInventory.inventario.get("carvao", 0))

	var outward_gateway: RegionGateway = farm.get_node_or_null("ExternalPathGateway") as RegionGateway
	if outward_gateway == null or outward_gateway.target_region_id != &"foraging_grove":
		_fail("saida real para o bosque nao esta configurada")
		return
	if not bool(farm.call(
		"request_player_interaction",
		outward_gateway,
		outward_gateway.global_position,
		outward_gateway.interaction_distance,
		Callable(outward_gateway, "activate")
	)):
		_fail("familiar nao aceitou a aproximacao do portal de saida")
		return
	for _frame in range(420):
		await get_tree().physics_frame
		if get_tree().current_scene != farm:
			break
	if get_tree().current_scene == farm:
		_fail("viagem para o bosque nao foi concluida")
		return
	await _wait_for_transition(coordinator)

	var grove: Node = get_tree().current_scene
	if grove == null or grove.call("get_current_region_identity").get("region_id", "") != "foraging_grove":
		_fail("destino nao assumiu a identidade do bosque")
		return
	var forage_node: ForageNode = grove.get_node_or_null("ForageNodes/CharcoalNearEntry") as ForageNode
	var curiosity: GroveFireflyCuriosity = grove.get_node_or_null("FireflyCuriosity") as GroveFireflyCuriosity
	if forage_node == null or curiosity == null:
		_fail("conteudo vertical minimo do bosque esta incompleto")
		return

	if not bool(grove.call(
		"request_player_interaction",
		forage_node,
		forage_node.global_position,
		forage_node.interaction_distance,
		Callable(forage_node, "collect")
	)):
		_fail("coleta proxima da entrada foi rejeitada")
		return
	for _frame in range(300):
		await get_tree().physics_frame
		if forage_node.is_collected():
			break
	if not forage_node.is_collected() or int(GlobalInventory.inventario.get("carvao", 0)) != initial_charcoal + 1:
		_fail("coleta nao entregou exatamente um recurso na Mochila")
		return
	if chest.get_contents() != _chest_before:
		_fail("coleta externa depositou recurso diretamente no Village Storage")
		return

	if not bool(grove.call(
		"request_player_interaction",
		curiosity,
		curiosity.global_position,
		curiosity.interaction_distance,
		Callable(curiosity, "investigate")
	)):
		_fail("curiosidade opcional rejeitou a aproximacao")
		return
	for _frame in range(560):
		await get_tree().physics_frame
		if int(curiosity.get_environment_state().get("reaction_count", 0)) > 0:
			break
	if int(curiosity.get_environment_state().get("reaction_count", 0)) != 1:
		_fail("curiosidade opcional nao reagiu durante a exploracao")
		return
	if int(GlobalInventory.inventario.get("carvao", 0)) != initial_charcoal + 1:
		_fail("curiosidade alterou o resultado da coleta")
		return

	var return_gateway: RegionGateway = grove.get_node_or_null("ReturnGateway") as RegionGateway
	if return_gateway == null or not bool(grove.call(
		"request_player_interaction",
		return_gateway,
		return_gateway.global_position,
		return_gateway.interaction_distance,
		Callable(return_gateway, "activate")
	)):
		_fail("retorno fisico a partir da ramificacao opcional foi rejeitado")
		return
	for _frame in range(760):
		await get_tree().physics_frame
		if get_tree().current_scene == farm:
			break
	if get_tree().current_scene != farm:
		_fail("retorno a Fazenda/Vila nao foi concluido")
		return
	await _wait_for_transition(coordinator)

	var returned_farm: Node = get_tree().current_scene
	if returned_farm.get_instance_id() != farm_instance_id or int(returned_farm.get_meta("foraging_vertical_slice_probe", 0)) != 91:
		_fail("retorno nao preservou a instancia runtime da Fazenda/Vila")
		return
	var return_entry: Dictionary = returned_farm.call("resolve_region_entry", &"from_foraging_grove")
	var returned_player: CharacterBody2D = returned_farm.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if returned_player == null or not returned_player.global_position.is_equal_approx(return_entry.get("global_position", Vector2.ZERO)):
		_fail("familiar nao retornou pela entrada correspondente")
		return
	var cached_grove: Node = coordinator.call("get_cached_region_scene", &"foraging_grove") as Node
	if cached_grove != grove or not forage_node.is_collected() or int(curiosity.get_environment_state().get("reaction_count", 0)) != 1:
		_fail("estado de exploracao nao permaneceu na instancia em cache")
		return
	if chest.get_contents() != _chest_before:
		_fail("Village Storage mudou durante todo o loop externo")
		return

	_restore_state(chest)
	returned_farm.queue_free()
	await get_tree().process_frame
	print("ForagingGroveVerticalSliceSmokeTest: PASS - viajar, explorar, coletar, observar e retornar preserva os contratos do vertical slice.")
	get_tree().quit(0)


func _wait_for_transition(coordinator: Node) -> void:
	for _frame in range(120):
		if not bool(coordinator.call("is_transition_in_progress")):
			return
		await get_tree().process_frame


func _restore_state(chest: VillageChest = null) -> void:
	GlobalInventory.inventario = _inventory_before.duplicate(true)
	if chest != null and is_instance_valid(chest):
		chest.set_contents(_chest_before)


func _fail(message: String) -> void:
	_restore_state()
	push_error("ForagingGroveVerticalSliceSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
