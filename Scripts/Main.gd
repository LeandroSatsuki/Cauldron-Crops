extends Node2D

var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D

const BASE_FARM_COLUMNS: int = 4
const BASE_FARM_ROWS: int = 4
const EXTRA_FARM_COLUMNS_RIGHT: int = 2
const EXTRA_FARM_ROWS_BOTTOM: int = 1
const FARM_SPACING: int = 80
const BASE_FARM_PIXEL_SIZE: int = 320

func _ready() -> void:
	_configurar_regiao_navegacao()
	
	var screen_size = get_viewport_rect().size
	var start_x: float = (screen_size.x - BASE_FARM_PIXEL_SIZE) / 2.0
	var start_y: float = (screen_size.y - BASE_FARM_PIXEL_SIZE) / 2.0

	_criar_farm_plot_base(start_x, start_y)
	_criar_farm_plot_extras_direita(start_x, start_y)
	_criar_farm_plot_extras_inferiores(start_x, start_y)

func _configurar_regiao_navegacao() -> void:
	if navigation_region == null:
		return

	var screen_size := get_viewport_rect().size
	var margem := 192.0
	var outline := PackedVector2Array([
		Vector2(-margem, -margem),
		Vector2(screen_size.x + margem, -margem),
		Vector2(screen_size.x + margem, screen_size.y + margem),
		Vector2(-margem, screen_size.y + margem)
	])
	var polygon := NavigationPolygon.new()
	polygon.add_outline(outline)
	polygon.make_polygons_from_outlines()
	navigation_region.navigation_polygon = polygon

func _criar_farm_plot_base(start_x: float, start_y: float) -> void:
	for x in range(BASE_FARM_COLUMNS):
		for y in range(BASE_FARM_ROWS):
			_instanciar_farm_plot(x, y, start_x, start_y)

func _criar_farm_plot_extras_direita(start_x: float, start_y: float) -> void:
	for x in range(BASE_FARM_COLUMNS, BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT):
		for y in range(BASE_FARM_ROWS):
			_instanciar_farm_plot(x, y, start_x, start_y)

func _criar_farm_plot_extras_inferiores(start_x: float, start_y: float) -> void:
	for x in range(BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT):
		for y in range(BASE_FARM_ROWS, BASE_FARM_ROWS + EXTRA_FARM_ROWS_BOTTOM):
			_instanciar_farm_plot(x, y, start_x, start_y)

func _instanciar_farm_plot(grid_x: int, grid_y: int, start_x: float, start_y: float) -> void:
	var plot: Node2D = farm_plot_scene.instantiate()
	plot.position = Vector2(start_x + (grid_x * FARM_SPACING), start_y + (grid_y * FARM_SPACING))
	plot.name = "FarmPlot_%d_%d" % [grid_x, grid_y]
	add_child(plot)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			if SaveManager.load_game():
				get_viewport().set_input_as_handled()
