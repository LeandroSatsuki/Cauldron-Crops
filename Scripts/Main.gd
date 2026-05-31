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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			if SaveManager.load_game():
				get_viewport().set_input_as_handled()
