extends RefCounted
class_name RecipeDatabase

const RECIPES_PATH := "res://Data/recipes/"

var recipes_by_id: Dictionary = {}

func load_recipes() -> void:
	recipes_by_id.clear()

	var dir := DirAccess.open(RECIPES_PATH)
	if dir == null:
		push_warning("RecipeDatabase: pasta de receitas nao encontrada em %s." % RECIPES_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := RECIPES_PATH.path_join(file_name)
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue

		if not file_name.to_lower().ends_with(".tres"):
			file_name = dir.get_next()
			continue

		var resource := load(full_path)
		if not (resource is RecipeData):
			push_warning("RecipeDatabase: recurso invalido ignorado em %s." % full_path)
			file_name = dir.get_next()
			continue

		var recipe := resource as RecipeData
		if recipe == null:
			push_warning("RecipeDatabase: falha ao converter recurso RecipeData em %s." % full_path)
			file_name = dir.get_next()
			continue

		if recipe.id.strip_edges() == "":
			push_warning("RecipeDatabase: receita com id vazio ignorada em %s." % full_path)
			file_name = dir.get_next()
			continue

		if recipes_by_id.has(recipe.id):
			push_warning("RecipeDatabase: id duplicado ignorado: %s (%s)." % [recipe.id, full_path])
			file_name = dir.get_next()
			continue

		recipes_by_id[recipe.id] = recipe
		file_name = dir.get_next()

	dir.list_dir_end()

func get_recipe(recipe_id: String) -> RecipeData:
	if recipe_id == "":
		return null

	if not recipes_by_id.has(recipe_id):
		return null

	return recipes_by_id.get(recipe_id) as RecipeData

func has_recipe(recipe_id: String) -> bool:
	return recipes_by_id.has(recipe_id)

func get_all_recipes() -> Array:
	var recipes: Array = []
	for recipe_id in recipes_by_id.keys():
		recipes.append(recipes_by_id[recipe_id])
	return recipes

func validate_recipes() -> Array:
	var problems: Array = []
	for recipe_id in recipes_by_id.keys():
		var recipe := recipes_by_id[recipe_id] as RecipeData
		if recipe == null:
			problems.append("%s: recurso invalido ou nulo." % str(recipe_id))
			continue

		if recipe.id.strip_edges() == "":
			problems.append("%s: id vazio." % str(recipe_id))
		if recipe.nome.strip_edges() == "":
			problems.append("%s: nome vazio." % str(recipe_id))
		if recipe.ingredientes.is_empty():
			problems.append("%s: ingredientes vazios." % str(recipe_id))
		if recipe.resultado_item.strip_edges() == "":
			problems.append("%s: resultado_item vazio." % str(recipe_id))
		if int(recipe.resultado_quantidade) <= 0:
			problems.append("%s: resultado_quantidade invalida (%s)." % [str(recipe_id), str(recipe.resultado_quantidade)])
		if float(recipe.tempo_producao) <= 0.0:
			problems.append("%s: tempo_producao invalido (%s)." % [str(recipe_id), str(recipe.tempo_producao)])
		if int(recipe.versao_do_schema) < 1:
			problems.append("%s: versao_do_schema invalida (%s)." % [str(recipe_id), str(recipe.versao_do_schema)])

	return problems

func compare_with_legacy_database() -> Array:
	var report: Array = []
	var legacy_ids: Array = []
	if Database != null:
		legacy_ids = Database.receitas_alquimia.keys()

	var resource_ids: Array = recipes_by_id.keys()
	resource_ids.sort()
	legacy_ids.sort()

	var only_in_resources: Array = []
	for recipe_id in resource_ids:
		if Database == null or not Database.receitas_alquimia.has(recipe_id):
			only_in_resources.append(recipe_id)

	var only_in_legacy: Array = []
	for recipe_id in legacy_ids:
		if not recipes_by_id.has(recipe_id):
			only_in_legacy.append(recipe_id)

	report.append("Somente em Resources: %s" % str(only_in_resources))
	report.append("Somente no legado: %s" % str(only_in_legacy))
	return report

static func debug_print_report() -> void:
	var db := RecipeDatabase.new()
	db.load_recipes()
	print(db.validate_recipes())
	print(db.compare_with_legacy_database())
