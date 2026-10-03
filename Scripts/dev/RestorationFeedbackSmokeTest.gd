extends Node

const MAIN := preload("res://Scenes/Main.tscn")
const SITE := preload("res://Scenes/GroveRestorationSite.tscn")
var _checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({"trigo": 1})
	var chest: VillageChest = main.get_node("VillageChest")
	chest.set_contents({"trigo": 3, "agua": 1})
	var herb: Node2D = main.get_node("RestorationProject_FirstHerbarium")
	if not _expect(not herb.visible and not herb.input_pickable, "projeto visível antes da purificação"):
		return
	herb.call("set_area_purified", true)
	var before := GlobalInventory.inventario.duplicate(true)
	var storage := chest.get_contents()
	var state: Dictionary = herb.call("get_save_data")
	var text: String = herb.call("get_requirements_feedback")
	if not _expect("Trigo: 4/5" in text and "Água: 1/1" in text and "Baú da Vila + Mochila" in text, "contador não soma as origens"):
		return
	if not _expect(GlobalInventory.inventario == before and chest.get_contents() == storage and herb.call("get_save_data") == state, "consulta consome recursos/progresso"):
		return
	if not _expect(not herb.call("try_restore") and GlobalInventory.inventario == before and chest.get_contents() == storage, "recusa consumiu recursos"):
		return
	var ui: Node = main.get_node("UI")
	var label: Label = ui.get_child(ui.get_child_count() - 1) as Label
	if not _expect(label != null and "Trigo x1" in label.text and "Baú da Vila primeiro" in label.text and "Nenhum recurso" in label.text, "recusa não explica falta/origem"):
		return
	var previous_label := label
	GlobalInventory.set_inventory_contents({"trigo": 1188})
	chest.set_contents({"trigo": 5, "agua": 1})
	before = GlobalInventory.inventario.duplicate(true)
	if not _expect(not herb.call("try_restore") and chest.get_item_quantity("trigo") == 5 and GlobalInventory.inventario == before, "recompensa bloqueada consumiu custo"):
		return
	label = ui.get_child(ui.get_child_count() - 1) as Label
	if not _expect("1x Rama Encantada" in label.text and "Deposite" in label.text and "Nenhum recurso" in label.text, "recusa não informa recompensa/destino"):
		return
	await get_tree().process_frame
	if not _expect(not is_instance_valid(previous_label) and herb.get("_feedback_label") == label, "aviso novo não substituiu o anterior"):
		return
	chest.deposit_from_personal_inventory("trigo", 99)
	if not _expect(herb.call("try_restore") and GlobalInventory.get_item_quantity("rama_encantada") == 1 and chest.get_item_quantity("trigo") == 99 and not herb.call("try_restore"), "restauração/recompensa não são únicas"):
		return
	if not _expect(not herb.get("prompt_label").visible and herb.call("get_requirements_feedback") == "Herbário restaurado", "requisitos obsoletos após concluir"):
		return
	herb.call("load_save_data", JSON.parse_string(JSON.stringify(state)))
	GlobalInventory.set_inventory_contents({"trigo": 1})
	chest.set_contents(storage)
	herb.call("_process", 0.0)
	if not _expect(herb.get("prompt_label").text == text, "load não reconstrói requisitos"):
		return
	var camera := get_viewport().get_camera_2d()
	camera.position = herb.position + Vector2(0, -100)
	camera.reset_smoothing()
	await _capture("herbarium")
	GroveExpedition.reset_progress()
	var site: GroveRestorationSite = SITE.instantiate()
	site.position = herb.position + Vector2(450, 500)
	main.add_child(site)
	if not _expect(site.get_requirements_feedback() == "Investigar clareira", "requisitos expostos antes de descobrir"):
		return
	if not _expect(site.interact() and GroveExpedition.discovered and not GroveExpedition.restored, "descoberta não permanece gratuita"):
		return
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 1})
	chest.set_contents({GroveExpedition.MIXTURE_ITEM: 10})
	site.call("_process", 0.0)
	text = site.get_requirements_feedback()
	before = GlobalInventory.inventario.duplicate(true)
	if not _expect("1/2" in text and "na Mochila" in text and "não é usado aqui" in text and not site.interact(), "Clareira contou/consumiu Storage remoto"):
		return
	if not _expect(GlobalInventory.inventario == before and chest.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 10 and "Nenhuma mistura" in site.feedback.text and not GroveExpedition.restored, "recusa perdeu mistura/progresso ou não explicou preservação"):
		return
	if not _expect(site.get_requirements_feedback() == text and GlobalInventory.inventario == before, "consulta da Clareira alterou estado"):
		return
	camera.position = site.position + Vector2(0, -130)
	camera.reset_smoothing()
	await _capture("clearing")
	GlobalInventory.set_inventory_contents({GroveExpedition.MIXTURE_ITEM: 2})
	site.call("_process", 0.0)
	if not _expect("2/2" in site.prompt.text and site.interact() and GroveExpedition.restored and GlobalInventory.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 0 and chest.get_item_quantity(GroveExpedition.MIXTURE_ITEM) == 10, "Clareira não consumiu só carga pessoal"):
		return
	var learned := GlobalInventory.receitas_descobertas.duplicate()
	if not _expect(not site.interact() and GlobalInventory.receitas_descobertas == learned and site.prompt.text == "Clareira restaurada", "repetição duplicou receita ou deixou requisitos obsoletos"):
		return
	print("RestorationFeedbackSmokeTest: PASS - %d verificações; origens, contadores, recusa, recompensa, JSON e conclusão única." % _checks)
	get_tree().quit(0)

func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	for frame in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/RestorationFeedback"))
	get_viewport().get_texture().get_image().save_png("res://Builds/QA/RestorationFeedback/" + label + ".png")

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("RestorationFeedbackSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
