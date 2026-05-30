extends Panel

@onready var resultado_label: Label = $ResultadoLabel
@onready var lista_receitas: VBoxContainer = $ScrollContainer/ListaReceitas

func _ready() -> void:
	for receita_key in Database.receitas_alquimia:
		var ingredientes = receita_key.split("_")
		var ingred1 = ingredientes[0]
		var ingred2 = ingredientes[1]
		var item_resultado = Database.receitas_alquimia[receita_key]
		
		var button = Button.new()
		button.text = "Fazer " + item_resultado + " (Requer: " + ingred1 + " + " + ingred2 + ")"
		button.pressed.connect(_tentar_fabricar.bind(ingred1, ingred2, item_resultado))
		if lista_receitas:
			lista_receitas.add_child(button)

func _tentar_fabricar(ingred1: String, ingred2: String, resultado: String) -> void:
	var qtd1 = GlobalInventory.inventario.get(ingred1, 0)
	var qtd2 = GlobalInventory.inventario.get(ingred2, 0)
	
	if qtd1 >= 1 and qtd2 >= 1:
		# Remover ambos os ingredientes
		var removed_1 = GlobalInventory.remover_item(ingred1, 1)
		var removed_2 = GlobalInventory.remover_item(ingred2, 1)
		
		if removed_1 and removed_2:
			GlobalInventory.adicionar_item(resultado, 1)
			if resultado_label:
				resultado_label.text = "Sucesso: " + resultado + " criado!"
		else:
			# Rollback if one somehow failed (shouldn't happen because of the check)
			if removed_1:
				GlobalInventory.adicionar_item(ingred1, 1)
			if removed_2:
				GlobalInventory.adicionar_item(ingred2, 1)
			if resultado_label:
				resultado_label.text = "Erro ao fabricar!"
	else:
		if resultado_label:
			resultado_label.text = "Faltam ingredientes!"
