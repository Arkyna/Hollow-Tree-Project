extends Control

func _ready():
	# Cari tombol Back dan connect signal-nya
	# Pastikan kamu punya tombol bernama 'BackButton' di scene ini
	var back_btn = find_child("BackButton") 
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	# Kembali ke Main Menu
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
