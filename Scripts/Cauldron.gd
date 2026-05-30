extends Node2D

const MOUSE_LEFT = MOUSE_BUTTON_LEFT

@onready var drop_slot_1: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot1
@onready var drop_slot_2: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot2
@onready var misturar_button: Button = $PopupLayer/CenterContainer/PopupUI/MisturarButton
@onready var resultado_label: Label = $PopupLayer/CenterContainer/PopupUI/ResultadoLabel
@onready var popup_ui: Panel = $PopupLayer/CenterContainer/PopupUI

var estado_atual: String = "IDLE"
var item_em_producao: String = ""
var tempo_producao: float = 5.0

func _ready() -> void:
	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)
	$Area2D.input_pickable = true
	$Area2D.input_event.connect(_on_area_2d_input_event)
	$BrewTimer.timeout.connect(_on_brew_timer_timeout)
	
	var btn_fechar = $PopupLayer/CenterContainer/PopupUI/BtnFechar
	if btn_fechar:
		btn_fechar.pressed.connect(func(): popup_ui.visible = false)
		
	# Ajustar o offset do sprite (escala 0.5): offset em pixels de textura (não escalados)
	$BaseAnchor/SpriteCaldeirao.offset = Vector2(0, -103)
	
	# Reset Visual
	$PopupLayer/CenterContainer/PopupUI.hide()
	$PopupLayer/CenterContainer/PopupUI.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Shader Material
	material = ShaderMaterial.new()
	material.shader = load("res://Shaders/transparencia.gdshader")

func _process(_delta: float) -> void:
	if $BaseAnchor/SpriteCaldeirao.frame >= 4:
		$BaseAnchor/SpriteCaldeirao.offset.y = -70
	else:
		$BaseAnchor/SpriteCaldeirao.offset.y = -103

func abrir_popup():
	get_viewport().set_input_as_handled()
	get_viewport().gui_disable_input = false
	print("DEBUG: Executando abrir_popup()")
	$PopupLayer/CenterContainer/PopupUI.visible = true
	$PopupLayer/CenterContainer/PopupUI.process_mode = Node.PROCESS_MODE_INHERIT
	$PopupLayer/CenterContainer/PopupUI.show()
	$PopupLayer/CenterContainer/PopupUI.move_to_front() # Move o nó para o topo da lista de renderização

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_LEFT:
		print("DEBUG: Caldeirão capturou o clique!")
		abrir_popup()
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
			$BaseAnchor/SpriteCaldeirao.play("brewing")
			var tween = create_tween()
			tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.6, 0.4), 0.2)
			tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.5, 0.5), 0.2)
			$BrewTimer.start(tempo_producao)
			_limpar_slots()
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
			$BaseAnchor/SpriteCaldeirao.play("brewing")
			var tween = create_tween()
			tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.6, 0.4), 0.2)
			tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.5, 0.5), 0.2)
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
	if drop_slot_2:
		drop_slot_2.item_vinculado = ""
		var lbl2 = drop_slot_2.get_node_or_null("Label")
		if lbl2: lbl2.text = "Soltar item"

func _on_brew_timer_timeout() -> void:
	if item_em_producao == "golem_coletor":
		EconomyManager.total_golems += 1
	elif item_em_producao != "":
		GlobalInventory.adicionar_item(item_em_producao, 1)
		
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		var nome_exibicao = "Golem" if item_em_producao == "golem_coletor" else item_em_producao
		ui.criar_texto_flutuante("Sucesso: " + nome_exibicao + "!", $BaseAnchor/SpriteCaldeirao.global_position, Color.GREEN)
		
	$BaseAnchor/SpriteCaldeirao.play("idle")
	estado_atual = "IDLE"
	item_em_producao = ""
