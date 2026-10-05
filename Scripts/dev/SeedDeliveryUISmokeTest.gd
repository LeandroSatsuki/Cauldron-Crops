extends Node

const MAIN := preload("res://Scenes/Main.tscn")
var home: Node
var cauldron: Node
var golem: Node
var book: Panel
var ui: Node
var choice: CheckButton
var hint: Label
var scroll: ScrollContainer
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "APPDATA isolado obrigatório")
		return _finish()
	for service in [PocoManager, GroveExpedition, HerbariumProduction, EventDirector]: service.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 600)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	ui = home.get_node("UI")
	cauldron = home.get_node("CauldronUI")
	golem = home.get_node("Golem")
	(golem.get("_think_timer") as Timer).stop()
	golem.set_physics_process(false)
	golem.call("set_work_priority", 4)
	book = ui.get("recipe_book")
	choice = book.get("_delivery_destination")
	hint = book.get("_delivery_hint")
	scroll = book.get_node("MarginContainer/VBoxRoot/Body/RightPanel")
	GlobalInventory.set_inventory_contents({"trigo": 20, "agua": 10})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	home.get_node("VillageChest").set_contents({"trigo": 20})
	home.get_node("PlayerAvatar").global_position = cauldron.get_node("BaseAnchor").global_position + Vector2(0, 64)
	GroveExpedition.load_save_data({"discovered": false, "restored": false, "forage_sources": {}})
	_open()
	_select("semente_trigo_replantio")
	await _settle()
	_check(choice.visible and choice.disabled and not choice.button_pressed, "gate mantém Mochila padrão")
	_check(hint.text.contains("Clareira"), "requisito explicado")
	await _click(choice)
	_check(not choice.button_pressed, "clique bloqueado não ativa destino")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	book.call("_refresh_recipe_list") # Reconcilia receitas do novo gate antes do clique.
	book.call("_update_delivery_controls")
	_check(not choice.disabled, "Clareira libera escolha sem ligar golem")
	var position_before: Vector2 = home.get_node("PlayerAvatar").global_position
	await _click(choice)
	_check(choice.button_pressed and hint.text.contains("Baú") and hint.text.contains("3 sementes"), "escolha real GUI e rendimento por preparo")
	_check(not book.get("status_label").text.contains("Resultado na Mochila"), "descrição acompanha destino escolhido sem promessa pessoal")
	_check(hint.text.contains("Aguarda") and int(golem.get("work_priority")) == 4, "pausado planeja sem mudar modo")
	_check(home.get_node("PlayerAvatar").global_position == position_before and ToolManager.is_hoe_selected(), "GUI não atravessa mundo ou muda ferramenta")
	_check(not bool(golem.get("seeding_enabled")), "destino não autorliga semeadura")
	book.set("_craft_quantity", 4)
	book.call("_atualizar_controles_producao", 20)
	_check(hint.text.contains("4 preparos = 12 sementes"), "quantidade finita total visível")
	for size in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = size
		await _settle()
		book.call("_apply_layout")
		await _settle()
		var visible_rect := get_viewport().get_visible_rect()
		_check(visible_rect.encloses(book.get_global_rect()), "Livro cabe em " + str(size))
		_check(book.get_theme_stylebox("panel").bg_color.a == 1.0, "painel opaco " + str(size))
		scroll.ensure_control_visible(choice)
		await _settle()
		_check(scroll.get_global_rect().intersects(choice.get_global_rect()), "destino acessível por scroll " + str(size))
		await _capture("seed-delivery-" + str(size.x) + "x" + str(size.y))
	book.call("fechar")
	_open()
	await _settle()
	_check(not choice.button_pressed, "reabrir volta ao padrão pessoal")
	_select("semente_tomate_recuperacao")
	await _settle()
	_check(choice.visible and not choice.disabled, "receita de Tomate também elegível")
	_check(not book.get("status_label").text.contains("exclusivo de trigo"), "descrição de Tomate respeita semeadura seletiva vigente")
	await _click(choice)
	_select("semente_trigo_replantio")
	_check(not choice.button_pressed, "trocar receita não carrega preferência")
	await _click(choice)
	_check(bool(SaveManager.call("_apply_save_data", {})), "parcial IDLE aceito com intenção aberta")
	_check(not book.visible and not choice.button_pressed and cauldron.call("get_save_data")["state"] == "IDLE", "parcial IDLE limpa intenção sem substituir produção")
	_open()
	_select("semente_trigo_replantio")
	await _click(choice)
	book.set("_craft_quantity", 2)
	book.call("_atualizar_controles_producao", 20)
	await _click(book.get("btn_produce"))
	_check(cauldron.call("get_save_data")["state"] == "SEED_DELIVERY" and not book.visible, "produzir confirma destino logístico e fecha Livro")
	_check(not choice.button_pressed and not bool(golem.get("seeding_enabled")), "nova encomenda não conserva preferência/ON")
	var order: Dictionary = cauldron.call("get_seed_delivery_order_data")
	_check(int(order["total"]) == 2 and int(order["converted"]) == 0, "somente número confirmado reservado")
	cauldron.call("_on_batch_timer_timeout")
	cauldron.call("_perform_primary_interaction")
	_check(cauldron.call("get_save_data")["delivery"]["phase"] == "ready", "clique contextual acompanha sem cancelar/recolher")
	_check(GlobalInventory.get_item_quantity("semente_basica") == 0, "saída logística não entra na Mochila")
	_check(bool(SaveManager.call("_apply_save_data", {})), "load parcial coerente")
	_check(not book.visible and not choice.button_pressed, "load fecha Livro e não deixa intenção ativa")
	cauldron.call("load_save_data", {"state": "IDLE"})
	_open()
	_select("semente_trigo_replantio")
	await _click(book.get("btn_produce"))
	_check(cauldron.call("get_save_data")["state"] == "BATCH", "padrão mantém produção pessoal antiga por clique GUI")
	cauldron.call("cancelar_producao_em_lote")
	_check(ToolManager.is_hoe_selected(), "fechar e cancelar não trocam ferramenta")
	_finish()

func _open() -> void:
	ui.call("abrir_livro_receitas", true, cauldron)

func _select(recipe_id: String) -> void:
	var index: int = book.call("_find_recipe_index", recipe_id)
	_check(index >= 0, "receita disponível no Livro: " + recipe_id)
	if index >= 0: book.call("_show_recipe_by_index", index)

func _click(button: BaseButton) -> void:
	# O conteúdo muda de altura ao trocar receita/destino. Aguarde o layout
	# antes de calcular o scroll, senão o clique de teste cai fora do clip.
	await _settle()
	scroll.ensure_control_visible(button)
	await _settle()
	var center := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.global_position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await _settle()

func _settle() -> void:
	for _frame in range(10): await get_tree().process_frame

func _capture(label: String) -> void:
	if "--capture-seed-delivery-ui" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/SeedDelivery-UI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(get_viewport().get_texture().get_image().save_png(directory + label + ".png") == OK, "captura técnica " + label)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SeedDeliveryUISmokeTest: " + label)

func _finish() -> void:
	print("SeedDeliveryUISmokeTest: %s - %d verificações" % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)
