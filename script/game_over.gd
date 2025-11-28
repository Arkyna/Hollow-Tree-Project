extends Node2D

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/test_zone.tscn")


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
