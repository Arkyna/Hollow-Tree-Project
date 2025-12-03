extends Control

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	# Connect the button signals
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# OPTIONAL: Reset game state just in case
	# This ensures if you come back to menu from game over, everything is clean
	if Manager:
		Manager.reset_game_state()

func _on_play_pressed() -> void:
	# Change this path to your actual first level scene!
	get_tree().change_scene_to_file("res://scene/zone1.tscn")

func _on_quit_pressed() -> void:
	# Quits the game desktop application
	get_tree().quit()
