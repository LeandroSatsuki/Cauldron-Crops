extends Panel

var ing_1: String = ""
var ing_2: String = ""

@onready var slot_1: Label = $Slot1
@onready var slot_2: Label = $Slot2
@onready var misturar_button: Button = $MisturarButton
@onready var resultado_label: Label = $ResultadoLabel
@onready var add_trigo_button: Button = $AddTrigoButton
@onready var add_agua_button: Button = $AddAguaButton

func _ready() -> void:
	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)
	if add_trigo_button:
		add_trigo_button.pressed.connect(func(): adicionar_ingrediente("trigo"))
	if add_agua_button:
		add_agua_button.pressed.connect(func(): adicionar_ingrediente("agua"))

func adicionar_ingrediente(nome_item: String) -> void:
	var slot_disponivel = ""
	if ing_1 == "":
		slot_disponivel = "slot1"
	elif ing_2 == "":
		slot_disponivel = "slot2"
	
	if slot_disponivel == "":
		print("Ambos os slots estão cheios!")
		return
		
	if GlobalInventory.remover_item(nome_item, 1):
		if slot_disponivel == "slot1":
			ing_1 = nome_item
			if slot_1:
				slot_1.text = nome_item
		else:
			ing_2 = nome_item
			if slot_2:
				slot_2.text = nome_item

func _on_misturar_button_pressed() -> void:
	if ing_1 == "" or ing_2 == "":
		return
	
	var resultado = Database.fabricar_pocao(ing_1, ing_2)
	
	if resultado_label:
		resultado_label.text = "Resultado: " + resultado
		
	GlobalInventory.adicionar_item(resultado)
	
	ing_1 = ""
	ing_2 = ""
	if slot_1:
		slot_1.text = "Vazio"
	if slot_2:
		slot_2.text = "Vazio"
