extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const RECIPE := "semente_basica_tomate_sol"
var _main: Node
var _cauldron: Node
var _chest: VillageChest
var _checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	await get_tree().process_frame
	_main = MAIN.instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	_main.process_mode = Node.PROCESS_MODE_DISABLED
	_cauldron = _main.get_node("CauldronUI")
	_chest = _main.get_node("VillageChest")
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents(_full_backpack())
	_chest.set_contents({})
	_cauldron.call("load_save_data", {"state": "BREWING", "result_item": "semente_verao", "result_quantity": 2, "time_remaining": 5.0})
	if not await _check_feedback("Mistura em preparo", "Faltam", false, "brewing"):
		return
	_cauldron.call("load_save_data", {"state": "READY", "result_item": "semente_verao", "result_quantity": 2, "time_remaining": 0.0})
	if not await _check_feedback("Resultado pronto", "Baú da Vila", false, "ready"):
		return
	var snapshot: Dictionary = _cauldron.call("get_save_data")
	_cauldron.call("_perform_primary_interaction")
	if not _expect(_cauldron.call("get_save_data") == snapshot and GlobalInventory.get_item_quantity("semente_verao") == 0, "aviso/recusa modificou resultado pronto"):
		return
	GlobalInventory.remover_item("feedback_probe_0", 99)
	_cauldron.call("_perform_primary_interaction")
	if not _expect(GlobalInventory.get_item_quantity("semente_verao") == 2 and not _cauldron.get("batch_progress_panel").visible, "recolhimento não ocultou aviso ou duplicou resultado"):
		return
	_cauldron.call("load_save_data", {"state": "IDLE"})
	GlobalInventory.set_inventory_contents(_full_backpack())
	_chest.set_contents({"semente_basica": 2, "tomate_sol": 2})
	if not _expect(_cauldron.call("iniciar_producao_em_lote", RECIPE, 2), "lote não iniciou"):
		return
	if not await _check_feedback("Produzindo", "0/2 preparos", true, "batch_running"):
		return
	_cauldron.call("_processar_tick_lote")
	if not await _check_feedback("Lote pausado", "recolher e retomar", true, "batch_waiting"):
		return
	var waiting: Dictionary = JSON.parse_string(JSON.stringify(_cauldron.call("get_save_data")))
	_cauldron.call("load_save_data", waiting)
	if not await _check_feedback("Lote pausado", "Mochila", true, "batch_loaded"):
		return
	GlobalInventory.remover_item("feedback_probe_0", 99)
	_cauldron.call("_perform_primary_interaction")
	if not _expect(GlobalInventory.get_item_quantity("semente_verao") == 2 and _cauldron.get("_batch_quantidade_concluida") == 1, "retomada entregou quantidade indevida"):
		return
	_cauldron.get("btn_cancelar_producao").pressed.emit()
	if not _expect(not _cauldron.get("batch_progress_panel").visible and _chest.get_item_quantity("semente_basica") == 1, "cancelamento pela UI falhou"):
		return
	GlobalInventory.set_inventory_contents({"semente_basica": 1, "tomate_sol": 2})
	_chest.set_contents({"semente_basica": 2, "tomate_sol": 1})
	_cauldron.call("iniciar_producao_em_lote", RECIPE, 3)
	GlobalInventory.set_inventory_contents(_full_backpack())
	_cauldron.get("btn_cancelar_producao").pressed.emit()
	if not await _check_feedback("Cancelamento pendente", "Ingredientes ainda reservados", true, "cancel_pending"):
		return
	if not _expect(_cauldron.get("btn_cancelar_producao").text == "Tentar cancelar novamente" and not _cauldron.get("batch_progress_bar").visible, "cancelamento pendente parece produção ativa"):
		return
	var pending: Dictionary = JSON.parse_string(JSON.stringify(_cauldron.call("get_save_data")))
	_cauldron.call("load_save_data", pending)
	if not await _check_feedback("Cancelamento pendente", "Libere espaço", true, "cancel_loaded"):
		return
	GlobalInventory.remover_item("feedback_probe_0", 99)
	GlobalInventory.remover_item("feedback_probe_1", 99)
	_cauldron.get("btn_cancelar_producao").pressed.emit()
	if not _expect(_cauldron.get("estado_atual") == "IDLE" and GlobalInventory.get_item_quantity("semente_basica") == 1 and GlobalInventory.get_item_quantity("tomate_sol") == 2 and not _cauldron.get("batch_progress_panel").visible, "nova tentativa perdeu reserva ou deixou aviso obsoleto"):
		return
	EconomyManager.total_golems = EconomyManager.max_golems
	_cauldron.call("load_save_data", {"state": "READY", "result_item": "golem_coletor", "result_quantity": 1, "time_remaining": 0.0})
	if not await _check_feedback("Resultado pronto", "capacidade de golems", false, "legacy_golem"):
		return
	print("CauldronFeedbackSmokeTest: PASS - %d verificações; estados, tela/câmera, JSON, retry, entrega e refund." % _checks)
	get_tree().quit(0)

func _check_feedback(title: String, hint: String, can_cancel: bool, capture_label: String) -> bool:
	var before: Dictionary = _cauldron.call("get_save_data")
	var stock := GlobalInventory.inventario.duplicate(true)
	var storage := _chest.get_contents()
	var feedback: Dictionary = _cauldron.call("get_production_feedback")
	_cauldron.call("_atualizar_interface_lote")
	if not _expect(feedback["title"].contains(title) and feedback["hint"].contains(hint) and feedback["can_cancel"] == can_cancel, "feedback incorreto em " + capture_label):
		return false
	if not _expect(_cauldron.call("get_save_data") == before and GlobalInventory.inventario == stock and _chest.get_contents() == storage, "apresentação modificou estado/estoques"):
		return false
	var panel: Control = _cauldron.get("batch_progress_panel")
	for resolution in [Vector2i(1280, 720), Vector2i(800, 720), Vector2i(1024, 768)]:
		get_tree().root.size = resolution
		for frame in range(8):
			await get_tree().process_frame
		if not _expect(panel.visible and Rect2(Vector2.ZERO, Vector2(resolution)).encloses(panel.get_global_rect()), "status fora da tela em %s: %s" % [resolution, panel.get_global_rect()]):
			return false
		if not _expect(panel.mouse_filter == Control.MOUSE_FILTER_STOP and panel.get_global_rect().encloses(_cauldron.get("batch_status_label").get_global_rect()) and panel.get_global_rect().encloses(_cauldron.get("production_hint_label").get_global_rect()), "texto/input não contido no painel"):
			return false
	var original_rect := panel.get_global_rect()
	var camera := get_viewport().get_camera_2d()
	camera.offset += Vector2(100, 100)
	camera.zoom = Vector2(1.5, 1.5)
	await get_tree().process_frame
	if not _expect(panel.get_global_rect() == original_rect, "câmera deslocou aviso de tela"):
		return false
	# HOME é removida da árvore e reutilizada na viagem; ready não repete.
	var status_layer := panel.get_parent()
	_cauldron.remove_child(status_layer)
	get_tree().root.size = Vector2i(800, 720)
	await get_tree().process_frame
	_cauldron.add_child(status_layer)
	for frame in range(8):
		await get_tree().process_frame
	if not _expect(Rect2(Vector2.ZERO, Vector2(800, 720)).encloses(panel.get_global_rect()) and _cauldron.call("get_save_data") == before, "retorno em cache deixou status fora da tela ou alterou produção"):
		return false
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var directory := "res://Builds/QA/CauldronFeedback/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		get_viewport().get_texture().get_image().save_png(directory + capture_label + ".png")
	return true

func _full_backpack() -> Dictionary:
	var result := {}
	for index in range(12):
		result["feedback_probe_%d" % index] = 99
	return result

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("CauldronFeedbackSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
