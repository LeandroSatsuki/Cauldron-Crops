extends Button

signal slot_clicado(item_id: String, is_right_click: bool, slot_node: Control)

var item_id: String = ""
var quantidade: int = 0
var tween_piscar: Tween

@onready var icon_label: Label = $ItemIconLabel
@onready var qtd_label: Label = $QuantidadeLabel
@onready var destaque: ReferenceRect = $Destaque

func _ready() -> void:
	pass

func configurar_slot(id: String, qtd: int, texto_exibicao: String) -> void:
	item_id = id
	quantidade = qtd
	if icon_label:
		icon_label.text = texto_exibicao
	if qtd_label:
		qtd_label.text = str(qtd)
	self.tooltip_text = texto_exibicao

func set_destaque(ativo: bool) -> void:
	if not destaque:
		destaque = $Destaque
		
	if ativo:
		destaque.visible = true
		if tween_piscar:
			tween_piscar.kill()
		destaque.modulate.a = 1.0
		tween_piscar = create_tween().set_loops()
		tween_piscar.tween_property(destaque, "modulate:a", 0.3, 0.8)
		tween_piscar.tween_property(destaque, "modulate:a", 1.0, 0.8)
	else:
		if destaque:
			destaque.visible = false
		if tween_piscar:
			tween_piscar.kill()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicado.emit(item_id, false, self)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_clicado.emit(item_id, true, self)
			accept_event()
