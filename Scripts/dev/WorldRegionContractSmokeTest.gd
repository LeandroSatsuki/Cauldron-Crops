extends Node


const MAIN_SCENE := preload("res://Scenes/Main.tscn")


var _published_transition: Dictionary = {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame

	var identity: Dictionary = main.call("get_current_region_identity")
	if identity.get("region_id", "") != "farm_village":
		_fail("identidade da regiao principal ausente ou incorreta")
		return
	if not bool(identity.get("is_home_region", false)):
		_fail("Fazenda/Vila nao foi marcada como HOME")
		return
	if identity.get("default_entry_id", "") != "village_arrival":
		_fail("entrada padrao da regiao nao foi declarada")
		return

	var entry: Dictionary = main.call("resolve_region_entry", &"village_arrival")
	var player: CharacterBody2D = main.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if not bool(entry.get("found", false)) or player == null:
		_fail("entrada nomeada ou familiar nao foi encontrado")
		return
	var entry_position: Vector2 = entry.get("global_position", Vector2.ZERO)
	if not player.global_position.is_equal_approx(entry_position):
		_fail("familiar nao iniciou no ponto de entrada declarado")
		return
	if bool(main.call("resolve_region_entry", &"missing_entry").get("found", false)):
		_fail("entrada inexistente foi aceita")
		return

	if bool(main.call("request_region_transition", &"farm_village", &"village_arrival")):
		_fail("transicao redundante para a regiao atual foi aceita")
		return
	if bool(main.call("request_region_transition", &"external_region_test", &"")):
		_fail("transicao sem entrada de destino foi aceita")
		return

	var scene_before_request: Node = get_tree().current_scene
	main.region_transition_requested.connect(_on_region_transition_requested)
	if not bool(main.call("request_region_transition", &"external_region_test", &"from_farm", &"north_exit")):
		_fail("pedido valido de transicao foi rejeitado")
		return
	var pending: Dictionary = main.call("peek_pending_region_transition")
	if pending.get("source_region_id", "") != "farm_village":
		_fail("origem nao foi preservada no contrato de transicao")
		return
	if pending.get("source_exit_id", "") != "north_exit":
		_fail("saida de origem nao foi preservada no contrato de transicao")
		return
	if pending.get("target_region_id", "") != "external_region_test" or pending.get("target_entry_id", "") != "from_farm":
		_fail("destino nao foi preservado no contrato de transicao")
		return
	if _published_transition != pending:
		_fail("mapa principal nao publicou o pedido para a futura camada de mundo")
		return
	if get_tree().current_scene != scene_before_request:
		_fail("o contrato local trocou de cena antes da camada de mundo existir")
		return

	var consumed: Dictionary = main.call("consume_pending_region_transition")
	if consumed != pending or not main.call("peek_pending_region_transition").is_empty():
		_fail("consumo do pedido de transicao nao foi deterministico")
		return

	main.queue_free()
	await get_tree().process_frame
	print("WorldRegionContractSmokeTest: PASS - identidade, entrada e contrato local de transicao estao coerentes.")
	get_tree().quit(0)


func _on_region_transition_requested(request: Dictionary) -> void:
	_published_transition = request


func _fail(message: String) -> void:
	push_error("WorldRegionContractSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
