extends Button

signal slot_clicado(id: String)

var item_id: String = ""
var quantidade: int = 0

@onready var icon_label: Label = $ItemIconLabel
@onready var qtd_label: Label = $QuantidadeLabel

func _ready() -> void:
	pressed.connect(_on_pressed)

func configurar_slot(id: String, qtd: int, texto_exibicao: String) -> void:
	item_id = id
	quantidade = qtd
	if icon_label:
		icon_label.text = texto_exibicao
	if qtd_label:
		qtd_label.text = str(qtd)

func _on_pressed() -> void:
	slot_clicado.emit(item_id)
