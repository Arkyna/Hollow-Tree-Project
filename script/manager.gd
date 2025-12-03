extends Node

# --- SIGNALS ---
signal score_updated(new_score)
signal fragments_updated(new_count: int)
signal lives_updated(new_lives: int)
signal player_respawn_requested

# --- VARIABLES ---
var current_score: int = 0
var inventory_list: Array = []
var collected_fragments: int = 0
var current_lives: int = 10
var max_lives: int = 10

# --- STAGE TRACKING VARIABLES (For Teleporter/Respawn Fix) ---
var current_active_stage: Node2D = null 
var last_checkpoint_stage: Node2D = null 

# --- GAME TIMER & HIGH SCORE VARIABLES ---
var start_time: float = 0.0 # Time in seconds when the timer started
var final_time: float = 0.0 # Stores the total elapsed time in seconds for the CURRENT run
var high_score_time: float = 99999.0 # Best time recorded in the current session (lower is better)

const FRAGMENTS_REQUIRED = 6
# ----------------------------------------------------

func _ready() -> void:
	current_lives = max_lives

# --- TIMER FUNCTIONS ---
func start_game_timer() -> void:
	# Records the current engine time to establish the start point
	start_time = Time.get_ticks_msec() / 1000.0
	final_time = 0.0

func stop_game_timer() -> void:
	# Calculates elapsed time and stores it in final_time
	if start_time > 0:
		final_time = (Time.get_ticks_msec() / 1000.0) - start_time
		start_time = 0.0 # Clear the timer
	
func format_time(time_in_seconds: float) -> String:
	# Formats seconds into MM:SS.mmm
	var minutes = floor(time_in_seconds / 60.0)
	var seconds = fmod(time_in_seconds, 60.0)
	var milliseconds = fmod(time_in_seconds * 1000.0, 1000.0)
	return "%02d:%02d.%03d" % [minutes, floor(seconds), milliseconds]
# ------------------------------

func add_item(item_name: String = "Coin"):
	current_score += 1
	inventory_list.append(item_name)
	score_updated.emit(current_score)
	
func lose_life() -> void:
	current_lives -= 1
	lives_updated.emit(current_lives)
	if current_lives > 0:
		# Player listens for this and starts the respawn sequence
		player_respawn_requested.emit()
	else:
		game_over() 

func collect_fragment():
	collected_fragments += 1
	fragments_updated.emit(collected_fragments)
	
	if collected_fragments == FRAGMENTS_REQUIRED: # <--- Now uses the constant
		stop_game_timer()
		
		# Check if new high score (lower time is better)
		if final_time > 0 and final_time < high_score_time:
			high_score_time = final_time
			print("Manager: New Best Time! ", format_time(high_score_time))
			
		print("Manager: All fragments collected! Final Time: ", format_time(final_time))

func reset_game_state() -> void:
	# --- CRUCIAL: ONLY CURRENT RUN STATS ARE RESET HERE ---
	current_score = 0
	collected_fragments = 0
	current_lives = max_lives
	final_time = 0.0
	start_time = 0.0
	
	
	# Reset Stage Refs (safe housekeeping)
	current_active_stage = null 
	last_checkpoint_stage = null 
	
	score_updated.emit(current_score)
	fragments_updated.emit(collected_fragments)
	lives_updated.emit(current_lives)
	
func game_over() -> void:
	stop_game_timer()
	var bgm_player = get_tree().get_first_node_in_group("BGM") 
	if bgm_player:
		pass
	get_tree().change_scene_to_file("res://scene/game_over.tscn")
