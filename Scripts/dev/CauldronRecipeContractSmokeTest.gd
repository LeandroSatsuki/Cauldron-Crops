extends Node

const CAULDRON_SCENE := preload("res://Scenes/Cauldron.tscn")
const RECIPE_BOOK_SCENE := preload("res://Scenes/RecipeBookUI.tscn")
const VILLAGE_CHEST_SCENE := preload("res://Scenes/VillageChest.tscn")
const RecipeDatabaseScript = preload("res://Scripts/data/RecipeDatabase.gd")
const RecipeResolverScript = preload("res://Scripts/data/RecipeResolver.gd")
const RESOURCE_RECIPE_ID := "semente_basica_tomate_sol"
const RESULT_ITEM_ID := "semente_verao"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var resolver = RecipeResolverScript.new()
	if not _assert_resource_contract(resolver):
		return
	if not _assert_order_contract(resolver):
		return
	if not _assert_legacy_fallback(resolver):
		return

	GlobalInventory.inventario = {
		"semente_basica": 3,
		"tomate_sol": 3,
		RESULT_ITEM_ID: 0
	}
	GlobalInventory.receitas_descobertas = []
	GlobalInventory.pontos_alquimia = 0

	var chest: VillageChest = VILLAGE_CHEST_SCENE.instantiate() as VillageChest
	add_child(chest)
	chest.set_contents({})
	var cauldron: Node2D = CAULDRON_SCENE.instantiate()
	add_child(cauldron)
	var recipe_book: Control = RECIPE_BOOK_SCENE.instantiate() as Control
	add_child(recipe_book)
	await get_tree().process_frame
	recipe_book.call("set_cauldron", cauldron)

	if not _exercise_manual_discovery(cauldron):
		return
	if not _exercise_batch_and_refund(cauldron):
		return
	if not _exercise_inactive_time(cauldron):
		return
	if not _exercise_village_storage_pilot(cauldron, chest, recipe_book):
		return

	print("CauldronRecipeContractSmokeTest: PASS - RecipeData e acesso transacional governam quantidade, tempo, recompensa, origem e refund.")
	await get_tree().create_timer(1.1).timeout
	recipe_book.queue_free()
	cauldron.queue_free()
	chest.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _assert_resource_contract(resolver) -> bool:
	var recipe: Dictionary = resolver.get_recipe(RESOURCE_RECIPE_ID)
	if recipe.is_empty():
		_fail("receita Resource nao foi resolvida")
		return false
	if str(recipe.get("source", "")) != "resource":
		_fail("Resource nao teve prioridade sobre o fallback")
		return false
	if int(recipe.get("resultado_quantidade", 0)) != 2:
		_fail("resultado_quantidade do RecipeData nao entrou no contrato")
		return false
	if not is_equal_approx(float(recipe.get("tempo_producao", 0.0)), 2.0):
		_fail("tempo_producao do RecipeData nao entrou no contrato")
		return false
	if int(recipe.get("recompensa_pontos_alquimia", -1)) != 1:
		_fail("recompensa de alquimia do RecipeData nao entrou no contrato")
		return false

	var database = RecipeDatabaseScript.new()
	database.load_recipes()
	var problems: Array = database.validate_recipes()
	if not problems.is_empty():
		_fail("catalogo Resource invalido: %s" % str(problems))
		return false
	return true


func _assert_order_contract(resolver) -> bool:
	var recipe_data: RecipeData = resolver.get_recipe_data(RESOURCE_RECIPE_ID)
	if recipe_data == null:
		_fail("RecipeData ausente no teste de ordem")
		return false

	var original_order_matters := recipe_data.ordem_importa
	var original_default_unlock := recipe_data.desbloqueada_por_padrao
	recipe_data.ordem_importa = true
	recipe_data.desbloqueada_por_padrao = true
	var direct: Dictionary = resolver.find_recipe_for_ingredients(["semente_basica", "tomate_sol"])
	var reversed: Dictionary = resolver.find_recipe_for_ingredients(["tomate_sol", "semente_basica"])
	var default_ids: Array = resolver.get_default_unlocked_recipe_ids()
	recipe_data.ordem_importa = original_order_matters
	recipe_data.desbloqueada_por_padrao = original_default_unlock

	if str(direct.get("id", "")) != RESOURCE_RECIPE_ID:
		_fail("ordem declarada nao aceitou a combinacao direta")
		return false
	if not reversed.is_empty():
		_fail("fallback legado ignorou ordem_importa do Resource")
		return false
	if not default_ids.has(RESOURCE_RECIPE_ID):
		_fail("desbloqueada_por_padrao nao entrou no contrato de descoberta")
		return false
	return true


func _assert_legacy_fallback(resolver) -> bool:
	const LEGACY_TEST_ID := "trigo_trigo"
	const LEGACY_TEST_RESULT := "resultado_legado_teste"
	Database.receitas_alquimia[LEGACY_TEST_ID] = LEGACY_TEST_RESULT
	var recipe: Dictionary = resolver.find_recipe_for_ingredients(["trigo", "trigo"])
	Database.receitas_alquimia.erase(LEGACY_TEST_ID)

	if str(recipe.get("id", "")) != LEGACY_TEST_ID or str(recipe.get("source", "")) != "legacy":
		_fail("fallback legado nao resolveu uma receita sem Resource")
		return false
	if int(recipe.get("resultado_quantidade", 0)) != 1:
		_fail("fallback legado nao aplicou quantidade compativel")
		return false
	if not is_equal_approx(float(recipe.get("tempo_producao", 0.0)), 5.0):
		_fail("fallback legado nao aplicou tempo compativel")
		return false
	if int(recipe.get("recompensa_pontos_alquimia", 0)) != 1:
		_fail("fallback legado nao aplicou recompensa compativel")
		return false
	return true


func _exercise_manual_discovery(cauldron: Node) -> bool:
	var slot_1: Node = cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot1")
	var slot_2: Node = cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot2")
	slot_1.set("item_vinculado", "semente_basica")
	slot_2.set("item_vinculado", "tomate_sol")
	cauldron.call("_on_misturar_button_pressed")

	if int(GlobalInventory.inventario.get("semente_basica", 0)) != 2 or int(GlobalInventory.inventario.get("tomate_sol", 0)) != 2:
		_fail("mistura manual nao consumiu exatamente um craft")
		return false
	if not GlobalInventory.receitas_descobertas.has(RESOURCE_RECIPE_ID):
		_fail("mistura manual nao registrou descoberta pelo id canonico")
		return false
	if GlobalInventory.pontos_alquimia != 1:
		_fail("descoberta nao aplicou recompensa do RecipeData uma unica vez")
		return false
	var known_recipe: Dictionary = cauldron.get("recipe_resolver").get_recipe(RESOURCE_RECIPE_ID)
	if bool(cauldron.call("_registrar_descoberta", known_recipe)) or GlobalInventory.pontos_alquimia != 1:
		_fail("receita ja descoberta recebeu recompensa novamente")
		return false

	var brew_timer: Timer = cauldron.get_node("BrewTimer")
	if not is_equal_approx(brew_timer.wait_time, 2.0):
		_fail("mistura manual nao usou tempo_producao do RecipeData")
		return false
	brew_timer.stop()
	cauldron.call("_on_brew_timer_timeout")
	if int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0)) != 2:
		_fail("mistura manual nao entregou resultado_quantidade do RecipeData")
		return false
	return true


func _exercise_batch_and_refund(cauldron: Node) -> bool:
	if not bool(cauldron.call("iniciar_producao_em_lote", RESOURCE_RECIPE_ID, 2)):
		_fail("producao em lote foi recusada")
		return false
	if int(GlobalInventory.inventario.get("semente_basica", 0)) != 0 or int(GlobalInventory.inventario.get("tomate_sol", 0)) != 0:
		_fail("lote nao reservou ingredientes para dois crafts")
		return false

	var batch_timer: Timer = cauldron.get_node("BatchTimer")
	if not is_equal_approx(batch_timer.wait_time, 2.0):
		_fail("lote nao usou tempo_producao por craft")
		return false
	batch_timer.stop()
	cauldron.call("_processar_tick_lote")
	if int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0)) != 4:
		_fail("tick do lote nao entregou resultado_quantidade")
		return false
	if GlobalInventory.pontos_alquimia != 1:
		_fail("producao conhecida concedeu recompensa de descoberta novamente")
		return false

	cauldron.call("cancelar_producao_em_lote")
	if int(GlobalInventory.inventario.get("semente_basica", 0)) != 1 or int(GlobalInventory.inventario.get("tomate_sol", 0)) != 1:
		_fail("cancelamento nao devolveu apenas o craft ainda pendente")
		return false
	if str(cauldron.get("estado_atual")) != "IDLE":
		_fail("cancelamento nao liberou o caldeirao")
		return false
	return true


func _exercise_inactive_time(cauldron: Node) -> bool:
	var result_before: int = int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0))
	if not bool(cauldron.call("iniciar_producao_em_lote", RESOURCE_RECIPE_ID, 1)):
		_fail("lote de controle para tempo inativo foi recusado")
		return false
	if not bool(cauldron.call("advance_inactive_time", 2.1)):
		_fail("caldeirao nao aceitou reconciliacao do tempo inativo")
		return false
	if int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0)) != result_before + 2:
		_fail("tempo inativo nao concluiu exatamente um craft do caldeirao")
		return false
	if str(cauldron.get("estado_atual")) != "IDLE" or bool(cauldron.get("_batch_ativo")):
		_fail("caldeirao permaneceu ocupado depois de concluir o tempo inativo")
		return false
	return true


func _exercise_village_storage_pilot(cauldron: Node, chest: VillageChest, recipe_book: Control) -> bool:
	GlobalInventory.inventario = {
		"semente_basica": 0,
		"tomate_sol": 1,
		RESULT_ITEM_ID: 0,
	}
	chest.set_contents({"semente_basica": 1})
	var ingredientes: Array = ["semente_basica", "tomate_sol"]
	if int(recipe_book.call("_calcular_quantidade_maxima", ingredientes)) != 1:
		_fail("Livro de Receitas nao somou Village Storage e Mochila")
		return false

	var slot_1: Node = cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot1")
	var slot_2: Node = cauldron.get_node("PopupLayer/CenterContainer/PopupUI/DropSlot2")
	slot_1.set("item_vinculado", "semente_basica")
	slot_2.set("item_vinculado", "tomate_sol")
	cauldron.call("_on_misturar_button_pressed")
	if str(cauldron.get("estado_atual")) != "BREWING":
		_fail("mistura manual nao iniciou com ingredientes divididos entre as origens")
		return false
	if chest.get_item_quantity("semente_basica") != 0 or int(GlobalInventory.inventario.get("tomate_sol", -1)) != 0:
		_fail("mistura manual nao consumiu cada ingrediente da origem disponivel")
		return false
	var brew_timer: Timer = cauldron.get_node("BrewTimer")
	brew_timer.stop()
	cauldron.call("_on_brew_timer_timeout")
	if int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0)) != 2:
		_fail("resultado do piloto manual mudou de destino")
		return false

	GlobalInventory.inventario = {
		"semente_basica": 1,
		"tomate_sol": 2,
		RESULT_ITEM_ID: 2,
	}
	chest.set_contents({"semente_basica": 2, "tomate_sol": 1})
	if int(recipe_book.call("_calcular_quantidade_maxima", ingredientes)) != 3:
		_fail("Livro de Receitas nao calculou tres crafts combinados")
		return false
	if not bool(cauldron.call("iniciar_producao_em_lote", RESOURCE_RECIPE_ID, 3)):
		_fail("lote combinado foi recusado")
		return false
	if chest.get_item_quantity("semente_basica") != 0 or chest.get_item_quantity("tomate_sol") != 0:
		_fail("reserva em lote nao priorizou o Village Storage")
		return false
	if int(GlobalInventory.inventario.get("semente_basica", -1)) != 0 or int(GlobalInventory.inventario.get("tomate_sol", -1)) != 0:
		_fail("reserva em lote nao completou a quantidade pela Mochila")
		return false

	var batch_timer: Timer = cauldron.get_node("BatchTimer")
	batch_timer.stop()
	cauldron.call("_processar_tick_lote")
	cauldron.call("cancelar_producao_em_lote")
	if chest.get_item_quantity("semente_basica") != 1 or chest.get_item_quantity("tomate_sol") != 0:
		_fail("cancelamento nao devolveu ao Village Storage apenas as reservas pendentes")
		return false
	if int(GlobalInventory.inventario.get("semente_basica", -1)) != 1 or int(GlobalInventory.inventario.get("tomate_sol", -1)) != 2:
		_fail("cancelamento nao devolveu a parte pendente a Mochila")
		return false
	if int(GlobalInventory.inventario.get(RESULT_ITEM_ID, 0)) != 4:
		_fail("unidade concluida antes do cancelamento nao entregou o resultado")
		return false
	return true


func _fail(message: String) -> void:
	push_error("CauldronRecipeContractSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
