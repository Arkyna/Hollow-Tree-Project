extends CharacterBody2D
class_name Enemy

# ... (Exports remain the same) ...
@export_group("Movement")
@export var speed: float = 60.0
@export var chase_speed_mult: float = 1.5
@export var arrive_distance: float = 10.0
@export_group("Patrol")
@export var patrol_parent: Node2D 

# ... (Nodes remain the same) ...
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea 
@onready var capture_area: Area2D = $CaptureZone 
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D 

enum State { PATROL, CHASE, RETURN }
var state: State = State.PATROL

# FIX: Change type from 'Player' to 'Node2D' to break cycle
var player_ref: Node2D = null 

var patrol_positions: Array[Vector2] = []
var patrol_index: int = 0

func _ready() -> void:
	# ... (Setup code remains the same) ...
	if patrol_parent:
		for child in patrol_parent.get_children():
			if child is Node2D:
				patrol_positions.append(child.global_position)
	else:
		patrol_positions.append(global_position)

	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)
	capture_area.body_entered.connect(_on_capture_entered)

func _physics_process(_delta: float) -> void:
	match state:
		State.PATROL: _state_patrol()
		State.CHASE:  _state_chase()
		State.RETURN: _state_return()
	move_and_slide()

# ... (Movement logic remains the same) ...
func _state_patrol() -> void:
	if patrol_positions.is_empty(): return
	var target = patrol_positions[patrol_index]
	nav_agent.target_position = target
	_move_towards_target(speed)
	if global_position.distance_to(target) < arrive_distance:
		patrol_index = (patrol_index + 1) % patrol_positions.size()

func _state_chase() -> void:
	if not player_ref:
		state = State.RETURN
		return
	nav_agent.target_position = player_ref.global_position
	_move_towards_target(speed * chase_speed_mult)

func _state_return() -> void:
	var target = patrol_positions[patrol_index]
	nav_agent.target_position = target
	_move_towards_target(speed)
	if global_position.distance_to(target) < arrive_distance:
		state = State.PATROL

func _move_towards_target(current_speed: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		return
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * current_speed
	update_animation(direction)

func update_animation(move_dir: Vector2) -> void:
	if move_dir == Vector2.ZERO:
		anim.play("idleFrontEnemy")
		return
	if abs(move_dir.x) > abs(move_dir.y):
		anim.play("sideEnemy")
		anim.flip_h = move_dir.x < 0
	elif move_dir.y > 0:
		anim.play("idleFrontEnemy") 
		anim.flip_h = false
	else:
		anim.play("backEnemy")
		anim.flip_h = false

# --- SIGNALS (FIXED) ---

func _on_detection_entered(body: Node2D) -> void:
	# FIX: Use Group check instead of 'is Player'
	if body.is_in_group("Player"): 
		player_ref = body
		state = State.CHASE

func _on_detection_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		state = State.RETURN

func _on_capture_entered(body: Node2D) -> void:
	# FIX: Use Group check instead of 'is Player'
	if body.is_in_group("Player"):
		print("Enemy: Caught player!")
		if body.has_method("die"):
			body.die()
		state = State.RETURN
