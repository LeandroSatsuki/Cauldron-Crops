extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().process_frame
	if "--capture-world" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		var path := "user://world_polish.png"
		get_viewport().get_texture().get_image().save_png(path)
		print("World screenshot: ", ProjectSettings.globalize_path(path))

	if main.has_node("FarmBlockoutV0"):
		_fail("guias macro de desenvolvimento continuam visiveis no mapa")
		return
	if main.has_node("FreeFarmingPilotArea"):
		_fail("marcador tecnico de agricultura livre esta ativo por padrao")
		return
	if main.get_node_or_null("FishingSpot") == null or main.get_node_or_null("CauldronUI") == null:
		_fail("limpeza visual removeu um elemento funcional do mapa")
		return
	if get_tree().get_nodes_in_group("lotes_terra").size() != 34:
		_fail("limpeza visual alterou a quantidade de FarmPlots")
		return
	# Executar frames reais: _process não pode sobrescrever a camada do solo.
	var plot: Node = get_tree().get_nodes_in_group("lotes_terra")[0]
	if plot.get_node("ColorRect").color.a != 0.0:
		_fail("lote intocado cobre o terreno com um bloco opaco")
		return
	plot.set("arado", true)
	if "--capture-world" in OS.get_cmdline_user_args():
		# Trazer um único lote ao lado do personagem para inspeção do solo.
		plot.global_position = main.get_node("PlayerAvatar").global_position + Vector2(85, 0)
	plot.call("_atualizar_visual")
	await get_tree().process_frame
	await get_tree().process_frame
	var earth: Sprite2D = plot.get_node("SpriteTerra")
	if not earth.visible or earth.z_as_relative or earth.z_index != -90:
		_fail("solo arado perdeu sua camada absoluta abaixo dos objetos")
		return
	if main.get_node("cenario").z_index >= earth.z_index:
		_fail("terreno cobre a textura do solo arado")
		return
	if plot.get_node("SpritePlanta").z_as_relative != true:
		_fail("planta deixou de acompanhar a profundidade do lote")
		return
	if "--capture-world" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://world_polish_soil.png")
	var lore: Node = main.get_node_or_null("LoreDiscovery_FirstPurifiedArea")
	if lore == null or lore.visible:
		_fail("descoberta de lore nao respeitou o bloqueio inicial")
		return

	print("WorldLayoutCleanupSmokeTest: PASS - terreno/solo/plantas ordenados, lotes vazios transparentes e mapa funcional preservado.")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WorldLayoutCleanupSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
