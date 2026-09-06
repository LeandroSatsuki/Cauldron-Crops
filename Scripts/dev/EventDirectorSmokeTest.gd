extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var pontos_originais := GlobalInventory.pontos_alquimia
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
		_fail("evento aleatorio de mundo nao criou marcador")
		return
	if not EventDirector.collect_world_event():
		_fail("marcador de mundo nao foi coletavel")
		return
	if EventDirector.has_active_world_event() or int(GlobalInventory.inventario.get("fragmento_celestial", 0)) != fragmentos_originais + 1:
		_fail("coleta do fragmento nao atualizou estado e inventario")
		return

	GlobalInventory.pontos_alquimia = pontos_originais
	GlobalInventory.inventario["escama_brilhante"] = escamas_originais
	GlobalInventory.inventario["fragmento_celestial"] = fragmentos_originais
	EventDirector.debug_reset_for_test()
	print("EventDirectorSmokeTest: PASS - janela previsivel, atividade e evento de mundo estao coerentes.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("EventDirectorSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
