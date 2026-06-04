extends Node2D

var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")
const FISHING_SPOT_SCENE_PATH: String = "res://Scenes/FishingSpot.tscn"
const FISHING_SPOT_SCRIPT_PATH: String = "res://Scripts/FishingSpot.gd"
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D

const BASE_FARM_COLUMNS: int = 4
const BASE_FARM_ROWS: int = 4
const EXTRA_FARM_COLUMNS_RIGHT: int = 2
const EXTRA_FARM_ROWS_BOTTOM: int = 1
const FARM_SPACING: int = 80
const BASE_FARM_PIXEL_SIZE: int = 320
const FISHING_SPOT_POSITION: Vector2 = Vector2(850, 220)
const FISHING_SPOT_Z_INDEX: int = 20

func _ready() -> void:
	_configurar_regiao_navegacao()
	
	var screen_size = get_viewport_rect().size
	var start_x: float = (screen_size.x - BASE_FARM_PIXEL_SIZE) / 2.0
	var start_y: float = (screen_size.y - BASE_FARM_PIXEL_SIZE) / 2.0

	_criar_farm_plot_base(start_x, start_y)
	_criar_farm_plot_extras_direita(start_x, start_y)
	_criar_farm_plot_extras_inferiores(start_x, start_y)
	_garantir_lago_da_fazenda()

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

func _garantir_lago_da_fazenda() -> void:
	var fishing_spot_node: Node = get_node_or_null("FishingSpot")
	var fishing_spot: Node2D = null

	if fishing_spot_node != null:
		fishing_spot = fishing_spot_node as Node2D
	else:
		var fishing_spot_scene: Resource = load(FISHING_SPOT_SCENE_PATH)
		if fishing_spot_scene is PackedScene:
			fishing_spot = (fishing_spot_scene as PackedScene).instantiate() as Node2D
		if fishing_spot == null:
			push_warning("Main: FishingSpot.tscn nao carregou; usando fallback em runtime.")
			fishing_spot = _criar_lago_da_fazenda_fallback()
		if fishing_spot == null:
			push_warning("Main: nao foi possivel criar o lago da fazenda.")
			return
		fishing_spot.name = "FishingSpot"
		add_child(fishing_spot)

	if fishing_spot == null:
		push_warning("Main: FishingSpot nao eh um Node2D valido.")
		return

	fishing_spot.position = FISHING_SPOT_POSITION
	fishing_spot.visible = true
	fishing_spot.z_index = FISHING_SPOT_Z_INDEX

func _criar_lago_da_fazenda_fallback() -> Node2D:
	var fishing_spot := Area2D.new()
	var fishing_spot_script: Script = load(FISHING_SPOT_SCRIPT_PATH) as Script
	if fishing_spot_script != null:
		fishing_spot.set_script(fishing_spot_script)

	fishing_spot.input_pickable = true
	fishing_spot.z_index = FISHING_SPOT_Z_INDEX

	var lake_glow := Polygon2D.new()
	lake_glow.name = "LakeGlow"
	lake_glow.z_index = 19
	lake_glow.color = Color(0.0862745, 0.509804, 0.784314, 0.45)
	lake_glow.polygon = PackedVector2Array([
		Vector2(-170, -45),
		Vector2(-125, -105),
		Vector2(80, -110),
		Vector2(165, -35),
		Vector2(150, 55),
		Vector2(60, 110),
		Vector2(-70, 110),
		Vector2(-170, 45)
	])
	fishing_spot.add_child(lake_glow)

	var lake_visual := Polygon2D.new()
	lake_visual.name = "LakeVisual"
	lake_visual.z_index = 20
	lake_visual.color = Color(0.12549, 0.705882, 0.921569, 0.96)
	lake_visual.polygon = PackedVector2Array([
		Vector2(-150, -35),
		Vector2(-110, -95),
		Vector2(60, -100),
		Vector2(145, -30),
		Vector2(130, 50),
		Vector2(50, 100),
		Vector2(-60, 100),
		Vector2(-150, 35)
	])
	fishing_spot.add_child(lake_visual)

	var moving_area := Node2D.new()
	moving_area.name = "MovingFishingArea"
	moving_area.visible = true
	moving_area.position = Vector2(44.0, -10.0)
	moving_area.z_index = 25
	fishing_spot.add_child(moving_area)

	var moving_area_glow := Polygon2D.new()
	moving_area_glow.name = "MovingFishingAreaGlow"
	moving_area_glow.z_index = 26
	moving_area_glow.color = Color(0.27451, 0.984314, 1.0, 0.52)
	moving_area_glow.polygon = PackedVector2Array([
		Vector2(-58, -12),
		Vector2(-34, -42),
		Vector2(18, -48),
		Vector2(54, -24),
		Vector2(58, 12),
		Vector2(30, 44),
		Vector2(-18, 48),
		Vector2(-56, 22)
	])
	moving_area.add_child(moving_area_glow)

	var moving_area_core := Polygon2D.new()
	moving_area_core.name = "MovingFishingAreaCore"
	moving_area_core.z_index = 27
	moving_area_core.color = Color(0.337255, 0.976471, 0.960784, 0.76)
	moving_area_core.polygon = PackedVector2Array([
		Vector2(-44, -8),
		Vector2(-24, -26),
		Vector2(14, -30),
		Vector2(40, -14),
		Vector2(44, 8),
		Vector2(22, 26),
		Vector2(-12, 30),
		Vector2(-40, 14)
	])
	moving_area.add_child(moving_area_core)

	var moving_area_ring := Line2D.new()
	moving_area_ring.name = "MovingFishingAreaRing"
	moving_area_ring.z_index = 28
	moving_area_ring.width = 8.0
	moving_area_ring.default_color = Color(0.760784, 0.996078, 1.0, 0.92)
	moving_area_ring.antialiased = true
	moving_area_ring.closed = true
	moving_area_ring.points = PackedVector2Array([
		Vector2(0, -40),
		Vector2(30, -28),
		Vector2(42, 0),
		Vector2(28, 30),
		Vector2(0, 40),
		Vector2(-30, 28),
		Vector2(-42, 0),
		Vector2(-28, -30)
	])
	moving_area.add_child(moving_area_ring)

	var moving_area_sparkle := Polygon2D.new()
	moving_area_sparkle.name = "MovingFishingAreaSparkle"
	moving_area_sparkle.position = Vector2(20, -16)
	moving_area_sparkle.z_index = 29
	moving_area_sparkle.color = Color(0.980392, 1.0, 1.0, 0.92)
	moving_area_sparkle.polygon = PackedVector2Array([
		Vector2(0, -5),
		Vector2(3, -2),
		Vector2(5, 0),
		Vector2(3, 2),
		Vector2(0, 5),
		Vector2(-3, 2),
		Vector2(-5, 0),
		Vector2(-3, -2)
	])
	moving_area.add_child(moving_area_sparkle)

	var bobber := Node2D.new()
	bobber.name = "Bobber"
	bobber.visible = false
	bobber.z_index = 30
	bobber.add_child(_criar_bobber_corpo())
	bobber.add_child(_criar_bobber_destaque())
	fishing_spot.add_child(bobber)

	var fishing_bite_timer := Timer.new()
	fishing_bite_timer.name = "FishingBiteTimer"
	fishing_bite_timer.wait_time = 3.0
	fishing_bite_timer.one_shot = true
	fishing_spot.add_child(fishing_bite_timer)

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = Vector2(340, 220)
	collision_shape.shape = rectangle_shape
	fishing_spot.add_child(collision_shape)

	return fishing_spot

func _criar_bobber_corpo() -> Polygon2D:
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.909804, 0.258824, 0.258824, 1)
	body.polygon = PackedVector2Array([
		Vector2(0, -7),
		Vector2(5, -5),
		Vector2(7, 0),
		Vector2(5, 5),
		Vector2(0, 7),
		Vector2(-5, 5),
		Vector2(-7, 0),
		Vector2(-5, -5)
	])
	return body

func _criar_bobber_destaque() -> Polygon2D:
	var highlight := Polygon2D.new()
	highlight.name = "Highlight"
	highlight.color = Color(0.976471, 0.976471, 0.976471, 0.9)
	highlight.polygon = PackedVector2Array([
		Vector2(-2, -6),
		Vector2(1, -6),
		Vector2(2, -3),
		Vector2(-1, -3)
	])
	return highlight

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			if SaveManager.load_game():
				get_viewport().set_input_as_handled()
