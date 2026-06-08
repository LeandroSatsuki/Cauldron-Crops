extends RefCounted
class_name RecipeResolver

const LEGACY_DEFAULT_TEMPO := 5.0
const RecipeDatabaseScript = preload("res://Scripts/data/RecipeDatabase.gd")

var _recipe_database: RecipeDatabase = null

func recipe_exists(recipe_id: String) -> bool:
	if recipe_id.strip_edges() == "":
		return false
	if get_recipe_data(recipe_id) != null:
		return true
	return Database != null and Database.receitas_alquimia.has(recipe_id)

func get_recipe_data(recipe_id: String) -> RecipeData:
	var recipe: RecipeData = _get_resource_recipe(recipe_id)
	if recipe != null:
		return recipe
	return null

func get_recipe(recipe_id: String) -> Dictionary:
	if recipe_id.strip_edges() == "":
		return {}

	var recipe_data := get_recipe_data(recipe_id)
	if recipe_data != null:
		return {
			"id": recipe_data.id,
			"nome": recipe_data.nome,
			"descricao": recipe_data.descricao,
			"categoria": recipe_data.categoria,
			"ingredientes": recipe_data.ingredientes.duplicate(true),
			"resultado_item": recipe_data.resultado_item,
			"resultado_quantidade": int(recipe_data.resultado_quantidade),
			"tempo_producao": float(recipe_data.tempo_producao),
			"source": "resource",
			"resource": recipe_data
		}

	if Database != null and Database.receitas_alquimia.has(recipe_id):
		return {
			"id": recipe_id,
			"nome": get_display_name(recipe_id),
			"descricao": "Receita legada/provisória.",
			"categoria": "legacy",
			"ingredientes": get_ingredients(recipe_id),
			"resultado_item": get_result(recipe_id),
			"resultado_quantidade": get_result_quantity(recipe_id),
			"tempo_producao": LEGACY_DEFAULT_TEMPO,
			"source": "legacy"
		}

	return {}

func get_ingredients(recipe_id: String) -> Array:
	var recipe_data := get_recipe_data(recipe_id)
	if recipe_data != null:
		return recipe_data.ingredientes.duplicate(true)

	if Database != null and Database.receitas_alquimia.has(recipe_id):
		return Database.obter_ingredientes_receita(recipe_id).duplicate(true)

	return []

func get_result(recipe_id: String) -> String:
	var recipe_data := get_recipe_data(recipe_id)
	if recipe_data != null:
		return recipe_data.resultado_item

	if Database != null and Database.receitas_alquimia.has(recipe_id):
		return str(Database.receitas_alquimia.get(recipe_id, ""))

	return ""

func get_result_quantity(recipe_id: String) -> int:
	var recipe_data := get_recipe_data(recipe_id)
	if recipe_data != null:
		return int(recipe_data.resultado_quantidade)

	if Database != null and Database.receitas_alquimia.has(recipe_id):
		return 1

	return 0

func get_display_name(recipe_id: String) -> String:
	var recipe_data := get_recipe_data(recipe_id)
	if recipe_data != null and recipe_data.nome.strip_edges() != "":
		return recipe_data.nome

	if recipe_id.strip_edges() == "":
		return "-"

	return _format_recipe_name(recipe_id)

func get_all_recipe_ids(include_legacy_fallback: bool = true) -> Array:
	var ids: Array = []
	var seen := {}

	var database := _get_recipe_database()
	if database != null:
		var resource_ids: Array = database.recipes_by_id.keys()
		resource_ids.sort()
		for recipe_id_variant in resource_ids:
			var recipe_id := str(recipe_id_variant)
			if recipe_id == "" or seen.has(recipe_id):
				continue
			seen[recipe_id] = true
			ids.append(recipe_id)

	if include_legacy_fallback and Database != null:
		var legacy_ids: Array = Database.receitas_alquimia.keys()
		legacy_ids.sort()
		for recipe_id_variant in legacy_ids:
			var recipe_id := str(recipe_id_variant)
			if recipe_id == "" or seen.has(recipe_id):
				continue
			seen[recipe_id] = true
			ids.append(recipe_id)

	return ids

func _get_resource_recipe(recipe_id: String) -> RecipeData:
	if recipe_id.strip_edges() == "":
		return null

	var database: RecipeDatabase = _get_recipe_database()
	if database == null or not database.has_recipe(recipe_id):
		return null

	var recipe := database.get_recipe(recipe_id)
	if recipe == null:
		return null

	if not _is_valid_recipe_data(recipe):
		return null

	return recipe

func _get_recipe_database() -> RecipeDatabase:
	if _recipe_database == null:
		_recipe_database = RecipeDatabaseScript.new()
		_recipe_database.load_recipes()
	return _recipe_database

func _is_valid_recipe_data(recipe) -> bool:
	if recipe == null:
		return false
	if recipe.id.strip_edges() == "":
		return false
	if recipe.nome.strip_edges() == "":
		return false
	if recipe.descricao.strip_edges() == "":
		return false
	if recipe.categoria.strip_edges() == "":
		return false
	if recipe.ingredientes.is_empty():
		return false
	if recipe.resultado_item.strip_edges() == "":
		return false
	if int(recipe.resultado_quantidade) <= 0:
		return false
	if float(recipe.tempo_producao) <= 0.0:
		return false
	if int(recipe.versao_do_schema) < 1:
		return false
	return true

func _format_recipe_name(recipe_id: String) -> String:
	var nome := recipe_id.replace("_", " ").strip_edges()
	if nome == "":
		return "-"
	return nome.substr(0, 1).to_upper() + nome.substr(1, nome.length() - 1)
