extends CharacterBody2D
class_name Player

# --- Configuration ---
@export_group("Movement Settings")
@export var walk_speed: float = 80.0
@export var sprint_speed: float = 140.0
@export var acceleration: float = 20.0 # Optional: adds a little weight to movement

# --- State ---
var can_sprint: bool = true
var is_sprinting: bool = false
var start_position: Vector2 = Vector2.ZERO # Stores original spawn point
var checkpoint_pos: Vector2 = Vector2.ZERO

# --- Nodes ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprint_timer: Timer = $SprintTimer
@onready var flashlight: Node2D = $Flashlight # Ensure you have a Node2D/PointLight2D named Flashlight

func _ready() -> void:
	# 1. Save the starting position for the Debug Reset feature
	start_position = global_position
	checkpoint_pos = global_position
	
	# 2. Setup Timer
	sprint_timer.one_shot = true
	sprint_timer.wait_time = 3.0 # Set this to however long they can sprint
	sprint_timer.timeout.connect(_on_sprint_timer_timeout)
	
	# 3. Register to Manager (Keep existing logic)
	var dm = get_tree().get_first_node_in_group("DemoManager")
	if dm:
		dm.register_player(self)
	
	anim.play("frontIdle")
	Manager.player_respawn_requested.connect(respawn_to_checkpoint)

func _physics_process(_delta: float) -> void:
	handle_debug_input() # Check for 'R' key
	handle_movement()
	check_enemy_collision()
	
	move_and_slide()

func _process(_delta: float) -> void:
	# Update visuals (Flashlight/Darkness) in _process to keep it smooth (high FPS)
	update_darkness_overlay()

# --- INPUT & MOVEMENT ---

func handle_debug_input() -> void:
	# DEBUG: Press R to reset position
	if Input.is_physical_key_pressed(KEY_R):
		global_position = start_position
		velocity = Vector2.ZERO
		print("Debug: Reset to start position.")

func handle_movement() -> void:
	# Godot 4: Cleaner way to get input vector (handles deadzones automatically)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# --- Sprint Logic ---
	var pressing_sprint := Input.is_action_pressed("sprint") # Ensure 'sprint' is in Project Settings -> Input Map
	
	# Reset sprint ability if button is released
	if not pressing_sprint:
		can_sprint = true
		is_sprinting = false
		sprint_timer.stop() # Stop draining stamina if we stop running
	
	# Start sprinting
	if pressing_sprint and input_dir != Vector2.ZERO and can_sprint:
		if not is_sprinting:
			is_sprinting = true
			sprint_timer.start()
	
	# Determine speed
	var current_speed := sprint_speed if is_sprinting else walk_speed
	
	# Apply Velocity
	if input_dir != Vector2.ZERO:
		velocity = input_dir * current_speed
		update_animation(input_dir)
		update_flashlight_smooth(input_dir.angle())
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)

# --- VISUALS ---

func update_animation(move_dir: Vector2) -> void:
	if move_dir == Vector2.ZERO:
		# Keep the last direction but switch to idle if you have idle anims
		# Or just pause current frame:
		if "Idle" not in anim.animation:
			# Logic to switch to idle version of current direction could go here
			# For now, based on your code, we just stop or keep playing
			pass
		return

	# Determine animation based on direction
	if abs(move_dir.x) > abs(move_dir.y):
		anim.play("side")
		anim.flip_h = move_dir.x < 0
	elif move_dir.y > 0:
		anim.play("frontIdle") # Or "frontWalk" if you have it
		anim.flip_h = false
	else:
		anim.play("back")
		anim.flip_h = false

func update_flashlight_smooth(target_angle: float) -> void:
	if not flashlight: return
	
	var current_rot = flashlight.rotation
	
	# Godot 4 lerp_angle handles the math wrap-around automatically
	flashlight.rotation = lerp_angle(current_rot, target_angle, 0.15)

func update_darkness_overlay() -> void:
	# Only run this if the group exists
	var overlay = get_tree().get_first_node_in_group("Darkness")
	if overlay and flashlight:
		overlay.set_light_position(global_position)
		overlay.set_light_angle(flashlight.rotation)

# --- SIGNALS & LOGIC ---

func _on_sprint_timer_timeout() -> void:
	# Stamina run out
	is_sprinting = false
	can_sprint = false
	print("Sprint exhausted")

func check_enemy_collision() -> void:
	# Efficient check for collisions
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check Class or Group
		if collider is Enemy or collider.is_in_group("Enemy"):
			die()
			break

# --- CHECKPOINTS & DEATH ---
func set_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	print("Checkpoint set: ", checkpoint_pos)

func respawn_to_checkpoint() -> void:
	print("Player: Starting Respawn Sequence...")
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	await Transition.fade_to_black() 
	
	var active = Manager.current_active_stage
	var target = Manager.last_checkpoint_stage
	
	if active and target and is_instance_valid(active) and is_instance_valid(target) and active != target:
		active.process_mode = Node.PROCESS_MODE_DISABLED
		active.visible = false
		
		target.process_mode = Node.PROCESS_MODE_INHERIT
		target.visible = true
		Manager.current_active_stage = target
	
	global_position = checkpoint_pos
	
	var cam = get_node_or_null("Camera2D") 
	if cam:
		cam.reset_smoothing()
	
	await get_tree().process_frame # Wait for camera to update position
	
	await Transition.fade_to_normal() # Screen reveals new position
	
	modulate.a = 0.5 
	await get_tree().create_timer(1.0).timeout
	modulate.a = 1.0
	
	set_physics_process(true)

func die() -> void:
	if not is_physics_processing(): 
		return
	print("Player died.")
	Manager.lose_life()
	set_physics_process(false)

func _go_to_game_over() -> void:
	get_tree().change_scene_to_file("res://scene/game_over.tscn")
