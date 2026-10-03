extends Node

const MAIN_SCENE := preload("res://Scenes/Main.tscn")
const BOOK_SCENE := preload("res://Scenes/RecipeBookUI.tscn")
const Resolver := preload("res://Scripts/data/RecipeResolver.gd")
const RESOLUTIONS: Array[Vector2i] = [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1920, 1080)]
var _checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	PocoManager.set_process(false)
	ToolManager.clear_tool()
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = RESOLUTIONS[0]
	await get_tree().process_frame
	GlobalInventory.set_inventory_contents({"carvao": 20})
	# Catálogo inteiro como fixture de descoberta, sem alterar arquivos de dados.
	GlobalInventory.receitas_descobertas = Resolver.new().get_all_recipe_ids()
	var main := MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	var cauldron: Node = main.get_node("CauldronUI")
	var chest: VillageChest = main.get_node("VillageChest")
	chest.set_contents({"carvao": 4})
	var stock_before: Dictionary = GlobalInventory.inventario.duplicate(true)
	var storage_before := chest.get_contents()
	var popup: Panel = cauldron.get("popup_ui")
	cauldron.call("abrir_popup")
	await _settle()
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await _settle()
		if not _expect(_screen().encloses(popup.get_global_rect()), "caldeirão fora da janela %s" % resolution):
			return
		if resolution.x < 960 and not _expect(not popup.get_global_rect().intersects(main.get_node("UI/InventoryBackdrop").get_global_rect()), "caldeirão cobriu Mochila necessária ao drag"):
			return
		for name in ["TitleLabel", "BtnFechar", "DropSlot1", "DropSlot2", "MisturarButton", "ResultadoLabel", "BtnLivroReceitas"]:
			if not _expect(popup.get_global_rect().encloses(popup.get_node(name).get_global_rect()), "controle %s fora do caldeirão" % name):
				return
		if not _expect(popup.self_modulate.a == 1.0 and (popup.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0 and not popup.get_node("CustomBackground").visible, "fundo do caldeirão ainda transparente"):
			return
		await _capture("cauldron_%d_%d" % [resolution.x, resolution.y])
	popup.position = Vector2(80, 70)
	await _settle()
	if not _expect(popup.position.is_equal_approx(Vector2(80, 70)), "posição arrastada do caldeirão perdida"):
		return
	popup.get_node("DropSlot1").call("_drop_data", Vector2.ZERO, "carvao")
	popup.get_node("DropSlot2").call("_drop_data", Vector2.ZERO, "carvao")
	if not _expect(popup.get_node("DropSlot1").get("item_vinculado") == "carvao" and popup.call("_can_drop_data", Vector2.ZERO, "trigo"), "contrato de drop alterado"):
		return
	popup.get_node("BtnLivroReceitas").pressed.emit()
	await _settle()
	var ui: Node = main.get_node("UI")
	var book: Panel = ui.get("recipe_book")
	if not _expect(book != null and book.visible and not popup.visible, "Livro não substituiu popup do caldeirão"):
		return
	var details: ScrollContainer = book.get_node("MarginContainer/VBoxRoot/Body/RightPanel")
	if not _expect((book.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0, "Livro não tem fundo opaco"):
		return
	for resolution in RESOLUTIONS:
		get_tree().root.size = resolution
		await _settle()
		if not _expect(_screen().encloses(book.get_global_rect()), "Livro fora da janela %s" % resolution):
			return
		if not _expect(book.get_global_rect().encloses(book.get("btn_close").get_global_rect()) and book.get_global_rect().encloses(book.get("recipe_list").get_global_rect()) and book.get_global_rect().encloses(details.get_global_rect()), "cabeçalho/lista/detalhes cortados"):
			return
		for index in range(book.get("recipe_list").item_count):
			book.get("recipe_list").select(index)
			book.get("recipe_list").item_selected.emit(index)
			await _settle()
			details.ensure_control_visible(book.get("btn_produce"))
			await _settle()
			if not _expect(details.get_global_rect().encloses(book.get("btn_produce").get_global_rect()), "botão Produzir inacessível por rolagem"):
				return
		await _capture("book_%d_%d" % [resolution.x, resolution.y])
	# Descrição sintética longa testa clipping/rolagem sem alterar catálogo ou save.
	book.position = Vector2(30, 25)
	await _settle()
	if not _expect(book.position.is_equal_approx(Vector2(30, 25)), "posição arrastada do Livro perdida"):
		return
	book.get("status_label").text = "Informação longa de receita para testar rolagem. ".repeat(40)
	await _settle()
	details.ensure_control_visible(book.get("btn_produce"))
	await _settle()
	if not _expect(details.get_v_scroll_bar().max_value > details.size.y and details.get_global_rect().encloses(book.get("btn_produce").get_global_rect()), "texto longo ocultou ações de produção"):
		return
	get_tree().root.size = Vector2i(800, 600)
	await _settle()
	if not _expect(_screen().encloses(book.get_global_rect()), "resize com detalhes longos esticou painel"):
		return
	# Restaurar receita real antes de produção e conferir o caminho por sinais.
	var recipe_index := int(book.call("_find_recipe_index", GroveExpedition.PREPARATION_RECIPE))
	book.get("recipe_list").select(recipe_index)
	book.get("recipe_list").item_selected.emit(recipe_index)
	await _settle()
	if not _expect(GlobalInventory.inventario == stock_before and chest.get_contents() == storage_before, "abrir/resize/seleção mudou recursos"):
		return
	book.get("quantity_input").text = "2"
	book.get("quantity_input").text_submitted.emit("2")
	book.get("btn_produce").pressed.emit()
	if not _expect(cauldron.get("_batch_ativo") and cauldron.get("_batch_quantidade_total") == 2 and not book.visible and chest.get_contents().get("carvao", 0) == 0 and GlobalInventory.inventario == stock_before, "produção do Livro perdeu quantidade/origem"):
		return
	cauldron.call("cancelar_producao_em_lote")
	if not _expect(chest.get_contents() == storage_before and GlobalInventory.inventario == stock_before, "cancelamento não restituiu reserva"):
		return
	cauldron.call("abrir_popup")
	popup.get_node("BtnFechar").pressed.emit()
	if not _expect(not popup.visible, "fechamento do caldeirão falhou"):
		return
	book.call("abrir")
	book.get("btn_close").pressed.emit()
	if not _expect(not book.visible and ui.visible, "fechamento do Livro ocultou HUD"):
		return
	var fallback := BOOK_SCENE.instantiate()
	ui.add_child(fallback)
	fallback.call("set_cauldron", cauldron)
	fallback.call("abrir")
	await _settle()
	if not _expect(_screen().encloses(fallback.get_global_rect()), "host alternativo fora da janela"):
		return
	fallback.call("fechar")
	if not _expect(ui.visible, "host alternativo ocultou HUD"):
		return
	print("AlchemyDialogLayoutSmokeTest: PASS - %d verificações; cinco resoluções, rolagem/drop/lote/refund/hosts." % _checks)
	get_tree().quit(0)

func _screen() -> Rect2:
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)

func _settle() -> void:
	for frame in range(8):
		await get_tree().process_frame

func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/AlchemyDialogs/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		push_error("AlchemyDialogLayoutSmokeTest: FAIL - " + message)
		get_tree().quit(1)
	return condition
