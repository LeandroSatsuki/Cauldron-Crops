extends CanvasLayer

var slot_scene = preload("res://Scenes/InventorySlot.tscn")

@onready var moedas_label: Label = $StatusPanel/MoedasLabel
@onready var season_label: Label = $StatusPanel/SeasonLabel
@onready var cargas_label: Label = $StatusPanel/CargasLabel
@onready var semente_label: Label = $StatusPanel/SementeLabel
@onready var golems_label: Label = $StatusPanel/GolemsLabel

@onready var usar_pocao_button: Button = $LeftPanel/UsarPocaoButton
@onready var dormir_button: Button = $LeftPanel/DormirButton
@onready var comprar_cosmetico_button: Button = $LeftPanel/ComprarCosmeticoButton
@onready var comprar_trigo_button: Button = $LeftPanel/GridSementes/ComprarTrigoButton
@onready var comprar_verao_button: Button = $LeftPanel/GridSementes/ComprarVeraoButton
@onready var comprar_golem_button: Button = $LeftPanel/ComprarGolemButton

@onready var inventory_bar: HBoxContainer = $InventoryBar
@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_texto: Label = $TooltipPanel/TooltipTexto
@onready var sell_menu: PanelContainer = $SellMenu

var ultimo_estado_inventario: Dictionary = {}

func _ready() -> void:
	if usar_pocao_button:
		usar_pocao_button.pressed.connect(_on_usar_pocao_button_pressed)
	if dormir_button:
		dormir_button.pressed.connect(_on_dormir_button_pressed)
	if comprar_cosmetico_button:
		comprar_cosmetico_button.pressed.connect(_on_comprar_cosmetico_button_pressed)
	if comprar_trigo_button:
		comprar_trigo_button.pressed.connect(_on_comprar_trigo_button_pressed)
		comprar_trigo_button.mouse_entered.connect(_on_comprar_trigo_button_mouse_entered)
		comprar_trigo_button.mouse_exited.connect(_on_comprar_trigo_button_mouse_exited)
	if comprar_verao_button:
		comprar_verao_button.pressed.connect(_on_comprar_verao_button_pressed)
		comprar_verao_button.mouse_entered.connect(_on_comprar_verao_button_mouse_entered)
		comprar_verao_button.mouse_exited.connect(_on_comprar_verao_button_mouse_exited)
	if comprar_golem_button:
		comprar_golem_button.pressed.connect(_on_comprar_golem_button_pressed)
		
	# Inicializa
	verificar_e_atualizar_inventario()

func _process(_delta: float) -> void:
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

func _on_slot_clicado(item_id: String) -> void:
	if item_id.begins_with("semente_"):
		GlobalInventory.semente_selecionada = item_id
		print("Semente selecionada equipada: ", item_id)
	else:
		if sell_menu:
			sell_menu.abrir(item_id, get_viewport().get_mouse_position())

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
	SeasonManager.avancar_estacao()

func _on_comprar_cosmetico_button_pressed() -> void:
	if EconomyManager.remover_moedas(50):
		print("Tema comprado e aplicado!")
		RenderingServer.set_default_clear_color(Color(0.1, 0.4, 0.1))

func _on_comprar_trigo_button_pressed() -> void:
	if EconomyManager.remover_moedas(5):
		GlobalInventory.adicionar_item("semente_basica", 1)
		criar_texto_flutuante("+1 Semente Trigo", get_viewport().get_mouse_position(), Color.YELLOW)

func _on_comprar_verao_button_pressed() -> void:
	if EconomyManager.remover_moedas(10):
		GlobalInventory.adicionar_item("semente_verao", 1)
		criar_texto_flutuante("+1 Semente Tomate", get_viewport().get_mouse_position(), Color.YELLOW)

func _on_comprar_golem_button_pressed() -> void:
	if EconomyManager.remover_moedas(100):
		EconomyManager.total_golems += 1

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
