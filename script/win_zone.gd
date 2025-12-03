extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Player reached the end!")
		# Load your "You Win" screen or Credits
		# For now, let's just go to the Main Menu or a Win Screen
		call_deferred("change_scene")

func change_scene() -> void:
	# Reset game state so they can play again properly
	Manager.reset_game_state()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
