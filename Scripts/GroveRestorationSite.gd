extends Area2D
class_name GroveRestorationSite

const ResourceAccess = preload("res://Scripts/VillageResourceAccess.gd")
const INTERACTION_DISTANCE := 94.0

@onready var prompt: Label = $Prompt
@onready var feedback: Label = $Feedback
var _feedback_tween: Tween


func _ready() -> void:
	input_event.connect(_on_input_event)
	GroveExpedition.progress_changed.connect(_refresh)
	_refresh()


func interact() -> bool:
	if GroveExpedition.restored:
		_show_feedback("Clareira restaurada.\nInfusão da Clareira aprendida!", Color("d2eb9c"))
		return false
	if GroveExpedition.discover():
		_show_feedback("Clareira descoberta!\nReceita: 2 carvões → Mistura Restauradora.\nPrepare 2 na vila e traga na Mochila.", Color("ecd99b"))
		return true
	# Sem VillageStorage: a expedição consome apenas a carga trazida pelo jogador.
	var access := ResourceAccess.new()
	var receipt: Dictionary = access.consume({GroveExpedition.MIXTURE_ITEM: GroveExpedition.REQUIRED_MIXTURES})
	if not bool(receipt.get("success", false)):
		_show_feedback("Traga 2 Misturas Restauradoras na Mochila.\nPrepare-as no caldeirão da vila.", Color("ecd99b"))
		return false
	if not GroveExpedition.complete_restoration():
		access.refund(receipt)
		return false
	_show_feedback("Clareira restaurada! Receita aprendida:\nInfusão da Clareira · carvão + mistura\n→ Poção de Crescimento (3 aplicações).", Color("d2eb9c"))
	return true


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_method("request_player_interaction"):
		if scene.call("request_player_interaction", self, global_position, INTERACTION_DISTANCE, Callable(self, "interact")):
			viewport.set_input_as_handled()


func _refresh() -> void:
	if prompt != null:
		prompt.text = "Clareira restaurada" if GroveExpedition.restored else ("Restaurar · 2 misturas na Mochila" if GroveExpedition.discovered else "Investigar clareira")
	queue_redraw()


func _draw() -> void:
	# Arte vetorial local, legível sobre o blockout existente, sem bloquear a trilha.
	draw_ellipse_patch(Color("547445") if GroveExpedition.restored else Color("665544"))
	for row in range(3):
		var y: float = -20.0 + row * 22.0
		draw_line(Vector2(-80, y), Vector2(80, y), Color("342e25"), 9.0, true)
		for column in range(5):
			var p := Vector2(-62 + column * 31, y - 4)
			if GroveExpedition.restored:
				draw_line(p, p + Vector2(0, -18), Color("86b75d"), 4.0, true)
				draw_circle(p + Vector2(-6, -13), 6.0, Color("93c665"))
				draw_circle(p + Vector2(6, -19), 5.0, Color("bfdf86"))
			else:
				draw_line(p, p + Vector2(4, -14), Color("ad9973"), 3.0, true)
				draw_line(p + Vector2(3, -10), p + Vector2(-5, -13), Color("8a775c"), 3.0, true)
	for x in [-104, 104]:
		draw_rect(Rect2(x - 4, -45, 8, 92), Color("a68a59"))
	for y in [-46, 46]:
		draw_line(Vector2(-106, y), Vector2(106, y), Color("a68a59"), 6.0, true)


func draw_ellipse_patch(color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle: float = TAU * index / 32.0
		points.append(Vector2(cos(angle) * 132.0, sin(angle) * 69.0))
	draw_colored_polygon(points, color)


func _show_feedback(message: String, color: Color) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	feedback.text = message
	feedback.modulate = color
	feedback.visible = true
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(7.0)
	_feedback_tween.tween_property(feedback, "modulate:a", 0.0, 0.5)
	_feedback_tween.tween_callback(feedback.hide)
