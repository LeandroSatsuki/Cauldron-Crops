extends Panel

@onready var drop_slot_1: Panel = $DropSlot1
@onready var drop_slot_2: Panel = $DropSlot2
@onready var misturar_button: Button = $MisturarButton
@onready var resultado_label: Label = $ResultadoLabel

func _ready() -> void:
	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)

func _on_misturar_button_pressed() -> void:
	if not drop_slot_1 or not drop_slot_2:
		return
		
	var item1 = drop_slot_1.item_vinculado
	var item2 = drop_slot_2.item_vinculado
	
	if item1 == "" or item2 == "":
		if resultado_label:
			resultado_label.text = "Solte ingredientes nos slots!"
		return
		
	var qtd1 = GlobalInventory.inventario.get(item1, 0)
	var qtd2 = GlobalInventory.inventario.get(item2, 0)
	
	var ok = false
	if item1 == item2:
		if qtd1 >= 2:
			ok = true
	else:
		if qtd1 >= 1 and qtd2 >= 1:
			ok = true
			
	if not ok:
		if resultado_label:
			resultado_label.text = "Ingredientes insuficientes!"
		return
		
	# Consume items from GlobalInventory
	var removed_1 = GlobalInventory.remover_item(item1, 1)
	var removed_2 = GlobalInventory.remover_item(item2, 1)
	
	if not (removed_1 and removed_2):
		if removed_1:
			GlobalInventory.adicionar_item(item1, 1)
		if removed_2:
			GlobalInventory.adicionar_item(item2, 1)
		if resultado_label:
			resultado_label.text = "Erro ao consumir ingredientes!"
		return
		
	var chave1 = item1 + "_" + item2
	var chave2 = item2 + "_" + item1
	var resultado = ""
	
	if Database.receitas_alquimia.has(chave1):
		resultado = Database.receitas_alquimia[chave1]
	elif Database.receitas_alquimia.has(chave2):
		resultado = Database.receitas_alquimia[chave2]
		
	if resultado != "":
		GlobalInventory.adicionar_item(resultado, 1)
		
		var chave_combinacao = chave1 if Database.receitas_alquimia.has(chave1) else chave2
		if not GlobalInventory.receitas_descobertas.has(chave_combinacao):
			GlobalInventory.receitas_descobertas.append(chave_combinacao)
			
		if resultado_label:
			resultado_label.text = "Nova Descoberta: " + resultado
	else:
		if resultado_label:
			resultado_label.text = "Mistura falhou! Ingredientes perdidos."
