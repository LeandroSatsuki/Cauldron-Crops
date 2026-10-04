extends Node

const CAULDRON := preload("res://Scenes/Cauldron.tscn")
const CHEST := preload("res://Scenes/VillageChest.tscn")
const BOOK := preload("res://Scenes/RecipeBookUI.tscn")
const RECOVERY := "semente_trigo_recuperacao"
const REPLANT := "semente_trigo_replantio"
const SEED := "semente_basica"
const FILLERS := ["tomate_sol", "abobora_sombria", "raiz_gelida", "palha_rara", "rama_encantada", "semente_inverno", "semente_verao", "semente_outono", "peixe_comum", "carvao", "mistura_restauradora"]
var cauldron: Node
var chest: VillageChest
var book: Control
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var qa_root := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(qa_root):
		_check(false, "execução exige APPDATA isolado dentro de Builds/QA")
		_finish()
		return
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.receitas_descobertas = []
	GlobalInventory.pontos_alquimia = 7
	chest = CHEST.instantiate()
	add_child(chest)
	cauldron = CAULDRON.instantiate()
	add_child(cauldron)
	book = BOOK.instantiate()
	add_child(book)
	book.call("set_cauldron", cauldron)
	await get_tree().process_frame
	_contracts()
	_manual()
	_book_production()
	_batch_and_refund()
	_limits_and_refusal()
	_capacity()
	await _json_reconstruction()
	_reset({"agua": 1}, {"carvao": 1})
	_check(cauldron.call("iniciar_producao_em_lote", RECOVERY, 1), "timer real inicia recuperação sem sementes/trigo")
	await get_tree().create_timer(2.3).timeout
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and cauldron.get("estado_atual") == "IDLE", "timer real entrega exatamente uma semente")
	_check(GlobalInventory.pontos_alquimia == 7, "receitas não concedem XP/maestria")
	_finish()

func _contracts() -> void:
	var resolver := RecipeResolver.new()
	var database := RecipeDatabase.new()
	database.load_recipes()
	_check(database.validate_recipes().is_empty(), "catálogo válido")
	for recipe_id in [RECOVERY, REPLANT]:
		var data := resolver.get_recipe_data(recipe_id)
		_check(data != null and data.resultado_item == SEED, "resultado canônico de " + recipe_id)
		_check(data.desbloqueada_por_padrao and not data.exige_descoberta and resolver.is_recipe_available(recipe_id), "receita disponível sem RNG/marco")
		_check(data.tempo_producao == 2.0 and data.recompensa_pontos_alquimia == 0, "tempo piloto/sem XP")
		_check(resolver.get_default_unlocked_recipe_ids().has(recipe_id), "receita padrão no Livro")
		_check(GlobalInventory.receitas_descobertas.count(recipe_id) == 1, "Livro inicial registra uma vez")
	_check(resolver.get_result_quantity(RECOVERY) == 1 and resolver.get_result_quantity(REPLANT) == 3, "quantidades aprovadas")
	_check(resolver.find_recipe_for_ingredients(["agua", "carvao"]).get("id") == RECOVERY, "recuperação independe da ordem")
	_check(resolver.find_recipe_for_ingredients(["trigo", "trigo"]).get("id") == REPLANT, "dois trigos resolvem replantio")
	_check(resolver.find_recipe_for_ingredients(["trigo"]).is_empty(), "um trigo não corresponde a dois")
	_check(resolver.find_recipe_for_ingredients(["carvao", "carvao"], true).get("id") == GroveExpedition.PREPARATION_RECIPE, "mistura restauradora preservada")
	_check(resolver.find_recipe_for_ingredients(["semente_basica", "tomate_sol"]).get("id") == "semente_basica_tomate_sol", "receita sazonal preservada")
	var personal := GlobalInventory.inventario.duplicate(true)
	var storage := chest.get_contents()
	GlobalInventory.receitas_descobertas = [] # representa lista legada sem receitas novas
	book.call("abrir")
	book.call("abrir")
	for recipe_id in [RECOVERY, REPLANT]:
		_check(GlobalInventory.receitas_descobertas.count(recipe_id) == 1 and int(book.call("_find_recipe_index", recipe_id)) >= 0, "Livro reconcilia legado sem duplicar")
	_check(GlobalInventory.inventario == personal and chest.get_contents() == storage and GlobalInventory.pontos_alquimia == 7, "abrir Livro não gera/consome itens ou XP")
	book.call("fechar")

func _manual() -> void:
	_reset({"agua": 1}, {"carvao": 1})
	_mix("carvao", "agua")
	_check(cauldron.get("estado_atual") == "BREWING", "mistura inicia recuperação com estoque de sementes/trigo zero")
	_check(chest.get_item_quantity("carvao") == 0 and GlobalInventory.get_item_quantity("agua") == 0, "uma unidade de cada origem consumida")
	_check(GlobalInventory.get_item_quantity(SEED) == 0, "resultado não chega antes de produzir")
	_finish_brew()
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and chest.get_item_quantity(SEED) == 0, "resultado vai só à Mochila")
	cauldron.call("_on_brew_timer_timeout")
	_check(GlobalInventory.get_item_quantity(SEED) == 1, "timeout repetido não duplica")
	_reset({"trigo": 1}, {"trigo": 1})
	_mix("trigo", "trigo")
	_check(GlobalInventory.get_item_quantity("trigo") == 0 and chest.get_item_quantity("trigo") == 0, "ingrediente duplicado consome dois trigos")
	_finish_brew()
	_check(GlobalInventory.get_item_quantity(SEED) == 3, "mistura de replantio entrega três")

func _book_production() -> void:
	for recipe_id in [RECOVERY, REPLANT]:
		_reset({"agua": 2} if recipe_id == RECOVERY else {}, {"carvao": 2} if recipe_id == RECOVERY else {"trigo": 4})
		book.call("abrir")
		var index := int(book.call("_find_recipe_index", recipe_id))
		var list: ItemList = book.get("recipe_list")
		list.select(index)
		list.item_selected.emit(index)
		_check(int(book.call("_calcular_quantidade_maxima", cauldron.get("recipe_resolver").get_ingredients(recipe_id))) == 2, "Livro calcula dois crafts da nova receita")
		book.get("quantity_input").text = "2"
		book.get("quantity_input").text_submitted.emit("2")
		book.get("btn_produce").pressed.emit()
		_check(cauldron.get("estado_atual") == "BATCH" and cauldron.get("_batch_quantidade_total") == 2 and not book.visible, "botão Produzir inicia duas unidades e fecha Livro")
		_tick()
		_tick()
		_check(GlobalInventory.get_item_quantity(SEED) == (2 if recipe_id == RECOVERY else 6), "Livro entrega quantidade canônica sem precisar arrastar água")

func _batch_and_refund() -> void:
	_reset({"trigo": 3}, {"trigo": 3})
	_check(int(book.call("_calcular_quantidade_maxima", ["trigo", "trigo"])) == 3, "Livro divide total por dois trigos")
	_check(cauldron.call("iniciar_producao_em_lote", REPLANT, 3), "lote de três inicia")
	_check(GlobalInventory.get_item_quantity("trigo") == 0 and chest.get_item_quantity("trigo") == 0, "reserva seis trigos")
	var receipts: Array = cauldron.get("_batch_reservation_receipts")
	_check(receipts.size() == 3 and receipts[0]["entries"][0]["source"] == "village_storage", "baú tem prioridade")
	_tick()
	_check(GlobalInventory.get_item_quantity(SEED) == 3, "primeiro craft entrega três")
	cauldron.call("cancelar_producao_em_lote")
	_check(chest.get_item_quantity("trigo") == 1 and GlobalInventory.get_item_quantity("trigo") == 3, "cancelamento devolve só pendentes às origens")
	cauldron.call("cancelar_producao_em_lote")
	_check(chest.get_item_quantity("trigo") == 1 and GlobalInventory.get_item_quantity(SEED) == 3, "cancelamento repetido não duplica")
	_reset({"agua": 2, "carvao": 1}, {"carvao": 1})
	_check(cauldron.call("iniciar_producao_em_lote", RECOVERY, 2), "lote recuperação usa água do poço e carvão dividido")
	_tick()
	cauldron.call("cancelar_producao_em_lote")
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and GlobalInventory.get_item_quantity("agua") == 1 and GlobalInventory.get_item_quantity("carvao") == 1 and chest.get_item_quantity("carvao") == 0, "refund preserva água e carvão da unidade pendente")

func _limits_and_refusal() -> void:
	_reset({"trigo": 4}, {"trigo": 1})
	_check(int(cauldron.call("calcular_quantidade_maxima_para_ingredientes", ["trigo", "trigo"])) == 2, "estoque ímpar permite dois crafts")
	_check(cauldron.call("iniciar_producao_em_lote", REPLANT, 99), "pedido grande limitado aos recursos reais")
	_check(cauldron.get("_batch_quantidade_total") == 2 and GlobalInventory.get_item_quantity("trigo") == 1, "reserva quatro, preserva trigo ímpar")
	_tick()
	_tick()
	_check(GlobalInventory.get_item_quantity(SEED) == 6 and cauldron.get("estado_atual") == "IDLE", "dois crafts entregam seis, não 99")
	for inventory in [{"carvao": 1}, {"agua": 1}, {"trigo": 1}, {}]:
		_reset(inventory, {})
		var before := GlobalInventory.inventario.duplicate(true)
		var recipe_id := REPLANT if inventory.has("trigo") else RECOVERY
		_check(not cauldron.call("iniciar_producao_em_lote", recipe_id, 1), "recusa por ingredientes insuficientes")
		_check(GlobalInventory.inventario == before and chest.get_contents().is_empty() and cauldron.get("estado_atual") == "IDLE", "recusa sem mutação")
	_reset({"trigo": 1}, {})
	_mix("trigo", "trigo")
	_check(GlobalInventory.get_item_quantity("trigo") == 1 and cauldron.get("estado_atual") == "IDLE", "mistura manual insuficiente conserva trigo")

func _capacity() -> void:
	var full := {SEED: 98, "agua": 1}
	for item_id in FILLERS:
		full[item_id] = 99
	_reset(full, {"trigo": 2})
	_check(GlobalInventory.get_used_slot_count() == 12, "fixture cheio sem ocupar slot com água")
	_check(cauldron.call("iniciar_producao_em_lote", REPLANT, 1), "produção pode reservar com Mochila cheia")
	_tick()
	_check(cauldron.get("_batch_waiting_for_space") and cauldron.get("_batch_quantidade_concluida") == 0, "resultado três não é entregue parcialmente em espaço de um")
	_check(GlobalInventory.get_item_quantity(SEED) == 98 and (cauldron.get("_batch_reservation_receipts") as Array).size() == 1, "resultado/reserva preservados")
	_tick()
	_check(GlobalInventory.get_item_quantity(SEED) == 98, "nova tentativa bloqueada não duplica")
	GlobalInventory.remover_item("tomate_sol", 99)
	cauldron.call("_perform_primary_interaction")
	_check(GlobalInventory.get_item_quantity(SEED) == 101 and cauldron.get("estado_atual") == "IDLE", "liberar espaço entrega três integralmente")
	cauldron.call("_perform_primary_interaction")
	_check(GlobalInventory.get_item_quantity(SEED) == 101 and chest.get_item_quantity(SEED) == 0, "recolher novamente não duplica/não deposita automaticamente")

func _json_reconstruction() -> void:
	_reset({"agua": 2}, {"carvao": 2})
	_check(cauldron.call("iniciar_producao_em_lote", RECOVERY, 2), "lote para snapshot inicia")
	cauldron.get_node("BatchTimer").stop()
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(cauldron.call("get_save_data")))
	_check(cauldron.call("is_save_data_valid", snapshot), "snapshot existente aceita nova receita/água")
	var personal := GlobalInventory.inventario.duplicate(true)
	var storage := chest.get_contents()
	_check(cauldron.call("load_save_data", snapshot) and cauldron.call("load_save_data", snapshot), "replay de snapshot válido")
	cauldron.get_node("BatchTimer").stop()
	_check(GlobalInventory.inventario == personal and chest.get_contents() == storage, "load não consome/refunda novamente")
	cauldron.queue_free()
	await get_tree().process_frame
	cauldron = CAULDRON.instantiate()
	add_child(cauldron)
	book.call("set_cauldron", cauldron)
	_check(cauldron.call("load_save_data", snapshot), "nova instância retoma snapshot")
	_tick()
	cauldron.call("cancelar_producao_em_lote")
	_check(GlobalInventory.get_item_quantity(SEED) == 1 and GlobalInventory.get_item_quantity("agua") == 1 and chest.get_item_quantity("carvao") == 1, "retomada entrega uma e refund apenas restante")

func _reset(personal: Dictionary, storage: Dictionary) -> void:
	_check(cauldron.call("load_save_data", {"state": "IDLE"}), "reset de fixture")
	GlobalInventory.set_inventory_contents(personal)
	chest.set_contents(storage)
	book.call("set_cauldron", cauldron)

func _mix(first: String, second: String) -> void:
	cauldron.get("drop_slot_1").set("item_vinculado", first)
	cauldron.get("drop_slot_2").set("item_vinculado", second)
	cauldron.call("_on_misturar_button_pressed")

func _finish_brew() -> void:
	cauldron.get_node("BrewTimer").stop()
	cauldron.call("_on_brew_timer_timeout")

func _tick() -> void:
	cauldron.get_node("BatchTimer").stop()
	cauldron.call("_processar_tick_lote")
	cauldron.get_node("BatchTimer").stop()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("SustainableSeedsSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("SustainableSeedsSmokeTest: PASS - %d verificações de receitas, recuperação, origens, lote, capacidade e JSON." % checks)
	get_tree().quit(1 if failed else 0)
