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

func abrir(id: String, posicao: Vector2) -> bool:
	item_atual_id = id
	valor_unitario = Database.obter_valor_base_item(id)
	if valor_unitario <= 0:
		valor_unitario = int(Database.precos.get(id, 0))

	if not Database.item_pode_vender(id) or valor_unitario <= 0:
		visible = false
		_mostrar_feedback("Este item não pode ser vendido.", posicao, Color(1.0, 0.35, 0.35))
		return false

	global_position = posicao
	visible = true
	return true

func _mostrar_feedback(texto: String, posicao: Vector2, cor: Color) -> void:
	var ui := get_parent()
	if ui and ui.has_method("criar_texto_flutuante"):
		ui.call("criar_texto_flutuante", texto, posicao, cor)

func _on_btn_vender_1_pressed() -> void:
	if valor_unitario <= 0:
		visible = false
		return
		
	if GlobalInventory.remover_item(item_atual_id, 1):
		EconomyManager.adicionar_moedas(valor_unitario)
		_mostrar_feedback("+" + str(valor_unitario) + " Moedas", global_position, Color.GREEN)
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
			_mostrar_feedback("+" + str(ganho) + " Moedas", global_position, Color.GREEN)
	visible = false
