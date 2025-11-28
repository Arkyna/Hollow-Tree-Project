extends CanvasLayer

@onready var mask: ColorRect = $Mask

func world_to_screen(world_pos: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return world_pos
	return cam.get_screen_transform() * world_pos   # Godot 4 version

func set_light_position(world_pos: Vector2) -> void:
	var screen_pos: Vector2 = world_to_screen(world_pos)

	var mat := mask.material
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("light_position", screen_pos)

func set_light_angle(angle: float) -> void:
	var mat := mask.material
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("cone_direction", angle)
