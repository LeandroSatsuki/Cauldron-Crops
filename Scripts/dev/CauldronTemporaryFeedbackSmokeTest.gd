extends Node
const MAIN := preload("res://Scenes/Main.tscn")
var checks := 0
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var cauldron: Node = main.get_node("CauldronUI")
	var ui: Node = main.get_node("UI")
	var before: Dictionary = cauldron.call("get_save_data")
	var inventory := GlobalInventory.inventario.duplicate(true)
	var chest: VillageChest = main.get_node("VillageChest")
	var storage := chest.get_contents()
	for resolution in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		get_tree().root.size = resolution
		for offset in [Vector2.ZERO, Vector2(1200, -600), Vector2(-900, 700)]:
			get_viewport().get_camera_2d().offset = offset
			get_viewport().get_camera_2d().force_update_scroll()
			cauldron.call("_mostrar_resultado_pendente", "trigo")
			await get_tree().process_frame
			var label: Label
			for child in ui.get_children():
				if child is Label and "resultado permanece" in child.text:
					label = child
			if "--baseline" in OS.get_cmdline_user_args():
				if label != null and not Rect2(Vector2.ZERO, Vector2(resolution)).encloses(label.get_global_rect()):
					print("CauldronTemporaryFeedbackSmokeTest: PASS - baseline reproduziu aviso fora da tela.")
					get_tree().quit(0)
					return
			for frame in range(8):
				await get_tree().process_frame
			if not _check(label != null and Rect2(Vector2.ZERO, Vector2(resolution)).encloses(label.get_global_rect()), "aviso fora da tela"):
				return
			if not _check(label.mouse_filter == Control.MOUSE_FILTER_IGNORE and label.autowrap_mode != TextServer.AUTOWRAP_OFF, "texto captura clique ou não quebra linha"):
				return
	cauldron.call("_mostrar_resultado_pendente", "golem_coletor")
	await get_tree().process_frame
	var active: Label = cauldron.get("_temporary_feedback")
	if not _check("Golems" in active.text, "limite de golems confundido com Mochila"):
		return
	get_tree().root.size = Vector2i(800, 600)
	for frame in range(10):
		await get_tree().process_frame
	if not _check(Rect2(Vector2.ZERO, Vector2(800, 600)).encloses(active.get_global_rect()), "resize com aviso ativo perdeu texto"):
		return
	if not _check(not active.get_global_rect().intersects(ui.get_node("InitialObjectivesPanel").get_global_rect()), "aviso cobre objetivos"):
		return
	for text in ["Produção cancelada", "Lote pronto: 2x Mistura Restauradora!", "Sucesso: 2x Mistura Restauradora!"]:
		cauldron.call("_mostrar_feedback_temporario", text, Color.GREEN)
		await get_tree().process_frame
		active = cauldron.get("_temporary_feedback")
		var count := 0
		for child in ui.get_children():
			if child is Label and child.get_script() == preload("res://Scripts/CauldronFeedbackLabel.gd"):
				count += 1
		if not _check(count == 1 and active.text == text, "aviso anterior empilhado"):
			return
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(1.0).timeout
	if not _check(is_instance_valid(active) and active.modulate.a == 1.0, "aviso saiu antes do tempo de leitura"):
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/TemporaryFeedback"))
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/TemporaryFeedback/notice.png")
	await get_tree().create_timer(4.3).timeout
	if not _check(not is_instance_valid(active), "aviso não encerrou animação"):
		return
	if not _check(cauldron.call("get_save_data") == before and GlobalInventory.inventario == inventory and chest.get_contents() == storage, "feedback alterou produção/estoque"):
		return
	print("CauldronTemporaryFeedbackSmokeTest: PASS - %d verificações." % checks)
	get_tree().quit(0)
func _check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		push_error("CauldronTemporaryFeedbackSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return ok
