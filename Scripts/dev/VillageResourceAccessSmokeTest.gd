extends Node

const VILLAGE_CHEST_SCENE := preload("res://Scenes/VillageChest.tscn")
const VillageResourceAccessScript := preload("res://Scripts/VillageResourceAccess.gd")

var _original_inventory: Dictionary = {}
var _chest: VillageChest = null


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_inventory = GlobalInventory.inventario.duplicate(true)
	GlobalInventory.inventario = {
		"trigo": 4,
		"carvao": 1,
		"semente_basica": 10,
	}
	_chest = VILLAGE_CHEST_SCENE.instantiate() as VillageChest
	add_child(_chest)
	_chest.set_contents({"trigo": 3, "carvao": 2})
	var access = VillageResourceAccessScript.new(_chest)

	if access.get_available("trigo") != 7:
		_fail("consulta combinada nao somou Village Storage e Mochila")
		return
	var sources: Dictionary = access.get_available_by_source("carvao")
	if int(sources.get(&"village_storage", -1)) != 2 or int(sources.get(&"personal_inventory", -1)) != 1:
		_fail("consulta por origem nao preservou os dois armazenamentos")
		return
	var missing: Dictionary = access.get_missing({"trigo": 8, "carvao": 5})
	if int(missing.get("trigo", 0)) != 1 or int(missing.get("carvao", 0)) != 2:
		_fail("calculo de faltantes nao refletiu a disponibilidade combinada")
		return

	var before_invalid_personal: Dictionary = GlobalInventory.inventario.duplicate(true)
	var before_invalid_storage: Dictionary = _chest.get_contents()
	var invalid_receipt: Dictionary = access.consume({"trigo": 0})
	if bool(invalid_receipt.get("success", true)) or str(invalid_receipt.get("reason", "")) != "invalid_requirements":
		_fail("requisito invalido foi aceito")
		return
	if GlobalInventory.inventario != before_invalid_personal or _chest.get_contents() != before_invalid_storage:
		_fail("requisito invalido alterou algum armazenamento")
		return

	var insufficient_receipt: Dictionary = access.consume({"trigo": 8, "carvao": 2})
	if bool(insufficient_receipt.get("success", true)) or str(insufficient_receipt.get("reason", "")) != "insufficient_resources":
		_fail("consumo insuficiente nao falhou antes da retirada")
		return
	if GlobalInventory.inventario != before_invalid_personal or _chest.get_contents() != before_invalid_storage:
		_fail("falha por insuficiencia nao foi atomica")
		return

	var receipt: Dictionary = access.consume({"trigo": 5, "carvao": 2})
	if not bool(receipt.get("success", false)):
		_fail("consumo combinado valido foi recusado")
		return
	if _chest.get_item_quantity("trigo") != 0 or _chest.get_item_quantity("carvao") != 0:
		_fail("Village Storage nao teve prioridade no consumo")
		return
	if int(GlobalInventory.inventario.get("trigo", -1)) != 2 or int(GlobalInventory.inventario.get("carvao", -1)) != 1:
		_fail("Mochila nao completou somente a quantidade restante")
		return
	if not access.refund(receipt):
		_fail("rollback valido foi recusado")
		return
	if _chest.get_contents() != before_invalid_storage or GlobalInventory.inventario != before_invalid_personal:
		_fail("rollback nao devolveu os itens as origens exatas")
		return
	if access.refund(receipt):
		_fail("o mesmo recibo permitiu rollback duplicado")
		return

	var personal_only_access = VillageResourceAccessScript.new()
	var personal_receipt: Dictionary = personal_only_access.consume({"carvao": 1})
	if not bool(personal_receipt.get("success", false)) or int(GlobalInventory.inventario.get("carvao", -1)) != 0:
		_fail("fallback sem Village Storage nao consumiu da Mochila")
		return
	if not personal_only_access.refund(personal_receipt) or int(GlobalInventory.inventario.get("carvao", -1)) != 1:
		_fail("fallback sem Village Storage nao restaurou a Mochila")
		return

	_restore_state()
	print("VillageResourceAccessSmokeTest: PASS - consulta, prioridade, atomicidade e rollback preservam Mochila e Village Storage.")
	get_tree().quit(0)


func _restore_state() -> void:
	GlobalInventory.inventario = _original_inventory.duplicate(true)
	if _chest != null and is_instance_valid(_chest):
		_chest.queue_free()


func _fail(message: String) -> void:
	_restore_state()
	push_error("VillageResourceAccessSmokeTest: FAIL - %s" % message)
	get_tree().quit(1)
