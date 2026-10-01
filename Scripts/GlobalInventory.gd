extends Node

const COLECAO_PESCA_ITENS: Array[String] = ["peixe_comum", "escama_brilhante"]
const BONUS_COLECAO_PESCA_NOME := "Memória das Marés"
const PERSONAL_SLOT_CAPACITY: int = 12
const DEFAULT_STACK_LIMIT: int = 99
const NON_SLOTTED_ITEM_IDS: Array[String] = ["agua"]

var inventario: Dictionary = {
	"semente_basica": 10,
	"semente_inverno": 0
}
var cargas_crescimento: int = 0
var semente_selecionada: String = ""
var receitas_descobertas: Array = []
var pontos_alquimia: int = 0
var skills_desbloqueadas: Array = []
var colecao_pesca_descobertas: Array[String] = []
var colecao_pesca_concluida: bool = false
var lore_descobertas: Array[String] = []
var _personal_capacity_enforced: bool = true

func adicionar_item(produto: String, quantidade: int = 1) -> void:
	# Wrapper legado restrito a debug/testes. Produtores ativos usam insercao
	# estruturada e tratam recusa antes de concluir ou consumir a origem.
	try_add_item(produto, quantidade)

func get_item_quantity(item_id: String) -> int:
	var normalized_item_id := item_id.strip_edges()
	if normalized_item_id == "":
		return 0
	return maxi(int(inventario.get(normalized_item_id, 0)), 0)

func get_stack_limit(item_id: String) -> int:
	var normalized_item_id := item_id.strip_edges()
	if normalized_item_id == "":
		return DEFAULT_STACK_LIMIT
	var item_data: Dictionary = Database.obter_item_data(normalized_item_id)
	return maxi(int(item_data.get("stack_maximo", DEFAULT_STACK_LIMIT)), 1)

func get_slot_capacity() -> int:
	return PERSONAL_SLOT_CAPACITY

func get_used_slot_count() -> int:
	var used_slots := 0
	for item_variant in inventario.keys():
		var item_id := str(item_variant).strip_edges()
		var quantity := maxi(int(inventario[item_variant]), 0)
		if not _uses_personal_slot(item_id) or quantity <= 0:
			continue
		var stack_limit := get_stack_limit(item_id)
		used_slots += int(ceili(float(quantity) / float(stack_limit)))
	return used_slots

func get_free_slot_count() -> int:
	return maxi(PERSONAL_SLOT_CAPACITY - get_used_slot_count(), 0)

func get_personal_slot_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_variant in inventario.keys():
		var item_id := str(item_variant).strip_edges()
		var quantity := maxi(int(inventario[item_variant]), 0)
		if not _uses_personal_slot(item_id) or quantity <= 0:
			continue
		var stack_limit := get_stack_limit(item_id)
		var stack_count := int(ceili(float(quantity) / float(stack_limit)))
		var remaining := quantity
		for stack_index in range(stack_count):
			var stack_quantity := mini(remaining, stack_limit)
			entries.append({
				"item_id": item_id,
				"quantity": stack_quantity,
				"stack_index": stack_index,
				"stack_count": stack_count,
			})
			remaining -= stack_quantity
	return entries

func is_capacity_enforced() -> bool:
	return _personal_capacity_enforced

func set_capacity_enforced(enabled: bool) -> void:
	# Gancho de teste; o gameplay inicia com o piloto ativo e o load nao o altera.
	_personal_capacity_enforced = enabled

func get_acceptance(item_id: String, quantity: int) -> Dictionary:
	var normalized_item_id := item_id.strip_edges()
	if normalized_item_id == "" or quantity <= 0:
		return _acceptance_result(quantity, 0, "invalid_request")
	if not _personal_capacity_enforced or not _uses_personal_slot(normalized_item_id):
		return _acceptance_result(quantity, quantity, "")

	var stack_limit := get_stack_limit(normalized_item_id)
	var current_quantity := get_item_quantity(normalized_item_id)
	var occupied_remainder := current_quantity % stack_limit
	var room_in_current_stack := 0 if current_quantity == 0 or occupied_remainder == 0 else stack_limit - occupied_remainder
	var room_in_new_stacks := get_free_slot_count() * stack_limit
	var accepted := mini(quantity, room_in_current_stack + room_in_new_stacks)
	var reason := "" if accepted == quantity else ("inventory_full" if accepted == 0 else "partial_capacity")
	return _acceptance_result(quantity, accepted, reason)

func try_add_item(item_id: String, quantity: int = 1) -> Dictionary:
	var normalized_item_id := item_id.strip_edges()
	var result := get_acceptance(normalized_item_id, quantity)
	var accepted := int(result.get("accepted", 0))
	if accepted <= 0:
		return result

	inventario[normalized_item_id] = get_item_quantity(normalized_item_id) + accepted
	if normalized_item_id != "agua":
		print("Item adicionado ao inventário: ", normalized_item_id, " (Total: ", inventario[normalized_item_id], ")")
	return result

func get_batch_acceptance(items: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for item_variant in items.keys():
		var item_id := str(item_variant).strip_edges()
		var quantity := int(items[item_variant])
		if item_id == "" or quantity <= 0:
			return _batch_acceptance_result(items, {}, "invalid_request")
		normalized[item_id] = int(normalized.get(item_id, 0)) + quantity

	if normalized.is_empty():
		return _batch_acceptance_result(items, {}, "invalid_request")
	if not _personal_capacity_enforced:
		return _batch_acceptance_result(normalized, normalized, "")

	var projected := inventario.duplicate(true)
	for item_variant in normalized.keys():
		var item_id := str(item_variant)
		projected[item_id] = maxi(int(projected.get(item_id, 0)), 0) + int(normalized[item_variant])
	var current_slots := get_used_slot_count()
	var allowed_slots := maxi(PERSONAL_SLOT_CAPACITY, current_slots)
	if _calculate_used_slots(projected) > allowed_slots:
		return _batch_acceptance_result(normalized, {}, "inventory_full")
	return _batch_acceptance_result(normalized, normalized, "")

func can_accept_items(items: Dictionary) -> bool:
	return bool(get_batch_acceptance(items).get("success", false))

func try_add_items(items: Dictionary) -> Dictionary:
	var result := get_batch_acceptance(items)
	if not bool(result.get("success", false)):
		return result
	var accepted: Dictionary = result.get("accepted", {})
	for item_variant in accepted.keys():
		var item_id := str(item_variant)
		var quantity := int(accepted[item_variant])
		inventario[item_id] = get_item_quantity(item_id) + quantity
		if item_id != "agua":
			print("Item adicionado ao inventário: ", item_id, " (Total: ", inventario[item_id], ")")
	return result

func can_remove_item(item_id: String, quantity: int) -> bool:
	var normalized_item_id := item_id.strip_edges()
	return normalized_item_id != "" and quantity > 0 and get_item_quantity(normalized_item_id) >= quantity

func remover_item(nome_do_item: String, quantidade: int) -> bool:
	var normalized_item_id := nome_do_item.strip_edges()
	if not can_remove_item(normalized_item_id, quantidade):
		return false
	inventario[normalized_item_id] = get_item_quantity(normalized_item_id) - quantidade
	if normalized_item_id == semente_selecionada and get_item_quantity(normalized_item_id) == 0:
		semente_selecionada = ""
	if normalized_item_id != "agua":
		print("Item removido do inventário: ", normalized_item_id, " (Restam: ", inventario[normalized_item_id], ")")
	return true

func set_inventory_contents(contents: Dictionary) -> bool:
	var normalized: Dictionary = {}
	for item_variant in contents.keys():
		var item_id := str(item_variant).strip_edges()
		var quantity := int(contents[item_variant])
		if item_id == "" or quantity < 0:
			return false
		normalized[item_id] = quantity
	inventario = normalized
	if semente_selecionada != "" and get_item_quantity(semente_selecionada) == 0:
		semente_selecionada = ""
	return true

func _uses_personal_slot(item_id: String) -> bool:
	return item_id != "" and not item_id in NON_SLOTTED_ITEM_IDS

func _calculate_used_slots(contents: Dictionary) -> int:
	var used_slots := 0
	for item_variant in contents.keys():
		var item_id := str(item_variant).strip_edges()
		var quantity := maxi(int(contents[item_variant]), 0)
		if not _uses_personal_slot(item_id) or quantity <= 0:
			continue
		used_slots += int(ceili(float(quantity) / float(get_stack_limit(item_id))))
	return used_slots

func _acceptance_result(requested: int, accepted: int, reason: String) -> Dictionary:
	var safe_accepted := maxi(accepted, 0)
	var safe_remainder := maxi(requested - safe_accepted, 0)
	return {
		"requested": requested,
		"accepted": safe_accepted,
		"remainder": safe_remainder,
		"success": requested > 0 and safe_accepted == requested,
		"reason": reason,
	}

func _batch_acceptance_result(requested: Dictionary, accepted: Dictionary, reason: String) -> Dictionary:
	var remainder: Dictionary = {}
	for item_variant in requested.keys():
		var item_id := str(item_variant)
		var remaining := int(requested[item_variant]) - int(accepted.get(item_id, 0))
		if remaining > 0:
			remainder[item_id] = remaining
	return {
		"requested": requested.duplicate(true),
		"accepted": accepted.duplicate(true),
		"remainder": remainder,
		"success": not requested.is_empty() and remainder.is_empty(),
		"reason": reason,
	}

func registrar_item_colecao_pesca(item_id: String) -> Dictionary:
	var ja_descoberto := item_id in colecao_pesca_descobertas
	if item_id in COLECAO_PESCA_ITENS and not ja_descoberto:
		colecao_pesca_descobertas.append(item_id)

	var estava_concluida := colecao_pesca_concluida
	colecao_pesca_concluida = _colecao_pesca_esta_completa()
	var progresso := obter_progresso_colecao_pesca()
	progresso["nova_descoberta"] = item_id in COLECAO_PESCA_ITENS and not ja_descoberto
	progresso["concluida_agora"] = not estava_concluida and colecao_pesca_concluida
	return progresso

func obter_progresso_colecao_pesca() -> Dictionary:
	_normalizar_colecao_pesca()
	return {
		"descobertas": colecao_pesca_descobertas.duplicate(),
		"quantidade": colecao_pesca_descobertas.size(),
		"total": COLECAO_PESCA_ITENS.size(),
		"concluida": colecao_pesca_concluida,
		"bonus_nome": BONUS_COLECAO_PESCA_NOME,
	}

func aplicar_colecao_pesca_save(descobertas: Array, concluida: bool) -> void:
	colecao_pesca_descobertas.clear()
	for item_variant in descobertas:
		var item_id := str(item_variant)
		if item_id in COLECAO_PESCA_ITENS and not item_id in colecao_pesca_descobertas:
			colecao_pesca_descobertas.append(item_id)
	colecao_pesca_concluida = concluida or _colecao_pesca_esta_completa()

func possui_bonus_colecao_pesca() -> bool:
	return colecao_pesca_concluida

func register_lore_discovery(discovery_id: String) -> bool:
	if discovery_id == "" or discovery_id in lore_descobertas:
		return false
	lore_descobertas.append(discovery_id)
	return true

func has_lore_discovery(discovery_id: String) -> bool:
	return discovery_id in lore_descobertas

func apply_lore_discoveries_save(discoveries: Array) -> void:
	lore_descobertas.clear()
	for discovery_variant in discoveries:
		var discovery_id := str(discovery_variant)
		if discovery_id != "" and not discovery_id in lore_descobertas:
			lore_descobertas.append(discovery_id)

func _colecao_pesca_esta_completa() -> bool:
	_normalizar_colecao_pesca()
	return colecao_pesca_descobertas.size() == COLECAO_PESCA_ITENS.size()

func _normalizar_colecao_pesca() -> void:
	var descobertas_validas: Array[String] = []
	for item_id in COLECAO_PESCA_ITENS:
		if item_id in colecao_pesca_descobertas:
			descobertas_validas.append(item_id)
	colecao_pesca_descobertas = descobertas_validas
	colecao_pesca_concluida = colecao_pesca_descobertas.size() == COLECAO_PESCA_ITENS.size()
