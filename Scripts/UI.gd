extends CanvasLayer

@onready var moedas_label: Label = $StatusPanel/MoedasLabel
@onready var season_label: Label = $StatusPanel/SeasonLabel
@onready var cargas_label: Label = $StatusPanel/CargasLabel
@onready var semente_label: Label = $StatusPanel/SementeLabel
@onready var golems_label: Label = $StatusPanel/GolemsLabel

@onready var vender_button: Button = $LeftPanel/VenderButton
@onready var usar_pocao_button: Button = $LeftPanel/UsarPocaoButton
@onready var dormir_button: Button = $LeftPanel/DormirButton
@onready var comprar_cosmetico_button: Button = $LeftPanel/ComprarCosmeticoButton
@onready var comprar_trigo_button: Button = $LeftPanel/GridSementes/ComprarTrigoButton
@onready var comprar_verao_button: Button = $LeftPanel/GridSementes/ComprarVeraoButton
@onready var equipar_trigo_button: Button = $LeftPanel/EquiparTrigoButton
@onready var equipar_inverno_button: Button = $LeftPanel/EquiparInvernoButton
@onready var equipar_verao_button: Button = $LeftPanel/EquiparVeraoButton
@onready var equipar_outono_button: Button = $LeftPanel/EquiparOutonoButton
@onready var comprar_golem_button: Button = $LeftPanel/ComprarGolemButton

@onready var trigo_label: Label = $InventoryBar/TrigoLabel
@onready var raiz_label: Label = $InventoryBar/RaizLabel
@onready var pocoes_label: Label = $InventoryBar/PocoesLabel
@onready var agua_label: Label = $InventoryBar/AguaLabel
@onready var semente_basica_label: Label = $InventoryBar/SementeBasicaLabel
@onready var semente_inverno_label: Label = $InventoryBar/SementeInvernoLabel
@onready var semente_verao_label: Label = $InventoryBar/SementeVeraoLabel
@onready var semente_outono_label: Label = $InventoryBar/SementeOutonoLabel

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_texto: Label = $TooltipPanel/TooltipTexto

func _ready() -> void:
	if vender_button:
		vender_button.pressed.connect(_on_vender_button_pressed)
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
	if equipar_trigo_button:
		equipar_trigo_button.pressed.connect(_on_equipar_trigo_button_pressed)
	if equipar_inverno_button:
		equipar_inverno_button.pressed.connect(_on_equipar_inverno_button_pressed)
	if equipar_verao_button:
		equipar_verao_button.pressed.connect(_on_equipar_verao_button_pressed)
	if equipar_outono_button:
		equipar_outono_button.pressed.connect(_on_equipar_outono_button_pressed)
	if comprar_golem_button:
		comprar_golem_button.pressed.connect(_on_comprar_golem_button_pressed)

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
		
	if trigo_label:
		trigo_label.text = "🌾 Trigo: " + str(GlobalInventory.inventario.get("trigo", 0))
	if raiz_label:
		raiz_label.text = "🧊 Raiz: " + str(GlobalInventory.inventario.get("raiz_gelida", 0))
	if pocoes_label:
		pocoes_label.text = "🧪 Poções: " + str(GlobalInventory.inventario.get("pocao_crescimento", 0))
	if agua_label:
		agua_label.text = "💧 Água: " + str(GlobalInventory.inventario.get("agua", 0))
	if semente_basica_label:
		semente_basica_label.text = "🌱 Semente Trigo: " + str(GlobalInventory.inventario.get("semente_basica", 0))
	if semente_inverno_label:
		semente_inverno_label.text = "❄️ Semente Raiz: " + str(GlobalInventory.inventario.get("semente_inverno", 0))
	if semente_verao_label:
		semente_verao_label.text = "☀️ Semente Tomate: " + str(GlobalInventory.inventario.get("semente_verao", 0))
	if semente_outono_label:
		semente_outono_label.text = "🍁 Semente Abóbora: " + str(GlobalInventory.inventario.get("semente_outono", 0))

func _on_vender_button_pressed() -> void:
	if GlobalInventory.remover_item("trigo", 1):
		EconomyManager.adicionar_moedas(15)
		criar_texto_flutuante("+15 Moedas", moedas_label.global_position + Vector2(100, 0), Color.GREEN)

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

func _on_equipar_trigo_button_pressed() -> void:
	GlobalInventory.semente_selecionada = "semente_basica"

func _on_equipar_inverno_button_pressed() -> void:
	GlobalInventory.semente_selecionada = "semente_inverno"

func _on_equipar_verao_button_pressed() -> void:
	GlobalInventory.semente_selecionada = "semente_verao"

func _on_equipar_outono_button_pressed() -> void:
	GlobalInventory.semente_selecionada = "semente_outono"

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
