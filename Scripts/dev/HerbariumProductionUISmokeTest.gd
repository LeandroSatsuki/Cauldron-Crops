extends Node

# Entrada sintética e caminhada real. Não homologa mouse físico ou arte final.
const MAIN := preload("res://Scenes/Main.tscn")
var home: Node2D
var site: Node2D
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
		_check(false, "APPDATA isolado antes de Main")
		return _finish()
	for service in [PocoManager, GroveExpedition, HerbariumProduction, EventDirector]:
		service.set_process(false)
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(800, 720)
	home = MAIN.instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await _settle()
	site = home.get_node("ProductiveHerbarium")
	panel = site.panel
	player = home.get_node("PlayerAvatar")
	chest = home.get_node("VillageChest")
	home.get_node("Golem").process_mode = Node.PROCESS_MODE_DISABLED
	(home.get_node("Golem").get("_think_timer") as Timer).stop()
	home.get_node("CauldronUI").process_mode = Node.PROCESS_MODE_DISABLED
	HerbariumProduction.reset_progress()
	GroveExpedition.reset_progress()
	GlobalInventory.set_inventory_contents({"trigo": 4, "tomate_sol": 1, "mistura_restauradora": 1})
	chest.set_contents({"trigo": 4, "tomate_sol": 1})
	ToolManager.select_hoe()
	GlobalInventory.semente_selecionada = ""
	for plot in home.get("farm_plot_registry").values():
		_check(site.global_position.distance_to(plot.global_position) > 60, "picking independente dos lotes")
	_check(home.call("_world_position_has_interaction_collider", site.global_position), "área clicável reconhecida")
	var cell: Vector2i = home.call("_converter_posicao_global_em_grid", site.global_position)
	_check(home.call("_obter_bloqueios_solo_na_celula", cell).get("building", false), "ponto bloqueia cultivo no seu footprint")
	_check(site.global_position == home.get("restoration_projects")["first_obstacle"].global_position + Vector2(104, 0), "junto ao Herbário sem mover projeto original")
	_place(site.global_position + Vector2(180, 0))
	site.open_panel()
	_check(not site.is_panel_open(), "abertura distante recusada")
	var before := GlobalInventory.inventario.duplicate(true)
	var initial := player.global_position
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	site.call("_on_input_event", get_viewport(), event, 0)
	_check(home.has_pending_player_interaction() and not site.is_panel_open(), "enxada selecionada inicia aproximação sem abrir remoto")
	await _wait(func(): return site.is_panel_open(), "chegada física abre painel")
	_check(player.global_position.distance_to(initial) > 80 and site.can_interact_now(), "personagem caminhou até alcance")
	_check(ToolManager.get_active_tool() == ToolManager.ToolType.HOE and GlobalInventory.inventario == before, "abrir preserva ferramenta e materiais")
	_check(home.call("_esta_modal_aberto") and not home.can_issue_player_move(Vector2.ZERO), "modal bloqueia movimento do mundo")
	panel.refresh()
	_check(panel.action_button.disabled and panel.status_label.text.contains("Clareira"), "gate explicado e ação desabilitada")
	for resolution in [Vector2i(800, 600), Vector2i(800, 720), Vector2i(1280, 720)]:
		get_tree().root.size = resolution
		await _settle()
		panel.refresh()
		_check(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "painel contido %s" % resolution)
		_check(panel.get_theme_stylebox("panel").bg_color.a == 1.0, "painel opaco")
		_check(panel.get_global_rect().encloses(panel.action_button.get_global_rect()), "ação acessível")
		await _capture("locked_%d_%d" % [resolution.x, resolution.y])
	var project: Node = home.get("restoration_projects")["first_obstacle"]
	home.get_node("PurificationObstacle").call("load_save_data", {"purified": true})
	project.call("set_area_purified", true)
	project.call("load_save_data", {"restored": true})
	GroveExpedition.load_save_data({"discovered": true, "restored": true, "forage_sources": {}})
	panel.refresh()
	_check(not panel.action_button.disabled and panel.action_button.text == "Ativar produção", "saldo combinado habilita confirmação")
	await _click(panel.action_button)
	_check(HerbariumProduction.activated and GlobalInventory.get_item_quantity("raiz_gelida") == 0, "ativação GUI não presenteia item")
	_check(chest.get_contents().is_empty() and GlobalInventory.get_item_quantity("trigo") == 0, "custo único combinando baú e mochila")
	_check(panel.action_button.text.contains("Coletar") and not panel.cost_box.visible, "painel passa à coleta pessoal")
	await _capture("available")
	await _click(panel.action_button)
	_check(GlobalInventory.get_item_quantity("raiz_gelida") == 1 and HerbariumProduction.renewal_remaining == 90.0, "coleta GUI entrega uma e inicia intervalo")
	_check(panel.action_button.disabled and panel.status_label.text.contains("90"), "renovação explícita sem segunda coleta")
	await _capture("renewing")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel.call("_input", escape)
	_check(not site.is_panel_open() and not home.call("_esta_modal_aberto"), "Escape fecha e libera mundo")
	_place(site.global_position + Vector2(200, 0))
	_check(site.request_open(), "rota adversarial inicia")
	var callback: Callable = home.get("_pending_player_interaction")["callback"]
	home.call("_cancel_pending_player_interaction", true)
	_place(site.global_position + Vector2(0, 40))
	callback.call()
	_check(not site.is_panel_open(), "callback cancelado não reabre")
	_place(site.global_position + Vector2(200, 0))
	site.request_open()
	callback = home.get("_pending_player_interaction")["callback"]
	HerbariumProduction.load_save_data(HerbariumProduction.get_save_data())
	_place(site.global_position + Vector2(0, 40))
	callback.call()
	_check(not site.is_panel_open(), "geração de load invalida abertura")
	site.open_panel()
	_check(site.is_panel_open(), "abertura local continua após cancelamento")
	_check(home.call("request_region_transition", &"foraging_grove", &"from_farm"), "viagem inicia")
	await _wait(func(): return not RegionTravelCoordinator.is_transition_in_progress(), "viagem conclui")
	_check(not site.is_panel_open() and not site.can_interact_now(), "HOME cacheada fecha e recusa interação")
	HerbariumProduction.advance_session_time(30)
	_check(HerbariumProduction.renewal_remaining == 60.0, "relógio único continua no Bosque")
	_check(RegionTravelCoordinator.return_home_for_load(), "retorna à vila")
	await _settle()
	_check(HerbariumProduction.renewal_remaining == 60.0 and not site.is_panel_open(), "retorno não duplica avanço nem abre painel")
	_finish()

func _place(point: Vector2) -> void:
	home.call("_cancel_pending_player_interaction", true)
	player.stop_moving()
	player.global_position = point

func _click(button: BaseButton) -> void:
	await _settle()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
		await get_tree().physics_frame

func _settle() -> void:
	for frame in range(8): await get_tree().process_frame
	await get_tree().physics_frame

func _wait(condition: Callable, label: String) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			_check(true, label)
			return
		await get_tree().physics_frame
	_check(false, "timeout " + label)

func _capture(label: String) -> void:
	if "--capture-herbarium-ui" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "res://Builds/QA/Herbarium-UI/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(get_viewport().get_texture().get_image().save_png(directory + label + ".png") == OK, "captura " + label)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("HerbariumProductionUISmokeTest: FAIL - " + label)

func _finish() -> void:
	print("HerbariumProductionUISmokeTest: %s - %d verificações UI/física. Não homologa mouse físico, arte ou balanceamento." % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)
