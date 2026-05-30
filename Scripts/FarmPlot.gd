extends Area2D

# Máquina de estados simples
enum State {
	VAZIO,
	CRESCENDO,
	PRONTO_PARA_COLHER
}

# O lote inicia no estado VAZIO
var estado_atual: State = State.VAZIO

# Semente atual sendo cultivada
var semente_atual: Dictionary = {}

@onready var timer: Timer = $Timer
@onready var color_rect = $ColorRect

func _ready() -> void:
	# Configura o timer como one-shot e conecta o sinal de timeout
	if timer:
		timer.one_shot = true
		timer.timeout.connect(_on_timer_timeout)
	else:
		push_error("Timer não encontrado na cena FarmPlot!")
	_atualizar_visual()

# Função para capturar cliques do mouse (usando _input_event)
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_plot_clicked()

func _on_plot_clicked() -> void:
	match estado_atual:
		State.VAZIO:
			# Se o lote for clicado no estado VAZIO:
			var semente_id = GlobalInventory.semente_selecionada
			if semente_id in Database:
				semente_atual = Database.get(semente_id)
			else:
				push_error("Semente '%s' não encontrada no Autoload Database!" % semente_id)
				return
			
			if semente_atual.get("estacao_ideal") != SeasonManager.estacao_atual:
				print("Semente fora de época! Essa planta não cresce nesta estação.")
				return
			
			var tempo = semente_atual.get("tempo_crescimento_segundos", 3.0)
			
			# Configura o Timer com o tempo_crescimento_segundos
			timer.wait_time = tempo
			
			# Inicia o timer
			timer.start()
			
			# Muda o estado para CRESCENDO
			estado_atual = State.CRESCENDO
			_atualizar_visual()
			print("Semente plantada! Estado alterado para: CRESCENDO. Tempo de crescimento: ", tempo, " segundos.")

		State.PRONTO_PARA_COLHER:
			# Se o lote for clicado no estado PRONTO_PARA_COLHER:
			# Lê qual é o produto_colheita da semente atual
			var produto = semente_atual.get("produto_colheita", "trigo")
			
			# Usa o Autoload GlobalInventory.adicionar_item() para guardar 1 unidade do produto
			if GlobalInventory.has_method("adicionar_item"):
				GlobalInventory.adicionar_item(produto)
			else:
				push_error("Autoload GlobalInventory não possui o método adicionar_item()!")
				return
			
			# Drop Raro
			if randf() <= 0.15:
				GlobalInventory.adicionar_item("semente_inverno", 1)
				print("💥 SORTE GRANDE! Drop raro: Semente de Inverno!")
			
			# Reseta o estado para VAZIO
			estado_atual = State.VAZIO
			_atualizar_visual()
			semente_atual = {}
			
			# Dá um print de sucesso no console
			print("Sucesso: Colheita realizada! Produto: '", produto, "' foi adicionado ao inventário. Lote agora está VAZIO.")

		State.CRESCENDO:
			if GlobalInventory.cargas_crescimento > 0:
				GlobalInventory.cargas_crescimento -= 1
				timer.start(timer.time_left / 2.0)
				print("Poção aplicada! Tempo reduzido pela metade.")
			else:
				# Opcional: print informativo de que ainda está crescendo
				print("A semente ainda está crescendo... Tempo restante: ", "%0.1f" % timer.time_left, "s")

# Quando o Timer emitir o sinal de timeout: o estado muda para PRONTO_PARA_COLHER
func _on_timer_timeout() -> void:
	if estado_atual == State.CRESCENDO:
		estado_atual = State.PRONTO_PARA_COLHER
		_atualizar_visual()
		print("O tempo de crescimento acabou! Estado alterado para: PRONTO_PARA_COLHER.")

func _atualizar_visual() -> void:
	match estado_atual:
		State.VAZIO:
			color_rect.color = Color(0.42, 0.26, 0.15)
		State.CRESCENDO:
			color_rect.color = Color(0.2, 0.5, 0.2)
		State.PRONTO_PARA_COLHER:
			color_rect.color = Color(0.8, 0.8, 0.2)
