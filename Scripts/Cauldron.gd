extends Node2D

const MOUSE_LEFT = MOUSE_BUTTON_LEFT
const UIDragHelperScript = preload("res://Scripts/UIDragHelper.gd")
const RecipeResolverScript = preload("res://Scripts/data/RecipeResolver.gd")
const VillageResourceAccessScript = preload("res://Scripts/VillageResourceAccess.gd")

@onready var drop_slot_1: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot1
@onready var drop_slot_2: Panel = $PopupLayer/CenterContainer/PopupUI/DropSlot2
@onready var misturar_button: Button = $PopupLayer/CenterContainer/PopupUI/MisturarButton
@onready var btn_livro_receitas: Button = $PopupLayer/CenterContainer/PopupUI/BtnLivroReceitas
@onready var resultado_label: Label = $PopupLayer/CenterContainer/PopupUI/ResultadoLabel
@onready var popup_ui: Panel = $PopupLayer/CenterContainer/PopupUI
@onready var batch_timer: Timer = $BatchTimer

@onready var batch_progress_panel: PanelContainer = $BatchProgressPanel
@onready var batch_status_label: Label = $BatchProgressPanel/MarginContainer/VBoxBatch/BatchStatusLabel
@onready var batch_progress_bar: ProgressBar = $BatchProgressPanel/MarginContainer/VBoxBatch/BatchProgressBar
@onready var btn_cancelar_producao: Button = $BatchProgressPanel/MarginContainer/VBoxBatch/BtnCancelarProducao

var estado_atual: String = "IDLE"
var item_em_producao: String = ""
var _item_quantidade_em_producao: int = 1
var tempo_producao: float = 5.0
var _batch_recipe_id: String = ""
var _batch_resultado: String = ""
var _batch_resultado_quantidade: int = 1
var _batch_tempo_por_unidade: float = 5.0
var _batch_ingredientes: Dictionary = {}
var _batch_quantidade_total: int = 0
var _batch_quantidade_concluida: int = 0
var _batch_ativo: bool = false
var _batch_waiting_for_space: bool = false
var _batch_cancel_pending: bool = false
var _batch_reservation_receipts: Array[Dictionary] = []
var _drag_helper: UIDragHelper = null
var recipe_resolver = null
var _village_resource_access = null
var _navigation_obstacle: NavigationObstacle2D = null
var _brew_pulse_tween: Tween = null

func _ready() -> void:
	add_to_group("cauldrons")
	_navigation_obstacle = _ensure_navigation_obstacle($BaseAnchor, 62.0)
	if popup_ui and is_instance_valid(popup_ui):
		var title_handle := popup_ui.get_node_or_null("TitleLabel") as Control
		if title_handle:
			_drag_helper = UIDragHelperScript.new()
			_drag_helper.attach(popup_ui, title_handle)

	if misturar_button:
		misturar_button.pressed.connect(_on_misturar_button_pressed)
	if btn_livro_receitas and not btn_livro_receitas.pressed.is_connected(_on_btn_livro_receitas_pressed):
		btn_livro_receitas.pressed.connect(_on_btn_livro_receitas_pressed)
	$Area2D.input_pickable = true
	$Area2D.input_event.connect(_on_area_2d_input_event)
	$BrewTimer.timeout.connect(_on_brew_timer_timeout)
	if batch_timer:
		batch_timer.timeout.connect(_on_batch_timer_timeout)
	if batch_progress_panel:
		batch_progress_panel.visible = false
	if btn_cancelar_producao and not btn_cancelar_producao.pressed.is_connected(_on_btn_cancelar_producao_pressed):
		btn_cancelar_producao.pressed.connect(_on_btn_cancelar_producao_pressed)
		btn_cancelar_producao.disabled = true
	_initialize_recipe_resolver()
	
	var btn_fechar = $PopupLayer/CenterContainer/PopupUI/BtnFechar
	if btn_fechar:
		btn_fechar.pressed.connect(func(): 
			popup_ui.visible = false
		)
		
	# Ajustar o offset do sprite (escala 0.5): offset em pixels de textura (não escalados)
	$BaseAnchor/SpriteCaldeirao.offset = Vector2(0, -103)
	
	# Reset Visual
	$PopupLayer/CenterContainer/PopupUI.hide()
	$PopupLayer/CenterContainer/PopupUI.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Shader Material
	material = ShaderMaterial.new()
	material.shader = load("res://Shaders/transparencia.gdshader")


func _ensure_navigation_obstacle(parent_node: Node2D, obstacle_radius: float) -> NavigationObstacle2D:
	var obstacle: NavigationObstacle2D = parent_node.get_node_or_null("PlayerNavigationObstacle") as NavigationObstacle2D
	if obstacle == null:
		obstacle = NavigationObstacle2D.new()
		obstacle.name = "PlayerNavigationObstacle"
		parent_node.add_child(obstacle)
	obstacle.radius = obstacle_radius
	obstacle.avoidance_enabled = true
	return obstacle

func _initialize_recipe_resolver() -> void:
	recipe_resolver = RecipeResolverScript.new()


func _get_village_resource_access():
	var village_storage: Node = _find_village_storage()
	if _village_resource_access == null:
		_village_resource_access = VillageResourceAccessScript.new(village_storage)
	elif _batch_reservation_receipts.is_empty():
		_village_resource_access.set_village_storage(village_storage)
	return _village_resource_access


func _find_village_storage() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for chest_variant in tree.get_nodes_in_group("village_chest"):
		var chest: Node = chest_variant as Node
		if chest != null and is_instance_valid(chest) and chest.has_method("get_item_quantity"):
			return chest
	return null


func get_save_data() -> Dictionary:
	if estado_atual == "BATCH":
		return {
			"state": "BATCH",
			"batch": {
				"recipe_id": _batch_recipe_id,
				"result_item": _batch_resultado,
				"result_quantity": _batch_resultado_quantidade,
				"seconds_per_craft": _batch_tempo_por_unidade,
				"total": _batch_quantidade_total,
				"completed": _batch_quantidade_concluida,
				"waiting_for_space": _batch_waiting_for_space,
				"cancel_pending": _batch_cancel_pending,
				"time_remaining": maxf(batch_timer.time_left, 0.0),
				"ingredients": _batch_ingredientes.duplicate(true),
				"reservations": _batch_reservation_receipts.duplicate(true),
			},
		}
	if estado_atual == "BREWING" or estado_atual == "READY":
		return {
			"state": estado_atual,
			"result_item": item_em_producao,
			"result_quantity": _item_quantidade_em_producao,
			"time_remaining": maxf($BrewTimer.time_left, 0.0) if estado_atual == "BREWING" else 0.0,
		}
	return {"state": "IDLE"}


func is_save_data_valid(data: Dictionary) -> bool:
	var state: Variant = data.get("state")
	if not (state is String) or state not in ["IDLE", "BREWING", "READY", "BATCH"]:
		return false
	if state == "IDLE":
		return true
	if state != "BATCH":
		return (
			_save_item_id_valid(data.get("result_item"))
			and _save_integer_valid(data.get("result_quantity"), 1)
			and _save_time_valid(data.get("time_remaining"))
			and (state != "READY" or float(data["time_remaining"]) == 0.0)
		)
	var batch_variant: Variant = data.get("batch")
	if not (batch_variant is Dictionary):
		return false
	var batch: Dictionary = batch_variant
	if not _save_item_id_valid(batch.get("recipe_id")) or not _save_item_id_valid(batch.get("result_item")):
		return false
	for key in ["result_quantity", "total", "completed"]:
		if not _save_integer_valid(batch.get(key), 0 if key == "completed" else 1):
			return false
	if int(batch["completed"]) >= int(batch["total"]):
		return false
	if not _save_time_valid(batch.get("seconds_per_craft")) or float(batch["seconds_per_craft"]) <= 0.0:
		return false
	if not _save_time_valid(batch.get("time_remaining")) or float(batch["time_remaining"]) > float(batch["seconds_per_craft"]):
		return false
	if not (batch.get("waiting_for_space") is bool) or not (batch.get("cancel_pending", false) is bool):
		return false
	if bool(batch["waiting_for_space"]) and bool(batch.get("cancel_pending", false)):
		return false
	if (bool(batch["waiting_for_space"]) or bool(batch.get("cancel_pending", false))) and float(batch["time_remaining"]) != 0.0:
		return false
	var ingredients_variant: Variant = batch.get("ingredients")
	var receipts_variant: Variant = batch.get("reservations")
	if not (ingredients_variant is Dictionary) or not (receipts_variant is Array):
		return false
	var ingredients: Dictionary = ingredients_variant
	var receipts: Array = receipts_variant
	if ingredients.is_empty() or receipts.size() != int(batch["total"]) - int(batch["completed"]):
		return false
	for item_id in ingredients:
		if not _save_item_id_valid(item_id) or not _save_integer_valid(ingredients[item_id], 1):
			return false
	for receipt in receipts:
		if not (receipt is Dictionary) or not _save_receipt_valid(receipt, ingredients):
			return false
	return true


func _save_receipt_valid(receipt: Dictionary, ingredients: Dictionary) -> bool:
	if not (receipt.get("success") is bool) or not bool(receipt["success"]) or not (receipt.get("refunded") is bool) or bool(receipt["refunded"]):
		return false
	if not (receipt.get("requirements") is Dictionary):
		return false
	var requirements: Dictionary = receipt["requirements"]
	if requirements.size() != ingredients.size():
		return false
	var expected: Dictionary = {}
	for item_id in ingredients:
		if not _save_integer_valid(requirements.get(item_id), 1) or int(requirements[item_id]) != int(ingredients[item_id]):
			return false
		expected[item_id] = int(ingredients[item_id])
	if not (receipt.get("entries") is Array):
		return false
	var reserved: Dictionary = {}
	for entry in receipt["entries"]:
		if not (entry is Dictionary) or not _save_item_id_valid(entry.get("item_id")) or not _save_integer_valid(entry.get("quantity"), 1):
			return false
		if str(entry.get("source", "")) not in ["village_storage", "personal_inventory"]:
			return false
		var item_id: String = entry["item_id"]
		reserved[item_id] = int(reserved.get(item_id, 0)) + int(entry["quantity"])
	return reserved == expected


func _save_item_id_valid(value: Variant) -> bool:
	return value is String and value != "" and value == value.strip_edges()


func _save_integer_valid(value: Variant, minimum: int) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and int(value) >= minimum and float(int(value)) == float(value)


func _save_time_valid(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) >= 0.0


func load_save_data(data: Dictionary) -> bool:
	if not is_save_data_valid(data):
		return false
	# Substituir um snapshot nunca cancela/reembolsa o estado anterior: os estoques
	# do mesmo save ja contem o efeito das reservas. Nada e' consumido outra vez.
	$BrewTimer.stop()
	batch_timer.stop()
	_parar_pulsar_magico()
	_finalizar_lote()
	_item_quantidade_em_producao = 1
	_village_resource_access = null
	_limpar_slots()
	fechar_popup()
	if resultado_label:
		resultado_label.text = ""
	estado_atual = data["state"]
	$BaseAnchor/SpriteCaldeirao.play("idle")
	$BaseAnchor/SpriteCaldeirao.scale = Vector2(0.5, 0.5)
	if estado_atual == "BREWING" or estado_atual == "READY":
		item_em_producao = data["result_item"]
		_item_quantidade_em_producao = int(data["result_quantity"])
		if estado_atual == "BREWING":
			_iniciar_processo_de_mistura()
			$BrewTimer.start(maxf(float(data["time_remaining"]), 0.001))
		elif resultado_label:
			resultado_label.text = "Resultado pronto: interaja para recolher."
	elif estado_atual == "BATCH":
		var batch: Dictionary = data["batch"]
		_batch_recipe_id = batch["recipe_id"]
		_batch_resultado = batch["result_item"]
		item_em_producao = _batch_resultado
		_batch_resultado_quantidade = int(batch["result_quantity"])
		_batch_tempo_por_unidade = float(batch["seconds_per_craft"])
		_batch_quantidade_total = int(batch["total"])
		_batch_quantidade_concluida = int(batch["completed"])
		_batch_ingredientes = batch["ingredients"].duplicate(true)
		_batch_reservation_receipts.assign(batch["reservations"].duplicate(true))
		_batch_waiting_for_space = batch["waiting_for_space"]
		_batch_cancel_pending = batch.get("cancel_pending", false)
		_batch_ativo = true
		_abrir_painel_lote()
		if not _batch_waiting_for_space and not _batch_cancel_pending:
			batch_timer.wait_time = _batch_tempo_por_unidade
			batch_timer.start(maxf(float(batch["time_remaining"]), 0.001))
		_atualizar_interface_lote()
	return true


func get_resource_availability_snapshot() -> Dictionary:
	var snapshot: Dictionary = GlobalInventory.inventario.duplicate(true)
	var village_storage: Node = _find_village_storage()
	if village_storage == null or not village_storage.has_method("get_contents"):
		return snapshot
	var storage_contents_variant: Variant = village_storage.call("get_contents")
	if not (storage_contents_variant is Dictionary):
		return snapshot
	var storage_contents: Dictionary = storage_contents_variant
	for item_variant in storage_contents.keys():
		var item_id: String = str(item_variant)
		var quantity: int = maxi(int(storage_contents[item_variant]), 0)
		snapshot[item_id] = maxi(int(snapshot.get(item_id, 0)), 0) + quantity
	return snapshot


func calcular_quantidade_maxima_para_ingredientes(ingredientes: Array) -> int:
	return _calcular_quantidade_maxima_ingredientes(ingredientes)

func _process(_delta: float) -> void:
	# Folhas limpas têm células uniformes; pé alinhado ao corpo físico.
	$BaseAnchor/SpriteCaldeirao.offset.y = -8
	if _batch_ativo:
		_atualizar_interface_lote()

func abrir_popup():
	$PopupLayer.visible = true
	popup_ui.show()
	popup_ui.visible = true
	popup_ui.move_to_front()
	popup_ui.grab_click_focus() # Força o foco do mouse para a interface

func fechar_popup() -> void:
	if popup_ui:
		popup_ui.visible = false
	if has_node("PopupLayer"):
		$PopupLayer.visible = false
	if batch_progress_panel:
		batch_progress_panel.move_to_front()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_LEFT:
		var main: Node = get_tree().current_scene
		if main != null and main.has_method("request_player_interaction"):
			if bool(main.call("request_player_interaction", self, $BaseAnchor.global_position, 64.0, Callable(self, "_perform_primary_interaction"))):
				viewport.set_input_as_handled()
			return
		_perform_primary_interaction()
		viewport.set_input_as_handled()


func _perform_primary_interaction() -> void:
	if estado_atual == "READY":
		_tentar_entregar_producao_pronta()
		return
	if _batch_ativo:
		if _batch_waiting_for_space:
			_processar_tick_lote()
			return
		cancelar_producao_em_lote()
		return
	abrir_popup()

func _on_btn_livro_receitas_pressed() -> void:
	print("DEBUG Cauldron: botão livro de receitas clicado")
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("abrir_livro_receitas"):
		ui.abrir_livro_receitas(true, self)
	else:
		push_warning("Cauldron: nao foi possivel abrir o Livro de Receitas. UI ausente ou metodo abrir_livro_receitas nao encontrado.")

func _on_btn_cancelar_producao_pressed() -> void:
	cancelar_producao_em_lote()

func iniciar_producao_em_lote(recipe_id: String, quantidade: int) -> bool:
	if _batch_ativo:
		push_warning("Cauldron: ja existe uma producao em lote em andamento.")
		return false
	if estado_atual != "IDLE":
		push_warning("Cauldron: nao e possivel iniciar lote enquanto o caldeirao esta ocupado.")
		return false
	if recipe_id == "":
		push_warning("Cauldron: receita vazia recebida para producao em lote.")
		return false
	var recipe: Dictionary = recipe_resolver.get_recipe(recipe_id)
	if recipe.is_empty():
		push_warning("Cauldron: receita inexistente para producao em lote: %s" % recipe_id)
		return false
	if quantidade <= 0:
		push_warning("Cauldron: quantidade invalida para producao em lote: %s" % str(quantidade))
		return false

	var ingredientes: Array = recipe.get("ingredientes", [])
	if ingredientes.is_empty():
		push_warning("Cauldron: nao foi possivel reconstruir os ingredientes da receita %s." % recipe_id)
		return false

	var quantidade_maxima := _calcular_quantidade_maxima_ingredientes(ingredientes)
	if quantidade_maxima <= 0:
		push_warning("Cauldron: ingredientes insuficientes para producao em lote de %s." % recipe_id)
		return false

	var quantidade_final := clampi(quantidade, 1, quantidade_maxima)
	var resultado: String = str(recipe.get("resultado_item", ""))
	var resultado_quantidade: int = int(recipe.get("resultado_quantidade", 0))
	var tempo_por_unidade: float = float(recipe.get("tempo_producao", 0.0))
	if resultado == "":
		push_warning("Cauldron: resultado vazio para a receita %s." % recipe_id)
		return false
	if resultado_quantidade <= 0 or tempo_por_unidade <= 0.0:
		push_warning("Cauldron: contrato de producao invalido para a receita %s." % recipe_id)
		return false
	if resultado == "golem_coletor":
		var espacos_disponiveis := EconomyManager.max_golems - EconomyManager.total_golems
		if espacos_disponiveis <= 0:
			push_warning("Cauldron: capacidade maxima de Golems atingida.")
			return false
		quantidade_final = min(quantidade_final, int(espacos_disponiveis / resultado_quantidade))
		if quantidade_final <= 0:
			push_warning("Cauldron: resultado da receita excede a capacidade disponivel de Golems.")
			return false

	var ingredientes_contados := _contar_ingredientes(ingredientes)
	var resource_access = _get_village_resource_access()
	var reservation_receipts: Array[Dictionary] = []
	for _unit_index in range(quantidade_final):
		var receipt: Dictionary = resource_access.consume(ingredientes_contados)
		if not bool(receipt.get("success", false)):
			for previous_receipt in reservation_receipts:
				resource_access.refund(previous_receipt)
			push_warning("Cauldron: falha ao reservar ingredientes para o lote de %s." % recipe_id)
			return false
		reservation_receipts.append(receipt)

	_batch_recipe_id = recipe_id
	_batch_resultado = resultado
	_batch_resultado_quantidade = resultado_quantidade
	_batch_tempo_por_unidade = tempo_por_unidade
	_batch_ingredientes = ingredientes_contados
	_batch_quantidade_total = quantidade_final
	_batch_quantidade_concluida = 0
	_batch_reservation_receipts = reservation_receipts
	_batch_ativo = true
	_batch_waiting_for_space = false
	_batch_cancel_pending = false
	estado_atual = "BATCH"
	item_em_producao = resultado

	_abrir_painel_lote()
	_atualizar_interface_lote()
	fechar_popup()
	_iniciar_proximo_tick_lote()
	return true

func cancelar_producao_em_lote() -> void:
	if not _batch_ativo:
		return

	if batch_timer:
		batch_timer.stop()
	var restante: int = int(max(_batch_quantidade_total - _batch_quantidade_concluida, 0))
	var resource_access = _get_village_resource_access()
	var unidades_devolvidas: int = 0
	var pending_receipts: Array[Dictionary] = []
	for receipt in _batch_reservation_receipts:
		if resource_access.refund(receipt):
			unidades_devolvidas += 1
		else:
			pending_receipts.append(receipt)
			push_warning("Cauldron: nao foi possivel devolver uma reserva do lote %s." % _batch_recipe_id)
	_batch_reservation_receipts = pending_receipts
	if not pending_receipts.is_empty():
		_batch_quantidade_total -= unidades_devolvidas
		_batch_waiting_for_space = false
		_batch_cancel_pending = true
		_atualizar_interface_lote()
		return

	if batch_timer:
		batch_timer.stop()

	_batch_ativo = false
	estado_atual = "IDLE"
	item_em_producao = ""
	_batch_recipe_id = ""
	_batch_resultado = ""
	_batch_resultado_quantidade = 1
	_batch_tempo_por_unidade = tempo_producao
	_batch_ingredientes.clear()
	_batch_quantidade_total = 0
	_batch_quantidade_concluida = 0
	_batch_waiting_for_space = false
	_batch_cancel_pending = false
	_batch_reservation_receipts.clear()

	if batch_progress_bar:
		batch_progress_bar.value = 0.0
	if batch_status_label:
		batch_status_label.text = "Producao cancelada."
	_fechar_painel_lote()
	_atualizar_botao_cancelar_lote(false)

	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		ui.criar_texto_flutuante("Produção cancelada", $BaseAnchor/SpriteCaldeirao.global_position, Color.YELLOW)
	print("Cauldron: producao em lote cancelada. Reservas devolvidas: %d/%d unidade(s)." % [unidades_devolvidas, restante])

func _contar_ingredientes(ingredientes: Array) -> Dictionary:
	var contagem: Dictionary = {}
	for ingrediente in ingredientes:
		var ingrediente_id := str(ingrediente)
		contagem[ingrediente_id] = int(contagem.get(ingrediente_id, 0)) + 1
	return contagem

func _calcular_quantidade_maxima_ingredientes(ingredientes: Array) -> int:
	if ingredientes.is_empty():
		return 0

	var contagem_necessaria := _contar_ingredientes(ingredientes)
	var resource_access = _get_village_resource_access()
	var quantidade_maxima := -1
	for ingrediente_id in contagem_necessaria.keys():
		var quantidade_no_inventario: int = resource_access.get_available(str(ingrediente_id))
		var quantidade_necessaria := int(contagem_necessaria[ingrediente_id])
		if quantidade_no_inventario < quantidade_necessaria:
			return 0

		var fabricaveis := int(quantidade_no_inventario / quantidade_necessaria)
		if quantidade_maxima == -1 or fabricaveis < quantidade_maxima:
			quantidade_maxima = fabricaveis

	return max(quantidade_maxima, 0)

func _abrir_painel_lote() -> void:
	if batch_progress_panel:
		batch_progress_panel.visible = true
	_atualizar_botao_cancelar_lote(true)

func _fechar_painel_lote() -> void:
	if batch_progress_panel:
		batch_progress_panel.visible = false
	_atualizar_botao_cancelar_lote(false)

func _atualizar_botao_cancelar_lote(ativo: bool) -> void:
	if btn_cancelar_producao:
		btn_cancelar_producao.visible = ativo
		btn_cancelar_producao.disabled = not ativo

func _iniciar_proximo_tick_lote() -> void:
	if not _batch_ativo or _batch_waiting_for_space or _batch_cancel_pending:
		return

	if batch_timer:
		batch_timer.stop()
		batch_timer.wait_time = max(0.1, _batch_tempo_por_unidade)
		batch_timer.start()
	else:
		_processar_tick_lote()

func _on_batch_timer_timeout() -> void:
	_processar_tick_lote()


func advance_inactive_time(elapsed_seconds: float) -> bool:
	var remaining_elapsed: float = maxf(elapsed_seconds, 0.0)
	if remaining_elapsed <= 0.0:
		return false
	var advanced: bool = false

	if _batch_ativo and batch_timer != null:
		if _batch_waiting_for_space or _batch_cancel_pending:
			return false
		var current_tick_remaining: float = maxf(batch_timer.time_left, 0.0)
		if current_tick_remaining <= 0.0:
			current_tick_remaining = maxf(_batch_tempo_por_unidade, 0.1)
		batch_timer.stop()
		while _batch_ativo and remaining_elapsed >= current_tick_remaining:
			remaining_elapsed -= current_tick_remaining
			_processar_tick_lote()
			advanced = true
			if _batch_waiting_for_space:
				break
			if _batch_ativo:
				batch_timer.stop()
				current_tick_remaining = maxf(_batch_tempo_por_unidade, 0.1)
		if _batch_ativo and not _batch_waiting_for_space:
			batch_timer.stop()
			batch_timer.start(maxf(current_tick_remaining - remaining_elapsed, 0.001))
			advanced = advanced or remaining_elapsed > 0.0
		return advanced

	var brew_timer: Timer = get_node_or_null("BrewTimer") as Timer
	if estado_atual == "BREWING" and brew_timer != null:
		var brew_remaining: float = maxf(brew_timer.time_left, 0.0)
		if brew_remaining <= 0.0:
			return false
		brew_timer.stop()
		if remaining_elapsed >= brew_remaining:
			_on_brew_timer_timeout()
		else:
			brew_timer.start(maxf(brew_remaining - remaining_elapsed, 0.001))
		return true
	return false

func _processar_tick_lote() -> void:
	if not _batch_ativo or _batch_cancel_pending:
		return

	if not _entregar_resultado(_batch_resultado, _batch_resultado_quantidade):
		_batch_waiting_for_space = true
		if batch_timer:
			batch_timer.stop()
		_atualizar_interface_lote()
		_mostrar_resultado_pendente(_batch_resultado)
		return

	_batch_waiting_for_space = false
	if not _batch_reservation_receipts.is_empty():
		_batch_reservation_receipts.pop_front()
	else:
		push_warning("Cauldron: lote ativo sem recibo de reserva para a unidade atual.")
	_batch_quantidade_concluida += 1

	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		var nome_exibicao = "Golem" if _batch_resultado == "golem_coletor" else Database.obter_nome_item(_batch_resultado)
		if nome_exibicao == "":
			nome_exibicao = _batch_resultado
		ui.criar_texto_flutuante("Lote pronto: %sx %s!" % [_batch_resultado_quantidade, nome_exibicao], $BaseAnchor/SpriteCaldeirao.global_position, Color.GREEN)

	if _batch_quantidade_concluida >= _batch_quantidade_total:
		_finalizar_lote()
	else:
		_iniciar_proximo_tick_lote()

func _finalizar_lote() -> void:
	_batch_ativo = false
	estado_atual = "IDLE"
	item_em_producao = ""
	_batch_recipe_id = ""
	_batch_resultado = ""
	_batch_resultado_quantidade = 1
	_batch_tempo_por_unidade = tempo_producao
	_batch_ingredientes.clear()
	_batch_quantidade_total = 0
	_batch_quantidade_concluida = 0
	_batch_waiting_for_space = false
	_batch_cancel_pending = false
	_batch_reservation_receipts.clear()
	if batch_timer:
		batch_timer.stop()
	if batch_progress_bar:
		batch_progress_bar.value = 0.0
	if batch_status_label:
		batch_status_label.text = "Producao em lote: concluida"
	_fechar_painel_lote()
	_atualizar_botao_cancelar_lote(false)

func _atualizar_interface_lote() -> void:
	if not _batch_ativo:
		return

	var progresso := 0.0
	if _batch_quantidade_total > 0:
		var fase_atual := 1.0
		if batch_timer and _batch_tempo_por_unidade > 0.0:
			fase_atual = 1.0 - clampf(batch_timer.time_left / _batch_tempo_por_unidade, 0.0, 1.0)
		progresso = clampf((float(_batch_quantidade_concluida) + fase_atual) / float(_batch_quantidade_total), 0.0, 1.0)

	if batch_progress_bar:
		batch_progress_bar.max_value = 1.0
		batch_progress_bar.value = progresso
	if batch_status_label:
		if _batch_cancel_pending:
			batch_status_label.text = "Cancelamento pendente: libere espaço e cancele novamente"
		elif _batch_waiting_for_space:
			batch_status_label.text = "Resultado pronto: libere espaço na Mochila"
		else:
			batch_status_label.text = "Producao em lote: %s/%s" % [_batch_quantidade_concluida, _batch_quantidade_total]

func _on_misturar_button_pressed() -> void:
	if estado_atual != "IDLE" or _batch_ativo:
		return
	if not drop_slot_1 or not drop_slot_2:
		return
		
	var item1: String = str(drop_slot_1.item_vinculado)
	var item2: String = str(drop_slot_2.item_vinculado)
	
	if item1 == "" or item2 == "":
		if resultado_label:
			resultado_label.text = "Solte ingredientes nos slots!"
		return
		
	var requirements: Dictionary = _contar_ingredientes([item1, item2])
	var resource_access = _get_village_resource_access()
	if not resource_access.can_consume(requirements):
		if resultado_label:
			resultado_label.text = "Ingredientes insuficientes!"
		return
		
	# Resolve a combinacao pelo contrato rico, preservando fallback legado.
	var recipe: Dictionary = recipe_resolver.find_recipe_for_ingredients([item1, item2]) if recipe_resolver != null else {}
	var resultado: String = str(recipe.get("resultado_item", ""))
		
	if resultado == "":
		var failed_mix_receipt: Dictionary = resource_access.consume(requirements)
		if bool(failed_mix_receipt.get("success", false)):
			if resultado_label:
				resultado_label.text = "Mistura falhou! Ingredientes perdidos."
			_limpar_slots()
		elif resultado_label:
			resultado_label.text = "Erro ao consumir ingredientes!"
		return
		
	var resultado_quantidade: int = int(recipe.get("resultado_quantidade", 0))
	var recipe_tempo_producao: float = float(recipe.get("tempo_producao", 0.0))
	if resultado_quantidade <= 0 or recipe_tempo_producao <= 0.0:
		if resultado_label:
			resultado_label.text = "Receita com dados de produção inválidos!"
		return

	if resultado == "golem_coletor":
		if EconomyManager.total_golems + resultado_quantidade > EconomyManager.max_golems:
			if resultado_label:
				resultado_label.text = "Capacidade máxima de Golems atingida!"
			return

	var receipt: Dictionary = resource_access.consume(requirements)
	if not bool(receipt.get("success", false)):
		if resultado_label:
			resultado_label.text = "Erro ao consumir ingredientes!"
		return

	_registrar_descoberta(recipe)
	item_em_producao = resultado
	_item_quantidade_em_producao = resultado_quantidade
	estado_atual = "BREWING"
	popup_ui.visible = false
	_iniciar_processo_de_mistura()
	$BrewTimer.start(recipe_tempo_producao)
	_limpar_slots()
	if resultado == "golem_coletor":
		fechar_popup()

func _limpar_slots() -> void:
	if drop_slot_1:
		drop_slot_1.item_vinculado = ""
		var lbl1 = drop_slot_1.get_node_or_null("Label")
		if lbl1: lbl1.text = "Soltar item"
		var icon1 = drop_slot_1.get_node_or_null("ItemIcon")
		if icon1: icon1.texture = null
	if drop_slot_2:
		drop_slot_2.item_vinculado = ""
		var lbl2 = drop_slot_2.get_node_or_null("Label")
		if lbl2: lbl2.text = "Soltar item"
		var icon2 = drop_slot_2.get_node_or_null("ItemIcon")
		if icon2: icon2.texture = null

func _iniciar_processo_de_mistura():
	# Troca para o roxo imediatamente
	$BaseAnchor/SpriteCaldeirao.play("brewing")
	_iniciar_pulsar_magico()

func _on_brew_timer_timeout() -> void:
	if estado_atual != "BREWING":
		return
	_parar_pulsar_magico()
	$BaseAnchor/SpriteCaldeirao.play("idle") # Volta para o verde
	$BaseAnchor/SpriteCaldeirao.scale = Vector2(0.5, 0.5)
	_tentar_entregar_producao_pronta()


func _tentar_entregar_producao_pronta() -> bool:
	if estado_atual != "BREWING" and estado_atual != "READY":
		return false
	if not _entregar_resultado(item_em_producao, _item_quantidade_em_producao):
		estado_atual = "READY"
		_mostrar_resultado_pendente(item_em_producao)
		return false

	estado_atual = "IDLE"
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		var nome_exibicao = "Golem" if item_em_producao == "golem_coletor" else Database.obter_nome_item(item_em_producao)
		if nome_exibicao == "":
			nome_exibicao = item_em_producao
		ui.criar_texto_flutuante("Sucesso: %sx %s!" % [_item_quantidade_em_producao, nome_exibicao], $BaseAnchor/SpriteCaldeirao.global_position, Color.GREEN)

	item_em_producao = ""
	_item_quantidade_em_producao = 1
	return true

func _registrar_descoberta(recipe: Dictionary) -> bool:
	var recipe_id := str(recipe.get("id", ""))
	if recipe_id == "" or GlobalInventory.receitas_descobertas.has(recipe_id):
		return false
	GlobalInventory.receitas_descobertas.append(recipe_id)
	GlobalInventory.pontos_alquimia += max(int(recipe.get("recompensa_pontos_alquimia", 0)), 0)
	return true

func _entregar_resultado(resultado: String, quantidade: int) -> bool:
	if resultado == "" or quantidade <= 0:
		return false
	if resultado == "golem_coletor":
		if EconomyManager.total_golems + quantidade > EconomyManager.max_golems:
			return false
		EconomyManager.total_golems += quantidade
		return true
	var insertion: Dictionary = GlobalInventory.try_add_items({resultado: quantidade})
	return bool(insertion.get("success", false))


func _mostrar_resultado_pendente(resultado: String) -> void:
	var message := "Capacidade máxima de Golems atingida. O resultado permanece no caldeirão." if resultado == "golem_coletor" else "Mochila sem espaço. O resultado permanece no caldeirão."
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("criar_texto_flutuante"):
		ui.criar_texto_flutuante(message, $BaseAnchor/SpriteCaldeirao.global_position, Color(1.0, 0.76, 0.42, 1.0))
	else:
		print(message)


func _iniciar_pulsar_magico():
	_parar_pulsar_magico()
	_brew_pulse_tween = create_tween().set_loops()
	_brew_pulse_tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.45, 0.45), 0.5)
	_brew_pulse_tween.tween_property($BaseAnchor/SpriteCaldeirao, "scale", Vector2(0.5, 0.5), 0.5)


func _parar_pulsar_magico() -> void:
	if _brew_pulse_tween != null:
		_brew_pulse_tween.kill()
		_brew_pulse_tween = null
	$BaseAnchor/SpriteCaldeirao.scale = Vector2(0.5, 0.5)
