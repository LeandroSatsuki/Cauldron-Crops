extends Node

# Estado limitado ao recorte da clareira; não é um sistema genérico de quests.
signal progress_changed
signal forage_state_changed(source_id: String)

const PREPARATION_RECIPE := "mistura_restauradora_bosque"
const REWARD_RECIPE := "infusao_clareira"
const LIVING_SOIL_RECIPE := "solo_vivo_retencao"
const MIXTURE_ITEM := "mistura_restauradora"
const REQUIRED_MIXTURES := 2
const RENEWABLE_SOURCE := "clearing_charcoal"
const CHARCOAL_RENEWAL_SECONDS := 45.0
const HUDLayoutScript = preload("res://Scripts/HUDLayout.gd")
const SOURCE_IDS: Array[String] = [
	"charcoal_entry", "charcoal_branch", "charcoal_main", "charcoal_deep", RENEWABLE_SOURCE,
]

var discovered: bool = false
var restored: bool = false
var _forage_states: Dictionary = {}
var _tracker: PanelContainer
var _tracker_body: Label
var _tracker_toggle: Button
var _tracker_collapsed: bool = false
var _tracker_refresh_seconds: float = 0.0
var _tracker_layout_queued := false


func _ready() -> void:
	_create_tracker()


func _process(delta: float) -> void:
	for source_id in _forage_states:
		var state: Dictionary = _forage_states[source_id]
		if float(state["renewal_remaining"]) <= 0.0:
			continue
		state["renewal_remaining"] = maxf(float(state["renewal_remaining"]) - delta, 0.0)
		if float(state["renewal_remaining"]) == 0.0:
			state["collected"] = false
			forage_state_changed.emit(source_id)
	_tracker_refresh_seconds -= delta
	if _tracker_refresh_seconds <= 0.0:
		_tracker_refresh_seconds = 0.25
		_refresh_tracker()


func discover() -> bool:
	if discovered:
		return false
	discovered = true
	reconcile_recipe_discoveries()
	progress_changed.emit()
	_refresh_tracker()
	return true


func complete_restoration() -> bool:
	if not discovered or restored:
		return false
	restored = true
	reconcile_recipe_discoveries()
	progress_changed.emit()
	_refresh_tracker()
	return true


func get_forage_state(source_id: String) -> Dictionary:
	return _forage_states.get(source_id, {"collected": false, "renewal_remaining": 0.0}).duplicate(true)


func record_collection(source_id: String) -> void:
	if source_id not in SOURCE_IDS:
		return
	_forage_states[source_id] = {
		"collected": true,
		"renewal_remaining": CHARCOAL_RENEWAL_SECONDS if source_id == RENEWABLE_SOURCE else 0.0,
	}
	forage_state_changed.emit(source_id)


func get_save_data() -> Dictionary:
	return {"discovered": discovered, "restored": restored, "forage_sources": _forage_states.duplicate(true)}


func is_save_data_valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("discovered") is bool or not value.get("restored") is bool:
		return false
	if value["restored"] and not value["discovered"]:
		return false
	var sources: Variant = value.get("forage_sources", {})
	if not sources is Dictionary:
		return false
	for source_id in sources:
		if source_id not in SOURCE_IDS or not sources[source_id] is Dictionary:
			return false
		var state: Dictionary = sources[source_id]
		var remaining: Variant = state.get("renewal_remaining")
		if not state.get("collected") is bool or not (remaining is float or remaining is int):
			return false
		if not is_finite(float(remaining)) or float(remaining) < 0.0 or float(remaining) > CHARCOAL_RENEWAL_SECONDS:
			return false
		if source_id != RENEWABLE_SOURCE and float(remaining) != 0.0:
			return false
		if (not state["collected"] and float(remaining) != 0.0) or (source_id == RENEWABLE_SOURCE and state["collected"] and float(remaining) <= 0.0):
			return false
	return true


func load_save_data(value: Dictionary) -> bool:
	if not is_save_data_valid(value):
		return false
	discovered = value["discovered"]
	restored = value["restored"]
	_forage_states = value.get("forage_sources", {}).duplicate(true)
	reconcile_recipe_discoveries()
	for source_id in SOURCE_IDS:
		forage_state_changed.emit(source_id)
	progress_changed.emit()
	_refresh_tracker()
	return true


func reset_progress() -> void:
	load_save_data({"discovered": false, "restored": false, "forage_sources": {}})


func reconcile_recipe_discoveries() -> void:
	for recipe_id in [PREPARATION_RECIPE, REWARD_RECIPE, LIVING_SOIL_RECIPE]:
		var learned: bool = discovered if recipe_id == PREPARATION_RECIPE else restored
		while recipe_id in GlobalInventory.receitas_descobertas:
			GlobalInventory.receitas_descobertas.erase(recipe_id)
		if learned:
			GlobalInventory.receitas_descobertas.append(recipe_id)


func get_objective_text() -> String:
	if not discovered or restored:
		return ""
	var carried: int = GlobalInventory.get_item_quantity(MIXTURE_ITEM)
	var scene := get_tree().current_scene
	var region_id := ""
	if scene != null and scene.has_method("get_current_region_identity"):
		region_id = str(scene.call("get_current_region_identity").get("region_id", ""))
	var home: Node = scene if region_id == "farm_village" else RegionTravelCoordinator.get_cached_region_scene(&"farm_village")
	var chest: Node = home.get_node_or_null("VillageChest") if home != null else null
	var stored := int(chest.call("get_item_quantity", MIXTURE_ITEM)) if chest != null else 0
	var missing := maxi(0, REQUIRED_MIXTURES - carried)
	var next_action: String
	if missing == 0:
		next_action = "Interaja com a clareira para restaurar." if region_id == "foraging_grove" else "Leve as 2 misturas à clareira do Bosque."
	elif stored > 0:
		var take := mini(stored, missing)
		next_action = "Retire %d mistura%s do Baú da Vila para a Mochila." % [take, "" if take == 1 else "s"]
		if region_id == "foraging_grove":
			next_action = "Volte à vila. " + next_action
	else:
		var cauldron: Node = home.get_node_or_null("CauldronUI") if home != null else null
		var production: Dictionary = cauldron.call("get_save_data") if cauldron != null else {}
		var batch: Dictionary = production.get("batch", {})
		var producing_mixture: bool = production.get("result_item", "") == MIXTURE_ITEM or batch.get("result_item", "") == MIXTURE_ITEM
		if producing_mixture:
			if bool(batch.get("cancel_pending", false)):
				next_action = "Cancelamento pendente: libere espaço na Mochila e tente cancelar no caldeirão."
			elif production.get("state", "") == "READY" or bool(batch.get("waiting_for_space", false)):
				next_action = "Mistura pronta: libere espaço na Mochila e interaja com o caldeirão para recolher."
			else:
				next_action = "Misturas em preparo. Aguarde o resultado do caldeirão."
			if region_id == "foraging_grove":
				next_action = "Volte à vila. " + next_action
		else:
			var personal_charcoal := GlobalInventory.get_item_quantity("carvao")
			var stored_charcoal := int(chest.call("get_item_quantity", "carvao")) if chest != null else 0
			var charcoal_missing := maxi(0, missing * 2 - personal_charcoal - stored_charcoal)
			if charcoal_missing > 0:
				next_action = "Reúna mais %d %s. Fonte renovável ao fim do caminho do Bosque." % [charcoal_missing, "carvão" if charcoal_missing == 1 else "carvões"]
			else:
				next_action = "Prepare %d mistura%s pelo Livro no caldeirão: 2 carvões por mistura." % [missing, "" if missing == 1 else "s"]
				if region_id == "foraging_grove":
					next_action = "Volte à vila. " + next_action
	return "Próxima ação: " + next_action + "\n\nMochila: %d / %d misturas" % [carried, REQUIRED_MIXTURES] + ("\nBaú da Vila: %d mistura%s" % [stored, "" if stored == 1 else "s"] if stored > 0 else "")


func _create_tracker() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GroveExpeditionTracker"
	layer.layer = 12
	add_child(layer)
	_tracker = PanelContainer.new()
	_tracker.name = "ExpeditionPanel"
	layer.add_child(_tracker)
	_tracker.minimum_size_changed.connect(_queue_tracker_layout)
	get_viewport().size_changed.connect(_queue_tracker_layout)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("233528")
	style.border_color = Color("81996b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	_tracker.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_tracker.add_child(column)
	_tracker_toggle = Button.new()
	_tracker_toggle.focus_mode = Control.FOCUS_NONE
	_tracker_toggle.pressed.connect(_toggle_tracker)
	column.add_child(_tracker_toggle)
	_tracker_body = Label.new()
	_tracker_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_body.add_theme_font_size_override("font_size", 16)
	_tracker_body.add_theme_color_override("font_color", Color("e7ecd7"))
	column.add_child(_tracker_body)
	_refresh_tracker()


func _toggle_tracker() -> void:
	_tracker_collapsed = not _tracker_collapsed
	_refresh_tracker()


func _refresh_tracker() -> void:
	if _tracker == null:
		return
	var scene: Node = get_tree().current_scene
	var region_id: String = ""
	if scene != null and scene.has_method("get_current_region_identity"):
		region_id = str(scene.call("get_current_region_identity").get("region_id", ""))
	_tracker.visible = discovered and not restored and region_id in ["farm_village", "foraging_grove"]
	var ui: Node = scene.get_node_or_null("UI") if scene != null else null
	if ui != null and ui.has_method("_tem_popup_modal_aberto") and bool(ui.call("_tem_popup_modal_aberto")):
		_tracker.visible = false
	_tracker_toggle.text = "Clareira · %s" % ["expandir +" if _tracker_collapsed else "minimizar −"]
	_tracker_body.visible = not _tracker_collapsed
	_tracker_body.text = get_objective_text()
	_queue_tracker_layout()


func _queue_tracker_layout() -> void:
	if _tracker_layout_queued:
		return
	_tracker_layout_queued = true
	_layout_tracker.call_deferred()


func _layout_tracker() -> void:
	_tracker_layout_queued = false
	if _tracker == null or not _tracker.is_visible_in_tree():
		return
	var screen := get_viewport().get_visible_rect().size
	_tracker.size.x = minf(336.0, screen.x - 40.0)
	_tracker.size.y = _tracker.get_combined_minimum_size().y
	var scene := get_tree().current_scene
	var ui := scene.get_node_or_null("UI") if scene != null else null
	var occupied := HUDLayoutScript.get_occupied_hud_rects(ui)
	if ui != null:
		for node_name in ["InventoryBackdrop", "ToolBarPanel", "LeftPanel", "InitialObjectivesPanel"]:
			var control: Control = ui.get_node(node_name)
			if not control.item_rect_changed.is_connected(_queue_tracker_layout):
				control.item_rect_changed.connect(_queue_tracker_layout)
				control.visibility_changed.connect(_queue_tracker_layout)
	var production := scene.get_node_or_null("CauldronUI/StatusLayer/BatchProgressPanel") as Control if scene != null else null
	if production != null and not production.item_rect_changed.is_connected(_queue_tracker_layout):
		production.item_rect_changed.connect(_queue_tracker_layout)
		production.visibility_changed.connect(_queue_tracker_layout)
	if production != null and production.is_visible_in_tree():
		occupied.append(production.get_global_rect())
	var protected := HUDLayoutScript.get_protected_hud_rects(ui)
	if production != null and production.is_visible_in_tree():
		var cancel := scene.get_node_or_null("CauldronUI/StatusLayer/BatchProgressPanel/MarginContainer/VBoxBatch/BtnCancelarProducao") as Control
		if cancel != null and cancel.is_visible_in_tree():
			protected.append(cancel.get_global_rect())
	_tracker.position = HUDLayoutScript.find_free_panel_position(_tracker.size, screen, occupied, protected)
