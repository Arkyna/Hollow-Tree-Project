extends Camera2D

func _process(_delta):
	global_position = global_position.snapped(Vector2(0.5, 0.5))
