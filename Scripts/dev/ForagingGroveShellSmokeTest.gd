extends Node


const GROVE_SCENE := preload("res://Scenes/ForagingGroveRegion.tscn")
const EXPECTED_BOUNDS := Rect2(0.0, 0.0, 2560.0, 1440.0)
const NAVIGABLE_SAMPLES := [
	Vector2(340.0, 720.0),
	Vector2(980.0, 750.0),
	Vector2(1600.0, 300.0),
	Vector2(2160.0, 710.0),
	Vector2(1570.0, 1220.0),
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	var grove: Node2D = GROVE_SCENE.instantiate() as Node2D
	if grove == null:
		_fail("a cena do bosque nao pode ser instanciada")
		return
	get_tree().root.add_child(grove)
	get_tree().current_scene = grove
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var identity: Dictionary = grove.call("get_current_region_identity")
	if identity.get("region_id", "") != "foraging_grove":
		_fail("identidade da regiao esta ausente ou incorreta")
		return
	if identity.get("default_entry_id", "") != "from_farm":
		_fail("entrada padrao nao aponta para a chegada da fazenda")
		return
	if grove.call("get_navigation_bounds") != EXPECTED_BOUNDS:
		_fail("limites navegaveis nao correspondem ao shell planejado")
		return

	var camera: Camera2D = grove.get_node_or_null("MainCamera") as Camera2D
	if camera == null or camera.limit_left != 0 or camera.limit_top != 0 \
		or camera.limit_right != 2560 or camera.limit_bottom != 1440:
		_fail("camera nao respeita os limites declarados da regiao")
		return

	var entry: Dictionary = grove.call("resolve_region_entry", &"from_farm")
	var player: CharacterBody2D = grove.get_node_or_null("PlayerAvatar") as CharacterBody2D
	if not bool(entry.get("found", false)) or player == null:
		_fail("entrada ou familiar nao foi encontrado")
		return
	if not player.global_position.is_equal_approx(entry.get("global_position", Vector2.ZERO)):
		_fail("familiar nao iniciou na entrada declarada")
		return

	var return_gateway: RegionGateway = grove.get_node_or_null("ReturnGateway") as RegionGateway
	if return_gateway == null or return_gateway.target_region_id != &"farm_village" \
		or return_gateway.target_entry_id != &"from_foraging_grove":
		_fail("portal de retorno nao aponta para a entrada correspondente da fazenda")
		return
	if get_tree().get_nodes_in_group("region_landmark").size() < 3:
		_fail("shell nao possui marcos visuais suficientes para orientar a exploracao")
		return
	if not get_tree().get_nodes_in_group("forage_node").is_empty():
		_fail("Fase A introduziu coleta antes da autorizacao")
		return

	for sample: Vector2 in NAVIGABLE_SAMPLES:
		if not bool(grove.call("is_world_position_navigable", sample)):
			_fail("ponto planejado nao e navegavel: %s" % sample)
			return
	if bool(grove.call("is_world_position_navigable", Vector2(300.0, 200.0))):
		_fail("floresta densa fora das trilhas foi aceita como navegavel")
		return
	if bool(grove.call("can_issue_player_move", Vector2(1240.0, 768.0))):
		_fail("colisao do marco central nao bloqueou clique de movimento")
		return

	var destination := Vector2(980.0, 750.0)
	if not bool(grove.call("try_move_player_to", destination)):
		_fail("movimento ate a clareira principal foi rejeitado")
		return
	for _frame in range(360):
		await get_tree().physics_frame
		if player.global_position.distance_to(destination) <= 20.0:
			break
	if player.global_position.distance_to(destination) > 20.0:
		_fail("familiar nao alcancou a clareira principal")
		return
	destination = Vector2(2160.0, 710.0)
	if not bool(grove.call("try_move_player_to", destination)):
		_fail("movimento ate a clareira profunda foi rejeitado")
		return
	for _frame in range(540):
		await get_tree().physics_frame
		if player.global_position.distance_to(destination) <= 20.0:
			break
	if player.global_position.distance_to(destination) > 20.0:
		_fail("familiar nao atravessou o bosque ate a clareira profunda")
		return

	grove.queue_free()
	await get_tree().process_frame
	print("ForagingGroveShellSmokeTest: PASS - shell, navegacao, camera, marcos e retorno estao coerentes; coleta permanece fora da Fase A.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("ForagingGroveShellSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
