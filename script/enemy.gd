extends CharacterBody2D
class_name Enemy

# --- Settings ---
@export_group("Movement")
@export var speed: float = 60.0
@export var chase_speed_mult: float = 1.5
@export var arrive_distance: float = 10.0

@export_group("Patrol")
# Drag a Node2D here that contains Marker2D children
@export var patrol_parent: Node2D 

# --- Nodes ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea # Ensure this node exists!
@onready var capture_area: Area2D = $CaptureZone     # Ensure this node exists!

# --- State ---
enum State { PATROL, CHASE, RETURN }
var state: State = State.PATROL

var player_ref: Player = null
var patrol_positions: Array[Vector2] = []
var patrol_index: int = 0

func _ready() -> void:
	# 1. Setup Patrol Points
	if patrol_parent:
		for child in patrol_parent.get_children():
			if child is Node2D:
				patrol_positions.append(child.global_position)
	else:
		# If no patrol points, just stay where spawned
		patrol_positions.append(global_position)

	# 2. Setup Navigation
	# Avoids "get_next_path_position" errors on frame 1
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
	# 3. Connect Signals (Godot 4 Style)
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)
	capture_area.body_entered.connect(_on_capture_entered)

func _physics_process(_delta: float) -> void:
	match state:
		State.PATROL: _state_patrol()
		State.CHASE:  _state_chase()
		State.RETURN: _state_return()
	
	move_and_slide()

# --- STATE LOGIC ---

func _state_patrol() -> void:
	if patrol_positions.is_empty(): return
	
	var target = patrol_positions[patrol_index]
	nav_agent.target_position = target
	
	_move_towards_target(speed)
	
	# Check if arrived at patrol point
	if global_position.distance_to(target) < arrive_distance:
		patrol_index = (patrol_index + 1) % patrol_positions.size()

func _state_chase() -> void:
	if not player_ref:
		state = State.RETURN
		return
		
	nav_agent.target_position = player_ref.global_position
	_move_towards_target(speed * chase_speed_mult)

func _state_return() -> void:
	# Return to the last known patrol point
	var target = patrol_positions[patrol_index]
	nav_agent.target_position = target
	
	_move_towards_target(speed)
	
	if global_position.distance_to(target) < arrive_distance:
		state = State.PATROL

func _move_towards_target(current_speed: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	
	velocity = direction * current_speed

# --- SIGNALS ---

func _on_detection_entered(body: Node2D) -> void:
	if body is Player: # Checks class_name Player
		player_ref = body
		state = State.CHASE

func _on_detection_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		state = State.RETURN

func _on_capture_entered(body: Node2D) -> void:
	# THIS IS THE CRITICAL FIX
	if body is Player:
		print("Enemy: Caught player!")
		
		# We simply tell the player to die. 
		# The Player script handles the Manager, Lives, and freezing.
		body.die()
		
		# Stop chasing for a moment so we don't spawn camp
		state = State.RETURN
