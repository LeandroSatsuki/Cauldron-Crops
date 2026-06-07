extends Node2D

const MOUSE_LEFT = MOUSE_BUTTON_LEFT

@onready var drop_slot_1: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot1
@onready var drop_slot_2: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot2
@onready var misturar_button: Button = $PopupLayer/CenterContainer/PopupUI/MisturarButton
@onready var btn_livro_receitas: Button = $PopupLayer/CenterContainer/PopupUI/BtnLivroReceitas
@onready var resultado_label: Label = $PopupLayer/CenterContainer/PopupUI/ResultadoLabel
@onready var popup_ui: Panel = $PopupLayer/CenterContainer/PopupUI
@onready var batch_timer: Timer = $BatchTimer
@onready var batch_progress_panel: PanelContainer = $BatchProgressPanel
@onready var batch_status_label: Label = $BatchProgressPanel/MarginContainer/VBoxBatch/BatchStatusLabel
@onready var batch_progress_bar: ProgressBar = $BatchProgressPanel/MarginContainer/VBoxBatch/BatchProgressBar
@onready var btn_cancelar_producao: Button = $BatchProgressPanel/MarginContainer/VBoxBatch/BtnCancelarProducao

var estado_atual: String = "IDLE"
var item_em_producao: String = ""
var tempo_producao: float = 5.0
var _batch_recipe_id: String = ""
var _batch_resultado: String = ""
var _batch_ingredientes: Dictionary = {}
var _batch_quantidade_total: int = 0
var _batch_quantidade_concluida: int = 0
var _batch_ativo: bool = false

func _ready() -> void:
	add_to_group("cauldrons")
	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)
	if btn_livro_receitas and not btn_livro_receitas.pressed.is_connected(_on_btn_livro_receitas_pressed):
		btn_livro_receitas.pressed.connect(_on_btn_livro_receitas_pressed)
	$Area2D.input_pickable = true
	$Area2D.input_event.connect(_on_area_2d_input_event)
	$BrewTimer.timeout.connect(_on_brew_timer_timeout)
	if batch_timer:
		batch_timer.timeout.connect(_on_batch_timer_timeout)
	if batch_progress_panel:
		batch_progress_panel.visible = false
	if btn_cancelar_producao and not btn_cancelar_producao.pressed.is_connected(_on_btn_cancelar_producao_pressed):
		btn_cancelar_producao.pressed.connect(_on_btn_cancelar_producao_pressed)
		btn_cancelar_producao.disabled = true
	
	var btn_fechar = $PopupLayer/CenterContainer/PopupUI/BtnFechar
	if btn_fechar:
		btn_fechar.pressed.connect(func(): 
			popup_ui.visible = false
		)
		
	# Ajustar o offset do sprite (escala 0.5): offset em pixels de textura (não escalados)
	$BaseAnchor/SpriteCaldeirao.offset = Vector2(0, -103)
	
	# Reset Visual
	$PopupLayer/CenterContainer/PopupUI.hide()
	$PopupLayer/CenterContainer/PopupUI.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Shader Material
	material = ShaderMaterial.new()
	material.shader = load("res://Shaders/transparencia.gdshader")

func _process(_delta: float) -> void:
	if $BaseAnchor/SpriteCaldeirao.frame >= 4:
		$BaseAnchor/SpriteCaldeirao.offset.y = -70
	else:
		$BaseAnchor/SpriteCaldeirao.offset.y = -103
	if _batch_ativo:
		_atualizar_interface_lote()

func abrir_popup():
	$PopupLayer.visible = true
	popup_ui.show()
	popup_ui.visible = true
	popup_ui.move_to_front()
	popup_ui.grab_click_focus() # Força o foco do mouse para a interface

func fechar_popup() -> void:
	if popup_ui:
		popup_ui.visible = false
	if has_node("PopupLayer"):
		$PopupLayer.visible = false
	if batch_progress_panel:
		batch_progress_panel.move_to_front()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_LEFT:
		if _batch_ativo:
			cancelar_producao_em_lote()
			return
		abrir_popup()

func _on_btn_livro_receitas_pressed() -> void:
	print("DEBUG Cauldron: botão livro de receitas clicado")
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("abrir_livro_receitas"):
		ui.abrir_livro_receitas(true, self)
	else:
		push_warning("Cauldron: nao foi possivel abrir o Livro de Receitas. UI ausente ou metodo abrir_livro_receitas nao encontrado.")

func _on_btn_cancelar_producao_pressed() -> void:
	cancelar_producao_em_lote()

func iniciar_producao_em_lote(recipe_id: String, quantidade: int) -> bool:
	if _batch_ativo:
		push_warning("Cauldron: ja existe uma producao em lote em andamento.")
		return false
	if estado_atual != "IDLE":
		push_warning("Cauldron: nao e possivel iniciar lote enquanto o caldeirao esta ocupado.")
		return false
	if recipe_id == "":
		push_warning("Cauldron: receita vazia recebida para producao em lote.")
		return false
	if not Database.receitas_alquimia.has(recipe_id):
		push_warning("Cauldron: receita inexistente para producao em lote: %s" % recipe_id)
		return false
	if quantidade <= 0:
		push_warning("Cauldron: quantidade invalida para producao em lote: %s" % str(quantidade))
		return false

	var ingredientes := Database.obter_ingredientes_receita(recipe_id)
	if ingredientes.is_empty():
		push_warning("Cauldron: nao foi possivel reconstruir os ingredientes da receita %s." % recipe_id)
		return false

	var quantidade_maxima := _calcular_quantidade_maxima_ingredientes(ingredientes)
	if quantidade_maxima <= 0:
		push_warning("Cauldron: ingredientes insuficientes para producao em lote de %s." % recipe_id)
		return false

	var quantidade_final := clampi(quantidade, 1, quantidade_maxima)
	var resultado := str(Database.receitas_alquimia.get(recipe_id, ""))
	if resultado == "":
		push_warning("Cauldron: resultado vazio para a receita %s." % recipe_id)
		return false
	if resultado == "golem_coletor":
		var espacos_disponiveis := EconomyManager.max_golems - EconomyManager.total_golems
		if espacos_disponiveis <= 0:
			push_warning("Cauldron: capacidade maxima de Golems atingida.")
			return false
		quantidade_final = min(quantidade_final, espacos_disponiveis)

	var ingredientes_contados := _contar_ingredientes(ingredientes)
	var removidos: Dictionary = {}
	for ingrediente_id in ingredientes_contados.keys():
		var total_necessario := int(ingredientes_contados[ingrediente_id]) * quantidade_final
		if total_necessario <= 0:
			continue
		if not GlobalInventory.remover_item(str(ingrediente_id), total_necessario):
			for rollback_id in removidos.keys():
				GlobalInventory.adicionar_item(str(rollback_id), int(removidos[rollback_id]))
			push_warning("Cauldron: falha ao consumir ingredientes para o lote de %s." % recipe_id)
			return false
		removidos[ingrediente_id] = total_necessario

	_batch_recipe_id = recipe_id
	_batch_resultado = resultado
	_batch_ingredientes = ingredientes_contados
	_batch_quantidade_total = quantidade_final
	_batch_quantidade_concluida = 0
	_batch_ativo = true
	estado_atual = "BATCH"
	item_em_producao = resultado

	_abrir_painel_lote()
	_atualizar_interface_lote()
	fechar_popup()
	_iniciar_proximo_tick_lote()
	return true

func cancelar_producao_em_lote() -> void:
	if not _batch_ativo:
		return

	var restante: int = int(max(_batch_quantidade_total - _batch_quantidade_concluida, 0))
	if restante > 0 and not _batch_ingredientes.is_empty():
		for ingrediente_id in _batch_ingredientes.keys():
			var quantidade_por_unidade: int = int(_batch_ingredientes[ingrediente_id])
			var quantidade_devolvida: int = int(quantidade_por_unidade) * int(restante)
			if quantidade_devolvida > 0:
				GlobalInventory.adicionar_item(str(ingrediente_id), quantidade_devolvida)

	if batch_timer:
		batch_timer.stop()

	_batch_ativo = false
	estado_atual = "IDLE"
	item_em_producao = ""
	_batch_recipe_id = ""
	_batch_resultado = ""
	_batch_ingredientes.clear()
	_batch_quantidade_total = 0
	_batch_quantidade_concluida = 0

	if batch_progress_bar:
		batch_progress_bar.value = 0.0
	if batch_status_label:
		batch_status_label.text = "Producao cancelada."
	_fechar_painel_lote()
	_atualizar_botao_cancelar_lote(false)

	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		ui.criar_texto_flutuante("Produção cancelada", $BaseAnchor/SpriteCaldeirao.global_position, Color.YELLOW)
	print("Cauldron: producao em lote cancelada. Ingredientes devolvidos para ", restante, " unidade(s) restante(s).")

func _contar_ingredientes(ingredientes: Array) -> Dictionary:
	var contagem: Dictionary = {}
	for ingrediente in ingredientes:
		var ingrediente_id := str(ingrediente)
		contagem[ingrediente_id] = int(contagem.get(ingrediente_id, 0)) + 1
	return contagem

func _calcular_quantidade_maxima_ingredientes(ingredientes: Array) -> int:
	if ingredientes.is_empty():
		return 0

	var contagem_necessaria := _contar_ingredientes(ingredientes)
	var quantidade_maxima := -1
	for ingrediente_id in contagem_necessaria.keys():
		var quantidade_no_inventario := int(GlobalInventory.inventario.get(str(ingrediente_id), 0))
		var quantidade_necessaria := int(contagem_necessaria[ingrediente_id])
		if quantidade_no_inventario < quantidade_necessaria:
			return 0

		var fabricaveis := int(quantidade_no_inventario / quantidade_necessaria)
		if quantidade_maxima == -1 or fabricaveis < quantidade_maxima:
			quantidade_maxima = fabricaveis

	return max(quantidade_maxima, 0)

func _abrir_painel_lote() -> void:
	if batch_progress_panel:
		batch_progress_panel.visible = true
	_atualizar_botao_cancelar_lote(true)

func _fechar_painel_lote() -> void:
	if batch_progress_panel:
		batch_progress_panel.visible = false
	_atualizar_botao_cancelar_lote(false)

func _atualizar_botao_cancelar_lote(ativo: bool) -> void:
	if btn_cancelar_producao:
		btn_cancelar_producao.visible = ativo
		btn_cancelar_producao.disabled = not ativo

func _iniciar_proximo_tick_lote() -> void:
	if not _batch_ativo:
		return

	if batch_timer:
		batch_timer.stop()
		batch_timer.wait_time = max(0.1, tempo_producao)
		batch_timer.start()
	else:
		_processar_tick_lote()

func _on_batch_timer_timeout() -> void:
	_processar_tick_lote()

func _processar_tick_lote() -> void:
	if not _batch_ativo:
		return

	_batch_quantidade_concluida += 1
	if _batch_resultado == "golem_coletor":
		EconomyManager.total_golems += 1
	elif _batch_resultado != "":
		GlobalInventory.adicionar_item(_batch_resultado, 1)

	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		var nome_exibicao = "Golem" if _batch_resultado == "golem_coletor" else Database.obter_nome_item(_batch_resultado)
		if nome_exibicao == "":
			nome_exibicao = _batch_resultado
		ui.criar_texto_flutuante("Lote pronto: " + nome_exibicao + "!", $BaseAnchor/SpriteCaldeirao.global_position, Color.GREEN)

	if _batch_quantidade_concluida >= _batch_quantidade_total:
		_finalizar_lote()
	else:
		_iniciar_proximo_tick_lote()

func _finalizar_lote() -> void:
	_batch_ativo = false
	estado_atual = "IDLE"
	item_em_producao = ""
	_batch_recipe_id = ""
	_batch_resultado = ""
	_batch_ingredientes.clear()
	_batch_quantidade_total = 0
	_batch_quantidade_concluida = 0
	if batch_timer:
		batch_timer.stop()
	if batch_progress_bar:
		batch_progress_bar.value = 0.0
	if batch_status_label:
		batch_status_label.text = "Producao em lote: concluida"
	_fechar_painel_lote()
	_atualizar_botao_cancelar_lote(false)

func _atualizar_interface_lote() -> void:
	if not _batch_ativo:
		return

	var progresso := 0.0
	if _batch_quantidade_total > 0:
		var fase_atual := 1.0
		if batch_timer and batch_timer.wait_time > 0.0:
			fase_atual = 1.0 - clampf(batch_timer.time_left / batch_timer.wait_time, 0.0, 1.0)
		progresso = clampf((float(_batch_quantidade_concluida) + fase_atual) / float(_batch_quantidade_total), 0.0, 1.0)

	if batch_progress_bar:
		batch_progress_bar.max_value = 1.0
		batch_progress_bar.value = progresso
	if batch_status_label:
		batch_status_label.text = "Producao em lote: %s/%s" % [_batch_quantidade_concluida, _batch_quantidade_total]

func _on_misturar_button_pressed() -> void:
	if not drop_slot_1 or not drop_slot_2:
		return
		
	var item1 = drop_slot_1.item_vinculado
	var item2 = drop_slot_2.item_vinculado
	
	if item1 == "" or item2 == "":
		if resultado_label:
			resultado_label.text = "Solte ingredientes nos slots!"
		return
		
	var qtd1 = GlobalInventory.inventario.get(item1, 0)
	var qtd2 = GlobalInventory.inventario.get(item2, 0)
	
	var ok = false
	if item1 == item2:
		if qtd1 >= 2:
			ok = true
	else:
		if qtd1 >= 1 and qtd2 >= 1:
			ok = true
			
	if not ok:
		if resultado_label:
			resultado_label.text = "Ingredientes insuficientes!"
		return
		
	# Determinar o resultado da combinação antes de consuming os ingredientes
	var chave1 = item1 + "_" + item2
	var chave2 = item2 + "_" + item1
	var resultado = ""
	var chave_combinacao = ""
	
	if Database.receitas_alquimia.has(chave1):
		resultado = Database.receitas_alquimia[chave1]
		chave_combinacao = chave1
	elif Database.receitas_alquimia.has(chave2):
		resultado = Database.receitas_alquimia[chave2]
		chave_combinacao = chave2
		
	if resultado == "":
		# Se a mistura falhar:
		var removed_1 = GlobalInventory.remover_item(item1, 1)
		var removed_2 = GlobalInventory.remover_item(item2, 1)
		if removed_1 and removed_2:
			if resultado_label:
				resultado_label.text = "Mistura falhou! Ingredientes perdidos."
			_limpar_slots()
		return
		
	if resultado == "golem_coletor":
		if EconomyManager.total_golems >= EconomyManager.max_golems:
			if resultado_label:
				resultado_label.text = "Capacidade máxima de Golems atingida!"
			return
		
		# Consome os ingredientes
		var removed_1 = GlobalInventory.remover_item(item1, 1)
		var removed_2 = GlobalInventory.remover_item(item2, 1)
		if removed_1 and removed_2:
			if not GlobalInventory.receitas_descobertas.has(chave_combinacao):
				GlobalInventory.pontos_alquimia += 1
				GlobalInventory.receitas_descobertas.append(chave_combinacao)
			
			# Iniciar produção
			item_em_producao = "golem_coletor"
			estado_atual = "BREWING"
			popup_ui.visible = false
			_iniciar_processo_de_mistura()
			$BrewTimer.start(tempo_producao)
			_limpar_slots()
			fechar_popup()
		else:
			if removed_1:
				GlobalInventory.adicionar_item(item1, 1)
			if removed_2:
				GlobalInventory.adicionar_item(item2, 1)
			if resultado_label:
				resultado_label.text = "Erro ao consumir ingredientes!"
	else:
		# Comportamento normal das outras poções
		var removed_1 = GlobalInventory.remover_item(item1, 1)
		var removed_2 = GlobalInventory.remover_item(item2, 1)
		
		if removed_1 and removed_2:
			if not GlobalInventory.receitas_descobertas.has(chave_combinacao):
				GlobalInventory.pontos_alquimia += 1
				GlobalInventory.receitas_descobertas.append(chave_combinacao)
			
			# Iniciar produção
			item_em_producao = resultado
			estado_atual = "BREWING"
			popup_ui.visible = false
			_iniciar_processo_de_mistura()
			$BrewTimer.start(tempo_producao)
			_limpar_slots()
		else:
			if removed_1:
				GlobalInventory.adicionar_item(item1, 1)
			if removed_2:
				GlobalInventory.adicionar_item(item2, 1)
			if resultado_label:
				resultado_label.text = "Erro ao consumir ingredientes!"

func _limpar_slots() -> void:
	if drop_slot_1:
		drop_slot_1.item_vinculado = ""
		var lbl1 = drop_slot_1.get_node_or_null("Label")
		if lbl1: lbl1.text = "Soltar item"
		var icon1 = drop_slot_1.get_node_or_null("ItemIcon")
		if icon1: icon1.texture = null
	if drop_slot_2:
		drop_slot_2.item_vinculado = ""
		var lbl2 = drop_slot_2.get_node_or_null("Label")
		if lbl2: lbl2.text = "Soltar item"
		var icon2 = drop_slot_2.get_node_or_null("ItemIcon")
		if icon2: icon2.texture = null

func _iniciar_processo_de_mistura():
	# Troca para o roxo imediatamente
	$BaseAnchor/SpriteCaldeirao.play("brewing")
	_iniciar_pulsar_magico()

func _on_brew_timer_timeout() -> void:
	$BaseAnchor/SpriteCaldeirao.play("idle") # Volta para o verde
	$BaseAnchor/SpriteCaldeirao.scale = Vector2(0.5, 0.5)
	estado_atual = "IDLE"
	
	if item_em_producao == "golem_coletor":
		EconomyManager.total_golems += 1
	elif item_em_producao != "":
		GlobalInventory.adicionar_item(item_em_producao, 1)
		
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		var nome_exibicao = "Golem" if item_em_producao == "golem_coletor" else Database.obter_nome_item(item_em_producao)
		if nome_exibicao == "":
			nome_exibicao = item_em_producao
		ui.criar_texto_flutuante("Sucesso: " + nome_exibicao + "!", $BaseAnchor/SpriteCaldeirao.global_position, Color.GREEN)
		
	item_em_producao = ""


func _iniciar_pulsar_magico():
	while estado_atual == "BREWING":
		var tween = create_tween()
		tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.45, 0.45), 0.5)
		tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.5, 0.5), 0.5)
		await tween.finished
