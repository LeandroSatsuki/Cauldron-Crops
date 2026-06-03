extends CanvasLayer

var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var pixel_ui_theme = preload("res://Themes/pixel_ui_theme.tres")
const FarmGridManagerSmokeTestScript = preload("res://Scripts/dev/FarmGridManagerSmokeTest.gd")

@onready var moedas_label: Label = $StatusPanel/MoedasLabel
@onready var season_label: Label = $StatusPanel/SeasonLabel
@onready var cargas_label: Label = $StatusPanel/CargasLabel
@onready var semente_label: Label = $StatusPanel/SementeLabel
@onready var golems_label: Label = $StatusPanel/GolemsLabel
@onready var capacity_label: Label = $StatusPanel/CapacityLabel
@onready var chest_status_label: Label = $StatusPanel/ChestStatusLabel
@onready var tool_label: Label = $StatusPanel/ToolLabel

@onready var usar_pocao_button: Button = $LeftPanel/UsarPocaoButton
@onready var dormir_button: Button = $LeftPanel/DormirButton
@onready var comprar_cosmetico_button: Button = $LeftPanel/ComprarCosmeticoButton
@onready var tool_hoe_button: Button = $LeftPanel/BtnToolHoe
@onready var tool_seed_button: Button = $LeftPanel/BtnToolSeed
@onready var tool_watering_can_button: Button = $LeftPanel/BtnToolWateringCan
@onready var tool_harvest_button: Button = $LeftPanel/BtnToolHarvest
@onready var comprar_trigo_button: Button = $LeftPanel/GridSementes/ComprarTrigoButton
@onready var comprar_verao_button: Button = $LeftPanel/GridSementes/ComprarVeraoButton
@onready var abrir_skill_tree_button: Button = $LeftPanel/AbrirSkillTreeButton
var skill_tree_scene = preload("res://Scenes/SkillTree.tscn")
var skill_tree: Panel

@onready var abrir_quests_button: Button = $LeftPanel/AbrirQuestsButton
var quest_board_scene = preload("res://Scenes/QuestBoard.tscn")
var quest_board: Panel

@onready var abrir_livro_receitas_button: Button = $LeftPanel/AbrirLivroReceitasButton
var recipe_book_scene = preload("res://Scenes/RecipeBookUI.tscn")
var recipe_book: Panel

@onready var village_chest_panel: PanelContainer = $VillageChestPanel
@onready var village_chest_contents: RichTextLabel = $VillageChestPanel/MarginContainer/VBoxChest/ChestContents
@onready var village_chest_withdraw_button: Button = $VillageChestPanel/MarginContainer/VBoxChest/ButtonsRow/RetirarTudoButton
@onready var village_chest_close_button: Button = $VillageChestPanel/MarginContainer/VBoxChest/ButtonsRow/FecharButton
var village_chest_ref: VillageChest = null

@onready var inventory_bar: HBoxContainer = $InventoryBar
@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_texto: Label = $TooltipPanel/TooltipTexto
@onready var sell_menu: PanelContainer = $SellMenu

@onready var debug_panel: PanelContainer = $DebugPanel
@onready var debug_last_action_label: Label = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/DebugLastActionLabel
@onready var debug_add_seeds_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugAddSeeds
@onready var debug_add_water_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugAddWater
@onready var debug_add_basic_ingredients_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugAddIngredients
@onready var debug_discover_all_recipes_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugDiscoverAllRecipes
@onready var debug_force_growth_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugForceGrowth
@onready var debug_save_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugSave
@onready var debug_load_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugLoad
@onready var debug_add_wheat_chest_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugAddWheatChest
@onready var debug_clear_chest_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugClearChest
@onready var debug_test_farm_grid_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnDebugTestFarmGrid
@onready var debug_close_button: Button = $DebugPanel/MarginContainer/ScrollContainer/VBoxDebug/BtnFechar

var ultimo_estado_inventario: Dictionary = {}
var item_focado_id: String = ""
var custo_dormir: int = 5
var timer_reset_dormir: float = 0.0
var _status_update_accum: float = 0.0

var quest_board_visivel: bool:
	get:
		return quest_board.visible if quest_board else false

func _ready() -> void:
	if usar_pocao_button:
		usar_pocao_button.pressed.connect(_on_usar_pocao_button_pressed)
	if dormir_button:
		dormir_button.pressed.connect(_on_dormir_button_pressed)
	if comprar_cosmetico_button:
		comprar_cosmetico_button.pressed.connect(_on_comprar_cosmetico_button_pressed)
	if tool_hoe_button:
		if not tool_hoe_button.pressed.is_connected(_on_tool_hoe_button_pressed):
			tool_hoe_button.pressed.connect(_on_tool_hoe_button_pressed)
	if tool_seed_button:
		if not tool_seed_button.pressed.is_connected(_on_tool_seed_button_pressed):
			tool_seed_button.pressed.connect(_on_tool_seed_button_pressed)
	if tool_watering_can_button:
		if not tool_watering_can_button.pressed.is_connected(_on_tool_watering_can_button_pressed):
			tool_watering_can_button.pressed.connect(_on_tool_watering_can_button_pressed)
	if tool_harvest_button:
		if not tool_harvest_button.pressed.is_connected(_on_tool_harvest_button_pressed):
			tool_harvest_button.pressed.connect(_on_tool_harvest_button_pressed)
	if comprar_trigo_button:
		comprar_trigo_button.gui_input.connect(func(event): _on_comprar_semente_gui_input(event, "semente_basica", 5, "+1 Semente Trigo", "+10 Semente Trigo"))
		comprar_trigo_button.mouse_entered.connect(_on_comprar_trigo_button_mouse_entered)
		comprar_trigo_button.mouse_exited.connect(_on_comprar_trigo_button_mouse_exited)
	if comprar_verao_button:
		comprar_verao_button.gui_input.connect(func(event): _on_comprar_semente_gui_input(event, "semente_verao", 10, "+1 Semente Tomate", "+10 Semente Tomate"))
		comprar_verao_button.mouse_entered.connect(_on_comprar_verao_button_mouse_entered)
		comprar_verao_button.mouse_exited.connect(_on_comprar_verao_button_mouse_exited)
		
	skill_tree = skill_tree_scene.instantiate()
	add_child(skill_tree)
	_aplicar_tema_pixel_ui(skill_tree)
	skill_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_tree.visibility_changed.connect(func():
		if skill_tree:
			skill_tree.mouse_filter = Control.MOUSE_FILTER_STOP if skill_tree.visible else Control.MOUSE_FILTER_IGNORE
	)
	if abrir_skill_tree_button:
		abrir_skill_tree_button.pressed.connect(func(): skill_tree.visible = true)
		
	quest_board = quest_board_scene.instantiate()
	add_child(quest_board)
	_aplicar_tema_pixel_ui(quest_board)
	quest_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_board.visibility_changed.connect(func():
		if quest_board:
			quest_board.mouse_filter = Control.MOUSE_FILTER_STOP if quest_board.visible else Control.MOUSE_FILTER_IGNORE
	)
	if abrir_quests_button:
		abrir_quests_button.pressed.connect(_on_abrir_quests_pressed)

	recipe_book = recipe_book_scene.instantiate()
	var cauldron_popup_layer := get_tree().current_scene.get_node_or_null("CauldronUI/PopupLayer")
	if cauldron_popup_layer:
		cauldron_popup_layer.add_child(recipe_book)
	else:
		add_child(recipe_book)
	recipe_book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_book.z_index = 200
	recipe_book.visibility_changed.connect(func():
		if recipe_book:
			recipe_book.mouse_filter = Control.MOUSE_FILTER_STOP if recipe_book.visible else Control.MOUSE_FILTER_IGNORE
	)
	if recipe_book.has_signal("craft_requested"):
		recipe_book.craft_requested.connect(_on_recipe_book_craft_requested)
	_vincular_caldeirao_no_livro(_resolver_caldeirao(get_tree().current_scene.get_node_or_null("CauldronUI")))
	if abrir_livro_receitas_button:
		abrir_livro_receitas_button.pressed.connect(_on_abrir_livro_receitas_pressed)
		
	if sell_menu:
		_aplicar_tema_pixel_ui(sell_menu)
		sell_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sell_menu.visibility_changed.connect(func():
			if sell_menu:
				sell_menu.mouse_filter = Control.MOUSE_FILTER_STOP if sell_menu.visible else Control.MOUSE_FILTER_IGNORE
		)
		
	if QuestManager:
		QuestManager.quest_atualizada.connect(_on_nova_quest_recebida)

	if debug_panel:
		debug_panel.visible = false
		debug_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if debug_add_seeds_button:
		debug_add_seeds_button.pressed.connect(_on_debug_add_seeds_pressed)
	if debug_add_water_button:
		debug_add_water_button.pressed.connect(_on_debug_add_water_pressed)
	if debug_add_basic_ingredients_button:
		debug_add_basic_ingredients_button.pressed.connect(_on_debug_add_basic_ingredients_pressed)
	if debug_discover_all_recipes_button:
		debug_discover_all_recipes_button.pressed.connect(_on_debug_discover_all_recipes_pressed)
	if debug_force_growth_button:
		debug_force_growth_button.pressed.connect(_on_debug_force_growth_pressed)
	if debug_save_button:
		debug_save_button.pressed.connect(_on_debug_save_pressed)
	if debug_load_button:
		debug_load_button.pressed.connect(_on_debug_load_pressed)
	if debug_add_wheat_chest_button:
		debug_add_wheat_chest_button.pressed.connect(_on_debug_add_wheat_to_chest_pressed)
	if debug_clear_chest_button:
		debug_clear_chest_button.pressed.connect(_on_debug_clear_chest_pressed)
	if debug_test_farm_grid_button:
		if not debug_test_farm_grid_button.pressed.is_connected(_on_debug_test_farm_grid_pressed):
			debug_test_farm_grid_button.pressed.connect(_on_debug_test_farm_grid_pressed)
	else:
		push_warning("DebugPanel: BtnDebugTestFarmGrid nao encontrado.")
	if debug_close_button:
		debug_close_button.pressed.connect(fechar_debug_panel)

	if village_chest_panel:
		village_chest_panel.visible = false
		village_chest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if village_chest_withdraw_button:
		village_chest_withdraw_button.pressed.connect(_on_village_chest_withdraw_pressed)
	if village_chest_close_button:
		village_chest_close_button.pressed.connect(fechar_bau_vila)
		
	# Inicializa
	verificar_e_atualizar_inventario()
	atualizar_status_jogo()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_toggle_debug_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		_selecionar_enxada()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_2:
		_selecionar_semente()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_3:
		_selecionar_regador()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_4:
		_selecionar_colheita()
		get_viewport().set_input_as_handled()

func _toggle_debug_panel() -> void:
	if debug_panel and debug_panel.visible:
		fechar_debug_panel()
	else:
		abrir_debug_panel()

func abrir_debug_panel() -> void:
	if not debug_panel:
		return

	debug_panel.visible = true
	debug_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_panel.move_to_front()
	print("Debug: painel aberto.")

func fechar_debug_panel() -> void:
	if not debug_panel:
		return

	debug_panel.visible = false
	debug_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("Debug: painel fechado.")

func _process(delta: float) -> void:
	timer_reset_dormir += delta
	_status_update_accum += delta
	if timer_reset_dormir >= 60.0:
		custo_dormir = 2 if "skill_dormir" in GlobalInventory.skills_desbloqueadas else 5
	if dormir_button:
		dormir_button.text = "Dormir (Custo: " + str(custo_dormir) + ")"
		
	if moedas_label:
		moedas_label.text = "Moedas: " + str(EconomyManager.moedas)
	if season_label:
		season_label.text = "Estação: " + SeasonManager.obter_nome_estacao() + " | Ano: " + str(SeasonManager.ano)
	if cargas_label:
		cargas_label.text = "Cargas Mágicas: " + str(GlobalInventory.cargas_crescimento)
	if semente_label:
		var nome = "Trigo"
		if GlobalInventory.semente_selecionada == "semente_inverno":
			nome = "Raiz"
		elif GlobalInventory.semente_selecionada == "semente_verao":
			nome = "Tomate"
		elif GlobalInventory.semente_selecionada == "semente_outono":
			nome = "Abóbora"
		semente_label.text = "Semente Atual: " + nome
	if golems_label:
		golems_label.text = "Golems Ativos: " + str(EconomyManager.total_golems)
		
	verificar_e_atualizar_inventario()
	if village_chest_panel and village_chest_panel.visible and village_chest_ref:
		_atualizar_painel_bau_vila()
	if _status_update_accum >= 0.5:
		_status_update_accum = 0.0
		atualizar_status_jogo()

func _aplicar_tema_pixel_ui(no: Node) -> void:
	if no is Control:
		(no as Control).theme = pixel_ui_theme

func atualizar_status_jogo() -> void:
	if moedas_label:
		moedas_label.text = "Moedas: %d" % int(EconomyManager.moedas)
	if season_label:
		season_label.text = "Estação: %s | Ano %d" % [SeasonManager.obter_nome_estacao(), int(SeasonManager.ano)]
	if cargas_label:
		cargas_label.text = "Água: %d" % int(GlobalInventory.inventario.get("agua", 0))
	if semente_label:
		semente_label.text = "Alquimia: %d" % int(GlobalInventory.pontos_alquimia)
	if golems_label:
		golems_label.text = "Golems: %d/%d" % [int(EconomyManager.total_golems), int(EconomyManager.max_golems)]
	if capacity_label:
		capacity_label.text = "Capacidade: %d/%d" % [int(EconomyManager.total_golems), int(EconomyManager.max_golems)]
	if chest_status_label:
		chest_status_label.text = "Baú: %s" % _obter_status_bau_vila()
	if tool_label:
		tool_label.text = "Ferramenta: %s" % _obter_nome_ferramenta_ativa()

func _obter_status_bau_vila() -> String:
	var chests: Array = get_tree().get_nodes_in_group("village_chest")
	for chest_variant in chests:
		var chest: Node = chest_variant
		if chest == null or not is_instance_valid(chest):
			continue
		if not chest.has_method("get_contents"):
			continue
		var conteudo_variant: Variant = chest.get_contents()
		if typeof(conteudo_variant) != TYPE_DICTIONARY:
			return "não encontrado"
		var conteudo: Dictionary = conteudo_variant
		if conteudo.is_empty():
			return "vazio"
		return "contém itens"
	return "não encontrado"

func verificar_e_atualizar_inventario() -> void:
	var precisa_atualizar = false
	if GlobalInventory.inventario.size() != ultimo_estado_inventario.size():
		precisa_atualizar = true
	else:
		for key in GlobalInventory.inventario:
			if not ultimo_estado_inventario.has(key) or GlobalInventory.inventario[key] != ultimo_estado_inventario[key]:
				precisa_atualizar = true
				break
				
	if precisa_atualizar:
		ultimo_estado_inventario = GlobalInventory.inventario.duplicate()
		atualizar_inventario_visual()

func atualizar_inventario_visual() -> void:
	if not inventory_bar:
		return
		
	# Limpa
	for child in inventory_bar.get_children():
		child.queue_free()
		
	# Cria slots
	for item_key in GlobalInventory.inventario:
		var qtd = GlobalInventory.inventario[item_key]
		if qtd > 0:
			var slot = slot_scene.instantiate()
			inventory_bar.add_child(slot)
			
			var emoji = obter_emoji_item(item_key)
			slot.configurar_slot(item_key, qtd, emoji)
			slot.slot_clicado.connect(_on_slot_clicado)
			if item_key == GlobalInventory.semente_selecionada or item_key == item_focado_id:
				slot.set_destaque(true)
			else:
				slot.set_destaque(false)
			
	atualizar_destaques()

func atualizar_destaques() -> void:
	if not inventory_bar:
		return
	for slot in inventory_bar.get_children():
		if slot.is_queued_for_deletion():
			continue
		if slot.has_method("set_destaque"):
			if slot.item_id == GlobalInventory.semente_selecionada or slot.item_id == item_focado_id:
				slot.set_destaque(true)
			else:
				slot.set_destaque(false)

func _on_slot_clicado(item_id: String, is_right_click: bool, slot_node: Control) -> void:
	if item_id.begins_with("semente_"):
		GlobalInventory.semente_selecionada = item_id
		item_focado_id = ""
		atualizar_destaques()
		
		if not is_right_click:
			print("Semente selecionada equipada: ", item_id)
		else:
			var preco_revenda = int(Database.custo_semente.get(item_id, 0) * 0.6)
			if preco_revenda > 0:
				var qtd_atual = GlobalInventory.inventario.get(item_id, 0)
				if qtd_atual >= 10:
					if GlobalInventory.remover_item(item_id, 10):
						var ganho = preco_revenda * 10
						EconomyManager.adicionar_moedas(ganho)
						criar_texto_flutuante("+" + str(ganho) + " Moedas", get_viewport().get_mouse_position(), Color.GREEN)
				else:
					print("Quantidade insuficiente de sementes para revenda!")
	else:
		item_focado_id = item_id
		GlobalInventory.semente_selecionada = ""
		atualizar_destaques()
		
		if is_right_click:
			# Venda 10x
			var preco = Database.precos.get(item_id, 0)
			if preco > 0:
				var qtd_atual = GlobalInventory.inventario.get(item_id, 0)
				if qtd_atual >= 10:
					if GlobalInventory.remover_item(item_id, 10):
						var ganho = preco * 10
						EconomyManager.adicionar_moedas(ganho)
						criar_texto_flutuante("+" + str(ganho) + " Moedas", get_viewport().get_mouse_position(), Color.GREEN)
				else:
					print("Quantidade insuficiente para vender 10x!")
		else:
			# Clique esquerdo -> abre SellMenu
			if sell_menu:
				var pos_fixa = slot_node.global_position + Vector2(0, slot_node.size.y + 5)
				sell_menu.abrir(item_id, pos_fixa)

func obter_emoji_item(item_id: String) -> String:
	match item_id:
		"trigo": return "🌾"
		"raiz_gelida": return "🧊"
		"tomate_sol": return "🍅"
		"abobora_sombria": return "🎃"
		"semente_basica": return "🌱"
		"semente_inverno": return "❄️"
		"semente_verao": return "☀️"
		"semente_outono": return "🍁"
		"pocao_crescimento": return "🧪"
		"pocao_aceleradora": return "⚡"
		"essencia_sombria": return "🔮"
		"adubo_flamejante": return "🔥"
		"elixir_estacional": return "🍶"
		"agua": return "💧"
	return "📦"

func _on_usar_pocao_button_pressed() -> void:
	if GlobalInventory.remover_item("pocao_crescimento", 1):
		GlobalInventory.cargas_crescimento += 3

func _on_dormir_button_pressed() -> void:
	if EconomyManager.moedas >= custo_dormir:
		if EconomyManager.remover_moedas(custo_dormir):
			criar_texto_flutuante("Custo: -" + str(custo_dormir), get_viewport().get_mouse_position(), Color.RED)
			SeasonManager.avancar_estacao()
			if "skill_dormir" in GlobalInventory.skills_desbloqueadas:
				custo_dormir = int(custo_dormir * 1.5)
			else:
				custo_dormir *= 2
			timer_reset_dormir = 0.0
	else:
		print("Moedas insuficientes para dormir!")

func _on_comprar_cosmetico_button_pressed() -> void:
	if EconomyManager.remover_moedas(50):
		print("Tema comprado e aplicado!")
		RenderingServer.set_default_clear_color(Color(0.1, 0.4, 0.1))

func _on_comprar_semente_gui_input(event: InputEvent, semente_id: String, preco_unitario: int, texto_1x: String, texto_10x: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if EconomyManager.remover_moedas(preco_unitario):
				GlobalInventory.adicionar_item(semente_id, 1)
				criar_texto_flutuante(texto_1x, get_viewport().get_mouse_position(), Color.YELLOW)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if EconomyManager.remover_moedas(preco_unitario * 10):
				GlobalInventory.adicionar_item(semente_id, 10)
				criar_texto_flutuante(texto_10x, get_viewport().get_mouse_position(), Color.YELLOW)


func _on_comprar_trigo_button_mouse_entered() -> void:
	if tooltip_panel:
		tooltip_panel.visible = true
	if tooltip_texto:
		tooltip_texto.text = "Semente de Trigo\nCusto: 5 Moedas\nEstação: Primavera\nUso: Adubo Flamejante"

func _on_comprar_trigo_button_mouse_exited() -> void:
	if tooltip_panel:
		tooltip_panel.visible = false

func _on_comprar_verao_button_mouse_entered() -> void:
	if tooltip_panel:
		tooltip_panel.visible = true
	if tooltip_texto:
		tooltip_texto.text = "Semente de Tomate\nCusto: 10 Moedas\nEstação: Verão\nUso: Adubo Flamejante"

func _on_comprar_verao_button_mouse_exited() -> void:
	if tooltip_panel:
		tooltip_panel.visible = false

func criar_texto_flutuante(texto: String, posicao_global: Vector2, cor: Color) -> void:
	var label = Label.new()
	label.text = texto
	label.modulate = cor
	label.global_position = posicao_global
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "global_position", posicao_global + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _on_abrir_quests_pressed() -> void:
	if quest_board:
		quest_board.visible = true
	var alerta = $LeftPanel/AbrirQuestsButton/AlertaQuest
	if alerta:
		alerta.visible = false

func _on_nova_quest_recebida() -> void:
	if not quest_board_visivel:
		var alerta = $LeftPanel/AbrirQuestsButton/AlertaQuest
		if alerta:
			alerta.visible = true

func _on_debug_add_seeds_pressed() -> void:
	GlobalInventory.adicionar_item("semente_basica", 10)
	print("Debug: adicionou semente_basica x10.")
	_atualizar_pos_debug_acao()

func _on_debug_add_water_pressed() -> void:
	GlobalInventory.adicionar_item("agua", 10)
	print("Debug: adicionou agua x10.")
	_atualizar_pos_debug_acao()

func _on_debug_add_basic_ingredients_pressed() -> void:
	GlobalInventory.adicionar_item("trigo", 10)
	GlobalInventory.adicionar_item("carvao", 10)
	GlobalInventory.adicionar_item("tomate_sol", 5)
	GlobalInventory.adicionar_item("raiz_gelida", 5)
	GlobalInventory.adicionar_item("palha_rara", 3)
	GlobalInventory.adicionar_item("rama_encantada", 3)
	print("Debug: adicionou ingredientes basicos ao inventario.")
	_atualizar_pos_debug_acao()

func _on_debug_discover_all_recipes_pressed() -> void:
	var adicionadas: int = 0
	for recipe_id_variant in Database.receitas_alquimia.keys():
		var recipe_id: String = str(recipe_id_variant)
		if recipe_id == "":
			continue
		if GlobalInventory.receitas_descobertas.has(recipe_id):
			continue
		GlobalInventory.receitas_descobertas.append(recipe_id)
		adicionadas += 1

	print("Debug: descobriu %d receitas." % adicionadas)

func _on_debug_force_growth_pressed() -> void:
	var lotes := get_tree().get_nodes_in_group("lotes_terra")
	var afetados: int = 0
	for lote in lotes:
		if lote == null or not is_instance_valid(lote):
			continue
		if lote.has_method("debug_force_ready_to_harvest"):
			lote.debug_force_ready_to_harvest()
			afetados += 1

	print("Debug: lotes forçados para colheita: %d." % afetados)

func _on_debug_save_pressed() -> void:
	if SaveManager and SaveManager.save_game():
		print("Debug: jogo salvo.")
	else:
		push_warning("Debug: falha ao salvar o jogo.")

func _on_debug_load_pressed() -> void:
	if SaveManager and SaveManager.load_game():
		print("Debug: jogo carregado.")
		_atualizar_pos_debug_acao()
	else:
		push_warning("Debug: falha ao carregar o jogo.")

func _on_debug_add_wheat_to_chest_pressed() -> void:
	var chest := _obter_bau_da_vila_debug()
	if chest == null:
		push_warning("Debug: baú da vila não encontrado.")
		return

	chest.deposit_item("trigo", 10)
	print("Debug: adicionou trigo x10 ao Baú da Vila.")
	_atualizar_painel_bau_vila()

func _on_debug_clear_chest_pressed() -> void:
	var chest := _obter_bau_da_vila_debug()
	if chest == null:
		push_warning("Debug: baú da vila não encontrado.")
		return

	if chest.has_method("clear_contents"):
		chest.clear_contents()
		print("Debug: baú da vila limpo.")
	else:
		push_warning("Debug: o baú da vila não possui clear_contents().")
		return

	_atualizar_painel_bau_vila()

func _on_debug_test_farm_grid_pressed() -> void:
	print("Debug FarmGrid: botao clicado.")
	var passou: bool = FarmGridManagerSmokeTestScript.run()
	if passou:
		print("Debug FarmGrid: smoke test passou.")
		_atualizar_pos_debug_acao("FarmGrid test: passou")
	else:
		push_warning("Debug FarmGrid: smoke test falhou.")
		_atualizar_pos_debug_acao("FarmGrid test: falhou")

func _on_tool_hoe_button_pressed() -> void:
	_selecionar_enxada()

func _selecionar_enxada() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager != null and tool_manager.has_method("select_hoe"):
		tool_manager.call("select_hoe")
	else:
		push_warning("UI: ToolManager nao encontrado.")
	atualizar_status_jogo()

func _selecionar_semente() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager != null and tool_manager.has_method("select_seed"):
		tool_manager.call("select_seed")
	else:
		push_warning("UI: ToolManager nao encontrado.")
	atualizar_status_jogo()

func _selecionar_regador() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager != null and tool_manager.has_method("select_watering_can"):
		tool_manager.call("select_watering_can")
	else:
		push_warning("UI: ToolManager nao encontrado.")
	atualizar_status_jogo()

func _selecionar_colheita() -> void:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager != null and tool_manager.has_method("select_harvest"):
		tool_manager.call("select_harvest")
	else:
		push_warning("UI: ToolManager nao encontrado.")
	atualizar_status_jogo()

func _on_tool_seed_button_pressed() -> void:
	_selecionar_semente()

func _on_tool_watering_can_button_pressed() -> void:
	_selecionar_regador()

func _on_tool_harvest_button_pressed() -> void:
	_selecionar_colheita()

func _obter_nome_ferramenta_ativa() -> String:
	var tool_manager: Node = _obter_tool_manager()
	if tool_manager != null and tool_manager.has_method("get_tool_name"):
		var ferramenta_nome: String = str(tool_manager.call("get_tool_name"))
		return ferramenta_nome
	return "Nenhuma"

func _obter_tool_manager() -> Node:
	if get_tree() == null:
		return null
	return get_tree().root.get_node_or_null("ToolManager")

func _atualizar_pos_debug_acao(acao_texto: String = "") -> void:
	if debug_last_action_label and acao_texto != "":
		debug_last_action_label.text = "Última ação: %s" % acao_texto
	verificar_e_atualizar_inventario()
	if village_chest_panel and village_chest_panel.visible:
		_atualizar_painel_bau_vila()

func _obter_bau_da_vila_debug() -> VillageChest:
	if village_chest_ref and is_instance_valid(village_chest_ref):
		return village_chest_ref

	var chests: Array = get_tree().get_nodes_in_group("village_chest")
	for chest in chests:
		if chest != null and is_instance_valid(chest) and chest is VillageChest:
			return chest

	return null

func abrir_bau_vila(bau: VillageChest) -> void:
	if bau == null or not is_instance_valid(bau):
		push_warning("UI: baú da vila inválido.")
		return

	village_chest_ref = bau
	if village_chest_panel:
		village_chest_panel.visible = true
		village_chest_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_atualizar_painel_bau_vila()

func fechar_bau_vila() -> void:
	if village_chest_panel:
		village_chest_panel.visible = false
		village_chest_panel.mouse_filter = Control.MOUSE_FILTER_PASS

func _atualizar_painel_bau_vila() -> void:
	if not village_chest_contents:
		return

	if village_chest_ref == null or not is_instance_valid(village_chest_ref):
		village_chest_contents.text = "Baú vazio."
		return

	var conteudo: Dictionary = village_chest_ref.get_contents()
	if conteudo.is_empty():
		village_chest_contents.text = "Baú vazio."
		return

	var linhas: PackedStringArray = PackedStringArray()
	for item_id in conteudo.keys():
		var quantidade: int = int(conteudo[item_id])
		if quantidade > 0:
			linhas.append("%s x%d" % [str(item_id), quantidade])

	if linhas.is_empty():
		village_chest_contents.text = "Baú vazio."
	else:
		village_chest_contents.text = "\n".join(linhas)

func _on_village_chest_withdraw_pressed() -> void:
	if village_chest_ref == null or not is_instance_valid(village_chest_ref):
		fechar_bau_vila()
		return

	var retirado: Dictionary = village_chest_ref.withdraw_all_to_global_inventory()
	if retirado.is_empty():
		if village_chest_contents:
			village_chest_contents.text = "Baú vazio."
		print("Baú vazio.")
	else:
		verificar_e_atualizar_inventario()
		_atualizar_painel_bau_vila()

func _on_abrir_livro_receitas_pressed() -> void:
	print("DEBUG UI: botão livro de receitas clicado")
	abrir_livro_receitas(false)

func abrir_livro_receitas(fechar_caldeirao: bool = false, cauldron: Node = null) -> void:
	if not recipe_book:
		_instanciar_livro_receitas()
	if not recipe_book:
		push_warning("Nao foi possivel abrir o Livro de Receitas: instancia nao encontrada.")
		return

	if fechar_caldeirao:
		var cauldron_ui := cauldron
		if not cauldron_ui:
			cauldron_ui = get_tree().current_scene.get_node_or_null("CauldronUI")
		if cauldron_ui and cauldron_ui.has_method("fechar_popup"):
			cauldron_ui.fechar_popup()
		elif fechar_caldeirao:
			push_warning("Nao foi possivel fechar o popup do caldeirao ao abrir o Livro de Receitas.")

	var cauldron_final := _resolver_caldeirao(cauldron)
	if cauldron_final:
		_vincular_caldeirao_no_livro(cauldron_final)
	else:
		push_warning("UI: nenhum caldeirao valido encontrado para o Livro de Receitas.")

	var cauldron_popup_layer := get_tree().current_scene.get_node_or_null("CauldronUI/PopupLayer")
	if cauldron_popup_layer:
		cauldron_popup_layer.visible = true

	if recipe_book and recipe_book.has_method("abrir"):
		recipe_book.abrir()
	else:
		push_warning("Livro de Receitas nao pode ser aberto porque a instancia nao foi encontrada.")

func fechar_livro_receitas() -> void:
	if recipe_book and recipe_book.has_method("fechar"):
		recipe_book.fechar()

func _on_recipe_book_craft_requested(recipe_id: String, quantidade: int) -> void:
	var cauldron_ui: Node = null
	if recipe_book and recipe_book.has_method("get_cauldron_reference"):
		cauldron_ui = recipe_book.get_cauldron_reference()
	cauldron_ui = _resolver_caldeirao(cauldron_ui)
	if not cauldron_ui:
		push_warning("Nao foi possivel iniciar producao em lote: caldeirao nao encontrado.")
		return

	var sucesso := bool(cauldron_ui.iniciar_producao_em_lote(recipe_id, quantidade))
	if sucesso:
		fechar_livro_receitas()
	else:
		push_warning("A producao em lote falhou para a receita %s." % recipe_id)

func _instanciar_livro_receitas() -> void:
	recipe_book = recipe_book_scene.instantiate()
	var cauldron_popup_layer := get_tree().current_scene.get_node_or_null("CauldronUI/PopupLayer")
	if cauldron_popup_layer:
		cauldron_popup_layer.visible = true
		cauldron_popup_layer.add_child(recipe_book)
	else:
		add_child(recipe_book)
	recipe_book.mouse_filter = Control.MOUSE_FILTER_PASS
	recipe_book.z_index = 200
	recipe_book.visibility_changed.connect(func():
		if recipe_book:
			recipe_book.mouse_filter = Control.MOUSE_FILTER_STOP if recipe_book.visible else Control.MOUSE_FILTER_PASS
	)
	if recipe_book.has_signal("craft_requested"):
		recipe_book.craft_requested.connect(_on_recipe_book_craft_requested)
	_vincular_caldeirao_no_livro(_resolver_caldeirao(get_tree().current_scene.get_node_or_null("CauldronUI")))

func _vincular_caldeirao_no_livro(cauldron: Node) -> void:
	if recipe_book == null or cauldron == null:
		return

	if not cauldron.has_method("iniciar_producao_em_lote"):
		push_warning("UI: o no recebido como caldeirao nao possui iniciar_producao_em_lote: %s" % cauldron.get_path())
		return

	if recipe_book.has_method("set_cauldron"):
		recipe_book.set_cauldron(cauldron)
	elif recipe_book.has_method("set_cauldron_reference"):
		recipe_book.set_cauldron_reference(cauldron)
	else:
		push_warning("UI: RecipeBookUI nao possui metodo para vincular caldeirao.")

func _resolver_caldeirao(cauldron: Node = null) -> Node:
	if cauldron != null and cauldron.has_method("iniciar_producao_em_lote"):
		return cauldron

	var cauldrons := get_tree().get_nodes_in_group("cauldrons")
	for node in cauldrons:
		if node != null and node.has_method("iniciar_producao_em_lote"):
			return node

	return null
