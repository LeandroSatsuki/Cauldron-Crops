extends Area2D

const TEX_SECA = preload("res://Assets/seca.png")
const TEX_MOLHADA = preload("res://Assets/molhada.png")
# Texturas futuras preparadas
const TEX_SECA_ADUBADA = preload("res://Assets/seca_adubada.png")
const TEX_MOLHADA_ADUBADA = preload("res://Assets/molhada_adubada.png")
const COR_SOLO_NATURAL = Color(0.235294, 0.345098, 0.172549, 1.0)
const GRID_SIZE = 64 # Tamanho padrao do tile
const TOOL_NONE := 0
const TOOL_HOE := 1
const TOOL_SEED := 2
const TOOL_WATERING_CAN := 3
const TOOL_HARVEST := 4
const FEEDBACK_COR: Color = Color(1.0, 0.95, 0.6, 1.0)

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
var is_rustling: bool = false
var tempo_total_crescimento: float = 0.0
var arado: bool = false

@onready var timer: Timer = $Timer
@onready var color_rect = $ColorRect
var regado: bool = false
@onready var visual_regado = $VisualRegado
@onready var tooltip_area: Control = $TooltipArea
@onready var golem_harvest_point: Marker2D = $GolemHarvestPoint
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var expansion_blocked: bool = false

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
	_configurar_camadas_visuais()
	_aplicar_estado_expansao()
	_atualizar_visual()

func _process(_delta: float) -> void:
	var base_z: int = int(global_position.y)
	z_index = base_z
	if color_rect:
		color_rect.z_as_relative = false
		color_rect.z_index = -100
	if has_node("SpriteTerra"):
		$SpriteTerra.z_as_relative = false
		$SpriteTerra.z_index = -90
	if visual_regado:
		visual_regado.z_as_relative = false
		visual_regado.z_index = -80
	if has_node("SpritePlanta"):
		$SpritePlanta.z_as_relative = true
		$SpritePlanta.z_index = 1
	if has_node("DropRaroVFX"):
		$DropRaroVFX.z_as_relative = false
		$DropRaroVFX.z_index = 2
	if tooltip_area:
		tooltip_area.z_as_relative = false
		tooltip_area.z_index = 10
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
			
			var wait_t: float = tempo_total_crescimento if tempo_total_crescimento > 0.0 else timer.wait_time
			var left_t: float = timer.time_left
			var progresso: float = (wait_t - left_t) / wait_t if wait_t > 0.0 else 0.0
			var estagio: int = 1 if progresso >= 0.5 else 0
			atualizar_visual_planta(semente_id_plantada, estagio)

# Função para capturar cliques do mouse (usando _input_event)
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var ui_node: Node = get_tree().current_scene.get_node_or_null("UI")
		if ui_node != null and ui_node.has_method("_tem_popup_modal_aberto") and ui_node.call("_tem_popup_modal_aberto"):
			return
		_on_plot_clicked()

func set_expansion_blocked(blocked: bool) -> void:
	expansion_blocked = blocked
	if is_inside_tree():
		_aplicar_estado_expansao()

func is_expansion_blocked() -> bool:
	return expansion_blocked

func _on_plot_clicked() -> void:
	var ferramenta_ativa: int = _obter_ferramenta_ativa()
	if ferramenta_ativa != TOOL_NONE:
		if ferramenta_ativa == TOOL_WATERING_CAN:
			_regar_lote_por_ferramenta()
			return
		if ferramenta_ativa == TOOL_HOE:
			if estado_atual != State.VAZIO:
				_mostrar_feedback("A ferramenta nao pode ser usada aqui.")
				return
			if arado:
				_mostrar_feedback("Lote já está arado.")
				return
			arado = true
			_atualizar_visual()
			_mostrar_feedback("Lote arado!")
			return
		if ferramenta_ativa == TOOL_HARVEST:
			if estado_atual == State.PRONTO_PARA_COLHER:
				_colher_manualmente(true)
				return
			if estado_atual == State.CRESCENDO:
				_mostrar_feedback("A planta ainda está crescendo.")
			return

	# Verificação de regar
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.item_focado_id == "agua" and (estado_atual == State.VAZIO or estado_atual == State.CRESCENDO):
		if _regar_lote_por_ferramenta():
			return
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

			if not arado:
				_mostrar_feedback("Are a terra antes de plantar.")
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
			tempo_total_crescimento = tempo
			
			# Inicia o timer
			timer.start()
			
			# Muda o estado para CRESCENDO
			estado_atual = State.CRESCENDO
			_atualizar_visual()
			atualizar_visual_planta(semente_id_plantada, 0)
			_mostrar_feedback("Semente plantada!")

		State.PRONTO_PARA_COLHER:
			if not _colher_manualmente(true):
				return

		State.CRESCENDO:
			if GlobalInventory.cargas_crescimento > 0:
				GlobalInventory.cargas_crescimento -= 1
				timer.start(timer.time_left / 2.0)
				print("Poção aplicada! Tempo reduzido pela metade.")
			else:
				_mostrar_feedback("A planta ainda está crescendo.")

func _obter_ferramenta_ativa() -> int:
	var tree: SceneTree = get_tree()
	if tree == null:
		return TOOL_NONE

	var tool_manager: Node = tree.root.get_node_or_null("ToolManager")
	if tool_manager == null or not tool_manager.has_method("get_active_tool"):
		return TOOL_NONE

	return int(tool_manager.call("get_active_tool"))

func _regar_lote_por_ferramenta() -> bool:
	if estado_atual != State.VAZIO and estado_atual != State.CRESCENDO:
		return false

	if GlobalInventory.inventario.get("agua", 0) < 1:
		_mostrar_feedback("Sem água.")
		return true

	if regado:
		_mostrar_feedback("Lote já está regado.")
		return true

	if GlobalInventory.remover_item("agua", 1):
		regado = true
		_atualizar_visual()
		_mostrar_feedback("Lote regado!")
		$SpriteTerra.texture = TEX_MOLHADA
		if estado_atual == State.CRESCENDO:
			timer.start(timer.time_left * 0.8)
		return true

	return true

func pode_ser_regado_por_golem() -> bool:
	if estado_atual != State.CRESCENDO:
		return false
	if regado:
		return false
	if expansion_blocked:
		return false
	if not visible:
		return false
	return true

func regar_por_golem() -> bool:
	if not pode_ser_regado_por_golem():
		return false

	regado = true
	_atualizar_visual()
	if timer and timer.time_left > 0.0:
		timer.start(timer.time_left * 0.8)
	return true

func harvest_by_golem() -> Array:
	if estado_atual != State.PRONTO_PARA_COLHER:
		return []

	var produto: String = str(semente_atual.get("produto_colheita", "trigo"))
	if produto == "":
		return []

	if timer:
		timer.stop()

	var recompensas: Array = _gerar_recompensas_colheita(produto)
	if recompensas.is_empty():
		return []

	_concluir_colheita()
	return recompensas

func _colher_manualmente(mostrar_textos: bool = true) -> bool:
	if estado_atual != State.PRONTO_PARA_COLHER:
		if estado_atual == State.CRESCENDO:
			_mostrar_feedback("A planta ainda está crescendo.")
		elif estado_atual == State.VAZIO:
			_mostrar_feedback("Nada para colher.")
		return false

	var produto: String = str(semente_atual.get("produto_colheita", "trigo"))
	var recompensas: Array = _gerar_recompensas_colheita(produto)
	if recompensas.is_empty():
		push_warning("FarmPlot: colheita manual sem recompensas geradas.")
		return false

	var ui: Node = null
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		ui = tree.current_scene.get_node_or_null("UI")

	_aplicar_recompensas_colheita(recompensas, ui, global_position, mostrar_textos)
	_concluir_colheita()
	_mostrar_feedback("Colhido!")
	return true

func debug_force_ready_to_harvest() -> void:
	if estado_atual == State.VAZIO:
		return

	if timer and not timer.is_stopped():
		timer.stop()

	estado_atual = State.PRONTO_PARA_COLHER
	pronto_para_colher = true
	_atualizar_visual()
	atualizar_visual_planta(semente_id_plantada, 2)
	print("Debug: lote forçado para colheita em ", get_path())

func debug_apply_daily_decay() -> bool:
	if estado_atual != State.VAZIO:
		return false
	if not arado:
		return false
	if semente_id_plantada != "":
		return false
	if not semente_atual.is_empty():
		return false

	if timer:
		timer.stop()

	estado_atual = State.VAZIO
	regado = false
	pronto_para_colher = false
	semente_atual = {}
	semente_id_plantada = ""
	tempo_total_crescimento = 0.0
	arado = false
	_atualizar_visual()
	atualizar_visual_planta("", 0)
	return true

func _mostrar_feedback(texto: String) -> void:
	if texto == "":
		return

	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		print(texto)
		return

	var ui: Node = tree.current_scene.get_node_or_null("UI")
	if ui != null and ui.has_method("criar_texto_flutuante"):
		var origem: Vector2 = global_position + Vector2(0.0, -48.0)
		ui.call("criar_texto_flutuante", texto, origem, FEEDBACK_COR)
		return

	print(texto)

func get_save_data() -> Dictionary:
	var estado_salvo: int = int(estado_atual)
	var tempo_restante: float = 0.0
	var tempo_total: float = maxf(tempo_total_crescimento, 0.0)

	if timer:
		tempo_restante = maxf(timer.time_left, 0.0)
		if tempo_total <= 0.0:
			tempo_total = maxf(timer.wait_time, 0.0)

	return {
		"estado_atual": estado_salvo,
		"semente_id_plantada": semente_id_plantada,
		"regado": regado,
		"arado": arado,
		"tempo_restante": tempo_restante,
		"tempo_total_crescimento": tempo_total,
		"pronto_para_colher": pronto_para_colher
	}

func load_save_data(data: Dictionary) -> void:
	if timer:
		timer.stop()

	if data.is_empty():
		_concluir_colheita(false)
		return

	var estado_salvo: int = int(data.get("estado_atual", int(State.VAZIO)))
	if estado_salvo < int(State.VAZIO) or estado_salvo > int(State.PRONTO_PARA_COLHER):
		estado_salvo = int(State.VAZIO)

	var semente_id_salva: String = str(data.get("semente_id_plantada", ""))
	var regado_salvo: bool = bool(data.get("regado", false))
	var arado_salvo: bool = bool(data.get("arado", false))
	var pronto_salvo: bool = bool(data.get("pronto_para_colher", false))
	var tempo_restante_salvo: float = maxf(float(data.get("tempo_restante", 0.0)), 0.0)
	var tempo_total_salvo: float = maxf(float(data.get("tempo_total_crescimento", 0.0)), 0.0)

	var estado_final: int = estado_salvo
	if estado_final == int(State.VAZIO) and semente_id_salva != "":
		if pronto_salvo:
			estado_final = int(State.PRONTO_PARA_COLHER)
		elif tempo_restante_salvo > 0.0:
			estado_final = int(State.CRESCENDO)

	if estado_final == int(State.VAZIO):
		estado_atual = State.VAZIO
		pronto_para_colher = false
		semente_atual = {}
		semente_id_plantada = ""
		regado = regado_salvo
		arado = arado_salvo
		tempo_total_crescimento = 0.0
		_atualizar_visual()
		atualizar_visual_planta("", 0)
		return

	var semente_dados: Dictionary = _obter_dados_semente_por_id(semente_id_salva)
	if semente_dados.is_empty():
		push_warning("FarmPlot: semente nao encontrada para restauracao: %s" % semente_id_salva)
		_concluir_colheita(false)
		return

	semente_atual = semente_dados
	semente_id_plantada = semente_id_salva
	regado = regado_salvo
	arado = arado_salvo or estado_final != int(State.VAZIO)
	tempo_total_crescimento = tempo_total_salvo
	if tempo_total_crescimento <= 0.0:
		tempo_total_crescimento = float(semente_atual.get("tempo_crescimento_segundos", 3.0))

	match estado_final:
		State.PRONTO_PARA_COLHER:
			estado_atual = State.PRONTO_PARA_COLHER
			pronto_para_colher = true
			_atualizar_visual()
			atualizar_visual_planta(semente_id_plantada, 2)
		State.CRESCENDO:
			estado_atual = State.CRESCENDO
			pronto_para_colher = false
			if tempo_restante_salvo <= 0.0:
				estado_atual = State.PRONTO_PARA_COLHER
				pronto_para_colher = true
				_atualizar_visual()
				atualizar_visual_planta(semente_id_plantada, 2)
			else:
				if timer:
					timer.wait_time = tempo_restante_salvo
					timer.start()
				_atualizar_visual()
				var wait_t: float = tempo_total_crescimento if tempo_total_crescimento > 0.0 else tempo_restante_salvo
				var progresso: float = (wait_t - tempo_restante_salvo) / wait_t if wait_t > 0.0 else 0.0
				var estagio: int = 1 if progresso >= 0.5 else 0
				atualizar_visual_planta(semente_id_plantada, estagio)
		_:
			_concluir_colheita()

func _obter_dados_semente_por_id(semente_id: String) -> Dictionary:
	match semente_id:
		"semente_basica":
			return Database.semente_basica.duplicate(true)
		"semente_inverno":
			return Database.semente_inverno.duplicate(true)
		"semente_verao":
			return Database.semente_verao.duplicate(true)
		"semente_outono":
			return Database.semente_outono.duplicate(true)
		_:
			return {}

func get_golem_harvest_position() -> Vector2:
	if golem_harvest_point and is_instance_valid(golem_harvest_point):
		return golem_harvest_point.global_position
	return global_position + Vector2(0, 24)

func _gerar_recompensas_colheita(produto: String) -> Array:
	var recompensas: Array = []
	if produto == "":
		return recompensas

	_adicionar_recompensa_colheita(
		recompensas,
		produto,
		1,
		true,
		"+1 " + _obter_nome_exibicao_item(produto),
		Color.YELLOW
	)

	if SeasonManager.estacao_atual == SeasonManager.Estacao.OUTONO and randf() <= 0.20:
		_adicionar_recompensa_colheita(recompensas, produto, 1)
		print("Bônus de Outono: Colheita em dobro!")

	if SeasonManager.estacao_atual == SeasonManager.Estacao.PRIMAVERA and randf() <= 0.20 and semente_id_plantada != "":
		_adicionar_recompensa_colheita(recompensas, semente_id_plantada, 1)
		print("Bônus de Primavera: Semente recuperada!")

	if randf() <= 0.15:
		_adicionar_recompensa_colheita(
			recompensas,
			"semente_inverno",
			1,
			true,
			"💥 RARO!",
			Color(0.5, 0.2, 0.9),
			Vector2(0, -20)
		)
		print("💥 SORTE GRANDE! Drop raro: Semente de Inverno!")

	if produto == "trigo" and randf() <= 0.005:
		_adicionar_recompensa_colheita(
			recompensas,
			"palha_rara",
			1,
			true,
			"Palha Rara!",
			Color(0.8, 0.2, 0.8),
			Vector2(0, -40)
		)
		print("💥 SORTE GRANDE! Drop raro: Palha Rara!")

	if produto == "abobora_sombria" and randf() <= 0.02:
		_adicionar_recompensa_colheita(
			recompensas,
			"rama_encantada",
			1,
			true,
			"Rama Encantada!",
			Color(0.8, 0.2, 0.8),
			Vector2(0, -40)
		)
		print("💥 SORTE GRANDE! Drop raro: Rama Encantada!")

	return recompensas

func _adicionar_recompensa_colheita(
	recompensas: Array,
	item_id: String,
	quantidade: int = 1,
	mostrar_texto: bool = false,
	texto_flutuante: String = "",
	cor: Color = Color.WHITE,
	offset: Vector2 = Vector2.ZERO
) -> void:
	if item_id == "" or quantidade <= 0:
		return

	recompensas.append({
		"item_id": item_id,
		"quantidade": quantidade,
		"mostrar_texto": mostrar_texto,
		"texto_flutuante": texto_flutuante,
		"cor": cor,
		"offset": offset
	})

func _aplicar_recompensas_colheita(recompensas: Array, ui: Node, origem_global: Vector2, mostrar_textos: bool = false) -> void:
	if not GlobalInventory.has_method("adicionar_item"):
		push_error("Autoload GlobalInventory não possui o método adicionar_item()!")
		return

	for recompensa_variant in recompensas:
		if typeof(recompensa_variant) != TYPE_DICTIONARY:
			continue

		var recompensa: Dictionary = recompensa_variant
		var item_id: String = str(recompensa.get("item_id", ""))
		var quantidade: int = int(recompensa.get("quantidade", 0))
		if item_id == "" or quantidade <= 0:
			continue

		GlobalInventory.adicionar_item(item_id, quantidade)

		if not mostrar_textos:
			continue
		if not bool(recompensa.get("mostrar_texto", false)):
			continue
		if not ui or not ui.has_method("criar_texto_flutuante"):
			continue

		var texto_flutuante: String = str(recompensa.get("texto_flutuante", ""))
		if texto_flutuante == "":
			continue

		var cor: Color = recompensa.get("cor", Color.WHITE)
		var offset: Vector2 = recompensa.get("offset", Vector2.ZERO)
		ui.criar_texto_flutuante(texto_flutuante, origem_global + offset, cor)

		if item_id == "semente_inverno" or item_id == "palha_rara" or item_id == "rama_encantada":
			var drop_vfx = get_node_or_null("DropRaroVFX")
			if drop_vfx:
				drop_vfx.emitting = true

func _obter_nome_exibicao_item(item_id: String) -> String:
	match item_id:
		"trigo":
			return "Trigo"
		"raiz_gelida":
			return "Raiz Gélida"
		"tomate_sol":
			return "Tomate Sol"
		"abobora_sombria":
			return "Abóbora Sombria"
		"agua":
			return "Água"
		"semente_inverno":
			return "Semente de Inverno"
		"palha_rara":
			return "Palha Rara"
		"rama_encantada":
			return "Rama Encantada"
		_:
			return item_id.replace("_", " ").capitalize()

func _concluir_colheita(preservar_arado: bool = true) -> void:
	estado_atual = State.VAZIO
	regado = false
	pronto_para_colher = false
	semente_atual = {}
	semente_id_plantada = ""
	tempo_total_crescimento = 0.0
	if not preservar_arado:
		arado = false

	if has_node("SpriteTerra"):
		_atualizar_visual()

	atualizar_visual_planta("", 0)

# Quando o Timer emitir o sinal de timeout: o estado muda para PRONTO_PARA_COLHER
func _on_timer_timeout() -> void:
	if estado_atual == State.CRESCENDO:
		if not regado and SeasonManager.estacao_atual != SeasonManager.Estacao.INVERNO:
			if randf() <= 0.20:
				semente_atual = {}
				semente_id_plantada = ""
				tempo_total_crescimento = 0.0
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
	if color_rect:
		color_rect.color = _obter_cor_base_solo()
	if visual_regado:
		visual_regado.visible = regado and (arado or estado_atual != State.VAZIO)
	if has_node("SpriteTerra"):
		$SpriteTerra.visible = _deve_mostrar_textura_terra()
		$SpriteTerra.texture = _obter_textura_terra()

func _obter_textura_terra() -> Texture2D:
	if arado:
		return TEX_MOLHADA_ADUBADA if regado else TEX_SECA_ADUBADA
	return TEX_MOLHADA if regado else TEX_SECA

func _obter_cor_base_solo() -> Color:
	if estado_atual == State.VAZIO and not arado:
		return COR_SOLO_NATURAL
	return Color(0, 0, 0, 0)

func _deve_mostrar_textura_terra() -> bool:
	if estado_atual == State.VAZIO and not arado:
		return false
	return true

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

func _configurar_camadas_visuais() -> void:
	z_as_relative = false
	if color_rect:
		color_rect.z_as_relative = false
		color_rect.z_index = -100
	if has_node("SpriteTerra"):
		$SpriteTerra.z_as_relative = false
		$SpriteTerra.z_index = -90
	if visual_regado:
		visual_regado.z_as_relative = false
		visual_regado.z_index = -80
	if has_node("SpritePlanta"):
		$SpritePlanta.z_as_relative = true
		$SpritePlanta.z_index = 1
	if has_node("DropRaroVFX"):
		$DropRaroVFX.z_as_relative = false
		$DropRaroVFX.z_index = 2
	if tooltip_area:
		tooltip_area.z_as_relative = false
		tooltip_area.z_index = 10

func _aplicar_estado_expansao() -> void:
	if collision_shape:
		collision_shape.disabled = expansion_blocked
	if tooltip_area:
		tooltip_area.visible = not expansion_blocked
	input_pickable = not expansion_blocked
	monitoring = not expansion_blocked
	monitorable = not expansion_blocked
	visible = not expansion_blocked
	set_process(not expansion_blocked)
	if not expansion_blocked:
		_atualizar_visual()

func _on_sway_area_body_entered(_body: Node2D) -> void:
	# Só balança se tiver uma textura de planta (ou seja, não é só terra pura)
	if has_node("SpritePlanta") and $SpritePlanta.texture != null:
		var tween = create_tween()
		# Faz a planta inclinar 10 graus pra direita, 10 pra esquerda, e voltar ao zero
		tween.tween_property($SpritePlanta, "rotation_degrees", 10.0, 0.1)
		tween.tween_property($SpritePlanta, "rotation_degrees", -10.0, 0.1)
		tween.tween_property($SpritePlanta, "rotation_degrees", 0.0, 0.15)

func rustle_from_golem() -> void:
	if is_rustling:
		return
	if estado_atual == State.VAZIO:
		return
	if not has_node("SpritePlanta"):
		return
	if $SpritePlanta.texture == null:
		return

	is_rustling = true
	var planta: Node2D = $SpritePlanta
	var rot_original: float = planta.rotation_degrees
	var pos_original: Vector2 = planta.position

	var tween = create_tween()
	tween.tween_property(planta, "rotation_degrees", rot_original + 8.0, 0.06)
	tween.tween_property(planta, "rotation_degrees", rot_original - 8.0, 0.08)
	tween.tween_property(planta, "rotation_degrees", rot_original, 0.06)
	tween.tween_callback(func():
		if is_instance_valid(planta):
			planta.rotation_degrees = rot_original
			planta.position = pos_original
		is_rustling = false
	)
