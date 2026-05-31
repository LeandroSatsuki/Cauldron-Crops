extends Node2D

@export var move_speed_pixels_per_second: float = 128.0
@export var think_interval: float = 1.0
@export var harvest_duration: float = 0.5
@export var deposit_duration: float = 0.3
@export var carry_capacity: int = 1

var state: String = "IDLE"
var carried_item_id: String = ""
var carried_quantity: int = 0
var target_plot: Node2D = null
var target_chest: Node2D = null
var _think_timer: Timer
var _current_tween: Tween

func _ready() -> void:
	_think_timer = Timer.new()
	_think_timer.wait_time = max(think_interval, 0.1)
	_think_timer.autostart = true
	_think_timer.one_shot = false
	_think_timer.timeout.connect(_on_think_timer_timeout)
	add_child(_think_timer)

func _on_think_timer_timeout() -> void:
	if state != "IDLE":
		return

	if carried_quantity > 0 and carried_item_id != "":
		_procurar_bau()
	else:
		_procurar_lote()

func _procurar_lote() -> void:
	var lotes = get_tree().get_nodes_in_group("lotes_terra")
	for lote in lotes:
		if not is_instance_valid(lote):
			continue
		if lote.get("pronto_para_colher") == true:
			target_plot = lote as Node2D
			if target_plot == null:
				continue
			state = "MOVING_TO_PLOT"
			_mover_para(target_plot.global_position, Callable(self, "_chegar_ao_lote"))
			return

func _procurar_bau() -> void:
	target_chest = _encontrar_bau()
	if target_chest == null:
		push_warning("Golem: nenhum Baú da Vila encontrado.")
		state = "IDLE"
		return

	state = "MOVING_TO_CHEST"
	_mover_para(target_chest.global_position, Callable(self, "_chegar_ao_bau"))

func _encontrar_bau() -> Node2D:
	var baus = get_tree().get_nodes_in_group("village_chest")
	for bau in baus:
		if not is_instance_valid(bau):
			continue
		if bau is Node2D:
			return bau as Node2D
	return null

func _mover_para(destino: Vector2, callback: Callable) -> void:
	if _current_tween:
		_current_tween.kill()
		_current_tween = null

	var distancia_pixels := global_position.distance_to(destino)
	var tempo_viagem: float = max(distancia_pixels / max(move_speed_pixels_per_second, 1.0), 0.05)

	_current_tween = create_tween()
	_current_tween.tween_property(self, "global_position", destino, tempo_viagem)
	_current_tween.tween_callback(callback)

func _chegar_ao_lote() -> void:
	if state != "MOVING_TO_PLOT":
		return

	state = "HARVESTING"
	await get_tree().create_timer(harvest_duration).timeout

	if not is_instance_valid(target_plot) or not target_plot.has_method("harvest_by_golem"):
		push_warning("Golem: lote inválido para colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		return

	var colheita: Dictionary = target_plot.harvest_by_golem()
	if colheita.is_empty():
		push_warning("Golem: o lote não entregou colheita.")
		_limpar_alvo_lote()
		state = "IDLE"
		return

	carried_item_id = str(colheita.get("item_id", ""))
	carried_quantity = min(int(colheita.get("quantidade", 0)), carry_capacity)

	_limpar_alvo_lote()

	if carried_item_id == "" or carried_quantity <= 0:
		push_warning("Golem: colheita inválida recebida do lote.")
		carried_item_id = ""
		carried_quantity = 0
		state = "IDLE"
		return

	_procurar_bau()

func _chegar_ao_bau() -> void:
	if state != "MOVING_TO_CHEST":
		return

	state = "DEPOSITING"
	await get_tree().create_timer(deposit_duration).timeout

	if is_instance_valid(target_chest) and target_chest.has_method("deposit_item"):
		target_chest.deposit_item(carried_item_id, carried_quantity)
		print("Golem: depositou %s x%d no Baú da Vila." % [carried_item_id, carried_quantity])
	else:
		push_warning("Golem: baú inválido para depósito.")

	carried_item_id = ""
	carried_quantity = 0
	target_chest = null
	state = "IDLE"

func _limpar_alvo_lote() -> void:
	target_plot = null
