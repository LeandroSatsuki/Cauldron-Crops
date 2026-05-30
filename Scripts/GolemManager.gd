extends Node

var tempo_acumulado: float = 0.0

func _process(delta: float) -> void:
	if EconomyManager.total_golems > 0:
		tempo_acumulado += delta
		if tempo_acumulado >= 4.0:
			tempo_acumulado = 0.0
			_colher_automaticamente()

func _colher_automaticamente() -> void:
	var colheitas_permitidas = EconomyManager.total_golems * 2
	var colheitas_feitas = 0
	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	for lote in lotes:
		if colheitas_feitas >= colheitas_permitidas:
			break
		if lote.estado_atual == lote.State.PRONTO_PARA_COLHER:
			lote._on_plot_clicked()
			colheitas_feitas += 1
