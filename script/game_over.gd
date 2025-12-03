extends Control

@onready var score_label: Label = %ScoreLabel
@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	score_label.text = "Found Fragments: " + str(Manager.collected_fragments)	
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_retry_pressed() -> void:
	Manager.reset_game_state()
	
	get_tree().change_scene_to_file("res://scene/zone1.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
