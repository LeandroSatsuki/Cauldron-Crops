extends Node

signal quest_atualizada

var quests_ativas: Array = []
var max_quests: int = 2

func tentar_gerar_quest() -> void:
	if quests_ativas.size() >= max_quests:
		return
		
	if randf() <= 0.30:
		var candidatos = []
		for key in Database.quests_exemplos:
			var q = Database.quests_exemplos[key]
			var estacao_ok = false
			if typeof(q.get("estacao")) == TYPE_STRING and q.get("estacao") == "geral":
				estacao_ok = true
			elif typeof(q.get("estacao")) == TYPE_INT and q.get("estacao") == SeasonManager.estacao_atual:
				estacao_ok = true
			
			if estacao_ok:
				# Verificar se já não está ativa
				var ja_ativa = false
				for active_q in quests_ativas:
					if active_q.get("texto") == q.get("texto"):
						ja_ativa = true
						break
				if not ja_ativa:
					var q_copy = q.duplicate()
					q_copy["id"] = key
					q_copy["aceita"] = false
					candidatos.append(q_copy)
					
		if candidatos.size() > 0:
			var quest_sorteada = candidatos[randi() % candidatos.size()]
			quests_ativas.append(quest_sorteada)
			quest_atualizada.emit()
			print("Nova Quest Gerada: ", quest_sorteada.get("texto"))

func limpar_quests_ignoradas() -> void:
	for i in range(quests_ativas.size() - 1, -1, -1):
		var q = quests_ativas[i]
		if not q.get("aceita", false):
			quests_ativas.remove_at(i)
