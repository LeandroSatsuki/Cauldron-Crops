extends Node


const MAIN_SCENE := preload("res://Scenes/Main.tscn")


var _last_failure_reason: String = ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var coordinator: Node = get_tree().root.get_node_or_null("RegionTravelCoordinator")
	if coordinator == null:
		_fail("coordenador de viagens nao foi carregado")
		return
	coordinator.transition_failed.connect(_on_transition_failed)

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
	var growing_plot: Node = farm.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	if growing_plot == null or not growing_plot.has_method("load_save_data"):
		_fail("lote de controle nao foi encontrado para validar tempo inativo")
		return
	growing_plot.call("load_save_data", {
		"estado_atual": 1,
		"semente_id_plantada": "semente_basica",
		"regado": true,
		"arado": true,
		"tempo_restante": 8.0,
		"tempo_total_crescimento": 8.0,
		"pronto_para_colher": false,
	})
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
	for _frame in range(90):
		if not bool(coordinator.call("is_transition_in_progress")):
			break
		await get_tree().process_frame

	var external_region: Node = get_tree().current_scene
	if external_region == null or external_region == farm:
		_fail("cena externa nao se tornou a regiao atual")
		return
	var external_identity: Dictionary = external_region.call("get_current_region_identity")
	var expected_region_id: String = String(outward_gateway.target_region_id)
	if external_identity.get("region_id", "") != expected_region_id:
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
	var inactive_time_before: float = float(growing_plot.call("get_save_data").get("tempo_restante", 0.0))
	await get_tree().create_timer(0.7).timeout

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
	for _frame in range(90):
		if not bool(coordinator.call("is_transition_in_progress")):
			break
		await get_tree().process_frame

	var returned_farm: Node = get_tree().current_scene
	if returned_farm == null or returned_farm.get_instance_id() != farm_instance_id:
		_fail("retorno recriou a Fazenda/Vila em vez de recuperar a mesma instancia")
		return
	if int(returned_farm.get_meta("region_travel_preservation_probe", 0)) != 73:
		_fail("estado runtime da Fazenda/Vila foi perdido durante a viagem")
		return
	var inactive_time_after: float = float(growing_plot.call("get_save_data").get("tempo_restante", 0.0))
	if inactive_time_after >= inactive_time_before - 0.5:
		_fail("tempo do cultivo nao avancou enquanto a Fazenda estava em cache (antes=%.2f depois=%.2f)" % [inactive_time_before, inactive_time_after])
		return
	if returned_farm.call("obter_farm_plot_por_grid_position", Vector2i(0, 0)) != growing_plot:
		_fail("cache da regiao removeu a identidade canonica do lote")
		return
	var return_entry: Dictionary = returned_farm.call("resolve_region_entry", &"from_foraging_grove")
	var returned_player: CharacterBody2D = returned_farm.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if returned_player == null or not returned_player.global_position.is_equal_approx(return_entry.get("global_position", Vector2.ZERO)):
		_fail("familiar nao retornou pela entrada correspondente")
		return
	if coordinator.call("get_cached_region_scene", StringName(expected_region_id)) != external_region:
		_fail("regiao externa nao foi preservada para uma nova visita")
		return
	if bool(coordinator.call("is_input_blocked")) or float(coordinator.call("get_transition_overlay_alpha")) > 0.01:
		_fail("fade nao liberou o input ao terminar a viagem")
		return

	_last_failure_reason = ""
	if not bool(returned_farm.call("request_region_transition", &"missing_region", &"missing_entry", &"test_exit")):
		_fail("pedido para destino invalido nao chegou ao coordenador")
		return
	if bool(returned_farm.call("request_region_transition", &"transition_test_region", &"from_farm", &"duplicate_exit")):
		_fail("pedido duplicado foi aceito durante uma transicao")
		return
	if not bool(coordinator.call("is_input_blocked")):
		_fail("overlay nao bloqueou input durante a transicao")
		return
	for _frame in range(120):
		if not bool(coordinator.call("is_transition_in_progress")):
			break
		await get_tree().process_frame
	if get_tree().current_scene != returned_farm:
		_fail("falha de destino removeu a regiao de origem")
		return
	if _last_failure_reason != "unknown_target_region":
		_fail("falha de destino nao foi comunicada de forma deterministica")
		return
	if bool(coordinator.call("is_input_blocked")) or float(coordinator.call("get_transition_overlay_alpha")) > 0.01:
		_fail("falha de transicao deixou tela ou input bloqueados")
		return
	if not returned_farm.call("peek_pending_region_transition").is_empty():
		_fail("falha de transicao deixou pedido pendente na regiao")
		return

	print("RegionTravelSmokeTest: PASS - ida, retorno, fade, bloqueio e recuperacao de falha estao coerentes.")
	get_tree().quit(0)


func _on_transition_failed(_request: Dictionary, reason: String) -> void:
	_last_failure_reason = reason


func _fail(message: String) -> void:
	push_error("RegionTravelSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
