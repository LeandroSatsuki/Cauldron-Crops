extends Node2D

const GRID_SIZE = 64.0
const TEMPO_POR_BLOCO = 0.5 # Exatos 2 quadrados por segundo

var base_pos: Vector2
var estado: String = "IDLE"
var alvo_atual: Node2D = null

func _ready() -> void:
	base_pos = global_position # Salva a casinha/baú
	# Timer do "Cérebro" para pensar a cada segundo
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_pensar)
	add_child(timer)

func _pensar() -> void:
	if estado == "IDLE":
		_procurar_alvo()

func _procurar_alvo() -> void:
	var lotes = get_tree().get_nodes_in_group("lote_plantacao")
	for lote in lotes:
		# Checa a variavel que criamos no FarmPlot
		if lote.get("pronto_para_colher") == true:
			alvo_atual = lote
			estado = "MOVING"
			_iniciar_movimento(alvo_atual.global_position, _colher_planta)
			break

func _iniciar_movimento(destino: Vector2, callback: Callable) -> void:
	# Calcula a distancia matematica exata para manter a velocidade constante
	var distancia_pixels = global_position.distance_to(destino)
	var distancia_em_blocos = distancia_pixels / GRID_SIZE
	var tempo_viagem = distancia_em_blocos * TEMPO_POR_BLOCO

	var tween = create_tween()
	tween.tween_property(self, "global_position", destino, tempo_viagem)
	tween.tween_callback(callback)

func _colher_planta() -> void:
	estado = "HARVESTING"
	# Simula o tempo arrancando a planta
	await get_tree().create_timer(1.0).timeout 

	if alvo_atual and is_instance_valid(alvo_atual):
		# Aqui chamaremos a funcao de colheita do FarmPlot no futuro
		alvo_atual.set("pronto_para_colher", false)

	estado = "RETURNING"
	_iniciar_movimento(base_pos, _chegar_na_base)

func _chegar_na_base() -> void:
	estado = "IDLE"
	alvo_atual = null
	# Aqui os itens vao para o bau/inventario no futuro
