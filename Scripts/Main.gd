extends Node2D

var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D

func _ready() -> void:
	_configurar_regiao_navegacao()
	
	var screen_size = get_viewport_rect().size
	var start_x = (screen_size.x - 320) / 2.0
	var start_y = (screen_size.y - 320) / 2.0
	
	for x in range(4):
		for y in range(4):
			var plot = farm_plot_scene.instantiate()
			plot.position = Vector2(start_x + (x * 80), start_y + (y * 80))
			add_child(plot)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			if SaveManager.load_game():
				get_viewport().set_input_as_handled()
