extends RefCounted
class_name LivingSoilState

# Piloto local; não é uma matriz genérica de solos ou aquisição.
const PILOT_CELL := Vector2i(2, 2)
const ITEM_ID := "preparo_solo_vivo"
const RECIPE_ID := "solo_vivo_retencao"
const WHEAT_SEED_ID := "semente_basica"

static func validate_flags(data: Dictionary, cell: Vector2i) -> bool:
	var treated: Variant = data.get("living_soil_treated", false)
	var moisture: Variant = data.get("living_soil_moisture", false)
	if not treated is bool or not moisture is bool:
		return false
	if (treated or moisture) and cell != PILOT_CELL:
		return false
	if treated:
		if data.has("crop_id") and data.get("tile_state") == 4:
			return false
		if not data.has("crop_id") and data.get("expansion_blocked", false) == true:
			return false
	if not moisture:
		return true
	if not treated:
		return false
	# Umidade herdada disponível é um estado vazio/arado/molhado, não cultura.
	if data.has("crop_id"):
		return data.get("crop_id") == "" and data.get("is_watered") == true and data.get("tile_state") == 2
	return data.get("semente_id_plantada", "") == "" and data.get("estado_atual", 0) == 0 and data.get("regado") == true and data.get("arado") == true and data.get("expansion_blocked", false) == false
