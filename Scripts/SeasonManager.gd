extends Node

enum Estacao { PRIMAVERA, VERAO, OUTONO, INVERNO }

var estacao_atual = Estacao.PRIMAVERA
var ano: int = 1

func avancar_estacao() -> void:
	if estacao_atual == Estacao.INVERNO:
		estacao_atual = Estacao.PRIMAVERA
		ano += 1
	else:
		estacao_atual = (estacao_atual + 1) as Estacao
	print("Nova Estação: ", obter_nome_estacao(), " | Ano: ", ano)

func obter_nome_estacao() -> String:
	match estacao_atual:
		Estacao.PRIMAVERA: return "Primavera"
		Estacao.VERAO: return "Verão"
		Estacao.OUTONO: return "Outono"
		Estacao.INVERNO: return "Inverno"
	return "Desconhecida"
