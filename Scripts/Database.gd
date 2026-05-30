extends Node

var semente_basica: Dictionary = {
	"tempo_crescimento_segundos": 3.0,
	"produto_colheita": "trigo",
	"estacao_ideal": SeasonManager.Estacao.PRIMAVERA
}

var semente_inverno: Dictionary = {
	"nome": "Raiz Gélida",
	"tempo_crescimento_segundos": 4.0,
	"produto_colheita": "raiz_gelida",
	"valor_venda": 20,
	"estacao_ideal": SeasonManager.Estacao.INVERNO
}

var receitas_alquimia: Dictionary = {
	"agua_trigo": "pocao_crescimento",
	"carvao_trigo": "pocao_aceleradora",
	"agua_carvao": "essencia_sombria"
}

func fabricar_pocao(ingrediente1: String, ingrediente2: String) -> String:
	var lista = [ingrediente1, ingrediente2]
	lista.sort()
	var chave = lista[0] + "_" + lista[1]
	if receitas_alquimia.has(chave):
		return receitas_alquimia[chave]
	return "falha_gororoba"
