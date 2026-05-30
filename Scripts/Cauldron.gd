extends Panel

@onready var slot_1: OptionButton = $Slot1
@onready var slot_2: OptionButton = $Slot2
@onready var misturar_button: Button = $MisturarButton
@onready var resultado_label: Label = $ResultadoLabel

var ultimo_inventario_cache: Dictionary = {}

func _ready() -> void:
	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)
	_atualizar_options_se_necessario()

func _process(_delta: float) -> void:
	_atualizar_options_se_necessario()

func _atualizar_options_se_necessario() -> void:
	var inventario_filtrado = {}
	for key in GlobalInventory.inventario:
		if GlobalInventory.inventario[key] >= 1:
			inventario_filtrado[key] = GlobalInventory.inventario[key]
			
	var precisa_atualizar = false
	if inventario_filtrado.size() != ultimo_inventario_cache.size():
		precisa_atualizar = true
	else:
		for key in inventario_filtrado:
			if not ultimo_inventario_cache.has(key) or inventario_filtrado[key] != ultimo_inventario_cache[key]:
				precisa_atualizar = true
				break
				
	if precisa_atualizar:
		ultimo_inventario_cache = inventario_filtrado.duplicate()
		_preencher_options(inventario_filtrado.keys())

func _preencher_options(itens: Array) -> void:
	var sel_text1 = ""
	if slot_1 and slot_1.selected != -1 and slot_1.selected < slot_1.item_count:
		sel_text1 = slot_1.get_item_text(slot_1.selected)
		
	var sel_text2 = ""
	if slot_2 and slot_2.selected != -1 and slot_2.selected < slot_2.item_count:
		sel_text2 = slot_2.get_item_text(slot_2.selected)
		
	if slot_1:
		slot_1.clear()
	if slot_2:
		slot_2.clear()
	
	for item in itens:
		if slot_1:
			slot_1.add_item(item)
		if slot_2:
			slot_2.add_item(item)
			
	# Restore selection if possible
	if sel_text1 != "" and slot_1:
		for i in range(slot_1.item_count):
			if slot_1.get_item_text(i) == sel_text1:
				slot_1.selected = i
				break
	if sel_text2 != "" and slot_2:
		for i in range(slot_2.item_count):
			if slot_2.get_item_text(i) == sel_text2:
				slot_2.selected = i
				break

func _on_misturar_button_pressed() -> void:
	if not slot_1 or not slot_2:
		return
		
	if slot_1.selected == -1 or slot_2.selected == -1:
		if resultado_label:
			resultado_label.text = "Selecione os ingredientes!"
		return
		
	var item1 = slot_1.get_item_text(slot_1.selected)
	var item2 = slot_2.get_item_text(slot_2.selected)
	
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
		
	# Consume items
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
