extends Node


const MAIN_SCENE := preload("res://Scenes/Main.tscn")


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
	await get_tree().process_frame
	if coordinator.call("get_active_region_id") != "farm_village":
		_fail("Fazenda/Vila nao foi registrada como regiao ativa")
		return

	farm.set_meta("region_travel_preservation_probe", 73)
	var farm_instance_id: int = farm.get_instance_id()
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var outward_gateway: RegionGateway = farm.get_node_or_null("ExternalPathGateway") as RegionGateway
	if outward_gateway == null:
		_fail("portal fisico de saida nao foi encontrado na Fazenda/Vila")
		return
	if not bool(farm.call(
		"request_player_interaction",
		outward_gateway,
		outward_gateway.global_position,
		outward_gateway.interaction_distance,
		Callable(outward_gateway, "activate")
	)):
		_fail("aproximacao ao portal de saida foi rejeitada")
		return
	for _frame in range(420):
		await get_tree().physics_frame
		if get_tree().current_scene != farm:
			break

	var external_region: Node = get_tree().current_scene
	if external_region == null or external_region == farm:
		_fail("cena externa nao se tornou a regiao atual")
		return
	var external_identity: Dictionary = external_region.call("get_current_region_identity")
	if external_identity.get("region_id", "") != "transition_test_region":
		_fail("identidade da cena externa esta incorreta")
		return
	var external_entry: Dictionary = external_region.call("resolve_region_entry", &"from_farm")
	var external_player: CharacterBody2D = external_region.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if external_player == null or not external_player.global_position.is_equal_approx(external_entry.get("global_position", Vector2.ZERO)):
		_fail("familiar nao chegou pela entrada correta da regiao externa")
		return
	if farm.is_inside_tree():
		_fail("Fazenda/Vila continuou processando enquanto estava fora da arvore")
		return

	var return_gateway: RegionGateway = external_region.get_node_or_null("ReturnGateway") as RegionGateway
	if return_gateway == null:
		_fail("portal fisico de retorno nao foi encontrado")
		return
	if not bool(external_region.call(
		"request_player_interaction",
		return_gateway,
		return_gateway.global_position,
		return_gateway.interaction_distance,
		Callable(return_gateway, "activate")
	)):
		_fail("aproximacao ao portal de retorno foi rejeitada")
		return
	for _frame in range(300):
		await get_tree().physics_frame
		if get_tree().current_scene == farm:
			break

	var returned_farm: Node = get_tree().current_scene
	if returned_farm == null or returned_farm.get_instance_id() != farm_instance_id:
		_fail("retorno recriou a Fazenda/Vila em vez de recuperar a mesma instancia")
		return
	if int(returned_farm.get_meta("region_travel_preservation_probe", 0)) != 73:
		_fail("estado runtime da Fazenda/Vila foi perdido durante a viagem")
		return
	var return_entry: Dictionary = returned_farm.call("resolve_region_entry", &"from_transition_test")
	var returned_player: CharacterBody2D = returned_farm.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if returned_player == null or not returned_player.global_position.is_equal_approx(return_entry.get("global_position", Vector2.ZERO)):
		_fail("familiar nao retornou pela entrada correspondente")
		return
	if coordinator.call("get_cached_region_scene", &"transition_test_region") != external_region:
		_fail("regiao externa nao foi preservada para uma nova visita")
		return

	print("RegionTravelSmokeTest: PASS - ida, retorno, entradas e preservacao em memoria estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RegionTravelSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
