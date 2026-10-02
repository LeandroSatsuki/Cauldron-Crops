extends Node2D

# Cenografia somente: nenhum collider, Control, estoque ou alteração de solo.
const GRASS := preload("res://Assets/scenery/grass_tile.png")
const GRASS_SHADER := preload("res://Shaders/farm_grass.gdshader")
const FIELD_BOUNDS := Rect2(-512, -384, 3072, 2304)
var _cauldron := Vector2.ZERO
var _chest := Vector2.ZERO
var _gateway := Vector2.ZERO
var _arrival := Vector2.ZERO
var _pond := Vector2.ZERO

func _ready() -> void:
	z_index = -160
	z_as_relative = false
	# Completar o fundo até além do enquadramento, sem ampliar navegação.
	var ground := Sprite2D.new()
	ground.name = "GroundBackdrop"
	ground.texture = GRASS
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.region_enabled = true
	ground.region_rect = Rect2(0, 0, 8192, 8192)
	ground.position = FIELD_BOUNDS.get_center()
	ground.z_as_relative = false
	ground.z_index = -220
	var grass_material := ShaderMaterial.new()
	grass_material.shader = GRASS_SHADER
	ground.material = grass_material
	add_child(ground)
	_configure.call_deferred()

func _configure() -> void:
	var world := get_parent()
	_cauldron = world.get_node("CauldronUI/BaseAnchor/ObstacleBody/CollisionShape2D").global_position
	_chest = world.get_node("VillageChest").global_position
	_gateway = world.get_node("ExternalPathGateway").global_position
	_arrival = world.get_node("RegionContext/VillageArrival").global_position
	_pond = world.get_node("FishingSpot").global_position
	queue_redraw()

func _draw() -> void:
	if _cauldron == Vector2.ZERO:
		return
	_trail([_chest, _chest + Vector2(155, 10), _cauldron + Vector2(-260, 100), _cauldron + Vector2(0, 55)], 52)
	_trail([_cauldron + Vector2(0, 55), _arrival + Vector2(-80, 0), _arrival, _gateway + Vector2(-120, 75), _gateway + Vector2(0, 42)], 56)
	_trail([_cauldron + Vector2(-65, 45), _cauldron + Vector2(-160, -95), _pond + Vector2(-220, 150), _pond + Vector2(-195, 30)], 34)
	# Clareiras discretas, sempre abaixo da terra preparada pelo jogador.
	_oval(_cauldron + Vector2(0, 18), Vector2(105, 57), Color("788054", 0.35))
	_oval(_chest + Vector2(0, 12), Vector2(65, 37), Color("788054", 0.32))
	var rng := RandomNumberGenerator.new()
	rng.seed = 47021 # RNG local: cenografia nunca interfere nos drops do jogo.
	for i in range(230):
		var point := Vector2(rng.randf_range(-400, 2460), rng.randf_range(-270, 1800))
		if _near_landmark(point):
			continue
		_tuft(point, rng.randf_range(0.65, 1.3))
	# Bordas de baixa vegetação, não muros/árvores atravessáveis.
	for anchor in [Vector2(90, 320), Vector2(240, 1060), Vector2(690, 1010), Vector2(1820, 1030), Vector2(2060, 440), Vector2(700, 170)]:
		for i in range(16):
			var point: Vector2 = anchor + Vector2(rng.randf_range(-95, 95), rng.randf_range(-40, 40))
			_oval(point, Vector2(12, 5), Color("4c693c", 0.65))
			_tuft(point, 1.35)
		for i in range(7):
			_flower(anchor + Vector2(rng.randf_range(-80, 80), rng.randf_range(-32, 32)), Color("e3d795") if i % 2 == 0 else Color("b8caa7"))

func _near_landmark(point: Vector2) -> bool:
	for landmark in [_cauldron, _chest, _gateway, _arrival, _pond]:
		if point.distance_to(landmark) < 180:
			return true
	return false

func _trail(anchors: Array, width: float) -> void:
	var curve := Curve2D.new()
	for i in range(anchors.size()):
		var before: Vector2 = anchors[maxi(i - 1, 0)]
		var after: Vector2 = anchors[mini(i + 1, anchors.size() - 1)]
		var tangent := (after - before) * 0.14
		curve.add_point(anchors[i], -tangent, tangent)
	var points := curve.get_baked_points()
	draw_polyline(points, Color("697346", 0.25), width + 14, true)
	draw_polyline(points, Color("a09a6b", 0.45), width, true)
	draw_polyline(points, Color("b2a878", 0.22), width * 0.53, true)
	for i in range(0, points.size(), 6):
		var point := points[i] + Vector2(sin(float(i)) * 12, cos(float(i) * 1.7) * 13)
		draw_rect(Rect2(point, Vector2(4, 2)), Color("c4b68c", 0.38))

func _oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)

func _tuft(point: Vector2, size: float) -> void:
	draw_line(point + Vector2(-4, 0) * size, point + Vector2(-7, -7) * size, Color("547740"), 2)
	draw_line(point, point + Vector2(-1, -10) * size, Color("7f9854"), 2)
	draw_line(point + Vector2(3, 0) * size, point + Vector2(5, -6) * size, Color("607e40"), 2)

func _flower(point: Vector2, color: Color) -> void:
	draw_line(point, point + Vector2(0, -8), Color("42623b"), 2)
	draw_rect(Rect2(point + Vector2(-3, -11), Vector2(6, 5)), color)
	draw_rect(Rect2(point + Vector2(-1, -9), Vector2(2, 2)), Color("ad914f"))
