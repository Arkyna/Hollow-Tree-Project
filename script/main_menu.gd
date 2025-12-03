extends Control

@onready var play_button: Button = %PlayButton
@onready var credits_button: Button = %CreditsButton # <--- Tambahan Baru
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	if Manager:
		Manager.reset_game_state()
	
	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed) # <--- Connect signal
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	# 2. Start the timer right before entering the game world
	Manager.start_game_timer()
	get_tree().change_scene_to_file("res://scene/zone1.tscn")

func _on_credits_pressed() -> void:
	# Pindah ke scene credits
	get_tree().change_scene_to_file("res://scene/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
