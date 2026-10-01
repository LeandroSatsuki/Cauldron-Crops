extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var pontos_originais := GlobalInventory.pontos_alquimia
	var inventario_original: Dictionary = GlobalInventory.inventario.duplicate(true)
	var capacidade_original: bool = GlobalInventory.is_capacity_enforced()
	var escamas_originais := int(GlobalInventory.inventario.get("escama_brilhante", 0))
	var fragmentos_originais := int(GlobalInventory.inventario.get("fragmento_celestial", 0))
	EventDirector.debug_reset_for_test()

	if EventDirector.is_rare_fish_window_active():
		_fail("janela previsivel iniciou ativa antes do atraso")
		return
	EventDirector.set("_session_elapsed", EventDirector.RARE_FISH_FIRST_WINDOW_DELAY)
	if not EventDirector.is_rare_fish_window_active() or not EventDirector.reward_rare_fish_window():
		_fail("janela previsivel nao concedeu recompensa quando ativa")
		return
	if int(GlobalInventory.inventario.get("escama_brilhante", 0)) != escamas_originais + 1:
		_fail("recompensa da janela previsivel nao chegou ao inventario")
		return

	if not EventDirector.debug_trigger_harvest_event(Vector2.ZERO):
		_fail("evento de atividade nao foi disparado")
		return
	if GlobalInventory.pontos_alquimia != pontos_originais + 1:
		_fail("evento de atividade nao aplicou a conveniencia esperada")
		return

	if not EventDirector.debug_trigger_world_event(Vector2(120.0, 80.0)) or not EventDirector.has_active_world_event():
		_fail("marcador de capacidade nao foi criado")
		return
	var constrained_inventory: Dictionary = {"fragmento_celestial": 99, "agua": 3}
	for index in range(11):
		constrained_inventory["item_teste_%02d" % index] = GlobalInventory.DEFAULT_STACK_LIMIT
	GlobalInventory.set_inventory_contents(constrained_inventory)
	GlobalInventory.set_capacity_enforced(true)
	var marker_before: Node = EventDirector.get("_world_event_marker") as Node
	var spawned_before := float(marker_before.get_meta("spawned_at", -1.0))
	EventDirector.set("_session_elapsed", spawned_before + 5.0)
	if EventDirector.collect_world_event():
		_fail("evento coletavel foi consumido sem espaco")
		return
	if not EventDirector.has_active_world_event() or GlobalInventory.get_item_quantity("fragmento_celestial") != 99:
		_fail("recusa por capacidade removeu marcador ou alterou inventario")
		return
	var marker_after: Node = EventDirector.get("_world_event_marker") as Node
	if float(marker_after.get_meta("spawned_at", -1.0)) <= spawned_before:
		_fail("recusa por capacidade nao renovou a janela do marcador")
		return
	if not GlobalInventory.remover_item("item_teste_00", GlobalInventory.DEFAULT_STACK_LIMIT):
		_fail("nao foi possivel liberar espaco para o evento")
		return
	if not EventDirector.collect_world_event() or EventDirector.has_active_world_event():
		_fail("marcador nao foi coletado depois de liberar espaco")
		return
	if GlobalInventory.get_item_quantity("fragmento_celestial") != 100:
		_fail("evento nao completou a pilha existente")
		return
	GlobalInventory.set_capacity_enforced(false)
	GlobalInventory.set_inventory_contents(inventario_original)

	if not EventDirector.debug_trigger_world_event(Vector2(120.0, 80.0)) or not EventDirector.has_active_world_event():
		_fail("evento aleatorio de mundo nao criou marcador")
		return
	if not EventDirector.collect_world_event():
		_fail("marcador de mundo nao foi coletavel")
		return
	if EventDirector.has_active_world_event() or int(GlobalInventory.inventario.get("fragmento_celestial", 0)) != fragmentos_originais + 1:
		_fail("coleta do fragmento nao atualizou estado e inventario")
		return

	GlobalInventory.pontos_alquimia = pontos_originais
	GlobalInventory.set_inventory_contents(inventario_original)
	GlobalInventory.set_capacity_enforced(capacidade_original)
	EventDirector.debug_reset_for_test()
	print("EventDirectorSmokeTest: PASS - janela previsivel, atividade e evento de mundo estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	GlobalInventory.set_capacity_enforced(false)
	push_error("EventDirectorSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
