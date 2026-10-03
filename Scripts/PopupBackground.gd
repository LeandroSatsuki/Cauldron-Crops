extends Panel

var _layout_initialized := false

func _ready() -> void:
	# Somente apresentação; manter o contrato de captura de cliques/drop abaixo.
	self_modulate = Color.WHITE
	custom_minimum_size = Vector2(480, 320)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("263b2c")
	panel_style.border_color = Color("aa9860")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel_style)
	get_node("CustomBackground").hide()
	for slot_name in ["DropSlot1", "DropSlot2"]:
		var slot: Panel = get_node(slot_name)
		slot.self_modulate = Color.WHITE
		var slot_style := panel_style.duplicate() as StyleBoxFlat
		slot_style.bg_color = Color("182a20")
		slot.add_theme_stylebox_override("panel", slot_style)
		var icon: TextureRect = slot.get_node("ItemIcon")
		icon.offset_left = 8
		icon.offset_top = 8
		icon.offset_right = -8
		icon.offset_bottom = -8
	get_node("MisturarButton").self_modulate = Color.WHITE
	get_node("MisturarButton/ResultadoLabel2").hide()
	get_node("ResultadoLabel").text = "Escolha dois ingredientes para experimentar uma mistura."
	get_node("ResultadoLabel").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_queue_layout)
	visibility_changed.connect(_queue_layout)
	_queue_layout()

func _queue_layout() -> void:
	_apply_layout.call_deferred()

func _apply_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var compact := viewport_size.y < 680
	size = Vector2(minf(640, viewport_size.x - 40), 320 if compact else 420)
	# Em janela estreita, manter acesso à Mochila para arrastar ingredientes.
	var minimum_y := 260.0 if viewport_size.x < 960 else 20.0
	var minimum_position := Vector2(20, minimum_y)
	if not _layout_initialized:
		global_position = (viewport_size - size) / 2
		_layout_initialized = true
	global_position = global_position.clamp(minimum_position, (viewport_size - size - Vector2(20, 20)).max(minimum_position))
	_set_rect("TitleLabel", Rect2(20, 16, size.x - 110, 32))
	get_node("TitleLabel").text = "Caldeirão"
	get_node("TitleLabel").horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_set_rect("BtnFechar", Rect2(size.x - 80, 16, 60, 32))
	get_node("BtnFechar").text = "Fechar"
	_set_rect("DropSlot1", Rect2(size.x / 2 - 106, 76 if compact else 112, 88, 88))
	_set_rect("DropSlot2", Rect2(size.x / 2 + 18, 76 if compact else 112, 88, 88))
	_set_rect("MisturarButton", Rect2(80, 174 if compact else 230, size.x - 160, 40))
	_set_rect("ResultadoLabel", Rect2(24, 220 if compact else 286, size.x - 48, 44 if compact else 60))
	_set_rect("BtnLivroReceitas", Rect2(24, 274 if compact else 362, size.x - 48, 34 if compact else 38))
	get_node("BtnLivroReceitas").text = "Abrir Livro de Receitas"

func _set_rect(node_name: String, rectangle: Rect2) -> void:
	var control: Control = get_node(node_name)
	control.position = rectangle.position
	control.size = rectangle.size

# Este script age como um "buraco negro" para qualquer input que
# caia nas áreas vazias do popup (entre os DropSlots).
# Garante que NENHUM clique ou drop vaze para a plantação (Area2D) abaixo.

func _can_drop_data(_at_position, data) -> bool:
	# Retorna true para QUALQUER dado.
	# Isso faz a UI capturar o item e impede o Godot de
	# passar o drop para o mundo 2D/plantação abaixo.
	return true

func _drop_data(_at_position, data) -> void:
	# Não faz absolutamente nada.
	# O item apenas "cai no fundo" com segurança.
	print("DEBUG: Item interceptado pelo fundo do Popup e descartado com segurança.")
