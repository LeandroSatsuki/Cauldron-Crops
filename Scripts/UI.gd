extends CanvasLayer

@onready var moedas_label: Label = $LeftPanel/MoedasLabel
@onready var estoque_label: Label = $LeftPanel/EstoqueLabel
@onready var vender_button: Button = $LeftPanel/VenderButton
@onready var usar_pocao_button: Button = $LeftPanel/UsarPocaoButton
@onready var cargas_label: Label = $LeftPanel/CargasLabel
@onready var dormir_button: Button = $LeftPanel/DormirButton
@onready var season_label: Label = $LeftPanel/SeasonLabel
@onready var comprar_cosmetico_button: Button = $LeftPanel/ComprarCosmeticoButton

func _ready() -> void:
	if vender_button:
		vender_button.pressed.connect(_on_vender_button_pressed)
	if usar_pocao_button:
		usar_pocao_button.pressed.connect(_on_usar_pocao_button_pressed)
	if dormir_button:
		dormir_button.pressed.connect(_on_dormir_button_pressed)
	if comprar_cosmetico_button:
		comprar_cosmetico_button.pressed.connect(_on_comprar_cosmetico_button_pressed)

func _process(_delta: float) -> void:
	if moedas_label:
		moedas_label.text = "Moedas: " + str(EconomyManager.moedas)
	if estoque_label:
		var trigo_count = GlobalInventory.inventario.get("trigo", 0)
		estoque_label.text = "Trigo no Estoque: " + str(trigo_count)
	if cargas_label:
		cargas_label.text = "Cargas Mágicas: " + str(GlobalInventory.cargas_crescimento)
	if season_label:
		season_label.text = "Estação: " + SeasonManager.obter_nome_estacao() + " | Ano: " + str(SeasonManager.ano)

func _on_vender_button_pressed() -> void:
	if GlobalInventory.remover_item("trigo", 1):
		EconomyManager.adicionar_moedas(15)

func _on_usar_pocao_button_pressed() -> void:
	if GlobalInventory.remover_item("pocao_crescimento", 1):
		GlobalInventory.cargas_crescimento += 3

func _on_dormir_button_pressed() -> void:
	SeasonManager.avancar_estacao()

func _on_comprar_cosmetico_button_pressed() -> void:
	if EconomyManager.remover_moedas(50):
		print("Tema comprado e aplicado!")
		RenderingServer.set_default_clear_color(Color(0.1, 0.4, 0.1))
