extends Node

# Eventos sintéticos/fixtures QA; não homologa cursor físico, arte ou balanceamento.
const MAIN := preload("res://Scenes/Main.tscn")
const ITEM := "adubo_flamejante"
const SOIL := "preparo_solo_vivo"
var home: Node2D
var plot: Node2D
var pilot: Node2D
var ui: Node
var panel: Control
var player: PlayerAvatar
var chest: VillageChest
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA isolado sob Builds/QA antes de instanciar Main")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	plot = home.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	pilot = home.call("obter_farm_plot_por_grid_position", Vector2i(2, 2))
	ui = home.get_node("UI")
	panel = ui.get("item_use_panel")
	player = home.get_node("PlayerAvatar")
	chest = home.get_node("VillageChest")
	var golem: Node = home.get_node("Golem")
	golem.call("set_work_priority", 4)
	(golem.get("_think_timer") as Timer).stop()
	golem.process_mode = Node.PROCESS_MODE_DISABLED
	home.get_node("CauldronUI").process_mode = Node.PROCESS_MODE_DISABLED
	for farm_plot in home.get("farm_plot_registry").values():
		farm_plot.process_mode = Node.PROCESS_MODE_DISABLED
	_reset()
	await _card_and_layout()
	await _physical_arrival()
	await _crop_identity_and_refusals()
	await _cancellation_contracts()
	await _existing_branches()
	await _travel_contract()
	_finish()

func _reset() -> void:
	home.cancel_consumable_application()
	panel.close_card()
	panel.cancel_application()
	ui.call("fechar_bau_vila")
	ToolManager.clear_tool()
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.cargas_crescimento = 0
	GlobalInventory.apply_backpack_progress([])
	GlobalInventory.set_capacity_enforced(true)
	GlobalInventory.set_inventory_contents({ITEM: 3, SOIL: 1, "pocao_crescimento": 1, "semente_basica": 5, "semente_verao": 5, "agua": 7})
	chest.set_contents({ITEM: 4})
	SeasonManager.estacao_atual = SeasonManager.Estacao.PRIMAVERA
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	home.get_node("CauldronUI").call("load_save_data", {"state": "IDLE"})
	_crop(false)
	_place(plot.global_position + Vector2(0, 35))

func _crop(ready: bool, seed: String = "semente_verao") -> void:
	plot.call("load_save_data", {"estado_atual": 2 if ready else 1, "semente_id_plantada": seed, "arado": true, "regado": true, "tempo_restante": 0.0 if ready else 60.0, "tempo_total_crescimento": 60.0, "pronto_para_colher": ready, "expansion_blocked": false, "pending_harvest_rewards": {}, "living_soil_treated": false, "living_soil_moisture": false, "flame_fertilizer_applied": false})
	_check(plot.get("estado_atual") == (2 if ready else 1) and plot.get("semente_id_plantada") == seed and not plot.get("flame_fertilizer_applied"), "fixture de cultura válida")

func _resources() -> Dictionary:
	var personal: Dictionary = {}
	for id in GlobalInventory.inventario:
		personal[id] = int(GlobalInventory.inventario[id])
	var stored: Dictionary = {}
	for id in chest.get_contents():
		stored[id] = int(chest.get_item_quantity(id))
	return {"personal": personal, "stored": stored, "doses": GlobalInventory.cargas_crescimento}

func _card_and_layout() -> void:
	ToolManager.select_hoe()
	GlobalInventory.semente_selecionada = "semente_verao"
	var tool: int = ToolManager.get_active_tool()
	var before := _resources()
	# Entrada usada pelo slot da Mochila, inclusive abertura só após o release.
	ui.call("_on_slot_clicado", ITEM, false, null)
	await _settle()
	_check(panel.is_card_open() and panel.apply_button.visible and not panel.apply_button.disabled, "consulta mostra Aplicar explícito")
	_check(ToolManager.get_active_tool() == tool and GlobalInventory.semente_selecionada == "semente_verao" and _resources() == before, "consulta conserva ferramenta/semente/estoques")
	_check(panel.description_label.text.contains("+2") and panel.description_label.text.contains("maduro"), "cartão comunica quantidade e alvo maduro")
	for size in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = size
		await _settle()
		panel.call("_process", 0.0)
		if not get_viewport().get_visible_rect().encloses(panel.card.get_global_rect()):
			print("FlameFertilizerUISmokeTest: layout probe viewport=%s card=%s minimum=%s title=%s description=%s button=%s" % [get_viewport().get_visible_rect(), panel.card.get_global_rect(), panel.card.get_combined_minimum_size(), panel.title_label.get_global_rect(), panel.description_label.get_global_rect(), panel.apply_button.get_global_rect()])
		_check(get_viewport().get_visible_rect().encloses(panel.card.get_global_rect()), "cartão contido %s" % size)
		_check(panel.card.get_theme_stylebox("panel").bg_color.a == 1.0, "cartão opaco %s" % size)
		_check(panel.card.get_global_rect().encloses(panel.apply_button.get_global_rect()), "Aplicar acessível %s" % size)
		await _capture("card_%d_%d" % [size.x, size.y])
	await _click(panel.apply_button)
	_check(home.selected_consumable == ITEM and ToolManager.get_active_tool() == ToolManager.ToolType.NONE and GlobalInventory.semente_selecionada == "", "Aplicar estabelece exclusividade sem consumo")
	_check(_resources() == before and not panel.is_card_open(), "Aplicar fecha consulta sem gastar")
	for size in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = size
		await _settle()
		panel.call("_process", 0.0)
		_check(panel.application_bar.visible and get_viewport().get_visible_rect().encloses(panel.application_bar.get_global_rect()), "faixa visível/contida %s" % size)
		_check(panel.application_bar.get_theme_stylebox("panel").bg_color.a == 1.0, "faixa opaca %s" % size)
		await _capture("bar_%d_%d" % [size.x, size.y])
	var cancel: Button = null
	# O botão é construído em runtime; localizar pelo texto, sem depender de nome.
	for button in panel.application_bar.find_children("*", "Button", true, false):
		if button.text == "Cancelar":
			cancel = button
	_check(cancel != null, "cancelamento visível existe")
	if cancel != null:
		await _click(cancel)
	_check(home.selected_consumable == "" and _resources() == before, "Cancelar GUI não consome")

func _physical_arrival() -> void:
	_reset()
	_place(plot.global_position + Vector2(190, 0))
	_check(home.begin_consumable_application(ITEM), "arma adubo para collider")
	var initial_position := player.global_position
	var generation: int = plot.call("get_crop_generation")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	plot.call("_input_event", get_viewport(), event, 0)
	_check(home.has_pending_player_interaction() and not plot.get("flame_fertilizer_applied") and GlobalInventory.get_item_quantity(ITEM) == 3, "collider inicia caminho sem reserva/consumo")
	_check(player.get_requested_destination().distance_to(plot.global_position) <= 46.0, "destino respeita aproximação de 46 pixels")
	if not await _wait(func(): return home.selected_consumable == "", "chegada física aplica"):
		return
	_check(player.global_position.distance_to(initial_position) > 100.0 and player.global_position.distance_to(plot.global_position) <= 46.0, "personagem realmente deslocou/chegou, sem teleporte")
	_check(plot.get("flame_fertilizer_applied") and int(plot.call("get_crop_generation")) == generation, "marca a mesma cultura sem trocar geração")
	_check(GlobalInventory.get_item_quantity(ITEM) == 2 and chest.get_item_quantity(ITEM) == 4, "consome uma unidade pessoal, conserva baú")
	var before := _resources()
	home.try_apply_selected_consumable_to_plot(plot)
	_check(_resources() == before, "sem intenção não repete consumo")
	_check(home.begin_consumable_application(ITEM), "arma segunda tentativa")
	home.try_apply_selected_consumable_to_plot(plot)
	_check(not home.has_pending_player_interaction() and _resources() == before, "reaplicação recusa sem caminhada/gasto")

func _start_route() -> Dictionary:
	_place(plot.global_position + Vector2(250, 0))
	_check(home.begin_consumable_application(ITEM), "arma rota adversarial")
	_check(home.try_apply_selected_consumable_to_plot(plot) and home.has_pending_player_interaction(), "captura callback de aproximação")
	return {"application": int(home.get("_consumable_generation")), "crop": int(plot.call("get_crop_generation"))}

func _commit_captured(tokens: Dictionary) -> void:
	_place(plot.global_position + Vector2(0, 35))
	home.call("_commit_consumable_application", weakref(plot), ITEM, tokens["application"], tokens["crop"])

func _crop_identity_and_refusals() -> void:
	_reset()
	_crop(true)
	_check(home.begin_consumable_application(ITEM), "adubo aceita tomate maduro")
	home.try_apply_selected_consumable_to_plot(plot)
	_check(plot.get("flame_fertilizer_applied") and GlobalInventory.get_item_quantity(ITEM) == 2, "terceiro ramo aplica em maduro")
	_reset()
	var tokens := _start_route()
	plot.call("_on_timer_timeout")
	_check(plot.get("estado_atual") == 2 and int(plot.call("get_crop_generation")) == int(tokens["crop"]), "amadurecer preserva identidade")
	_commit_captured(tokens)
	_check(plot.get("flame_fertilizer_applied") and GlobalInventory.get_item_quantity(ITEM) == 2, "crescendo→maduro durante caminho continua válido")
	_reset()
	tokens = _start_route()
	plot.call("_concluir_colheita")
	_check(plot.call("try_plant_from_personal_inventory", "semente_verao")["success"], "novo tomate plantado no mesmo nó")
	var before := _resources()
	_check(int(plot.call("get_crop_generation")) != int(tokens["crop"]), "replantio tem outra geração")
	_commit_captured(tokens)
	_check(not plot.get("flame_fertilizer_applied") and _resources() == before and home.selected_consumable == ITEM, "callback não aduba nova cultura no mesmo nó")
	for mutation in ["stock", "hidden", "detached", "empty", "wrong_crop", "pending_rewards", "far"]:
		_reset()
		tokens = _start_route()
		var plot_parent: Node = plot.get_parent()
		if mutation == "stock":
			GlobalInventory.set_inventory_contents({"semente_basica": 5})
		elif mutation == "hidden":
			plot.hide()
		elif mutation == "detached":
			plot_parent.remove_child(plot)
		elif mutation == "empty":
			plot.call("_concluir_colheita")
		elif mutation == "wrong_crop":
			_crop(false, "semente_basica")
		elif mutation == "pending_rewards":
			plot.call("_on_timer_timeout")
			plot.call("_obter_ou_gerar_recompensas_colheita", "tomate_sol")
		before = _resources()
		if mutation == "far":
			player.stop_moving()
			home.call("_commit_consumable_application", weakref(plot), ITEM, tokens["application"], tokens["crop"])
		else:
			_commit_captured(tokens)
		_check(_resources() == before and not plot.get("flame_fertilizer_applied"), "alvo/estoque revalidado sem gasto: " + mutation)
		if mutation == "detached":
			plot_parent.add_child(plot)
		plot.show()
	_reset()
	_check(home.begin_consumable_application(ITEM), "arma teste alvo ausente")
	var before_null := _resources()
	_check(home.try_apply_selected_consumable_to_plot(null) and not home.has_pending_player_interaction() and _resources() == before_null, "alvo nulo recusa sem fallback")

func _cancellation_contracts() -> void:
	for cancellation in ["button", "escape", "right", "tool", "seed", "modal", "load", "new_item", "camera"]:
		_reset()
		var tokens := _start_route()
		var before := _resources()
		if cancellation == "button":
			panel.cancel_application()
		elif cancellation == "escape":
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			get_viewport().push_input(escape, true)
		elif cancellation == "right":
			_push_mouse(Vector2(10, 10), MOUSE_BUTTON_RIGHT, true)
			_push_mouse(Vector2(10, 10), MOUSE_BUTTON_RIGHT, false)
		elif cancellation == "tool":
			ToolManager.select_hoe()
			home.call("_process", 0.0)
		elif cancellation == "seed":
			GlobalInventory.semente_selecionada = "semente_verao"
			home.call("_process", 0.0)
		elif cancellation == "modal":
			ui.call("abrir_bau_vila", chest)
			home.call("_process", 0.0)
		elif cancellation == "load":
			var snapshot: Dictionary = SaveManager.call("_build_save_data")
			_check(SaveManager.call("_apply_save_data", snapshot), "load real em memória durante aproximação")
		elif cancellation == "new_item":
			panel.show_item("pocao_crescimento")
		elif cancellation == "camera":
			var middle := InputEventMouseButton.new()
			middle.button_index = MOUSE_BUTTON_MIDDLE
			middle.pressed = true
			home.call("_unhandled_input", middle)
			middle.pressed = false
			home.call("_unhandled_input", middle)
		_check(home.selected_consumable == "" and not home.has_pending_player_interaction(), "cancela intenção/rota: " + cancellation)
		_commit_captured(tokens)
		_check(_resources() == before and not plot.get("flame_fertilizer_applied"), "callback velho perto não consome: " + cancellation)
		ui.call("fechar_bau_vila")
		panel.close_card()
		await _settle()

func _existing_branches() -> void:
	_reset()
	_crop(false, "semente_basica")
	_check(home.begin_consumable_application("pocao_crescimento"), "ramo Crescimento continua habilitado")
	home.try_apply_selected_consumable_to_plot(plot)
	_check(GlobalInventory.cargas_crescimento == 2 and GlobalInventory.get_item_quantity("pocao_crescimento") == 0 and not plot.get("flame_fertilizer_applied"), "Crescimento não cai no ramo Adubo")
	_check(is_equal_approx(plot.get_node("Timer").time_left, 30.0), "Crescimento conserva redução pela metade")
	pilot.call("load_save_data", {"estado_atual": 0, "semente_id_plantada": "", "arado": true, "regado": false, "expansion_blocked": false, "living_soil_treated": false, "living_soil_moisture": false, "flame_fertilizer_applied": false})
	_check(pilot.get("estado_atual") == 0 and not pilot.get("living_soil_treated"), "fixture piloto vazio")
	_place(pilot.global_position + Vector2(0, 35))
	_check(home.begin_consumable_application(SOIL), "ramo Solo Vivo continua habilitado")
	home.try_apply_selected_consumable_to_plot(pilot)
	_check(pilot.get("living_soil_treated") and not pilot.get("flame_fertilizer_applied") and GlobalInventory.get_item_quantity(SOIL) == 0, "Solo Vivo não cai no ramo Adubo")

func _travel_contract() -> void:
	_reset()
	var tokens := _start_route()
	var before := _resources()
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "viagem real cancela aplicação")
	if not await _wait(func(): return not RegionTravelCoordinator.is_transition_in_progress(), "viagem conclui"):
		return
	_check(get_tree().current_scene != home and not home.is_inside_tree() and home.selected_consumable == "", "HOME cacheada não mantém intenção")
	home.call("_commit_consumable_application", weakref(plot), ITEM, tokens["application"], tokens["crop"])
	_check(_resources() == before and not plot.get("flame_fertilizer_applied"), "callback em cache não gasta/aplica remoto")
	_check(RegionTravelCoordinator.return_home_for_load(), "retorno HOME preserva fixture")
	await _settle()
	_commit_captured(tokens)
	_check(_resources() == before and not plot.get("flame_fertilizer_applied"), "callback antigo após retorno ainda recusado")

func _place(point: Vector2) -> void:
	home.call("_cancel_pending_player_interaction", true)
	player.stop_moving()
	player.global_position = point

func _click(button: BaseButton) -> void:
	await _settle()
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	for pressed in [true, false]:
		_push_mouse(point, MOUSE_BUTTON_LEFT, pressed)
		await get_tree().process_frame
		await get_tree().physics_frame

func _push_mouse(point: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = pressed
	get_viewport().push_input(event, true)

func _settle() -> void:
	for index in range(8):
		await get_tree().process_frame
	await get_tree().physics_frame

func _wait(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if bool(condition.call()):
			_check(true, label)
			return true
		await get_tree().physics_frame
	_check(false, "timeout: " + label)
	return false

func _capture(label: String) -> void:
	if "--capture-flame-fertilizer-ui" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/FlameFertilizer-UI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(get_viewport().get_texture().get_image().save_png(directory + label + ".png") == OK, "captura QA " + label)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("FlameFertilizerUISmokeTest: FAIL - " + label)

func _finish() -> void:
	if not failed:
		print("FlameFertilizerUISmokeTest: PASS - %d verificações UI/física/cancelamento/identidade. Não homologa mouse físico, arte ou balanceamento." % checks)
	else:
		print("FlameFertilizerUISmokeTest: total executado=%d, resultado FAIL." % checks)
	get_tree().quit(1 if failed else 0)
