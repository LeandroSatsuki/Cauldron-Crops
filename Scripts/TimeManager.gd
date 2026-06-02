extends Node
class_name TimeManager

const DAYS_PER_SEASON: int = 7
const DAYS_PER_YEAR: int = DAYS_PER_SEASON * 4
const SEASONS: Array[String] = ["Primavera", "Verão", "Outono", "Inverno"]

var real_time_enabled: bool = false
var current_day: int = 1
var current_week_day: int = 1
var current_season_index: int = 0
var current_year: int = 1
var last_real_date: String = ""

func get_current_day() -> int:
	return current_day

func get_current_week_day() -> int:
	return current_week_day

func get_current_season_name() -> String:
	if SEASONS.is_empty():
		return "Desconhecida"

	var season_index: int = clampi(current_season_index, 0, SEASONS.size() - 1)
	return SEASONS[season_index]

func get_current_year() -> int:
	return current_year

func advance_debug_day() -> void:
	_avancar_dias_internos(1)

func advance_debug_week() -> void:
	_avancar_dias_internos(DAYS_PER_SEASON)

func reset_debug_time() -> void:
	real_time_enabled = false
	current_day = 1
	current_week_day = 1
	current_season_index = 0
	current_year = 1
	last_real_date = ""

func process_real_time_if_enabled() -> void:
	if not real_time_enabled:
		return

	var data_real_atual: String = _obter_data_real_atual()
	if data_real_atual == "":
		return

	if last_real_date == "":
		last_real_date = data_real_atual
		return

	if data_real_atual == last_real_date:
		return

	var dias_passados: int = _calcular_dias_passados(last_real_date, data_real_atual)
	if dias_passados > 0:
		_avancar_dias_internos(dias_passados)

	last_real_date = data_real_atual

func _avancar_dias_internos(dias: int) -> void:
	if dias <= 0:
		return

	current_day += dias
	_recalcular_estado_calendario()

func _recalcular_estado_calendario() -> void:
	if current_day < 1:
		current_day = 1

	var dia_total_zero_based: int = current_day - 1
	var dia_total_no_ano: int = dia_total_zero_based % DAYS_PER_YEAR
	current_year = int(dia_total_zero_based / DAYS_PER_YEAR) + 1
	current_season_index = int(dia_total_no_ano / DAYS_PER_SEASON)
	current_week_day = (dia_total_no_ano % DAYS_PER_SEASON) + 1

func _obter_data_real_atual() -> String:
	return Time.get_date_string_from_system()

func _calcular_dias_passados(data_anterior: String, data_atual: String) -> int:
	var serial_anterior: int = _obter_serial_data(data_anterior)
	var serial_atual: int = _obter_serial_data(data_atual)
	if serial_anterior < 0 or serial_atual < 0:
		return 0
	return serial_atual - serial_anterior

func _obter_serial_data(data_texto: String) -> int:
	var partes: PackedStringArray = data_texto.split("-", false, 3)
	if partes.size() != 3:
		return -1

	var ano: int = int(partes[0])
	var mes: int = int(partes[1])
	var dia: int = int(partes[2])

	if ano < 1 or mes < 1 or mes > 12 or dia < 1:
		return -1

	var dia_do_ano: int = _obter_dia_do_ano(ano, mes, dia)
	if dia_do_ano < 1:
		return -1

	var anos_anteriores: int = ano - 1
	var bissextos_anteriores: int = int(anos_anteriores / 4) - int(anos_anteriores / 100) + int(anos_anteriores / 400)
	return (anos_anteriores * 365) + bissextos_anteriores + dia_do_ano - 1

func _obter_dia_do_ano(ano: int, mes: int, dia: int) -> int:
	var dias_por_mes: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if _eh_bissexto(ano):
		dias_por_mes[1] = 29

	if mes < 1 or mes > dias_por_mes.size():
		return -1

	var limite_dia: int = dias_por_mes[mes - 1]
	if dia > limite_dia:
		return -1

	var acumulado: int = 0
	for indice in range(mes - 1):
		acumulado += dias_por_mes[indice]

	return acumulado + dia

func _eh_bissexto(ano: int) -> bool:
	if ano % 400 == 0:
		return true
	if ano % 100 == 0:
		return false
	return ano % 4 == 0
