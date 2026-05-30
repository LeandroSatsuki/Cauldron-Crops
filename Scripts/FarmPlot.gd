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
var semente_id_plantada: String = ""

@onready var timer: Timer = $Timer
@onready var color_rect = $ColorRect
var regado: bool = false
@onready var visual_regado = $VisualRegado

func _ready() -> void:
	add_to_group("lotes_terra")
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
	# Verificação de regar
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.item_focado_id == "agua" and (estado_atual == State.VAZIO or estado_atual == State.CRESCENDO):
		if GlobalInventory.inventario.get("agua", 0) >= 1:
			if not regado:
				if GlobalInventory.remover_item("agua", 1):
					regado = true
					_atualizar_visual()
					print("Lote Regado!")
					if estado_atual == State.CRESCENDO:
						timer.start(timer.time_left * 0.8)
			else:
				print("Lote já está regado!")
		return

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
			
			if not GlobalInventory.remover_item(semente_id, 1):
				print("Sem sementes deste tipo no estoque!")
				return
			
			semente_id_plantada = semente_id
			var tempo = semente_atual.get("tempo_crescimento_segundos", 3.0)
			if regado:
				tempo = tempo * 0.8
			if SeasonManager.estacao_atual == SeasonManager.Estacao.VERAO:
				tempo = tempo * 0.8
			
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
				
			# Bônus de Outono (Colheita Extra)
			if SeasonManager.estacao_atual == SeasonManager.Estacao.OUTONO and randf() <= 0.20:
				GlobalInventory.adicionar_item(produto, 1)
				print("Bônus de Outono: Colheita em dobro!")
				
			# Bônus de Primavera (Semente Extra)
			if SeasonManager.estacao_atual == SeasonManager.Estacao.PRIMAVERA and randf() <= 0.20:
				GlobalInventory.adicionar_item(semente_id_plantada, 1)
				print("Bônus de Primavera: Semente recuperada!")
			
			ui = get_tree().current_scene.get_node_or_null("UI")
			if ui and ui.has_method("criar_texto_flutuante"):
				var nome_exibicao = "Trigo" if produto == "trigo" else "Raiz"
				ui.criar_texto_flutuante("+1 " + nome_exibicao, global_position, Color.YELLOW)
			
			# Drop Raro
			if randf() <= 0.15:
				GlobalInventory.adicionar_item("semente_inverno", 1)
				if ui and ui.has_method("criar_texto_flutuante"):
					ui.criar_texto_flutuante("💥 RARO!", global_position + Vector2(0, -20), Color(0.5, 0.2, 0.9))
				print("💥 SORTE GRANDE! Drop raro: Semente de Inverno!")
			
			# Reseta o estado para VAZIO
			estado_atual = State.VAZIO
			regado = false
			_atualizar_visual()
			semente_atual = {}
			semente_id_plantada = ""
			
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
		if not regado and SeasonManager.estacao_atual != SeasonManager.Estacao.INVERNO:
			if randf() <= 0.20:
				semente_atual = {}
				semente_id_plantada = ""
				estado_atual = State.VAZIO
				_atualizar_visual()
				print("A planta morreu de sede!")
				return
		
		estado_atual = State.PRONTO_PARA_COLHER
		_atualizar_visual()
		print("O tempo de crescimento acabou! Estado alterado para: PRONTO_PARA_COLHER.")

func _atualizar_visual() -> void:
	if visual_regado:
		visual_regado.visible = regado
	match estado_atual:
		State.VAZIO:
			color_rect.color = Color(0.42, 0.26, 0.15)
		State.CRESCENDO:
			color_rect.color = Color(0.2, 0.5, 0.2)
		State.PRONTO_PARA_COLHER:
			color_rect.color = Color(0.8, 0.8, 0.2)
