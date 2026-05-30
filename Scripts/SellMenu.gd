extends PanelContainer

var item_atual_id: String = ""
var valor_unitario: int = 0

@onready var btn_vender_1: Button = $VBoxContainer/BtnVender1
@onready var btn_vender_todos: Button = $VBoxContainer/BtnVenderTodos

func _ready() -> void:
	if btn_vender_1:
		btn_vender_1.pressed.connect(_on_btn_vender_1_pressed)
	if btn_vender_todos:
		btn_vender_todos.pressed.connect(_on_btn_vender_todos_pressed)

func abrir(id: String, posicao: Vector2) -> void:
	item_atual_id = id
	valor_unitario = Database.precos.get(id, 0)
	global_position = posicao
	visible = true

func _on_btn_vender_1_pressed() -> void:
	if valor_unitario <= 0:
		visible = false
		return
		
	if GlobalInventory.remover_item(item_atual_id, 1):
		EconomyManager.adicionar_moedas(valor_unitario)
		var ui = get_parent()
		if ui and ui.has_method("criar_texto_flutuante"):
			ui.criar_texto_flutuante("+" + str(valor_unitario) + " Moedas", global_position, Color.GREEN)
	visible = false

func _on_btn_vender_todos_pressed() -> void:
	if valor_unitario <= 0:
		visible = false
		return
		
	var total = GlobalInventory.inventario.get(item_atual_id, 0)
	if total > 0:
		if GlobalInventory.remover_item(item_atual_id, total):
			var ganho = total * valor_unitario
			EconomyManager.adicionar_moedas(ganho)
			var ui = get_parent()
			if ui and ui.has_method("criar_texto_flutuante"):
				ui.criar_texto_flutuante("+" + str(ganho) + " Moedas", global_position, Color.GREEN)
	visible = false
