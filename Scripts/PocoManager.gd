extends Node

var tempo_acumulado: float = 0.0

func _process(delta: float) -> void:
	tempo_acumulado += delta
	if tempo_acumulado >= 1.0:
		tempo_acumulado -= 1.0
		var agua_atual = GlobalInventory.inventario.get("agua", 0)
		if agua_atual < EconomyManager.poco_capacidade_maxima:
			GlobalInventory.adicionar_item("agua", 1)
