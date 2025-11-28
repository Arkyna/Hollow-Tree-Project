extends Area2D

func _on_body_entered(body):
	if body is Player:
		var current_scene_file = get_tree().current_scene.scene_file_path
		var file_name = current_scene_file.get_file().get_basename().replace("test_zone", "")
		var next_level_scene = int(file_name) + 1
		var next_level_path = "res://scene/test_zone" + str(next_level_scene) + ".tscn"

		print("Next level:", next_level_scene)
		print("Next path:", next_level_path)

		if next_level_scene > 2:
			call_deferred("_go_to_game_over")  # safely defer
		else:
			call_deferred("_change_scene_safely", next_level_path)


func _go_to_game_over():
	print(">>> Changing to Game Over scene...")
	get_tree().change_scene_to_file("res://scene/game_over.tscn")


func _change_scene_safely(next_level_path):
	print(">>> Changing to next level...")
	get_tree().change_scene_to_file(next_level_path)
