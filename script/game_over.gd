extends Control

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel       # <--- Make sure this is set to Unique (%) in Scene
@onready var high_score_label: Label = %HighScoreLabel # <--- Optional: Add this if you want to show Best Time
@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	# 1. Display Fragments Found
	score_label.text = "Found Fragments: " + str(Manager.collected_fragments)
	
	# 2. Display Time Survived (Current Run)
	if Manager.final_time > 0:
		# Use the helper function from Manager to make it look like "01:23.456"
		time_label.text = "Time: " + Manager.format_time(Manager.final_time)
	else:
		time_label.text = "Time: --:--"

	# 3. Display Best Time (High Score)
	if high_score_label:
		if Manager.high_score_time < 99999.0:
			high_score_label.text = "Best: " + Manager.format_time(Manager.high_score_time)
		else:
			high_score_label.text = "Best: --:--"

	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_retry_pressed() -> void:
	Manager.reset_game_state()
	get_tree().change_scene_to_file("res://scene/zone1.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
