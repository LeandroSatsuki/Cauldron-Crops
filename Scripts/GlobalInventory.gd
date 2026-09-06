extends Node

const COLECAO_PESCA_ITENS: Array[String] = ["peixe_comum", "escama_brilhante"]
const BONUS_COLECAO_PESCA_NOME := "Memória das Marés"

var inventario: Dictionary = {
	"semente_basica": 10,
	"semente_inverno": 0
}
var cargas_crescimento: int = 0
var semente_selecionada: String = "semente_basica"
var receitas_descobertas: Array = []
var pontos_alquimia: int = 0
var skills_desbloqueadas: Array = []
var colecao_pesca_descobertas: Array[String] = []
var colecao_pesca_concluida: bool = false

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

func registrar_item_colecao_pesca(item_id: String) -> Dictionary:
	var ja_descoberto := item_id in colecao_pesca_descobertas
	if item_id in COLECAO_PESCA_ITENS and not ja_descoberto:
		colecao_pesca_descobertas.append(item_id)

	var estava_concluida := colecao_pesca_concluida
	colecao_pesca_concluida = _colecao_pesca_esta_completa()
	var progresso := obter_progresso_colecao_pesca()
	progresso["nova_descoberta"] = item_id in COLECAO_PESCA_ITENS and not ja_descoberto
	progresso["concluida_agora"] = not estava_concluida and colecao_pesca_concluida
	return progresso

func obter_progresso_colecao_pesca() -> Dictionary:
	_normalizar_colecao_pesca()
	return {
		"descobertas": colecao_pesca_descobertas.duplicate(),
		"quantidade": colecao_pesca_descobertas.size(),
		"total": COLECAO_PESCA_ITENS.size(),
		"concluida": colecao_pesca_concluida,
		"bonus_nome": BONUS_COLECAO_PESCA_NOME,
	}

func aplicar_colecao_pesca_save(descobertas: Array, concluida: bool) -> void:
	colecao_pesca_descobertas.clear()
	for item_variant in descobertas:
		var item_id := str(item_variant)
		if item_id in COLECAO_PESCA_ITENS and not item_id in colecao_pesca_descobertas:
			colecao_pesca_descobertas.append(item_id)
	colecao_pesca_concluida = concluida or _colecao_pesca_esta_completa()

func possui_bonus_colecao_pesca() -> bool:
	return colecao_pesca_concluida

func _colecao_pesca_esta_completa() -> bool:
	_normalizar_colecao_pesca()
	return colecao_pesca_descobertas.size() == COLECAO_PESCA_ITENS.size()

func _normalizar_colecao_pesca() -> void:
	var descobertas_validas: Array[String] = []
	for item_id in COLECAO_PESCA_ITENS:
		if item_id in colecao_pesca_descobertas:
			descobertas_validas.append(item_id)
	colecao_pesca_descobertas = descobertas_validas
	colecao_pesca_concluida = colecao_pesca_descobertas.size() == COLECAO_PESCA_ITENS.size()
