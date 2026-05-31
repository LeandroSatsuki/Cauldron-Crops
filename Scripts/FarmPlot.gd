extends Area2D

const TEX_SECA = preload("res://Assets/seca.png")
const TEX_MOLHADA = preload("res://Assets/molhada.png")
# Texturas futuras preparadas
const TEX_SECA_ADUBADA = preload("res://Assets/seca_adubada.png")
const TEX_MOLHADA_ADUBADA = preload("res://Assets/molhada_adubada.png")

const SHEET_CROPS_1 = preload("res://Assets/crops_1.png")
const SHEET_CROPS_2 = preload("res://Assets/crops_2.png")

# Mapeamento: "nome_da_semente": [Referencia_da_Sheet, Coluna_na_Sheet]
const CROP_DATA = {
	"milho": [SHEET_CROPS_1, 0],
	"tomate": [SHEET_CROPS_1, 1],
	"abobora": [SHEET_CROPS_1, 2],
	"rabanete": [SHEET_CROPS_1, 3],
	"trigo": [SHEET_CROPS_2, 0],
	"feijao": [SHEET_CROPS_2, 1],
	"cebola": [SHEET_CROPS_2, 2],
	"cenoura": [SHEET_CROPS_2, 3],
	# Mapeamento para os IDs de sementes reais do jogo:
	"semente_basica": [SHEET_CROPS_2, 0],   # trigo
	"semente_verao": [SHEET_CROPS_1, 1],    # tomate
	"semente_outono": [SHEET_CROPS_1, 2],   # abobora
	"semente_inverno": [SHEET_CROPS_1, 3]   # rabanete (raiz_gelida)
}

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
@onready var tooltip_area: Control = $TooltipArea

func _ready() -> void:
	add_to_group("lotes_terra")
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
	# estagio_crescimento deve ser: 0 (broto), 1 (crescendo), 2 (maduro)
	if semente_id == "" or not CROP_DATA.has(semente_id):
		if has_node("SpritePlanta"):
			$SpritePlanta.texture = null
		return

	var dados = CROP_DATA[semente_id]
	var sheet_selecionada = dados[0]
	var coluna = dados[1]

	if has_node("SpritePlanta"):
		$SpritePlanta.texture = sheet_selecionada

		# Matemática do frame: (linha * total_colunas) + coluna atual
		# Linha 0 = broto, Linha 1 = crescendo, Linha 2 = maduro
		var frame_calculado = (estagio_crescimento * 4) + coluna
		$SpritePlanta.frame = frame_calculado
