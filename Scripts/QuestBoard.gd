extends Panel

@onready var lista_quests: VBoxContainer = $ListaQuests
@onready var btn_fechar: Button = $BtnFechar

func _ready() -> void:
	if btn_fechar:
		btn_fechar.pressed.connect(func(): visible = false)
	if QuestManager:
		QuestManager.quest_atualizada.connect(rebuild_ui)
	rebuild_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			rebuild_ui()

func rebuild_ui() -> void:
	if not lista_quests:
		return
		
	# Limpar lista antiga
	for child in lista_quests.get_children():
		child.queue_free()
		
	if not QuestManager:
		return
		
	for quest in QuestManager.quests_ativas:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = SIZE_EXPAND_FILL
		lista_quests.add_child(hbox)
		
		var label = Label.new()
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		var item_id = quest.get("pedido_item", "")
		var qtd_necessaria = quest.get("pedido_qtd", 0)
		var qtd_atual = GlobalInventory.inventario.get(item_id, 0)
		label.text = quest.get("texto", "") + " - " + str(qtd_atual) + "/" + str(qtd_necessaria) + " " + item_id
		hbox.add_child(label)
		
		var btn_entregar = Button.new()
		btn_entregar.text = "Entregar"
		btn_entregar.pressed.connect(_on_entregar_pressed.bind(quest))
		# Desativa se não tiver itens suficientes
		if qtd_atual < qtd_necessaria:
			btn_entregar.disabled = true
		hbox.add_child(btn_entregar)
		
		var btn_dispensar = Button.new()
		btn_dispensar.text = "Dispensar"
		btn_dispensar.pressed.connect(_on_dispensar_pressed.bind(quest))
		hbox.add_child(btn_dispensar)
		
		if not quest.get("aceita", false):
			var btn_aceitar = Button.new()
			btn_aceitar.text = "Aceitar"
			btn_aceitar.pressed.connect(_on_aceitar_pressed.bind(quest))
			hbox.add_child(btn_aceitar)

func _on_dispensar_pressed(quest: Dictionary) -> void:
	if QuestManager:
		QuestManager.quests_ativas.erase(quest)
		QuestManager.quest_atualizada.emit()

func _on_aceitar_pressed(quest: Dictionary) -> void:
	if QuestManager:
		for q in QuestManager.quests_ativas:
			if q == quest:
				q["aceita"] = true
				break
		QuestManager.quest_atualizada.emit()
	rebuild_ui()

func _on_entregar_pressed(quest: Dictionary) -> void:
	var item_id = quest.get("pedido_item", "")
	var qtd_necessaria = quest.get("pedido_qtd", 0)
	var qtd_atual = GlobalInventory.inventario.get(item_id, 0)
	
	if qtd_atual >= qtd_necessaria:
		if GlobalInventory.remover_item(item_id, qtd_necessaria):
			# Aplicar recompensa
			var recompensa_tipo = quest.get("recompensa_tipo", "")
			var recompensa_qtd = quest.get("recompensa_qtd", 0)
			
			match recompensa_tipo:
				"moedas":
					EconomyManager.adicionar_moedas(recompensa_qtd)
				"pontos_alquimia":
					GlobalInventory.pontos_alquimia += recompensa_qtd
				_:
					GlobalInventory.adicionar_item(recompensa_tipo, recompensa_qtd)
					
			if QuestManager:
				QuestManager.quests_ativas.erase(quest)
				QuestManager.quest_atualizada.emit()
				
			var ui = get_tree().current_scene.get_node_or_null("UI")
			if ui and ui.has_method("criar_texto_flutuante"):
				ui.criar_texto_flutuante("Sucesso!", global_position + Vector2(200, 150), Color.GREEN)
				
			print("Quest entregue com sucesso! Recompensa: ", recompensa_tipo, " x", recompensa_qtd)
