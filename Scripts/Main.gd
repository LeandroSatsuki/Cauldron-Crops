extends Node2D

var farm_plot_scene = preload("res://Scenes/FarmPlot.tscn")

func _ready() -> void:
	GlobalInventory.adicionar_item("agua", 10)
	
	var screen_size = get_viewport_rect().size
	var grid_offset = (screen_size / 2.0) - Vector2(120, 120)
	
	for x in range(4):
		for y in range(4):
			var plot = farm_plot_scene.instantiate()
			plot.position = grid_offset + Vector2(x * 80, y * 80)
			add_child(plot)
