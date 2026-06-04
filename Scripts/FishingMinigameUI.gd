extends Control

signal minigame_closed

const POPUP_SIZE: Vector2 = Vector2(560.0, 260.0)
const BAR_SIZE: Vector2 = Vector2(440.0, 36.0)
const BAR_HIT_ZONE_SIZE: Vector2 = Vector2(88.0, 36.0)
const BAR_HIT_ZONE_POSITION: Vector2 = Vector2(176.0, 0.0)
const MARKER_SIZE: Vector2 = Vector2(8.0, 36.0)
const MARKER_SPEED: float = 230.0
const PERFECT_TOLERANCE: float = 10.0
const GOOD_TOLERANCE: float = 30.0
const POPUP_MARGIN: float = 24.0
const AUTO_CLOSE_DELAY: float = 1.5

@onready var popup_panel: PanelContainer = $PopupPanel
@onready var dimmer: ColorRect = $Dimmer
@onready var title_label: Label = $PopupPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label: Label = $PopupPanel/MarginContainer/VBoxContainer/InstructionLabel
@onready var bar_area: Control = $PopupPanel/MarginContainer/VBoxContainer/BarArea
@onready var bar_background: ColorRect = $PopupPanel/MarginContainer/VBoxContainer/BarArea/BarBackground
@onready var hit_zone: ColorRect = $PopupPanel/MarginContainer/VBoxContainer/BarArea/HitZone
@onready var marker: ColorRect = $PopupPanel/MarginContainer/VBoxContainer/BarArea/Marker
@onready var result_label: Label = $PopupPanel/MarginContainer/VBoxContainer/ResultLabel
@onready var close_button: Button = $PopupPanel/MarginContainer/VBoxContainer/ButtonsRow/CloseButton
@onready var auto_close_timer: Timer = $AutoCloseTimer

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _ativo: bool = false
var _resultado_travado: bool = false
var _marker_position_x: float = 0.0
var _marker_direction: float = 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2.ZERO
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_unhandled_input(true)
	if popup_panel:
		popup_panel.custom_minimum_size = POPUP_SIZE
		popup_panel.size = POPUP_SIZE
		popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if not popup_panel.gui_input.is_connected(_on_popup_gui_input):
			popup_panel.gui_input.connect(_on_popup_gui_input)
	if dimmer:
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		if not dimmer.gui_input.is_connected(_on_popup_gui_input):
			dimmer.gui_input.connect(_on_popup_gui_input)

	if title_label:
		title_label.text = "Pesca de Ressonância"
	if instruction_label:
		instruction_label.text = "Sinta o pulso da água e confirme no momento certo."
	if close_button and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
	if auto_close_timer:
		auto_close_timer.wait_time = AUTO_CLOSE_DELAY
		auto_close_timer.one_shot = true
		if not auto_close_timer.timeout.is_connected(_on_auto_close_timer_timeout):
			auto_close_timer.timeout.connect(_on_auto_close_timer_timeout)
	if bar_area:
		bar_area.custom_minimum_size = BAR_SIZE
		bar_area.size = BAR_SIZE
		bar_area.mouse_filter = Control.MOUSE_FILTER_STOP
		if not bar_area.gui_input.is_connected(_on_popup_gui_input):
			bar_area.gui_input.connect(_on_popup_gui_input)
	if bar_background:
		bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_background.custom_minimum_size = BAR_SIZE
		bar_background.size = BAR_SIZE
	if hit_zone:
		hit_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit_zone.position = BAR_HIT_ZONE_POSITION
		hit_zone.custom_minimum_size = BAR_HIT_ZONE_SIZE
		hit_zone.size = BAR_HIT_ZONE_SIZE
	if marker:
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.custom_minimum_size = MARKER_SIZE
		marker.size = MARKER_SIZE

	_rng.randomize()
	_resetar_barra()
	_aplicar_estado_visivel(false)

func abrir_popup(origem_global: Vector2) -> Control:
	_ativo = true
	_resultado_travado = false
	_aplicar_estado_visivel(true)
	if popup_panel:
		popup_panel.custom_minimum_size = POPUP_SIZE
		popup_panel.size = POPUP_SIZE
	if bar_area:
		bar_area.custom_minimum_size = BAR_SIZE
		bar_area.size = BAR_SIZE
	_posicionar_popup(origem_global)
	_resetar_barra()
	if instruction_label:
		instruction_label.text = "Sinta o pulso da água e confirme no momento certo."
	if result_label:
		result_label.text = "Resultado: aguardando a ressonância..."
		result_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if close_button:
		close_button.disabled = false
	if auto_close_timer:
		auto_close_timer.stop()
	return self

func fechar_popup() -> void:
	if not visible and not _ativo:
		return
	_ativo = false
	_aplicar_estado_visivel(false)
	if auto_close_timer:
		auto_close_timer.stop()
	minigame_closed.emit()

func _process(delta: float) -> void:
	if not _ativo or _resultado_travado or marker == null:
		return

	var limite_maximo: float = max(0.0, BAR_SIZE.x - MARKER_SIZE.x)
	_marker_position_x += MARKER_SPEED * _marker_direction * delta

	if _marker_position_x <= 0.0:
		_marker_position_x = 0.0
		_marker_direction = 1.0
	elif _marker_position_x >= limite_maximo:
		_marker_position_x = limite_maximo
		_marker_direction = -1.0

	marker.position = Vector2(_marker_position_x, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if not _ativo or _resultado_travado:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_confirmar_tentativa()
		get_viewport().set_input_as_handled()

func _on_popup_gui_input(event: InputEvent) -> void:
	if not _ativo or _resultado_travado:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_confirmar_tentativa()
		get_viewport().set_input_as_handled()

func _on_close_button_pressed() -> void:
	fechar_popup()

func _confirmar_tentativa() -> void:
	if not _ativo or _resultado_travado:
		return
	_resultado_travado = true
	if close_button:
		close_button.disabled = false

	var resultado: String = _avaliar_resultado()
	if result_label:
		match resultado:
			"Perfeito":
				result_label.text = "Ressonância perfeita!"
				result_label.modulate = Color(0.98, 0.92, 0.42, 1.0)
			"Bom":
				result_label.text = "Boa sincronia."
				result_label.modulate = Color(0.55, 0.93, 1.0, 1.0)
			_:
				result_label.text = "O pulso se perdeu."
				result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	if instruction_label:
		instruction_label.text = "Feche o popup para voltar ao lago."
	if auto_close_timer:
		auto_close_timer.start()

func _avaliar_resultado() -> String:
	if marker == null:
		return "Errou"

	var marcador_centro: float = _marker_position_x + (MARKER_SIZE.x * 0.5)
	var zona_centro: float = BAR_HIT_ZONE_POSITION.x + (BAR_HIT_ZONE_SIZE.x * 0.5)
	var distancia: float = abs(marcador_centro - zona_centro)

	if distancia <= PERFECT_TOLERANCE:
		return "Perfeito"
	if distancia <= GOOD_TOLERANCE:
		return "Bom"
	return "Errou"

func _resetar_barra() -> void:
	_resultado_travado = false
	_marker_position_x = _rng.randf_range(0.0, max(0.0, BAR_SIZE.x - MARKER_SIZE.x))
	_marker_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	if marker:
		marker.position = Vector2(_marker_position_x, 0.0)

func _aplicar_estado_visivel(visivel: bool) -> void:
	visible = visivel
	mouse_filter = Control.MOUSE_FILTER_STOP if visivel else Control.MOUSE_FILTER_IGNORE
	if popup_panel:
		popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP if visivel else Control.MOUSE_FILTER_IGNORE
	if dimmer:
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP if visivel else Control.MOUSE_FILTER_IGNORE
	if bar_area:
		bar_area.mouse_filter = Control.MOUSE_FILTER_STOP if visivel else Control.MOUSE_FILTER_IGNORE
	if close_button:
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP if visivel else Control.MOUSE_FILTER_IGNORE

func _on_auto_close_timer_timeout() -> void:
	fechar_popup()

func _posicionar_popup(origem_global: Vector2) -> void:
	if popup_panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var popup_size: Vector2 = popup_panel.custom_minimum_size
	if popup_size == Vector2.ZERO:
		popup_size = POPUP_SIZE

	var desired_position: Vector2 = origem_global + Vector2(-popup_size.x * 0.5, -popup_size.y - 32.0)
	var max_x: float = max(POPUP_MARGIN, viewport_size.x - popup_size.x - POPUP_MARGIN)
	var max_y: float = max(POPUP_MARGIN, viewport_size.y - popup_size.y - POPUP_MARGIN)
	desired_position.x = clamp(desired_position.x, POPUP_MARGIN, max_x)
	desired_position.y = clamp(desired_position.y, POPUP_MARGIN, max_y)
	popup_panel.position = desired_position
