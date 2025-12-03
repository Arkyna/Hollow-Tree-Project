extends Node

# --- SIGNALS ---
signal score_updated(new_score)
signal fragments_updated(new_count: int)
signal lives_updated(new_lives: int)
signal player_respawn_requested

# --- VARIABLES ---
var current_score: int = 0         # <--- You named it current_score here
var inventory_list: Array = []
var collected_fragments: int = 0
var current_lives: int = 2
var max_lives: int = 2

func _ready() -> void:
	current_lives = max_lives

func add_item(item_name: String = "Coin"):
	current_score += 1
	inventory_list.append(item_name)
	print("Manager: Item collected! Score is now: ", current_score)
	score_updated.emit(current_score)
	
func lose_life() -> void:
	current_lives -= 1
	lives_updated.emit(current_lives)
	print("Manager: Life lost. Remaining: ", current_lives)
	if current_lives > 0:
		player_respawn_requested.emit()
	else:
		game_over()

# Inside manager.gd

func collect_fragment():
	collected_fragments += 1
	fragments_updated.emit(collected_fragments)
	
	if collected_fragments == 3:
		print("Manager: All fragments collected! Gate opening sound playing...")

# --- THE FIX IS HERE ---
func reset_game_state() -> void:
	# 1. Reset values (Use the correct variable names!)
	current_score = 0          # Changed 'score' to 'current_score'
	collected_fragments = 0    # Added this so fragments reset too!
	current_lives = max_lives
	
	# 2. Update listeners
	score_updated.emit(current_score)
	fragments_updated.emit(collected_fragments) # Update UI for fragments
	lives_updated.emit(current_lives)
	
	print("Manager: Game State Reset.")
	
func game_over() -> void:
	print("Manager: GAME OVER")
	# Don't reset lives here, let the Retry button do it via reset_game_state
	get_tree().change_scene_to_file("res://scene/game_over.tscn")
