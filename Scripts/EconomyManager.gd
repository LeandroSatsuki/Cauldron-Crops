extends Node

var moedas : int = 0
var total_golems: int = 0

func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	print("Moedas adicionadas: ", quantidade, " (Total: ", moedas, ")")

func remover_moedas(quantidade: int) -> bool:
	if moedas >= quantidade:
		moedas -= quantidade
		print("Moedas removidas: ", quantidade, " (Restam: ", moedas, ")")
		return true
	return false
