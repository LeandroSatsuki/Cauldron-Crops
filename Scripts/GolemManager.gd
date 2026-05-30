extends Node

var tempo_acumulado: float = 0.0

func _process(delta: float) -> void:
	if EconomyManager.total_golems > 0:
		tempo_acumulado += delta
		if tempo_acumulado >= 2.0:
			tempo_acumulado = 0.0
			_colher_automaticamente()

func _colher_automaticamente() -> void:
	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	for lote in lotes:
		if lote.estado_atual == lote.State.PRONTO_PARA_COLHER:
			lote._on_plot_clicked()
