extends Node2D

var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")

func _ready() -> void:
	
	var screen_size = get_viewport_rect().size
	var start_x = (screen_size.x - 320) / 2.0
	var start_y = (screen_size.y - 320) / 2.0
	
	for x in range(4):
		for y in range(4):
			var plot = farm_plot_scene.instantiate()
			plot.position = Vector2(start_x + (x * 80), start_y + (y * 80))
			add_child(plot)
