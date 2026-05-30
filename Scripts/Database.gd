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

var semente_verao: Dictionary = {
	"nome": "Tomate do Sol",
	"tempo_crescimento_segundos": 5.0,
	"produto_colheita": "tomate_sol",
	"valor_venda": 25,
	"estacao_ideal": SeasonManager.Estacao.VERAO
}

var semente_outono: Dictionary = {
	"nome": "Abóbora Sombria",
	"tempo_crescimento_segundos": 6.0,
	"produto_colheita": "abobora_sombria",
	"valor_venda": 35,
	"estacao_ideal": SeasonManager.Estacao.OUTONO
}

var precos: Dictionary = {
	"trigo": 15,
	"tomate_sol": 25,
	"abobora_sombria": 35,
	"raiz_gelida": 20,
	"palha_rara": 500,
	"rama_encantada": 300
}

var custo_semente = {
	"semente_basica": 5,
	"semente_verao": 10,
	"semente_outono": 15,
	"semente_inverno": 20,
	"palha_rara": 500,
	"rama_encantada": 300
}

var receitas_alquimia: Dictionary = {
	"agua_trigo": "pocao_crescimento",
	"carvao_trigo": "pocao_aceleradora",
	"agua_carvao": "essencia_sombria",
	"tomate_sol_trigo": "adubo_flamejante",
	"abobora_sombria_raiz_gelida": "elixir_estacional",
	"palha_rara_rama_encantada": "golem_coletor",
	"agua_tomate_sol": "semente_outono",
	"agua_raiz_gelida": "pocao_crescimento"
}

func fabricar_pocao(ingrediente1: String, ingrediente2: String) -> String:
	var lista = [ingrediente1, ingrediente2]
	lista.sort()
	var chave = lista[0] + "_" + lista[1]
	if receitas_alquimia.has(chave):
		return receitas_alquimia[chave]
	return "falha_gororoba"
