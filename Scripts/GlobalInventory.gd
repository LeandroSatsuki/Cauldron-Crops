extends Node

var inventario: Dictionary = {
	"semente_basica": 10,
	"semente_inverno": 0
}
var cargas_crescimento: int = 0
var semente_selecionada: String = "semente_basica"
var receitas_descobertas: Array = []
var pontos_alquimia: int = 0
var skills_desbloqueadas: Array = []

func adicionar_item(produto: String, quantidade: int = 1) -> void:
	if inventario.has(produto):
		inventario[produto] += quantidade
	else:
		inventario[produto] = quantidade
	if produto != "agua":
		print("Item adicionado ao inventário: ", produto, " (Total: ", inventario[produto], ")")

func remover_item(nome_do_item: String, quantidade: int) -> bool:
	if inventario.has(nome_do_item) and inventario[nome_do_item] >= quantidade:
		inventario[nome_do_item] -= quantidade
		if nome_do_item != "agua":
			print("Item removido do inventário: ", nome_do_item, " (Restam: ", inventario[nome_do_item], ")")
		return true
	return false
