extends RefCounted
class_name VillageWellState

const BASE_CAPACITY := 10
const IMPROVED_CAPACITY := 20
const WATER_SKILL := "skill_agua"
const PROJECT_REQUIREMENTS := {"trigo": 8, "mistura_restauradora": 1}

# Preflight puro: nenhum recurso, ponto, marco ou água é concedido no load.
static func resolve_snapshot(data: Dictionary, current_capacity: int, current_project: bool, current_skills: Array, current_grove_restored: bool) -> Dictionary:
	var inventory: Dictionary = data.get("inventory", {}) if data.get("inventory", {}) is Dictionary else {}
	var complete := inventory.get("inventario") is Dictionary
	var well: Variant = data.get("poco", {})
	if not well is Dictionary:
		return {"valid": false}
	var capacity: Variant = well.get("capacidade_maxima", BASE_CAPACITY if complete else current_capacity)
	if not _is_whole_number(capacity, 1):
		return {"valid": false}
	var project: Variant = well.get("melhoria_projeto", false if complete else current_project)
	if not project is bool:
		return {"valid": false}
	var grove: Variant = data.get("grove_expedition", {})
	var restored: bool = bool(grove.get("restored", false)) if grove is Dictionary and data.has("grove_expedition") else (false if complete else current_grove_restored)
	if project and not restored:
		return {"valid": false}
	var skills: Variant = inventory.get("skills_desbloqueadas", current_skills)
	var skill_available: bool = skills is Array and WATER_SKILL in skills
	var resolved_capacity := int(capacity)
	if project or skill_available:
		resolved_capacity = maxi(resolved_capacity, IMPROVED_CAPACITY)
	if well.has("agua_atual") and not _is_whole_number(well["agua_atual"], 0):
		return {"valid": false}
	return {"valid": true, "capacity": resolved_capacity, "project": project, "has_water": well.has("agua_atual"), "water": int(well.get("agua_atual", 0))}

static func _is_whole_number(value: Variant, minimum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(int(value)) == float(value)
