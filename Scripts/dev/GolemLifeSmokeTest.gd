extends Node

@onready var golem: Node = $Golem


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if golem == null or not golem.has_method("get_life_state"):
		_fail("golem sem contrato de vida")
		return

	golem.set("think_interval", 99.0)
	golem.set("idle_look_duration", 0.1)
	golem.set("rest_duration", 0.1)
	golem.set("react_duration", 0.1)
	var think_timer: Timer = golem.get("_think_timer")
	if think_timer:
		think_timer.stop()

	golem.call("_on_think_timer_timeout")
	if str(golem.call("get_life_state")) != "LOOKING" or str(golem.call("get_life_action_label")) != "olhando ao redor":
		_fail("golem nao entrou em olhar ao redor quando nao havia trabalho")
		return
	if str(golem.call("get_current_task_label")) != "Olhando ao redor":
		_fail("estado de olhar nao foi exposto para a interface")
		return
	await get_tree().create_timer(0.2).timeout
	if str(golem.call("get_life_state")) != "IDLE":
		_fail("golem nao retornou ao idle depois da pequena pausa")
		return

	golem.call("_on_think_timer_timeout")
	await get_tree().create_timer(0.2).timeout
	golem.call("_on_think_timer_timeout")
	if str(golem.call("get_life_state")) != "RESTING" or str(golem.call("get_life_action_label")) != "descansando":
		_fail("golem nao procurou ou iniciou o descanso")
		return
	if str(golem.call("get_current_task_label")) != "Descansando":
		_fail("estado de descanso nao foi exposto para a interface")
		return
	await get_tree().create_timer(0.2).timeout
	if str(golem.call("get_life_state")) != "IDLE":
		_fail("golem nao terminou o descanso")
		return

	if not bool(golem.call("notify_weather_reaction", "chuva")):
		_fail("reacao a chuva nao foi aceita")
		return
	if str(golem.call("get_life_state")) != "REACTING":
		_fail("reacao a chuva nao entrou no estado visual correto")
		return
	if bool(golem.call("notify_weather_reaction", "sol")):
		_fail("reacao aceitou clima nao suportado")
		return
	await get_tree().create_timer(0.2).timeout
	if str(golem.call("get_life_state")) != "IDLE":
		_fail("golem nao retornou ao idle depois da reacao")
		return

	golem.call("set_work_priority", 4)
	if bool(golem.call("reagir_a_chuva")):
		_fail("golem pausado aceitou reacao de clima")
		return

	print("GolemLifeSmokeTest: PASS - idle, olhar, descanso, reacao a chuva e pausa coexistem com o contrato de trabalho.")
	golem.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("GolemLifeSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
