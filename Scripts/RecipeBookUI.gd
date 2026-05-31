extends Panel

const KNOWN_ITEM_IDS := [
	"agua",
	"carvao",
	"trigo",
	"tomate_sol",
	"abobora_sombria",
	"raiz_gelida",
	"palha_rara",
	"rama_encantada",
	"semente_basica",
	"semente_inverno",
	"semente_verao",
	"semente_outono",
	"pocao_crescimento",
	"pocao_aceleradora",
	"essencia_sombria",
	"adubo_flamejante",
	"elixir_estacional",
	"golem_coletor"
]

@onready var recipe_list: ItemList = $MarginContainer/VBoxRoot/Body/LeftPanel/LeftBox/RecipeList
@onready var empty_label: Label = $MarginContainer/VBoxRoot/Body/LeftPanel/LeftBox/EmptyLabel
@onready var recipe_id_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/RecipeIdLabel
@onready var ingredients_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/IngredientsLabel
@onready var result_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/ResultLabel
@onready var max_craft_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/MaxCraftLabel
@onready var status_label: Label = $MarginContainer/VBoxRoot/Body/RightPanel/RightBox/StatusLabel
@onready var btn_close: Button = $MarginContainer/VBoxRoot/HeaderBar/BtnFechar

var _last_discovered_count: int = -1
var _selected_recipe_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	if btn_close:
		btn_close.pressed.connect(fechar)
	if recipe_list:
		recipe_list.item_selected.connect(_on_recipe_selected)
		recipe_list.allow_reselect = true

	_refresh_recipe_list()
	_show_empty_state()

func _process(_delta: float) -> void:
	if not visible:
		return

	var current_count := GlobalInventory.receitas_descobertas.size()
	if current_count != _last_discovered_count:
		_refresh_recipe_list()

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
	_show_recipe(recipe_id)

func _show_recipe(recipe_id: String) -> void:
	if recipe_id == "":
		_show_empty_state()
		return

	if not Database.receitas_alquimia.has(recipe_id):
		_show_unavailable_recipe(recipe_id)
		return

	var ingredientes := _resolver_ingredientes_da_receita(recipe_id)
	var resultado := str(Database.receitas_alquimia.get(recipe_id, ""))
	recipe_id_label.text = "Receita: " + _format_recipe_name(recipe_id)
	result_label.text = "Resultado: " + _format_item_name(resultado)

	if ingredientes.is_empty():
		ingredients_label.text = "Ingredientes: nao foi possivel reconstruir os ingredientes desta receita."
		max_craft_label.text = "Quantidade maxima: indisponivel"
		status_label.text = "Limite atual: formato da receita precisa de adaptacao."
		return

	ingredients_label.text = "Ingredientes: " + _format_ingredients(ingredientes)
	var quantidade_maxima := _calcular_quantidade_maxima(ingredientes)
	max_craft_label.text = "Quantidade maxima: " + str(quantidade_maxima)
	if quantidade_maxima <= 0:
		status_label.text = "Voce nao tem ingredientes suficientes."
	else:
		status_label.text = "Voce pode fabricar esta receita agora."

func _show_empty_state() -> void:
	_selected_recipe_id = ""
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

func _show_unavailable_recipe(recipe_id: String) -> void:
	recipe_id_label.text = "Receita: " + _format_recipe_name(recipe_id)
	ingredients_label.text = "Ingredientes: indisponiveis"
	result_label.text = "Resultado: indisponivel"
	max_craft_label.text = "Quantidade maxima: indisponivel"
	status_label.text = "A receita existe no save, mas nao esta presente no Database."

func _resolver_ingredientes_da_receita(recipe_id: String) -> Array:
	for i in range(KNOWN_ITEM_IDS.size()):
		for j in range(i, KNOWN_ITEM_IDS.size()):
			var item_a: String = str(KNOWN_ITEM_IDS[i])
			var item_b: String = str(KNOWN_ITEM_IDS[j])
			if recipe_id == "%s_%s" % [item_a, item_b]:
				return [item_a, item_b]
			if recipe_id == "%s_%s" % [item_b, item_a]:
				return [item_b, item_a]

	return []

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

func _format_recipe_name(recipe_id: String) -> String:
	return _format_item_name(recipe_id)

func _format_item_name(item_id: String) -> String:
	if item_id == "":
		return "-"

	var nome := item_id.replace("_", " ")
	if nome.length() == 0:
		return "-"

	return nome.substr(0, 1).to_upper() + nome.substr(1, nome.length() - 1)
