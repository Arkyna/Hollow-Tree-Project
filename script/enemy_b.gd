extends CharacterBody2D
class_name ShadowStalker

@export var patrol_speed: float = 45.0
@export var chase_speed: float = 80.0
@export var arrive_distance: float = 8.0
@export var freeze_delay_ms: int = 500  # half second recover time

@export var patrol_parent: NodePath = NodePath("")
@export var player_path: NodePath = NodePath("")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var light_area: Area2D = $LightCheckArea

enum State { IDLE, CHASE, FROZEN, RECOVER }
var state: State = State.IDLE

var player: Node2D
var patrol_points: Array[Node2D] = []
var patrol_index: int = 0
var freeze_until: int = 0


func _ready() -> void:
	# Resolve player
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	else:
		player = get_tree().get_first_node_in_group("Player")

	# Patrol points
	var parent = null
	if patrol_parent != NodePath(""):
		parent = get_node_or_null(patrol_parent)
	elif has_node("PatrolPoints"):
		parent = $PatrolPoints

	if parent:
		for c in parent.get_children():
			if c is Node2D:
				patrol_points.append(c)

	if patrol_points.is_empty():
		var fallback := Node2D.new()
		fallback.global_position = global_position
		add_child(fallback)
		patrol_points.append(fallback)

	# Connect signals
	detection_area.connect("body_entered", Callable(self, "_on_detect_enter"))
	detection_area.connect("body_exited", Callable(self, "_on_detect_exit"))
	light_area.connect("area_entered", Callable(self, "_on_light_enter"))
	light_area.connect("area_exited", Callable(self, "_on_light_exit"))

	nav.path_max_distance = 1024
	nav.target_desired_distance = 1.0
	anim.play("idle")  # starting animation



func _physics_process(delta: float) -> void:
	match state:

		State.FROZEN:
			velocity = Vector2.ZERO
			return

		State.RECOVER:
			if Time.get_ticks_msec() >= freeze_until:
				# Timer finished: choose state
				if _player_visible():
					state = State.CHASE
				else:
					state = State.IDLE
			velocity = Vector2.ZERO
			return

		State.IDLE:
			_do_patrol(delta)

		State.CHASE:
			_do_chase(delta)

	move_and_slide()



# ─────────────────────────────────────────────
# PATROL
# ─────────────────────────────────────────────
func _do_patrol(delta: float) -> void:
	var target := patrol_points[patrol_index].global_position
	nav.target_position = target

	_move_towards(nav.get_next_path_position(), patrol_speed)

	if global_position.distance_to(target) <= arrive_distance:
		patrol_index = (patrol_index + 1) % patrol_points.size()

	anim.play("walk")



# ─────────────────────────────────────────────
# CHASE
# ─────────────────────────────────────────────
func _do_chase(delta: float) -> void:
	if player == null:
		state = State.IDLE
		return

	nav.target_position = player.global_position
	_move_towards(nav.get_next_path_position(), chase_speed)

	anim.play("walk")



func _move_towards(next_pos: Vector2, speed: float) -> void:
	var dir := (next_pos - global_position).normalized()
	velocity = dir * speed



# ─────────────────────────────────────────────
# STATE CHANGES — DETECTION
# ─────────────────────────────────────────────
func _on_detect_enter(body: Node) -> void:
	if state in [State.FROZEN, State.RECOVER]:
		return
	if body.is_in_group("Player"):
		state = State.CHASE


func _on_detect_exit(body: Node) -> void:
	if state in [State.FROZEN, State.RECOVER]:
		return
	if body.is_in_group("Player"):
		state = State.IDLE



# ─────────────────────────────────────────────
# STATE CHANGES — LIGHT
# ─────────────────────────────────────────────
func _on_light_enter(area: Area2D) -> void:
	# Entered flashlight zone → instant freeze
	state = State.FROZEN
	velocity = Vector2.ZERO

	# freeze animation but keep current frame (A2)
	anim.pause()

	# set recovery timer
	freeze_until = Time.get_ticks_msec() + freeze_delay_ms



func _on_light_exit(area: Area2D) -> void:
	# Left the light → but cannot immediately chase
	state = State.RECOVER
	velocity = Vector2.ZERO
	# stay frozen in place, animation still paused
	# movement allowed only after freeze_until



# ─────────────────────────────────────────────
# HELPER
# ─────────────────────────────────────────────
func _player_visible() -> bool:
	if player == null:
		return false
	return detection_area.get_overlapping_bodies().has(player)
