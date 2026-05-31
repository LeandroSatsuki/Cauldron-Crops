extends Panel

signal craft_requested(recipe_id: String, quantidade: int)

@onready var recipe_list: ItemList = $MarginContainer/VBoxRoot/Body/LeftPanel/LeftBox/RecipeList
@onready var empty_label: Label = $MarginContainer/VBoxRoot/Body/LeftPanel/LeftBox/EmptyLabel
@onready var recipe_id_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/RecipeIdLabel
@onready var ingredients_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/IngredientsLabel
@onready var result_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/ResultLabel
@onready var max_craft_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/MaxCraftLabel
@onready var status_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/StatusLabel
@onready var quantity_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/QuantityRow/QuantityLabel
@onready var btn_quantity_minus: Button = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/QuantityRow/BtnQuantidadeMenos
@onready var btn_quantity_plus: Button = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/QuantityRow/BtnQuantidadeMais
@onready var quantity_input: LineEdit = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/QuantityInputRow/QuantityInput
@onready var btn_produce: Button = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/BtnProduzir
@onready var btn_close: Button = $MarginContainer/VBoxRoot/HeaderBar/BtnFechar

var _last_discovered_count: int = -1
var _last_inventory_snapshot: Dictionary = {}
var _selected_recipe_id: String = ""
var _craft_quantity: int = 1
var cauldron_ref: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	z_index = 200

	if btn_close:
		btn_close.pressed.connect(fechar)
	if recipe_list:
		recipe_list.item_selected.connect(_on_recipe_selected)
		recipe_list.allow_reselect = true
	if btn_quantity_minus:
		btn_quantity_minus.pressed.connect(_on_quantity_minus_pressed)
	if btn_quantity_plus:
		btn_quantity_plus.pressed.connect(_on_quantity_plus_pressed)
	if quantity_input:
		quantity_input.text_submitted.connect(_on_quantity_input_submitted)
		quantity_input.focus_exited.connect(_on_quantity_input_focus_exited)
	if btn_produce:
		btn_produce.pressed.connect(_on_produce_pressed)

	_cache_inventory_snapshot()
	_refresh_recipe_list()
	_show_empty_state()

func _process(_delta: float) -> void:
	if not visible:
		return

	var current_count := GlobalInventory.receitas_descobertas.size()
	if current_count != _last_discovered_count:
		_refresh_recipe_list()
	elif _inventory_changed() and _selected_recipe_id != "":
		_show_recipe(_selected_recipe_id)

func abrir() -> void:
	visible = true
	move_to_front()
	grab_click_focus()
	_refresh_recipe_list()

func fechar() -> void:
	visible = false

func toggle() -> void:
	if visible:
		fechar()
	else:
		abrir()

func _refresh_recipe_list() -> void:
	if not recipe_list:
		return

	_last_discovered_count = GlobalInventory.receitas_descobertas.size()
	var previous_selection := _selected_recipe_id
	recipe_list.clear()

	var discovered := _get_unique_discovered_recipes()
	if discovered.is_empty():
		_show_empty_state()
		return

	empty_label.visible = false
	recipe_list.visible = true

	for recipe_id in discovered:
		var display_name := _format_recipe_name(recipe_id)
		var index := recipe_list.add_item(display_name)
		recipe_list.set_item_metadata(index, recipe_id)

	var target_index := 0
	if previous_selection != "":
		var found_index := _find_recipe_index(previous_selection)
		if found_index != -1:
			target_index = found_index
	recipe_list.select(target_index)
	_show_recipe_by_index(target_index)

func _get_unique_discovered_recipes() -> Array:
	var seen := {}
	var recipes: Array = []

	for recipe_id in GlobalInventory.receitas_descobertas:
		if typeof(recipe_id) != TYPE_STRING:
			continue
		if seen.has(recipe_id):
			continue
		if not Database.receitas_alquimia.has(recipe_id):
			continue

		seen[recipe_id] = true
		recipes.append(recipe_id)

	return recipes

func _find_recipe_index(recipe_id: String) -> int:
	if not recipe_list:
		return -1

	for i in range(recipe_list.item_count):
		if str(recipe_list.get_item_metadata(i)) == recipe_id:
			return i
	return -1

func _on_recipe_selected(index: int) -> void:
	_show_recipe_by_index(index)

func _show_recipe_by_index(index: int) -> void:
	if not recipe_list:
		return
	if index < 0 or index >= recipe_list.item_count:
		_show_empty_state()
		return

	var recipe_id := str(recipe_list.get_item_metadata(index))
	_selected_recipe_id = recipe_id
	_craft_quantity = 1
	_show_recipe(recipe_id)

func _show_recipe(recipe_id: String) -> void:
	if recipe_id == "":
		_show_empty_state()
		return

	if not Database.receitas_alquimia.has(recipe_id):
		_show_unavailable_recipe(recipe_id)
		return

	var ingredientes := Database.obter_ingredientes_receita(recipe_id)
	var resultado := str(Database.receitas_alquimia.get(recipe_id, ""))
	recipe_id_label.text = "Receita: " + _format_recipe_name(recipe_id)
	result_label.text = "Resultado: " + _format_item_name(resultado)

	if ingredientes.is_empty():
		ingredients_label.text = "Ingredientes: nao foi possivel reconstruir os ingredientes desta receita."
		max_craft_label.text = "Quantidade maxima: indisponivel"
		status_label.text = "Limite atual: formato da receita precisa de adaptacao."
		_craft_quantity = 0
		_atualizar_controles_producao(0)
		_cache_inventory_snapshot()
		return

	ingredients_label.text = "Ingredientes: " + _format_ingredients(ingredientes)
	var quantidade_maxima := _calcular_quantidade_maxima(ingredientes)
	max_craft_label.text = "Quantidade maxima: " + str(quantidade_maxima)
	if quantidade_maxima <= 0:
		status_label.text = "Voce nao tem ingredientes suficientes."
		_craft_quantity = 0
	else:
		status_label.text = "Voce pode fabricar esta receita agora."
		if _craft_quantity <= 0 or _craft_quantity > quantidade_maxima:
			_craft_quantity = 1

	_atualizar_controles_producao(quantidade_maxima)
	_cache_inventory_snapshot()

func _show_empty_state() -> void:
	_selected_recipe_id = ""
	_craft_quantity = 0
	if empty_label:
		empty_label.visible = true
		empty_label.text = "Nenhuma receita descoberta ainda."
	if recipe_list:
		recipe_list.visible = false
	if recipe_id_label:
		recipe_id_label.text = "Receita: -"
	if ingredients_label:
		ingredients_label.text = "Ingredientes: -"
	if result_label:
		result_label.text = "Resultado: -"
	if max_craft_label:
		max_craft_label.text = "Quantidade maxima: -"
	if status_label:
		status_label.text = "Descubra uma receita no caldeirao para ver os detalhes."
	_atualizar_controles_producao(0)
	_cache_inventory_snapshot()

func _show_unavailable_recipe(recipe_id: String) -> void:
	recipe_id_label.text = "Receita: " + _format_recipe_name(recipe_id)
	ingredients_label.text = "Ingredientes: indisponiveis"
	result_label.text = "Resultado: indisponivel"
	max_craft_label.text = "Quantidade maxima: indisponivel"
	status_label.text = "A receita existe no save, mas nao esta presente no Database."
	_craft_quantity = 0
	_atualizar_controles_producao(0)
	_cache_inventory_snapshot()

func _calcular_quantidade_maxima(ingredientes: Array) -> int:
	if ingredientes.is_empty():
		return 0

	var contagem_necessaria := {}
	for ingrediente in ingredientes:
		var ingrediente_id := str(ingrediente)
		contagem_necessaria[ingrediente_id] = contagem_necessaria.get(ingrediente_id, 0) + 1

	var quantidade_maxima := -1
	for ingrediente_id in contagem_necessaria.keys():
		var quantidade_no_inventario := int(GlobalInventory.inventario.get(ingrediente_id, 0))
		var quantidade_necessaria := int(contagem_necessaria[ingrediente_id])
		if quantidade_no_inventario < quantidade_necessaria:
			return 0

		var fabricaveis: int = int(quantidade_no_inventario / quantidade_necessaria)
		if quantidade_maxima == -1 or fabricaveis < quantidade_maxima:
			quantidade_maxima = fabricaveis

	return max(quantidade_maxima, 0)

func _format_ingredients(ingredientes: Array) -> String:
	var contagem := {}
	for ingrediente in ingredientes:
		var ingrediente_id := str(ingrediente)
		contagem[ingrediente_id] = contagem.get(ingrediente_id, 0) + 1

	var partes: Array[String] = []
	for ingrediente_id in contagem.keys():
		var qtd := int(contagem[ingrediente_id])
		partes.append("%s x %s" % [str(qtd), _format_item_name(ingrediente_id)])

	return ", ".join(partes)

func _atualizar_controles_producao(quantidade_maxima: int) -> void:
	if quantity_label:
		if quantidade_maxima <= 0:
			quantity_label.text = "Quantidade: 0"
		else:
			quantity_label.text = "Quantidade: " + str(_craft_quantity)

	if quantity_input:
		quantity_input.editable = quantidade_maxima > 0
		if quantidade_maxima <= 0:
			quantity_input.text = "0"
		elif not quantity_input.has_focus():
			quantity_input.text = str(_craft_quantity)

	if btn_quantity_minus:
		btn_quantity_minus.disabled = quantidade_maxima <= 0 or _craft_quantity <= 1
	if btn_quantity_plus:
		btn_quantity_plus.disabled = quantidade_maxima <= 0 or _craft_quantity >= quantidade_maxima
	if btn_produce:
		btn_produce.disabled = quantidade_maxima <= 0 or _selected_recipe_id == "" or _craft_quantity <= 0

func _on_quantity_minus_pressed() -> void:
	if _selected_recipe_id == "":
		return

	var ingredientes := Database.obter_ingredientes_receita(_selected_recipe_id)
	var quantidade_maxima := _calcular_quantidade_maxima(ingredientes)
	if quantidade_maxima <= 0:
		return
	if _craft_quantity > 1:
		_craft_quantity -= 1
	_craft_quantity = min(_craft_quantity, quantidade_maxima)
	_atualizar_controles_producao(quantidade_maxima)

func _on_quantity_plus_pressed() -> void:
	if _selected_recipe_id == "":
		return

	var ingredientes := Database.obter_ingredientes_receita(_selected_recipe_id)
	var quantidade_maxima := _calcular_quantidade_maxima(ingredientes)
	if quantidade_maxima <= 0:
		return
	_craft_quantity = min(_craft_quantity + 1, quantidade_maxima)
	_atualizar_controles_producao(quantidade_maxima)

func _on_quantity_input_submitted(_text: String) -> void:
	_aplicar_quantidade_digitada()

func _on_quantity_input_focus_exited() -> void:
	_aplicar_quantidade_digitada()

func _aplicar_quantidade_digitada() -> void:
	if _selected_recipe_id == "":
		return

	var ingredientes := Database.obter_ingredientes_receita(_selected_recipe_id)
	var quantidade_maxima := _calcular_quantidade_maxima(ingredientes)
	if quantidade_maxima <= 0:
		return

	var texto := ""
	if quantity_input:
		texto = quantity_input.text.strip_edges()

	var valor_digitado := 1
	if texto != "" and texto.is_valid_int():
		valor_digitado = int(texto)

	_craft_quantity = clampi(valor_digitado, 1, quantidade_maxima)
	if quantity_input:
		quantity_input.text = str(_craft_quantity)
	_atualizar_controles_producao(quantidade_maxima)

func _on_produce_pressed() -> void:
	if _selected_recipe_id == "" or _craft_quantity <= 0:
		if status_label:
			status_label.text = "Selecione uma receita."
		return

	var cauldron := _get_valid_cauldron()
	if cauldron == null:
		if status_label:
			status_label.text = "Nenhum caldeirao vinculado para produzir."
		push_warning("RecipeBookUI: nenhum caldeirao valido encontrado.")
		return

	var quantidade := int(_craft_quantity)
	var ok := bool(cauldron.iniciar_producao_em_lote(_selected_recipe_id, quantidade))
	if ok:
		if status_label:
			status_label.text = "Producao iniciada."
		fechar()
	else:
		if status_label:
			status_label.text = "Nao foi possivel iniciar a producao."

func set_cauldron(cauldron: Node) -> void:
	if cauldron == null:
		push_warning("RecipeBookUI: set_cauldron recebeu null.")
		return

	if not cauldron.has_method("iniciar_producao_em_lote"):
		push_warning("RecipeBookUI: caldeirao invalido path=%s script=%s has_batch=%s" % [
			str(cauldron.get_path()),
			str(cauldron.get_script().resource_path) if cauldron.get_script() else "sem script",
			str(cauldron.has_method("iniciar_producao_em_lote"))
		])
		return

	cauldron_ref = cauldron

func _get_valid_cauldron() -> Node:
	if cauldron_ref != null and cauldron_ref.has_method("iniciar_producao_em_lote"):
		return cauldron_ref

	var cauldrons := get_tree().get_nodes_in_group("cauldrons")
	for node in cauldrons:
		if node != null and node.has_method("iniciar_producao_em_lote"):
			cauldron_ref = node
			return node

	return null

func set_cauldron_reference(cauldron: Node) -> void:
	set_cauldron(cauldron)

func get_cauldron_reference() -> Node:
	return cauldron_ref

func _cache_inventory_snapshot() -> void:
	_last_inventory_snapshot = GlobalInventory.inventario.duplicate()

func _inventory_changed() -> bool:
	if _last_inventory_snapshot.size() != GlobalInventory.inventario.size():
		return true

	for item_id in GlobalInventory.inventario:
		if not _last_inventory_snapshot.has(item_id):
			return true
		if int(_last_inventory_snapshot[item_id]) != int(GlobalInventory.inventario[item_id]):
			return true

	return false

func _format_recipe_name(recipe_id: String) -> String:
	return _format_item_name(recipe_id)

func _format_item_name(item_id: String) -> String:
	if item_id == "":
		return "-"

	var nome := item_id.replace("_", " ")
	if nome.length() == 0:
		return "-"

	return nome.substr(0, 1).to_upper() + nome.substr(1, nome.length() - 1)
