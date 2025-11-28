extends CharacterBody2D
class_name Enemy

@export var speed: float = 60.0
@export var chase_speed_mult: float = 1.5
@export var arrive_distance: float = 8.0

@export var player: NodePath = NodePath("")        # optional: set manually
@export var game_manager_path: NodePath = NodePath("") # optional
@export var patrol_parent: NodePath = NodePath("") # e.g. path to a PatrolPoints Node2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var _player_node: Node2D = null
var _game_manager: Node = null
var patrol_positions: Array[Vector2] = []
var patrol_index: int = 0

enum State { PATROL, CHASE, RETURN }
var state: State = State.PATROL

# children (optional)
var detection_area: Area2D = null
var capture_area: Area2D = null

func _ready() -> void:
	# --- player resolution ---
	if player != NodePath(""):
		_player_node = get_node_or_null(player) as Node2D
	else:
		var p = get_tree().get_first_node_in_group("Player")
		if p and p is Node2D:
			_player_node = p

	# --- game manager (autoload recommended) ---
	if game_manager_path != NodePath(""):
		_game_manager = get_node_or_null(game_manager_path)
	else:
		_game_manager = get_node_or_null("/root/GameManager")

	# --- patrol positions (cache stable Vector2s) ---
	var parent_node: Node = null
	if patrol_parent != NodePath(""):
		parent_node = get_node_or_null(patrol_parent)
	elif has_node("PatrolPoints"):
		parent_node = $PatrolPoints

	if parent_node != null:
		for child in parent_node.get_children():
			if child is Node2D:
				patrol_positions.append(child.global_position)

	if patrol_positions.size() == 0:
		# single-point fallback
		patrol_positions.append(global_position)

	patrol_index = 0

	# --- detection/capture areas ---
	if has_node("DetectionArea"):
		detection_area = $DetectionArea
		detection_area.connect("body_entered", Callable(self, "_on_detection_body_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_detection_body_exited"))

	if has_node("CaptureZone"):
		capture_area = $CaptureZone
		capture_area.connect("body_entered", Callable(self, "_on_capture_body_entered"))

	nav_agent.target_desired_distance = 1.0
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	match state:
		State.PATROL: _patrol(delta)
		State.CHASE:  _chase(delta)
		State.RETURN: _return_to_patrol(delta)

# ---------- behaviors ----------
func _patrol(delta: float) -> void:
	var target_pos: Vector2 = patrol_positions[patrol_index]
	nav_agent.target_position = target_pos
	_move_along_agent(speed)
	if global_position.distance_to(target_pos) <= arrive_distance:
		patrol_index = (patrol_index + 1) % patrol_positions.size()

func _chase(delta: float) -> void:
	if _player_node == null:
		state = State.RETURN
		return
	nav_agent.target_position = _player_node.global_position
	_move_along_agent(speed * chase_speed_mult)

func _return_to_patrol(delta: float) -> void:
	var target_pos: Vector2 = patrol_positions[patrol_index]
	nav_agent.target_position = target_pos
	_move_along_agent(speed)
	if global_position.distance_to(target_pos) <= arrive_distance:
		state = State.PATROL

func _move_along_agent(current_speed: float) -> void:
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var dir: Vector2 = Vector2.ZERO
	if next_pos != Vector2.ZERO:
		dir = (next_pos - global_position).normalized()
	else:
		var fallback := nav_agent.target_position - global_position
		if fallback.length() > 0.0:
			dir = fallback.normalized()
	velocity = dir * current_speed
	move_and_slide()

# ---------- signals ----------
func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		state = State.CHASE

func _on_detection_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		state = State.RETURN

func _on_capture_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if _game_manager != null and _game_manager.has_method("damage_player"):
			_game_manager.damage_player(self)
		else:
			# fallback: try to call Player.respawn_to_checkpoint if available
			if body.has_method("respawn_to_checkpoint"):
				body.respawn_to_checkpoint()
		state = State.RETURN
		
		
#		ADD NEW TYPE OF ENEMY: WEEPING ANGLE TYPE
#		ADDING SAVE SPOT
