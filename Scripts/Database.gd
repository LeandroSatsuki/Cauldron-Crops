extends Node

const RECEITA_ITEM_IDS := [
	"agua",
	"peixe_comum",
	"carvao",
	"trigo",
	"tomate_sol",
	"abobora_sombria",
	"raiz_gelida",
	"palha_rara",
	"rama_encantada",
	"semente_basica",
	"semente_inverno",
	"semente_verao",
	"semente_outono",
	"pocao_crescimento",
	"pocao_aceleradora",
	"essencia_sombria",
	"adubo_flamejante",
	"elixir_estacional",
	"golem_coletor"
]

const ITEM_FALLBACK_DATA: Dictionary = {
	"nome": "",
	"categoria": "desconhecida",
	"raridade": "desconhecida",
	"valor_base": 0,
	"pode_vender": false,
	"pode_usar_em_receita": false,
	"tags": [],
	"origem": "desconhecida",
	"descricao": "",
	"icone": "?"
}

var itens: Dictionary = {
	"agua": {
		"nome": "Água",
		"categoria": "recurso",
		"raridade": "comum",
		"valor_base": 0,
		"pode_vender": false,
		"pode_usar_em_receita": false,
		"tags": ["recurso", "agua", "irrigacao"],
		"origem": "poco",
		"descricao": "Recurso básico usado para irrigação e apoio ao cultivo.",
		"icone": "💧"
	},
	"carvao": {
		"nome": "Carvão",
		"categoria": "ingrediente",
		"raridade": "comum",
		"valor_base": 12,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["mineral", "combustivel", "ingrediente"],
		"origem": "coleta",
		"descricao": "Material simples usado em misturas e receitas básicas.",
		"icone": "⚫"
	},
	"trigo": {
		"nome": "Trigo",
		"categoria": "crop",
		"raridade": "comum",
		"valor_base": 15,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["crop", "cereal", "ingrediente"],
		"origem": "cultivo",
		"descricao": "Colheita básica e versátil da fazenda.",
		"icone": "🌾"
	},
	"tomate_sol": {
		"nome": "Tomate do Sol",
		"categoria": "crop",
		"raridade": "comum",
		"valor_base": 25,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["crop", "vegetal", "ingrediente", "verao"],
		"origem": "cultivo",
		"descricao": "Colheita luminosa, boa para receitas simples e futuras misturas.",
		"icone": "🍅"
	},
	"abobora_sombria": {
		"nome": "Abóbora Sombria",
		"categoria": "crop",
		"raridade": "comum",
		"valor_base": 35,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["crop", "vegetal", "ingrediente", "outono"],
		"origem": "cultivo",
		"descricao": "Colheita sazonal com uso em receitas mais misteriosas.",
		"icone": "🎃"
	},
	"raiz_gelida": {
		"nome": "Raiz Gélida",
		"categoria": "crop",
		"raridade": "comum",
		"valor_base": 20,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["crop", "raiz", "ingrediente", "frio"],
		"origem": "cultivo",
		"descricao": "Raiz resistente ao frio, útil em receitas geladas.",
		"icone": "🧊"
	},
	"palha_rara": {
		"nome": "Palha Rara",
		"categoria": "ingrediente",
		"raridade": "raro",
		"valor_base": 500,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["ingrediente", "fibra", "raridade"],
		"origem": "colheita",
		"descricao": "Material incomum usado em receitas e progressão futura.",
		"icone": "🟨"
	},
	"rama_encantada": {
		"nome": "Rama Encantada",
		"categoria": "ingrediente",
		"raridade": "raro",
		"valor_base": 300,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["ingrediente", "magico", "ramagem"],
		"origem": "colheita",
		"descricao": "Ramo misterioso usado em alquimia e receitas especiais.",
		"icone": "🌿"
	},
	"semente_basica": {
		"nome": "Semente de Trigo",
		"categoria": "semente",
		"raridade": "comum",
		"valor_base": 5,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["semente", "crop", "trigo"],
		"origem": "cultivo",
		"descricao": "Semente básica usada para iniciar o ciclo de cultivo.",
		"icone": "🌱"
	},
	"semente_inverno": {
		"nome": "Semente de Raiz",
		"categoria": "semente",
		"raridade": "comum",
		"valor_base": 20,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["semente", "crop", "frio"],
		"origem": "cultivo",
		"descricao": "Semente adaptada a plantações de inverno.",
		"icone": "❄️"
	},
	"semente_verao": {
		"nome": "Semente de Tomate",
		"categoria": "semente",
		"raridade": "comum",
		"valor_base": 10,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["semente", "crop", "verao"],
		"origem": "cultivo",
		"descricao": "Semente calorosa para plantações de verão.",
		"icone": "☀️"
	},
	"semente_outono": {
		"nome": "Semente de Abóbora",
		"categoria": "semente",
		"raridade": "comum",
		"valor_base": 15,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["semente", "crop", "outono"],
		"origem": "cultivo",
		"descricao": "Semente sazonal para a colheita de outono.",
		"icone": "🍁"
	},
	"pocao_crescimento": {
		"nome": "Poção de Crescimento",
		"categoria": "consumivel",
		"raridade": "comum",
		"valor_base": 18,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["pocao", "consumivel", "crescimento"],
		"origem": "alquimia",
		"descricao": "Acelera o crescimento das plantações por um curto período.",
		"icone": "🧪"
	},
	"pocao_aceleradora": {
		"nome": "Poção Aceleradora",
		"categoria": "consumivel",
		"raridade": "comum",
		"valor_base": 24,
		"pode_vender": true,
		"pode_usar_em_receita": false,
		"tags": ["pocao", "consumivel", "velocidade"],
		"origem": "alquimia",
		"descricao": "Apoio simples para acelerar processos da fazenda.",
		"icone": "⚡"
	},
	"essencia_sombria": {
		"nome": "Essência Sombria",
		"categoria": "ingrediente",
		"raridade": "raro",
		"valor_base": 30,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["ingrediente", "magico", "sombrio"],
		"origem": "alquimia",
		"descricao": "Ingrediente arcano usado em misturas mais densas.",
		"icone": "🔮"
	},
	"adubo_flamejante": {
		"nome": "Adubo Flamejante",
		"categoria": "consumivel",
		"raridade": "raro",
		"valor_base": 40,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["adubo", "consumivel", "fogo"],
		"origem": "alquimia",
		"descricao": "Adubo especial usado em receitas e futuras melhorias.",
		"icone": "🔥"
	},
	"elixir_estacional": {
		"nome": "Elixir Estacional",
		"categoria": "consumivel",
		"raridade": "raro",
		"valor_base": 45,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["elixir", "consumivel", "estacao"],
		"origem": "alquimia",
		"descricao": "Elixir ligado ao ciclo das estações e da fazenda.",
		"icone": "🍶"
	},
	"golem_coletor": {
		"nome": "Golem Coletor",
		"categoria": "utilitario",
		"raridade": "epico",
		"valor_base": 0,
		"pode_vender": false,
		"pode_usar_em_receita": false,
		"tags": ["golem", "utilitario", "invocacao"],
		"origem": "alquimia",
		"descricao": "Resultado especial ligado à automação e ao Baú da Vila.",
		"icone": "🤖"
	},
	"pocao_purificadora_fraca": {
		"nome": "Poção Purificadora Fraca",
		"categoria": "pocao",
		"raridade": "incomum",
		"valor_base": 0,
		"pode_vender": false,
		"pode_usar_em_receita": false,
		"tags": ["pocao", "purificacao", "magico"],
		"origem": "caldeirao",
		"descricao": "Uma poção simples capaz de enfraquecer pequenas corrupções mágicas.",
		"icone": "🧪"
	},
	"peixe_comum": {
		"nome": "Peixe Comum",
		"categoria": "pesca",
		"raridade": "comum",
		"valor_base": 8,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["peixe", "aquatico", "ingrediente"],
		"origem": "pesca",
		"descricao": "Um peixe simples, útil para receitas e venda básica.",
		"icone": "🐟"
	},
	"escama_brilhante": {
		"nome": "Escama Brilhante",
		"categoria": "ingrediente_aquatico",
		"raridade": "raro",
		"valor_base": 25,
		"pode_vender": true,
		"pode_usar_em_receita": true,
		"tags": ["escama", "aquatico", "magico", "ingrediente"],
		"origem": "pesca",
		"descricao": "Escama luminosa útil em receitas aquáticas e mágicas.",
		"icone": "✨"
	}
}

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
	"trigo_raiz_gelida": "pocao_crescimento",
	"carvao_trigo": "pocao_aceleradora",
	"carvao_raiz_gelida": "essencia_sombria",
	"tomate_sol_trigo": "adubo_flamejante",
	"abobora_sombria_raiz_gelida": "elixir_estacional",
	"palha_rara_rama_encantada": "golem_coletor",
	"tomate_sol_raiz_gelida": "semente_outono",
	"raiz_gelida_peixe_comum": "pocao_purificadora_fraca",
	"peixe_comum_trigo": "pocao_aceleradora"
}

var quests_exemplos: Dictionary = {
	"q1": {"estacao": "geral", "pedido_item": "trigo", "pedido_qtd": 10, "recompensa_tipo": "moedas", "recompensa_qtd": 300, "texto": "A Taverna precisa de Trigo!"},
	"q2": {"estacao": 0, "pedido_item": "agua", "pedido_qtd": 5, "recompensa_tipo": "pontos_alquimia", "recompensa_qtd": 1, "texto": "Pesquisa de Primavera: Traga água limpa."},
	"q3": {"estacao": 2, "pedido_item": "abobora_sombria", "pedido_qtd": 3, "recompensa_tipo": "semente_inverno", "recompensa_qtd": 2, "texto": "Festival de Outono! Precisamos de Abóboras."}
}

func fabricar_pocao(ingrediente1: String, ingrediente2: String) -> String:
	var lista = [ingrediente1, ingrediente2]
	lista.sort()
	var chave = lista[0] + "_" + lista[1]
	if receitas_alquimia.has(chave):
		return receitas_alquimia[chave]
	return "falha_gororoba"

func obter_ingredientes_receita(receita_id: String) -> Array:
	for i in range(RECEITA_ITEM_IDS.size()):
		for j in range(i, RECEITA_ITEM_IDS.size()):
			var ingrediente_a := str(RECEITA_ITEM_IDS[i])
			var ingrediente_b := str(RECEITA_ITEM_IDS[j])
			if receita_id == "%s_%s" % [ingrediente_a, ingrediente_b]:
				return [ingrediente_a, ingrediente_b]
			if receita_id == "%s_%s" % [ingrediente_b, ingrediente_a]:
				return [ingrediente_b, ingrediente_a]

	return []

func obter_item_data(item_id: String) -> Dictionary:
	if item_id == "":
		return _montar_item_fallback("")

	if itens.has(item_id):
		var item_variant: Variant = itens[item_id]
		if typeof(item_variant) == TYPE_DICTIONARY:
			var item_data: Dictionary = (item_variant as Dictionary).duplicate(true)
			item_data["item_id"] = item_id
			return item_data

	return _montar_item_fallback(item_id)

func obter_nome_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	var nome: String = str(item_data.get("nome", ""))
	return nome if nome != "" else item_id

func obter_icone_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	var icone: String = str(item_data.get("icone", "?"))
	return icone if icone != "" else "?"

func obter_valor_base_item(item_id: String) -> int:
	var item_data: Dictionary = obter_item_data(item_id)
	return int(item_data.get("valor_base", 0))

func item_pode_usar_em_receita(item_id: String) -> bool:
	var item_data: Dictionary = obter_item_data(item_id)
	return bool(item_data.get("pode_usar_em_receita", false))

func item_pode_vender(item_id: String) -> bool:
	var item_data: Dictionary = obter_item_data(item_id)
	return bool(item_data.get("pode_vender", false))

func obter_tags_item(item_id: String) -> Array:
	var item_data: Dictionary = obter_item_data(item_id)
	var tags_variant: Variant = item_data.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return []
	return (tags_variant as Array).duplicate(true)

func obter_categoria_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	return str(item_data.get("categoria", "desconhecida"))

func obter_raridade_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	return str(item_data.get("raridade", "desconhecida"))

func obter_origem_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	return str(item_data.get("origem", "desconhecida"))

func obter_descricao_item(item_id: String) -> String:
	var item_data: Dictionary = obter_item_data(item_id)
	return str(item_data.get("descricao", ""))

func _montar_item_fallback(item_id: String) -> Dictionary:
	var item_fallback: Dictionary = ITEM_FALLBACK_DATA.duplicate(true)
	item_fallback["item_id"] = item_id
	item_fallback["nome"] = item_id if item_id != "" else "item_desconhecido"
	return item_fallback
