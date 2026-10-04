extends Area2D

const TEX_SECA = preload("res://Assets/seca.png")
const TEX_MOLHADA = preload("res://Assets/molhada.png")
# Texturas futuras preparadas
const TEX_SECA_ADUBADA = preload("res://Assets/seca_adubada.png")
const TEX_MOLHADA_ADUBADA = preload("res://Assets/molhada_adubada.png")
# Solo intocado usa o terreno da cena, sem blocos cobrindo a grama.
const COR_SOLO_NATURAL = Color(0, 0, 0, 0)
const GRID_SIZE = 80 # Tamanho padrao do tile
const TOOL_NONE := 0
const TOOL_HOE := 1
const TOOL_SEED := 2
const TOOL_WATERING_CAN := 3
const TOOL_HARVEST := 4
const FEEDBACK_COR: Color = Color(1.0, 0.95, 0.6, 1.0)
const LivingSoil = preload("res://Scripts/LivingSoilState.gd")

# Máquina de estados simples
enum State {
	VAZIO,
	CRESCENDO,
	PRONTO_PARA_COLHER
}

signal estado_alterado

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
var _pending_manual_harvest_rewards: Array = []
var living_soil_treated: bool = false
var living_soil_moisture: bool = false

func _ready() -> void:
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

func _notificar_estado_alterado() -> void:
	estado_alterado.emit()

func _process(_delta: float) -> void:
	var base_z: int = int(global_position.y)
	z_index = base_z
	# Não reverter as camadas absolutas de solo configuradas no _ready.
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
	if living_soil_treated:
		tooltip_area.tooltip_text += "\nSolo Vivo · tratamento durável"
		tooltip_area.tooltip_text += "\nUmidade preservada para trigo" if living_soil_moisture else "\nTrigo regado conserva umidade após colher"

# Função para capturar cliques do mouse (usando _input_event)
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if expansion_blocked:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var ui_node: Node = get_tree().current_scene.get_node_or_null("UI")
		if ui_node != null and ui_node.has_method("_tem_popup_modal_aberto") and ui_node.call("_tem_popup_modal_aberto"):
			return
		var main: Node = get_tree().current_scene
		if main != null and main.has_method("try_apply_selected_consumable_to_plot") and bool(main.call("try_apply_selected_consumable_to_plot", self)):
			_viewport.set_input_as_handled()
			return
		if main != null and main.has_method("request_player_interaction"):
			if bool(main.call("request_player_interaction", self, global_position, 46.0, Callable(self, "_on_plot_clicked"))):
				_viewport.set_input_as_handled()
			return
		_on_plot_clicked()
		_viewport.set_input_as_handled()

func set_expansion_blocked(blocked: bool) -> void:
	expansion_blocked = blocked
	if is_inside_tree():
		_aplicar_estado_expansao()

func is_expansion_blocked() -> bool:
	return expansion_blocked

func _on_plot_clicked() -> void:
	if expansion_blocked:
		return
	var main: Node = get_tree().current_scene
	if main != null and main.has_method("try_apply_selected_consumable_to_plot") and bool(main.call("try_apply_selected_consumable_to_plot", self)):
		return

	var ferramenta_ativa: int = _obter_ferramenta_ativa()
	if ferramenta_ativa != TOOL_NONE:
		if ferramenta_ativa == TOOL_WATERING_CAN:
			_regar_lote_por_ferramenta()
			return
		if ferramenta_ativa == TOOL_HOE:
			tentar_arar()
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
			var result := try_plant_from_personal_inventory(GlobalInventory.semente_selecionada)
			_mostrar_feedback(_planting_feedback(str(result.get("reason", ""))))

		State.PRONTO_PARA_COLHER:
			if not _colher_manualmente(true):
				return

		State.CRESCENDO:
			_mostrar_feedback("A planta ainda está crescendo.")


func _is_application_runtime_available() -> bool:
	if not is_inside_tree() or is_queued_for_deletion() or not is_visible_in_tree() or expansion_blocked:
		return false
	if SaveManager.is_applying_snapshot() or RegionTravelCoordinator.is_transition_in_progress():
		return false
	var scene: Node = get_tree().current_scene
	if scene == null or not scene.is_ancestor_of(self):
		return false
	if scene.has_method("get_current_region_identity") and scene.call("get_current_region_identity").get("region_id", "") != "farm_village":
		return false
	return true


func can_apply_growth_dose() -> bool:
	return _is_application_runtime_available() and estado_atual == State.CRESCENDO and is_instance_valid(timer) and not timer.is_stopped() and timer.time_left > 0.0 and (GlobalInventory.cargas_crescimento > 0 or GlobalInventory.can_remove_item("pocao_crescimento", 1))


func apply_growth_dose() -> bool:
	# A Main revalida intenção/proximidade; o domínio consome somente no alvo válido.
	if not can_apply_growth_dose():
		return false
	var remaining: float = timer.time_left
	if GlobalInventory.cargas_crescimento <= 0:
		if not GlobalInventory.remover_item("pocao_crescimento", 1):
			return false
		GlobalInventory.cargas_crescimento += 3
	GlobalInventory.cargas_crescimento -= 1
	timer.start(remaining / 2.0)
	_notificar_estado_alterado()
	return true


func _is_living_soil_pilot_plot() -> bool:
	if not is_inside_tree():
		return false
	var scene: Node = get_tree().current_scene
	return scene != null and scene.has_method("is_living_soil_pilot_plot") and bool(scene.call("is_living_soil_pilot_plot", self))


func can_apply_living_soil() -> bool:
	return _is_application_runtime_available() and _is_living_soil_pilot_plot() and not living_soil_treated and estado_atual == State.VAZIO and arado and GlobalInventory.can_remove_item(LivingSoil.ITEM_ID, 1)


func apply_living_soil() -> bool:
	if not can_apply_living_soil():
		return false
	# remover_item é síncrono e não publica sinais de um estado intermediário.
	if not GlobalInventory.remover_item(LivingSoil.ITEM_ID, 1):
		return false
	living_soil_treated = true
	living_soil_moisture = false
	_atualizar_visual()
	_notificar_estado_alterado()
	return true


func validate_seed_planting(seed_id: String) -> Dictionary:
	# Consulta pura: inclusive metadados, timer e sinais ficam intactos na recusa.
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(timer):
		return _planting_result(false, "unavailable")
	if expansion_blocked:
		return _planting_result(false, "blocked")
	if not is_visible_in_tree():
		return _planting_result(false, "hidden")
	if estado_atual != State.VAZIO:
		return _planting_result(false, "occupied")
	if seed_id == "":
		return _planting_result(false, "no_seed")
	var seed_data := _obter_dados_semente_por_id(seed_id)
	if seed_data.is_empty():
		return _planting_result(false, "invalid_seed")
	if not Database.semente_permite_estacao(seed_data, SeasonManager.estacao_atual):
		return _planting_result(false, "wrong_season")
	if not arado:
		return _planting_result(false, "untilled")
	return _planting_result(true, "")


func try_plant_from_personal_inventory(seed_id: String) -> Dictionary:
	return _try_plant_seed(seed_id, Callable(GlobalInventory, "remover_item").bind(seed_id, 1))


func try_plant_from_golem_cargo(cargo: GolemSeedCargo) -> Dictionary:
	if cargo == null or not cargo.has_seed():
		return _planting_result(false, "no_cargo")
	var cell := cargo.get_target_cell()
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	# A identidade vem do registro vivo, nunca do nome/posição visual do nó.
	if scene == null or not scene.has_method("obter_farm_plot_por_grid_position"):
		return _planting_result(false, "target_mismatch")
	if scene.call("obter_farm_plot_por_grid_position", cell) != self:
		return _planting_result(false, "target_mismatch")
	var seed_id := cargo.get_item_id()
	if not cargo.can_consume_for_plant(seed_id, cell):
		return _planting_result(false, "return_pending")
	return _try_plant_seed(
		seed_id,
		Callable(cargo, "consume_for_plant").bind(seed_id, cell)
	)


func _try_plant_seed(seed_id: String, consume_seed: Callable) -> Dictionary:
	var validation := validate_seed_planting(seed_id)
	if not bool(validation.get("success", false)):
		return validation
	# Somente os dois consumidores internos síncronos/sem sinais acima.
	# Não aceitar fontes agregadas nem callbacks externos que publiquem estado parcial.
	if not consume_seed.is_valid() or not bool(consume_seed.call()):
		return _planting_result(false, "no_stock")
	# Outro cultivo descarta só água herdada; rega manual comum segue inalterada.
	if living_soil_moisture and seed_id != LivingSoil.WHEAT_SEED_ID:
		regado = false
	living_soil_moisture = false

	semente_atual = _obter_dados_semente_por_id(seed_id)
	semente_id_plantada = seed_id
	pronto_para_colher = false
	var growth_time := float(semente_atual.get("tempo_crescimento_segundos", 3.0))
	if regado:
		growth_time *= 0.8
	if SeasonManager.estacao_atual == SeasonManager.Estacao.VERAO:
		growth_time *= 0.8
	tempo_total_crescimento = growth_time
	timer.start(growth_time)
	estado_atual = State.CRESCENDO
	_atualizar_visual()
	atualizar_visual_planta(seed_id, 0)
	# Todos os observadores já veem fonte consumida, cultura e timer consistentes.
	_notificar_estado_alterado()
	return _planting_result(true, "")


func _planting_result(success: bool, reason: String) -> Dictionary:
	return {"success": success, "reason": reason}


func _planting_feedback(reason: String) -> String:
	match reason:
		"": return "Semente plantada!"
		"no_seed": return "Selecione uma semente no inventario."
		"wrong_season": return "Semente fora de época!"
		"untilled": return "Are a terra antes de plantar."
		"no_stock": return "Sem sementes deste tipo na Mochila!"
		_: return "Não é possível plantar neste lote."


func tentar_arar(mostrar_feedback: bool = true) -> bool:
	if expansion_blocked or not _solo_permite_arar():
		if mostrar_feedback:
			_mostrar_feedback("A ferramenta nao pode ser usada aqui.")
		return false
	if estado_atual != State.VAZIO:
		if mostrar_feedback:
			_mostrar_feedback("A ferramenta nao pode ser usada aqui.")
		return false
	if arado:
		if mostrar_feedback:
			_mostrar_feedback("Lote já está arado.")
		return false

	arado = true
	_atualizar_visual()
	_notificar_estado_alterado()
	if mostrar_feedback:
		_mostrar_feedback("Lote arado!")
	return true


func _solo_permite_arar() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return false

	var scene: Node = tree.current_scene
	if not scene.has_method("avaliar_solo_para_arar"):
		return true

	var evaluation_variant: Variant = scene.call("avaliar_solo_para_arar", global_position)
	if typeof(evaluation_variant) != TYPE_DICTIONARY:
		return false
	return bool((evaluation_variant as Dictionary).get("valid", false))


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
		_notificar_estado_alterado()
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
	_notificar_estado_alterado()
	if timer and timer.time_left > 0.0:
		timer.start(timer.time_left * 0.8)
	return true

func harvest_by_golem(receive_rewards: Callable = Callable()) -> Array:
	if estado_atual != State.PRONTO_PARA_COLHER:
		return []

	var produto: String = str(semente_atual.get("produto_colheita", "trigo"))
	if produto == "":
		return []

	if timer:
		timer.stop()

	var recompensas: Array = _obter_ou_gerar_recompensas_colheita(produto)
	if recompensas.is_empty():
		return []

	# Transferência física: nenhum sinal publica lote vazio sem carga no golem.
	_complete_successful_harvest(true, false)
	if receive_rewards.is_valid():
		receive_rewards.call(recompensas)
	EventDirector.notify_harvest(global_position)
	_notificar_estado_alterado()
	return recompensas

func _colher_manualmente(mostrar_textos: bool = true) -> bool:
	if estado_atual != State.PRONTO_PARA_COLHER:
		if estado_atual == State.CRESCENDO:
			_mostrar_feedback("A planta ainda está crescendo.")
		elif estado_atual == State.VAZIO:
			_mostrar_feedback("Nada para colher.")
		return false

	var produto: String = str(semente_atual.get("produto_colheita", "trigo"))
	var recompensas: Array = _obter_ou_gerar_recompensas_colheita(produto)
	if recompensas.is_empty():
		push_warning("FarmPlot: colheita manual sem recompensas geradas.")
		return false

	var ui: Node = null
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		ui = tree.current_scene.get_node_or_null("UI")

	if not _aplicar_recompensas_colheita(recompensas, ui, global_position, mostrar_textos):
		_mostrar_feedback("Mochila sem espaço para a colheita.")
		return false
	_complete_successful_harvest()
	EventDirector.notify_harvest(global_position)
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
	_notificar_estado_alterado()
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
	living_soil_moisture = false
	pronto_para_colher = false
	semente_atual = {}
	semente_id_plantada = ""
	tempo_total_crescimento = 0.0
	arado = false
	_atualizar_visual()
	_notificar_estado_alterado()
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
		"expansion_blocked": expansion_blocked,
		"tempo_restante": tempo_restante,
		"tempo_total_crescimento": tempo_total,
		"pronto_para_colher": pronto_para_colher,
		"pending_harvest_rewards": _get_pending_harvest_totals(),
		"living_soil_treated": living_soil_treated,
		"living_soil_moisture": living_soil_moisture
	}

func load_save_data(data: Dictionary) -> void:
	var soil_cell: Vector2i = LivingSoil.PILOT_CELL if _is_living_soil_pilot_plot() else Vector2i(-1, -1)
	if not LivingSoil.validate_flags(data, soil_cell):
		push_warning("FarmPlot: estado de Solo Vivo invalido; lote nao alterado.")
		return
	if not FarmTileData.is_pending_harvest_valid(data.get("pending_harvest_rewards", {})):
		push_warning("FarmPlot: recompensa pendente invalida; lote nao alterado.")
		return
	if timer:
		timer.stop()
	_pending_manual_harvest_rewards.clear()
	living_soil_treated = data.get("living_soil_treated", false)
	living_soil_moisture = data.get("living_soil_moisture", false)

	if data.is_empty():
		_concluir_colheita(false)
		return

	var expansion_blocked_salvo: bool = bool(data.get("expansion_blocked", expansion_blocked))
	var estado_salvo: int = int(data.get("estado_atual", int(State.VAZIO)))
	if estado_salvo < int(State.VAZIO) or estado_salvo > int(State.PRONTO_PARA_COLHER):
		estado_salvo = int(State.VAZIO)

	var semente_id_salva: String = str(data.get("semente_id_plantada", ""))
	var regado_salvo: bool = bool(data.get("regado", false))
	var arado_salvo: bool = bool(data.get("arado", false))
	var pronto_salvo: bool = bool(data.get("pronto_para_colher", false))
	var tempo_restante_salvo: float = maxf(float(data.get("tempo_restante", 0.0)), 0.0)
	var tempo_total_salvo: float = maxf(float(data.get("tempo_total_crescimento", 0.0)), 0.0)
	set_expansion_blocked(expansion_blocked_salvo)

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
		_notificar_estado_alterado()
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
			_notificar_estado_alterado()
		State.CRESCENDO:
			estado_atual = State.CRESCENDO
			pronto_para_colher = false
			if tempo_restante_salvo <= 0.0:
				estado_atual = State.PRONTO_PARA_COLHER
				pronto_para_colher = true
				_atualizar_visual()
				atualizar_visual_planta(semente_id_plantada, 2)
				_notificar_estado_alterado()
			else:
				if timer:
					timer.wait_time = tempo_restante_salvo
					timer.start()
				_atualizar_visual()
				_notificar_estado_alterado()
				var wait_t: float = tempo_total_crescimento if tempo_total_crescimento > 0.0 else tempo_restante_salvo
				var progresso: float = (wait_t - tempo_restante_salvo) / wait_t if wait_t > 0.0 else 0.0
				var estagio: int = 1 if progresso >= 0.5 else 0
				atualizar_visual_planta(semente_id_plantada, estagio)
		_:
			_concluir_colheita()
	if estado_atual == State.PRONTO_PARA_COLHER:
		for item_id in data.get("pending_harvest_rewards", {}):
			var quantity: int = int(data["pending_harvest_rewards"][item_id])
			_adicionar_recompensa_colheita(_pending_manual_harvest_rewards, item_id, quantity, true, "+%d %s" % [quantity, _obter_nome_exibicao_item(item_id)], Color.YELLOW)
		_notificar_estado_alterado()


func advance_inactive_time(elapsed_seconds: float) -> bool:
	if elapsed_seconds <= 0.0 or estado_atual != State.CRESCENDO or timer == null:
		return false
	var remaining_seconds: float = maxf(timer.time_left, 0.0)
	if remaining_seconds <= 0.0:
		return false
	if elapsed_seconds >= remaining_seconds:
		timer.stop()
		_on_timer_timeout()
		return true
	timer.start(maxf(remaining_seconds - elapsed_seconds, 0.001))
	_atualizar_visual()
	_notificar_estado_alterado()
	return true

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

func _obter_ou_gerar_recompensas_colheita(produto: String) -> Array:
	if _pending_manual_harvest_rewards.is_empty():
		_pending_manual_harvest_rewards = _gerar_recompensas_colheita(produto).duplicate(true)
		_notificar_estado_alterado()
	return _pending_manual_harvest_rewards.duplicate(true)

func _get_pending_harvest_totals() -> Dictionary:
	var totals: Dictionary = {}
	for reward in _pending_manual_harvest_rewards:
		var item_id: String = str(reward.get("item_id", ""))
		totals[item_id] = int(totals.get(item_id, 0)) + int(reward.get("quantidade", 0))
	return totals

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

func _aplicar_recompensas_colheita(recompensas: Array, ui: Node, origem_global: Vector2, mostrar_textos: bool = false) -> bool:
	if not GlobalInventory.has_method("try_add_items"):
		push_error("Autoload GlobalInventory não possui o método try_add_items()!")
		return false

	var itens_agrupados: Dictionary = {}
	for recompensa_variant in recompensas:
		if typeof(recompensa_variant) != TYPE_DICTIONARY:
			continue
		var recompensa: Dictionary = recompensa_variant
		var item_id: String = str(recompensa.get("item_id", ""))
		var quantidade: int = int(recompensa.get("quantidade", 0))
		if item_id != "" and quantidade > 0:
			itens_agrupados[item_id] = int(itens_agrupados.get(item_id, 0)) + quantidade
	var insertion: Dictionary = GlobalInventory.try_add_items(itens_agrupados)
	if not bool(insertion.get("success", false)):
		return false

	for recompensa_variant in recompensas:
		if typeof(recompensa_variant) != TYPE_DICTIONARY:
			continue

		var recompensa: Dictionary = recompensa_variant
		var item_id: String = str(recompensa.get("item_id", ""))
		var quantidade: int = int(recompensa.get("quantidade", 0))
		if item_id == "" or quantidade <= 0:
			continue

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
	return true

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

func _complete_successful_harvest(preservar_arado: bool = true, notify_change: bool = true) -> void:
	# Só os commits manual/golem chamam este caminho. Reset nunca cria umidade.
	var retain: bool = living_soil_treated and regado and semente_id_plantada == LivingSoil.WHEAT_SEED_ID
	_concluir_colheita(preservar_arado, false)
	if retain:
		living_soil_moisture = true
		regado = true
		_atualizar_visual()
	if notify_change:
		_notificar_estado_alterado()


func _concluir_colheita(preservar_arado: bool = true, notify_change: bool = true) -> void:
	_pending_manual_harvest_rewards.clear()
	estado_atual = State.VAZIO
	regado = false
	living_soil_moisture = false
	pronto_para_colher = false
	semente_atual = {}
	semente_id_plantada = ""
	tempo_total_crescimento = 0.0
	if not preservar_arado:
		arado = false

	if has_node("SpriteTerra"):
		_atualizar_visual()

	atualizar_visual_planta("", 0)
	if notify_change:
		_notificar_estado_alterado()

# Quando o Timer emitir o sinal de timeout: o estado muda para PRONTO_PARA_COLHER
func _on_timer_timeout() -> void:
	if estado_atual == State.CRESCENDO:
		if not regado and SeasonManager.estacao_atual != SeasonManager.Estacao.INVERNO:
			if randf() <= 0.20:
				living_soil_moisture = false
				regado = false
				semente_atual = {}
				semente_id_plantada = ""
				tempo_total_crescimento = 0.0
				estado_atual = State.VAZIO
				_atualizar_visual()
				_notificar_estado_alterado()
				atualizar_visual_planta("", 0)
				print("A planta morreu de sede!")
				return
		
		estado_atual = State.PRONTO_PARA_COLHER
		_atualizar_visual()
		_notificar_estado_alterado()
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
		$DropRaroVFX.z_as_relative = true
		$DropRaroVFX.z_index = 3
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
