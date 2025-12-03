extends CharacterBody2D
class_name ShadowStalker

# --- Configuration ---
@export_group("Stats")
@export var patrol_speed: float = 45.0
@export var chase_speed: float = 80.0
@export var arrive_distance: float = 10.0
@export var freeze_delay: float = 0.5 # Seconds (easier to edit than ms)

@export_group("References")
@export var patrol_parent: Node2D # Direct reference is better than NodePath
@export var player_target: Node2D # Can be assigned manually or found auto

# --- Nodes ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
# @onready var capture_area removed
@onready var recover_timer: Timer = $RecoverTimer 

# --- State ---
enum State { IDLE, CHASE, FROZEN, RECOVER }
var state: State = State.IDLE
var patrol_points: Array[Node2D] = []
var patrol_index: int = 0

func _ready() -> void:
	# 1. Setup Timer
	recover_timer.wait_time = freeze_delay
	recover_timer.one_shot = true
	recover_timer.timeout.connect(_on_recover_timeout)
	
	# 2. Find Player (Fallback)
	if not player_target:
		player_target = get_tree().get_first_node_in_group("Player")

	# 3. Setup Patrol
	if patrol_parent:
		for child in patrol_parent.get_children():
			if child is Node2D:
				patrol_points.append(child)
	
	# If no points, patrol current spot
	if patrol_points.is_empty():
		patrol_points.append(self) 

	# 4. Signals
	detection_area.body_entered.connect(_on_detect_enter)
	detection_area.body_exited.connect(_on_detect_exit)
	# capture_area signal removed
	
	# Assuming LightCheckArea is linked via Editor signals or has a specific script
	if has_node("LightCheckArea"):
		var light_area = $LightCheckArea
		light_area.area_entered.connect(_on_light_enter)
		light_area.area_exited.connect(_on_light_exit)

	# 5. Nav Sync
	call_deferred("actor_setup")

func actor_setup():
	await get_tree().physics_frame
	anim.play("idle")

func _physics_process(_delta: float) -> void:
	# If frozen or recovering, stop moving immediately
	if state == State.FROZEN or state == State.RECOVER:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		State.IDLE:
			_process_patrol()
		State.CHASE:
			_process_chase()

	move_and_slide()
	_check_collisions() # <--- NEW: Check for physical collision after moving

# ─────────────────────────────────────────────
# BEHAVIORS
# ─────────────────────────────────────────────

func _check_collisions() -> void:
	# Iterate through all objects we collided with in the last move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is Player:
			_attack_player(collider)
			break # Don't attack twice in one frame

func _attack_player(body: Player) -> void:
	# Check if we are physically capable of attacking (not frozen)
	if state == State.FROZEN or state == State.RECOVER:
		return
		
	print("ShadowStalker: Caught player via collision!")
	body.die()
	
	# Stop chasing briefly
	state = State.IDLE

func _process_patrol() -> void:
	if patrol_points.is_empty(): return
	
	var target_node = patrol_points[patrol_index]
	nav_agent.target_position = target_node.global_position
	
	if global_position.distance_to(target_node.global_position) < arrive_distance:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		velocity = Vector2.ZERO 
		anim.play("idle")
	else:
		_move_via_nav(patrol_speed)
		anim.play("walk")

func _process_chase() -> void:
	if not player_target:
		state = State.IDLE
		return
		
	# OPTIMIZATION: Only recalculate path every 6 frames (~10 times per second)
	# Recalculating pathfinding 60 times a second causes massive lag.
	if Engine.get_physics_frames() % 6 == 0:
		nav_agent.target_position = player_target.global_position
	
	_move_via_nav(chase_speed)
	anim.play("walk") 

func _move_via_nav(speed: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
		
	var next_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_pos)
	
	velocity = dir * speed

# ─────────────────────────────────────────────
# SIGNALS & STATE TRANSITIONS
# ─────────────────────────────────────────────

func _on_detect_enter(body: Node2D) -> void:
	if body == player_target and state not in [State.FROZEN, State.RECOVER]:
		state = State.CHASE

func _on_detect_exit(body: Node2D) -> void:
	if body == player_target and state not in [State.FROZEN, State.RECOVER]:
		state = State.IDLE

# _on_capture_entered removed (Logic moved to _check_collisions)

func _on_light_enter(_area: Area2D) -> void:
	state = State.FROZEN
	anim.pause()
	recover_timer.stop() 

func _on_light_exit(_area: Area2D) -> void:
	state = State.RECOVER
	recover_timer.start() 

func _on_recover_timeout() -> void:
	anim.play() 
	if _can_see_player():
		state = State.CHASE
	else:
		state = State.IDLE

# ─────────────────────────────────────────────
# HELPER
# ─────────────────────────────────────────────

func _can_see_player() -> bool:
	if not player_target: return false
	return detection_area.overlaps_body(player_target)
