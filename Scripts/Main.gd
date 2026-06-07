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

const FISHING_SPOT_POSITION: Vector2 = Vector2(1110, 160)

const FISHING_SPOT_Z_INDEX: int = 20

const EXPANSION_POCKET_COLUMNS: int = 2

const EXPANSION_POCKET_ROWS: int = 2

const EXPANSION_POCKET_START_COLUMN: int = BASE_FARM_COLUMNS + EXTRA_FARM_COLUMNS_RIGHT

const EXPANSION_POCKET_START_ROW: int = 0

const EXPANSION_V0_OBSTACLE_ID: String = "first_obstacle"

const BLOCKOUT_FARM_Z_INDEX: int = 40



var expansion_area_configs: Dictionary = {}

var expansion_area_order: Array[String] = []

var expansion_area_visuals: Dictionary = {}

var expansion_area_plots: Dictionary = {}



func _ready() -> void:

	_configurar_regiao_navegacao()



	var screen_size = get_viewport_rect().size

	var start_x: float = (screen_size.x - BASE_FARM_PIXEL_SIZE) / 2.0 - 40.0

	var start_y: float = (screen_size.y - BASE_FARM_PIXEL_SIZE) / 2.0



	_criar_farm_plot_base(start_x, start_y)

	_criar_farm_plot_extras_direita(start_x, start_y)

	_criar_farm_plot_extras_inferiores(start_x, start_y)

	_garantir_lago_da_fazenda()

	_registrar_area_expansao_v0(start_x, start_y)

	_garantir_areas_expansao(start_x, start_y)

	_conectar_obstaculos_purificacao()

	_sincronizar_areas_expansao()

	_criar_blockout_fazenda_v0(start_x, start_y)



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



func _registrar_area_expansao_v0(start_x: float, start_y: float) -> void:

	if expansion_area_configs.has(EXPANSION_V0_OBSTACLE_ID):

		return



	expansion_area_order.append(EXPANSION_V0_OBSTACLE_ID)

	expansion_area_configs[EXPANSION_V0_OBSTACLE_ID] = {

		"obstacle_id": EXPANSION_V0_OBSTACLE_ID,

		"visual_name": "BlockedAreaVisual",

		"visual_position": Vector2(

			start_x + ((EXPANSION_POCKET_START_COLUMN + 0.5) * float(FARM_SPACING)),

			start_y + ((EXPANSION_POCKET_START_ROW + 0.7) * float(FARM_SPACING))

		),

		"pocket_start_column": EXPANSION_POCKET_START_COLUMN,

		"pocket_start_row": EXPANSION_POCKET_START_ROW,

		"pocket_columns": EXPANSION_POCKET_COLUMNS,

		"pocket_rows": EXPANSION_POCKET_ROWS

	}



func _garantir_areas_expansao(start_x: float, start_y: float) -> void:

	for obstacle_id in expansion_area_order:

		_garantir_area_expansao(obstacle_id, start_x, start_y)



func _garantir_area_expansao(obstacle_id: String, start_x: float, start_y: float) -> void:

	var area_config: Dictionary = _obter_config_area_expansao(obstacle_id)

	if area_config.is_empty():

		return



	if not expansion_area_visuals.has(obstacle_id):

		var visual: Node2D = _criar_area_bloqueada_visual()

		if visual != null:

			visual.name = str(area_config.get("visual_name", "BlockedAreaVisual"))

			visual.position = area_config.get("visual_position", Vector2.ZERO)

			expansion_area_visuals[obstacle_id] = visual

			add_child(visual)



	if not expansion_area_plots.has(obstacle_id):

		var area_plots: Array = _criar_pocket_expansao(obstacle_id, start_x, start_y)

		expansion_area_plots[obstacle_id] = area_plots



func _criar_pocket_expansao(obstacle_id: String, start_x: float, start_y: float) -> Array:

	var area_config: Dictionary = _obter_config_area_expansao(obstacle_id)

	var area_plots: Array = []

	if area_config.is_empty():

		return area_plots



	var pocket_start_column: int = int(area_config.get("pocket_start_column", 0))

	var pocket_start_row: int = int(area_config.get("pocket_start_row", 0))

	var pocket_columns: int = int(area_config.get("pocket_columns", 0))

	var pocket_rows: int = int(area_config.get("pocket_rows", 0))



	for x in range(pocket_columns):

		for y in range(pocket_rows):

			var grid_x: int = pocket_start_column + x

			var grid_y: int = pocket_start_row + y

			var plot: Node2D = farm_plot_scene.instantiate()

			plot.position = Vector2(start_x + (grid_x * FARM_SPACING), start_y + (grid_y * FARM_SPACING))

			plot.name = "FarmPlot_%d_%d" % [grid_x, grid_y]

			if plot.has_method("set_expansion_blocked"):

				plot.call("set_expansion_blocked", true)

			plot.visible = false

			add_child(plot)

			area_plots.append(plot)



	return area_plots



func _obter_config_area_expansao(obstacle_id: String) -> Dictionary:

	if not expansion_area_configs.has(obstacle_id):

		return {}

	var area_config_variant: Variant = expansion_area_configs.get(obstacle_id, {})

	if typeof(area_config_variant) != TYPE_DICTIONARY:

		return {}

	return area_config_variant



func _criar_area_bloqueada_visual() -> Node2D:

	var bloqueio := Node2D.new()

	bloqueio.z_index = 36



	var sombra := Polygon2D.new()

	sombra.name = "BlockedAreaShadow"

	sombra.z_index = 0

	sombra.color = Color(0.160784, 0.054902, 0.2, 0.58)

	sombra.polygon = PackedVector2Array([

		Vector2(-98, -46),

		Vector2(-68, -90),

		Vector2(28, -96),

		Vector2(94, -48),

		Vector2(108, 10),

		Vector2(74, 66),

		Vector2(6, 96),

		Vector2(-78, 80),

		Vector2(-110, 26)

	])

	bloqueio.add_child(sombra)



	var raiz := Polygon2D.new()

	raiz.name = "BlockedAreaRoot"

	raiz.z_index = 1

	raiz.color = Color(0.317647, 0.133333, 0.4, 0.92)

	raiz.polygon = PackedVector2Array([

		Vector2(-74, -30),

		Vector2(-38, -68),

		Vector2(20, -74),

		Vector2(70, -36),

		Vector2(82, 14),

		Vector2(52, 58),

		Vector2(-6, 70),

		Vector2(-64, 44)

	])

	bloqueio.add_child(raiz)



	var cristal := Polygon2D.new()

	cristal.name = "BlockedAreaCrystal"

	cristal.position = Vector2(18, -8)

	cristal.z_index = 2

	cristal.color = Color(0.780392, 0.27451, 0.905882, 0.88)

	cristal.polygon = PackedVector2Array([

		Vector2(0, -32),

		Vector2(18, -14),

		Vector2(28, 0),

		Vector2(18, 16),

		Vector2(0, 32),

		Vector2(-18, 16),

		Vector2(-28, 0),

		Vector2(-18, -14)

	])

	bloqueio.add_child(cristal)



	var anel := Line2D.new()

	anel.name = "BlockedAreaRing"

	anel.z_index = 3

	anel.width = 7.0

	anel.default_color = Color(0.941176, 0.768627, 1.0, 0.85)

	anel.antialiased = true

	anel.closed = true

	anel.points = PackedVector2Array([

		Vector2(0, -52),

		Vector2(36, -34),

		Vector2(54, 0),

		Vector2(38, 38),

		Vector2(0, 54),

		Vector2(-38, 38),

		Vector2(-54, 0),

		Vector2(-36, -34)

	])

	bloqueio.add_child(anel)



	return bloqueio



func _criar_blockout_fazenda_v0(start_x: float, start_y: float) -> void:

	if has_node("FarmBlockoutV0"):

		return



	var blockout_root := Node2D.new()

	blockout_root.name = "FarmBlockoutV0"

	blockout_root.z_index = BLOCKOUT_FARM_Z_INDEX

	blockout_root.z_as_relative = false

	add_child(blockout_root)



	var zonas: Array = [

		{

			"id": "creatures_animals_future",

			"title": "Criaturas mágicas",

			"subtitle": "Animais e aliados encantados",

			"center": Vector2(start_x + (8.9 * FARM_SPACING), start_y - (1.1 * FARM_SPACING)),

			"size": Vector2(210, 136),

			"fill": Color(0.160784, 0.356863, 0.258824, 0.3),

			"outline": Color(0.690196, 0.882353, 0.741176, 0.68)

		},

		{

			"id": "helpers_golems_future",

			"title": "Golems / ajudantes",

			"subtitle": "Área de apoio da fazenda",

			"center": Vector2(start_x - (1.9 * FARM_SPACING), start_y + (5.2 * FARM_SPACING)),

			"size": Vector2(190, 128),

			"fill": Color(0.294118, 0.184314, 0.454902, 0.28),

			"outline": Color(0.843137, 0.713726, 0.976471, 0.68)

		},

		{

			"id": "foraging_resources_future",

			"title": "Recursos / forrageamento",

			"subtitle": "Área de coleta natural",

			"center": Vector2(start_x + (9.8 * FARM_SPACING), start_y + (5.0 * FARM_SPACING)),

			"size": Vector2(220, 140),

			"fill": Color(0.486275, 0.333333, 0.113725, 0.28),

			"outline": Color(0.988235, 0.878431, 0.619608, 0.68)

		},

		{

			"id": "blocked_area_future",

			"title": "Corrupção futura",

			"subtitle": "Segunda área corrompida",

			"center": Vector2(start_x + (10.8 * FARM_SPACING), start_y + (1.2 * FARM_SPACING)),

			"size": Vector2(210, 136),

			"fill": Color(0.337255, 0.121569, 0.454902, 0.32),

			"outline": Color(0.94902, 0.760784, 1.0, 0.72)

		},

		{

			"id": "ruin_mystery_future",

			"title": "Ruína / mistério",

			"subtitle": "Zona de enigma futuro",

			"center": Vector2(start_x + (10.8 * FARM_SPACING), start_y + (6.0 * FARM_SPACING)),

			"size": Vector2(220, 138),

			"fill": Color(0.184314, 0.184314, 0.227451, 0.26),

			"outline": Color(0.823529, 0.831373, 0.87451, 0.64)

		}

	]



	for zona in zonas:

		var marcador: Node2D = _criar_marcador_zona(

			str(zona.get("id", "zona_futura")),

			str(zona.get("title", "Zona futura")),

			str(zona.get("subtitle", "")),

			zona.get("center", Vector2.ZERO),

			zona.get("size", Vector2(200, 120)),

			zona.get("fill", Color(1, 1, 1, 0.35)),

			zona.get("outline", Color(1, 1, 1, 0.85))

		)

		blockout_root.add_child(marcador)



func _criar_marcador_zona(zona_id: String, titulo: String, subtitulo: String, centro: Vector2, tamanho: Vector2, fill_color: Color, outline_color: Color) -> Node2D:

	var marcador := Node2D.new()

	marcador.name = "Blockout_%s" % zona_id

	marcador.position = centro

	marcador.z_index = BLOCKOUT_FARM_Z_INDEX

	marcador.z_as_relative = false



	var sombra := Polygon2D.new()

	sombra.name = "Sombra"

	sombra.color = Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * 0.32)

	sombra.polygon = _criar_poligono_retangular(tamanho + Vector2(30, 24))

	sombra.position = Vector2(8, 10)

	marcador.add_child(sombra)



	var corpo := Polygon2D.new()

	corpo.name = "Corpo"

	corpo.color = fill_color

	corpo.polygon = _criar_poligono_retangular(tamanho)

	marcador.add_child(corpo)



	var contorno := Line2D.new()

	contorno.name = "Contorno"

	contorno.width = 3.0

	contorno.default_color = outline_color

	contorno.closed = true

	contorno.antialiased = true

	contorno.points = _criar_pontos_retangulo(tamanho)

	marcador.add_child(contorno)



	var detalhe_horizontal := Line2D.new()

	detalhe_horizontal.name = "DetalheHorizontal"

	detalhe_horizontal.width = 1.5

	detalhe_horizontal.default_color = Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.42)

	detalhe_horizontal.points = PackedVector2Array([

		Vector2(-tamanho.x * 0.35, 0),

		Vector2(tamanho.x * 0.35, 0)

	])

	marcador.add_child(detalhe_horizontal)



	var detalhe_vertical := Line2D.new()

	detalhe_vertical.name = "DetalheVertical"

	detalhe_vertical.width = 1.5

	detalhe_vertical.default_color = Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.34)

	detalhe_vertical.points = PackedVector2Array([

		Vector2(0, -tamanho.y * 0.32),

		Vector2(0, tamanho.y * 0.32)

	])

	marcador.add_child(detalhe_vertical)



	var etiqueta := Label.new()

	etiqueta.name = "Etiqueta"

	etiqueta.text = titulo + "\n" + subtitulo

	etiqueta.position = Vector2(-tamanho.x * 0.5, -tamanho.y * 0.5 - 48)

	etiqueta.size = Vector2(tamanho.x, 70)

	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	etiqueta.add_theme_font_size_override("font_size", 15)

	etiqueta.add_theme_color_override("font_color", outline_color)

	etiqueta.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))

	etiqueta.add_theme_constant_override("shadow_offset_x", 2)

	etiqueta.add_theme_constant_override("shadow_offset_y", 2)

	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	marcador.add_child(etiqueta)



	return marcador



func _criar_poligono_retangular(tamanho: Vector2) -> PackedVector2Array:

	var meio_x: float = tamanho.x * 0.5

	var meio_y: float = tamanho.y * 0.5

	return PackedVector2Array([

		Vector2(-meio_x, -meio_y),

		Vector2(meio_x, -meio_y),

		Vector2(meio_x, meio_y),

		Vector2(-meio_x, meio_y)

	])



func _criar_pontos_retangulo(tamanho: Vector2) -> PackedVector2Array:

	var pontos := _criar_poligono_retangular(tamanho)

	pontos.append(pontos[0])

	return pontos



func _conectar_obstaculos_purificacao() -> void:

	var tree: SceneTree = get_tree()

	if tree == null:

		return



	var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

	for obstaculo_variant in obstaculos:

		var obstaculo: Node = obstaculo_variant

		if obstaculo == null or not is_instance_valid(obstaculo):

			continue

		if not obstaculo.has_signal("purified"):

			continue

		if not obstaculo.is_connected("purified", Callable(self, "_on_obstaculo_purificado")):

			obstaculo.connect("purified", Callable(self, "_on_obstaculo_purificado"))



func _obter_estado_purificacao_obstaculo(obstacle_id: String) -> bool:

	var obstaculo: Node = _obter_obstaculo_purificacao_por_id(obstacle_id)

	if obstaculo == null or not obstaculo.has_method("get_save_data"):

		return false



	var obstacle_data_variant: Variant = obstaculo.call("get_save_data")

	if typeof(obstacle_data_variant) != TYPE_DICTIONARY:

		return false



	return bool((obstacle_data_variant as Dictionary).get("purified", false))



func _obter_obstaculo_purificacao_por_id(obstacle_id: String) -> Node:

	if obstacle_id == "":

		return null



	var tree: SceneTree = get_tree()

	if tree == null:

		return null



	var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

	for obstaculo_variant in obstaculos:

		var obstaculo: Node = obstaculo_variant

		if obstaculo == null or not is_instance_valid(obstaculo):

			continue

		if obstaculo.has_method("get_obstacle_id"):

			if str(obstaculo.call("get_obstacle_id")) == obstacle_id:

				return obstaculo

		elif obstaculo.name == obstacle_id:

			return obstaculo



	return null



func _aplicar_estado_area_expansao(obstacle_id: String, purificado: bool) -> void:

	if obstacle_id == "":

		return



	if expansion_area_visuals.has(obstacle_id):

		var visual: Node = expansion_area_visuals[obstacle_id]

		if visual != null and is_instance_valid(visual):

			visual.visible = not purificado



	if expansion_area_plots.has(obstacle_id):

		var area_plots: Array = expansion_area_plots[obstacle_id]

		for plot_variant in area_plots:

			var plot: Node = plot_variant

			if plot == null or not is_instance_valid(plot):

				continue

			if plot.has_method("set_expansion_blocked"):

				plot.call("set_expansion_blocked", not purificado)



func _sincronizar_areas_expansao() -> void:

	for obstacle_id in expansion_area_order:

		_aplicar_estado_area_expansao(obstacle_id, _obter_estado_purificacao_obstaculo(obstacle_id))



func sincronizar_area_bloqueada_v0() -> void:

	_sincronizar_areas_expansao()



func _on_obstaculo_purificado(obstacle_id: String) -> void:

	if obstacle_id == "":

		return

	_aplicar_estado_area_expansao(obstacle_id, true)

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



func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		var ui_node: Node = get_node_or_null("UI")
		if ui_node != null and ui_node.has_method("_tem_popup_modal_aberto") and ui_node.call("_tem_popup_modal_aberto"):
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		var tree: SceneTree = get_tree()

		if tree == null:

			return



		var obstaculos: Array = tree.get_nodes_in_group("purification_obstacle")

		for obstaculo_variant in obstaculos:

			var obstaculo: Node = obstaculo_variant

			if obstaculo == null or not is_instance_valid(obstaculo):

				continue

			if not obstaculo.has_method("try_handle_global_click"):

				continue

			if obstaculo.call("try_handle_global_click", get_global_mouse_position()):

				get_viewport().set_input_as_handled()

				return



func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_F5:

			SaveManager.save_game()

			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_F9:

			if SaveManager.load_game():

				var ui_node := get_node_or_null("UI")

				if ui_node and ui_node.has_method("reiniciar_objetivos_iniciais_apos_load"):

					ui_node.call("reiniciar_objetivos_iniciais_apos_load")

				get_viewport().set_input_as_handled()
