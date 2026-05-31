extends Area2D

const TEX_SECA = preload("res://Assets/seca.png")
const TEX_MOLHADA = preload("res://Assets/molhada.png")
# Texturas futuras preparadas
const TEX_SECA_ADUBADA = preload("res://Assets/seca_adubada.png")
const TEX_MOLHADA_ADUBADA = preload("res://Assets/molhada_adubada.png")
const GRID_SIZE = 64 # Tamanho padrao do tile

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
var pronto_para_colher: bool = false

@onready var timer: Timer = $Timer
@onready var color_rect = $ColorRect
var regado: bool = false
@onready var visual_regado = $VisualRegado
@onready var tooltip_area: Control = $TooltipArea

func _ready() -> void:
	# Trava o posicionamento no centro perfeito do grid
	var snap_x = round(global_position.x / GRID_SIZE) * GRID_SIZE
	var snap_y = round(global_position.y / GRID_SIZE) * GRID_SIZE
	global_position = Vector2(snap_x, snap_y)

	add_to_group("lotes_terra")
	add_to_group("lote_plantacao")
	# Configura o timer como one-shot e conecta o sinal de timeout
	if timer:
		timer.one_shot = true
		timer.timeout.connect(_on_timer_timeout)
	else:
		push_error("Timer não encontrado na cena FarmPlot!")
	_atualizar_visual()

func _process(_delta: float) -> void:
	if not tooltip_area:
		return
		
	match estado_atual:
		State.VAZIO:
			tooltip_area.tooltip_text = "Lote Vazio\n(Requer Semente)"
		State.PRONTO_PARA_COLHER:
			var nome = semente_atual.get("nome", "Trigo" if semente_atual.get("produto_colheita", "trigo") == "trigo" else "Desconhecido")
			tooltip_area.tooltip_text = "Pronto para colher!\nProduto: " + nome
		State.CRESCENDO:
			var nome = semente_atual.get("nome", "Trigo" if semente_atual.get("produto_colheita", "trigo") == "trigo" else "Semente")
			var tempo = "%0.1f" % timer.time_left
			var status_agua = "Sim 💧" if regado else "Não 🥀"
			tooltip_area.tooltip_text = "Planta: " + nome + "\nTempo: " + tempo + "s\nRegado: " + status_agua
			
			var wait_t = timer.wait_time
			var left_t = timer.time_left
			var progresso = (wait_t - left_t) / wait_t if wait_t > 0 else 0.0
			var estagio = 1 if progresso >= 0.5 else 0
			atualizar_visual_planta(semente_id_plantada, estagio)

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
					$SpriteTerra.texture = TEX_MOLHADA
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
			atualizar_visual_planta(semente_id_plantada, 0)
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
				$DropRaroVFX.emitting = true
				
			if produto == "trigo" and randf() <= 0.005:
				GlobalInventory.adicionar_item("palha_rara", 1)
				if ui and ui.has_method("criar_texto_flutuante"):
					ui.criar_texto_flutuante("Palha Rara!", global_position + Vector2(0, -40), Color(0.8, 0.2, 0.8))
				print("💥 SORTE GRANDE! Drop raro: Palha Rara!")
				$DropRaroVFX.emitting = true
				
			if produto == "abobora_sombria" and randf() <= 0.02:
				GlobalInventory.adicionar_item("rama_encantada", 1)
				if ui and ui.has_method("criar_texto_flutuante"):
					ui.criar_texto_flutuante("Rama Encantada!", global_position + Vector2(0, -40), Color(0.8, 0.2, 0.8))
				print("💥 SORTE GRANDE! Drop raro: Rama Encantada!")
				$DropRaroVFX.emitting = true
			
			# Reseta o estado para VAZIO
			estado_atual = State.VAZIO
			regado = false
			$SpriteTerra.texture = TEX_SECA
			_atualizar_visual()
			atualizar_visual_planta("", 0)
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

func harvest_by_golem() -> Dictionary:
	if estado_atual != State.PRONTO_PARA_COLHER:
		return {}

	var produto: String = str(semente_atual.get("produto_colheita", "trigo"))
	if produto == "":
		return {}

	if timer:
		timer.stop()

	# V1: o golem colhe apenas 1 item básico, sem bônus extras ou drops raros.
	estado_atual = State.VAZIO
	regado = false
	semente_atual = {}
	semente_id_plantada = ""
	pronto_para_colher = false

	if has_node("SpriteTerra"):
		$SpriteTerra.texture = TEX_SECA

	_atualizar_visual()
	atualizar_visual_planta("", 0)

	return {
		"item_id": produto,
		"quantidade": 1
	}

# Quando o Timer emitir o sinal de timeout: o estado muda para PRONTO_PARA_COLHER
func _on_timer_timeout() -> void:
	if estado_atual == State.CRESCENDO:
		if not regado and SeasonManager.estacao_atual != SeasonManager.Estacao.INVERNO:
			if randf() <= 0.20:
				semente_atual = {}
				semente_id_plantada = ""
				estado_atual = State.VAZIO
				_atualizar_visual()
				atualizar_visual_planta("", 0)
				print("A planta morreu de sede!")
				return
		
		estado_atual = State.PRONTO_PARA_COLHER
		_atualizar_visual()
		atualizar_visual_planta(semente_id_plantada, 2)
		print("O tempo de crescimento acabou! Estado alterado para: PRONTO_PARA_COLHER.")

func _atualizar_visual() -> void:
	if visual_regado:
		visual_regado.visible = regado
	if has_node("SpriteTerra"):
		$SpriteTerra.texture = TEX_MOLHADA if regado else TEX_SECA
	match estado_atual:
		State.VAZIO:
			color_rect.color = Color(0, 0, 0, 0)
		State.CRESCENDO:
			color_rect.color = Color(0, 0, 0, 0)
		State.PRONTO_PARA_COLHER:
			color_rect.color = Color(0, 0, 0, 0)

func atualizar_visual_planta(semente_id: String, estagio_crescimento: int):
	if semente_id == "":
		pronto_para_colher = false
		if has_node("SpritePlanta"):
			$SpritePlanta.texture = null
		return

	if estagio_crescimento == 2:
		pronto_para_colher = true

	var nomes_estagio = ["broto", "crescendo", "maduro"]
	if estagio_crescimento < 0 or estagio_crescimento > 2:
		return

	var sufixo = nomes_estagio[estagio_crescimento]
	
	# Mapeamento do ID da semente para o nome do arquivo gerado
	var id_base = semente_id
	var mapeamento = {
		"semente_basica": "trigo",
		"semente_verao": "tomate",
		"semente_outono": "abobora",
		"semente_inverno": "rabanete",
		"trigo": "trigo",
		"tomate": "tomate",
		"abobora": "abobora",
		"rabanete": "rabanete",
		"milho": "milho",
		"feijao": "feijao",
		"cebola": "cebola",
		"cenoura": "cenoura"
	}
	if mapeamento.has(semente_id):
		id_base = mapeamento[semente_id]
		
	var caminho = "res://Assets/" + id_base + "_" + sufixo + ".png"

	if ResourceLoader.exists(caminho):
		var textura = load(caminho)
		if has_node("SpritePlanta"):
			$SpritePlanta.texture = textura
			$SpritePlanta.hframes = 1 # Garante que nao vai fatiar a nova imagem
			$SpritePlanta.vframes = 1
			$SpritePlanta.frame = 0
			$SpritePlanta.scale = Vector2(0.18, 0.18) # Crescimento retangular (alta e fina)
			# Como todas as imagens agora são recortadas rente às bordas (bounding box),
			# a fórmula universal abaixo alinha a base da imagem exatamente com y = 0.
			$SpritePlanta.offset = Vector2(0, -textura.get_height() / 2.0)
	else:
		print("AVISO: Imagem nao encontrada: ", caminho)

func _on_sway_area_body_entered(_body: Node2D) -> void:
	# Só balança se tiver uma textura de planta (ou seja, não é só terra pura)
	if has_node("SpritePlanta") and $SpritePlanta.texture != null:
		var tween = create_tween()
		# Faz a planta inclinar 10 graus pra direita, 10 pra esquerda, e voltar ao zero
		tween.tween_property($SpritePlanta, "rotation_degrees", 10.0, 0.1)
		tween.tween_property($SpritePlanta, "rotation_degrees", -10.0, 0.1)
		tween.tween_property($SpritePlanta, "rotation_degrees", 0.0, 0.15)
