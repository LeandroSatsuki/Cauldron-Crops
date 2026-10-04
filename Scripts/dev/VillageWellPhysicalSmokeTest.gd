extends Node

const MAIN := preload("res://Scenes/Main.tscn")
var main: Node2D
var well: VillageWell
var panel: PanelContainer
var player: PlayerAvatar
var chest: VillageChest
var checks := 0
var failed := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		_check(false, "exige APPDATA isolado")
		return _finish()
	PocoManager.set_process(false)
	GroveExpedition.set_process(false)
	_reset(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await _settle()
	well = main.get_node("VillageWell")
	panel = well.panel
	player = main.get_node("PlayerAvatar")
	chest = main.get_node("VillageChest")
	main.get_node("Golem").call("set_work_priority", 4)
	(main.get_node("Golem").get("_think_timer") as Timer).stop()
	chest.set_contents({"trigo": 5, "mistura_restauradora": 1})
	if "--verify-well-physical-reopen" in OS.get_cmdline_user_args():
		_check(SaveManager.load_game(), "novo processo carrega arquivo QA")
		_place(well.global_position + Vector2(0, 60))
		well.open_panel()
		panel.refresh()
		_check(well.is_panel_open() and panel.status_label.text.contains("já obtido") and well.get("_improved"), "reabertura mostra benefício e visual melhorado")
		_check(not panel.improve_button.visible and not well.try_improve_from_panel(), "reabertura não cobra novamente")
		_check(GlobalInventory.get_item_quantity("agua") == 7 and chest.get_contents().is_empty(), "arquivo preserva reserva e custo já consumido")
		return _finish()
	_check(well.global_position == Vector2(540, 280) and well.is_in_group("village_well"), "posição canônica fora dos canteiros")
	for plot in main.get("farm_plot_registry").values():
		_check(well.global_position.distance_to(plot.global_position) > 100, "nenhum lote atual sob o poço")
	_check(main.call("_world_position_has_interaction_collider", well.global_position), "poço possui área de interação")
	var cell: Vector2i = main.call("_converter_posicao_global_em_grid", well.global_position)
	_check(main.call("_obter_bloqueios_solo_na_celula", cell).get("building", false), "política identifica construção")
	var original_inventory := GlobalInventory.inventario.duplicate(true)
	_place(well.global_position + Vector2(250, 0))
	well.open_panel()
	_check(not well.is_panel_open() and not well.try_improve_from_panel(), "callback distante não abre ou consome")
	await _test_approach_and_input()
	panel.refresh()
	_check(panel.improve_button.disabled and panel.status_label.text.contains("Clareira"), "projeto bloqueado antes do marco, reserva continua disponível")
	await _click(panel.improve_button)
	_check(GlobalInventory.inventario == original_inventory and EconomyManager.poco_capacidade_maxima == 10, "clique bloqueado não consome")
	for resolution in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		await _settle()
		_check_layout()
		await _capture("well_%d_%d_locked" % [resolution.x, resolution.y])
	var previous := panel.position
	var drag_press := InputEventMouseButton.new()
	drag_press.button_index = MOUSE_BUTTON_LEFT
	drag_press.pressed = true
	panel.get("_drag").call("_on_handle_gui_input", drag_press)
	var motion := InputEventMouseMotion.new()
	panel.get("_drag").set("drag_offset", previous + Vector2(35, 15) - panel.title.get_global_mouse_position())
	panel.get("_drag").call("_on_handle_gui_input", motion)
	drag_press.pressed = false
	panel.get("_drag").call("_on_handle_gui_input", drag_press)
	panel.refresh()
	_check(panel.position.distance_to(previous + Vector2(35, 15)) < 1, "arraste e consulta conservam posição")
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	GlobalInventory.set_inventory_contents({"agua": 7, "trigo": 2})
	panel.refresh()
	_check(panel.improve_button.disabled and panel.status_label.text.contains("Faltam"), "falta de material atualiza sem consumir")
	GlobalInventory.set_inventory_contents({"agua": 7, "trigo": 3})
	panel.refresh()
	_check(not panel.improve_button.disabled, "complemento pessoal habilita confirmação")
	await _capture("well_ready")
	await _click(panel.improve_button)
	_check(EconomyManager.well_improved_by_project and EconomyManager.poco_capacidade_maxima == 20, "clique no botão melhora pelo contrato")
	_check(chest.get_contents().is_empty() and GlobalInventory.get_item_quantity("trigo") == 0 and GlobalInventory.get_item_quantity("agua") == 7 and GlobalInventory.pontos_alquimia == 3, "baú primeiro, sem água/XP instantâneos")
	_check(not panel.improve_button.visible and well.get("_improved"), "estado concluído e visual mudam")
	panel.improve_button.pressed.emit()
	_check(GlobalInventory.get_item_quantity("agua") == 7 and not well.try_improve_from_panel(), "callback antigo não cobra benefício duplicado")
	_check_layout()
	await _capture("well_completed")
	_check(SaveManager.save_game(), "salva melhoria por UI em arquivo QA")
	_check(SaveManager.load_game() and not well.is_panel_open(), "load fecha painel obsoleto")
	_place(well.global_position + Vector2(0, 60))
	well.open_panel()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	get_viewport().push_input(escape, true)
	await _settle()
	_check(not well.is_panel_open() and not main.call("_esta_modal_aberto"), "Escape libera contexto")
	await _test_old_skill_and_regressions()
	await _test_travel()
	_finish()

func _test_approach_and_input() -> void:
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)
	var camera: Camera2D = main.get_node("MainCamera")
	main.call("set_camera_follow_enabled", false)
	var limits := [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
	# Cursor físico pode estar fora da janela oculta. Liberar limites só no
	# fixture permite alinhar o canvas sem mover esse cursor ou mudar o mapa.
	camera.limit_left = -1000000
	camera.limit_top = -1000000
	camera.limit_right = 1000000
	camera.limit_bottom = 1000000
	camera.position = well.global_position
	camera.force_update_scroll()
	# Mesmo contrato usado pelo teste dos objetos existentes: arbitragem antes
	# do picking, depois evento do collider; não automatiza o cursor do Windows.
	var point := well.global_position + Vector2(0, -25)
	camera.position += point - main.get_global_mouse_position()
	camera.force_update_scroll()
	_check(main.get_global_mouse_position().distance_to(point) < 0.1, "canvas QA alinhado ao collider sem controlar cursor")
	var reset := InputEventAction.new()
	reset.action = "well_qa_unused"
	get_viewport().push_input(reset)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main.call("_unhandled_input", click)
	_check(not get_viewport().is_input_handled() and not main.call("has_pending_player_interaction"), "enxada não captura clique antes do picking")
	camera.limit_left = limits[0]
	camera.limit_top = limits[1]
	camera.limit_right = limits[2]
	camera.limit_bottom = limits[3]
	well.call("_on_input_event", get_viewport(), click, 0)
	_check(main.call("has_pending_player_interaction") and not well.is_panel_open(), "clique com enxada inicia aproximação, sem arar")
	var deadline := Time.get_ticks_msec() + 6000
	while not well.is_panel_open() and Time.get_ticks_msec() < deadline:
		await get_tree().physics_frame
	_check(well.is_panel_open() and well.can_interact_now() and not player.has_active_destination(), "aproximação real para fora do collider, sem andar contra parede")
	_check(not main.call("has_pending_player_interaction") and ToolManager.is_hoe_selected(), "chegada conserva enxada e encerra rota")
	_check(main.call("_esta_modal_aberto") and not main.call("try_move_player_to", Vector2(900, 700), false), "modal bloqueia movimento")
	var before := GlobalInventory.inventario.duplicate(true)
	await _click_world(main.call("_converter_grid_em_posicao_global", Vector2i(6, 5)))
	_check(main.call("obter_farm_plot_por_grid_position", Vector2i(6, 5)) == null and before == GlobalInventory.inventario, "painel impede clique vazando para cultivo")

func _test_old_skill_and_regressions() -> void:
	_reset(true)
	chest.set_contents({"trigo": 8, "mistura_restauradora": 1})
	_check(EconomyManager.try_unlock_water_skill(), "habilidade continua alternativa")
	_place(well.global_position + Vector2(0, 60))
	well.open_panel()
	panel.refresh()
	_check(not panel.improve_button.visible and not well.try_improve_from_panel() and not EconomyManager.well_improved_by_project, "painel reconhece alternativa sem projeto pago")
	well.close_panel()
	var ui := main.get_node("UI")
	_place(chest.global_position + Vector2(0, 70))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	chest.call("_on_clickable_area_input_event", get_viewport(), click, 0)
	_check(ui.get("village_chest_panel").visible and ToolManager.is_hoe_selected(), "baú abre com enxada após Poço")
	ui.call("fechar_bau_vila")
	var cauldron := main.get_node("CauldronUI")
	var anchor: Node2D = cauldron.get_node("BaseAnchor")
	_place(anchor.global_position + Vector2(0, 70))
	cauldron.call("_on_area_2d_input_event", get_viewport(), click, 0)
	_check(cauldron.get_node("PopupLayer/CenterContainer/PopupUI").visible and ToolManager.is_hoe_selected(), "caldeirão abre com enxada após Poço")
	cauldron.call("fechar_popup")
	var plot: Node2D = main.call("obter_farm_plot_por_grid_position", Vector2i(0, 0))
	_place(plot.global_position + Vector2(0, 55))
	plot.call("_on_plot_clicked")
	_check(plot.get("arado") and ToolManager.is_hoe_selected(), "arar lote continua funcional depois dos painéis")

func _test_travel() -> void:
	_reset(true)
	chest.set_contents({"trigo": 8, "mistura_restauradora": 1})
	_place(well.global_position + Vector2(0, 60))
	well.open_panel()
	_check(main.call("request_region_transition", &"foraging_grove", &"from_farm"), "viagem pelo coordenador")
	_check(not well.is_panel_open(), "início de transição fecha modal")
	var deadline := Time.get_ticks_msec() + 6000
	while RegionTravelCoordinator.is_transition_in_progress() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(get_tree().current_scene != main and not main.is_inside_tree(), "vila fica em cache")
	panel.improve_button.pressed.emit()
	_check(not well.try_improve_from_panel() and chest.get_item_quantity("trigo") == 8 and EconomyManager.poco_capacidade_maxima == 10, "callback cacheado não consome")
	get_tree().root.size = Vector2i(800, 600)
	_check(RegionTravelCoordinator.return_home_for_load(), "retorna HOME")
	_place(well.global_position + Vector2(0, 60))
	well.open_panel()
	await _settle()
	_check_layout()
	_check(well.is_panel_open() and not panel.improve_button.disabled, "retorno/resize não deixam modal órfão")
	await _click(panel.improve_button)
	_check(SaveManager.save_game(), "arquivo final para reabertura física")

func _check_layout() -> void:
	var rect := panel.get_global_rect()
	_check(get_viewport().get_visible_rect().encloses(rect), "painel contido no viewport")
	_check(panel.get_theme_stylebox("panel").bg_color.a == 1.0, "fundo opaco")
	for control in [panel.title, panel.water_label, panel.water_bar, panel.status_label, panel.improve_button, panel.feedback]:
		if control.is_visible_in_tree():
			_check(rect.encloses(control.get_global_rect()), "controle contido " + str(control.name))

func _reset(restored: bool) -> void:
	EconomyManager.well_improved_by_project = false
	EconomyManager.poco_capacidade_maxima = 10
	GlobalInventory.skills_desbloqueadas = []
	GlobalInventory.pontos_alquimia = 3
	GlobalInventory.semente_selecionada = ""
	GlobalInventory.set_inventory_contents({"agua": 7, "trigo": 3})
	GroveExpedition.load_save_data({"discovered": restored, "restored": restored, "forage_sources": {}})
	ToolManager.force_select_tool(ToolManager.ToolType.HOE)

func _place(point: Vector2) -> void:
	main.call("_cancel_pending_player_interaction", true)
	player.stop_moving()
	player.global_position = point

func _click_world(point: Vector2) -> void:
	var screen := get_viewport().get_canvas_transform() * point
	await _click_at(screen)

func _click(button: BaseButton) -> void:
	await _settle()
	await _click_at(button.get_global_rect().get_center())

func _click_at(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
		await get_tree().physics_frame

func _settle() -> void:
	for index in range(10):
		await get_tree().process_frame
	await get_tree().physics_frame

func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/VillageWellPhysical/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	get_viewport().get_texture().get_image().save_png(directory + label + ".png")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("VillageWellPhysicalSmokeTest: FAIL - " + message)

func _finish() -> void:
	if not failed:
		print("VillageWellPhysicalSmokeTest: PASS - %d verificações de picking, aproximação, painel, custos, load e viagem." % checks)
	get_tree().quit(1 if failed else 0)
