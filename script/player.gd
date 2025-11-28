extends CharacterBody2D
class_name Player

# movement
var walk_speed: float = 80.0
var sprint_speed: float = 140.0

# sprint state
var can_sprint: bool = true
var is_sprinting: bool = false

var direction: Vector2 = Vector2.ZERO

@onready var anim := $AnimatedSprite2D
@onready var sprint_timer := $SprintTimer  # pastikan node Timer bernama "SprintTimer"

func _ready() -> void:
	# Optional: pastikan properti timer
	sprint_timer.one_shot = true
	sprint_timer.autostart = false
	anim.play("frontIdle")
	
	var dm = get_tree().get_first_node_in_group("DemoManager")  # OR use get_node("...") if you prefer paths
	if dm:
		dm.register_player(self)

func _physics_process(delta) -> void:
	handle_input()
	move_and_slide()
	check_enemy_collision()

func handle_input() -> void:
	# baca arah (belum dinormalisasi)
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	)
	if direction != Vector2.ZERO:
		var target_angle := direction.angle()
		_update_flashlight_smooth(target_angle)

	var is_moving := direction != Vector2.ZERO
	var pressing_sprint := Input.is_action_pressed("sprint")

	# jika pemain melepas tombol sprint, izinkan sprint lagi
	if not pressing_sprint:
		can_sprint = true

	# mulai sprint hanya sekali saat kondisi terpenuhi
	if pressing_sprint and is_moving and can_sprint:
		if not is_sprinting:
			is_sprinting = true
			if sprint_timer.is_stopped():
				sprint_timer.start()
	else:
		# kalau tidak menekan sprint, hentikan sprint flag (tapi jangan set can_sprint di sini)
		is_sprinting = false

	# set speed berdasarkan flag
	var current_speed: float = sprint_speed if is_sprinting else walk_speed

	# movement
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		play_anim("idle")
	else:
		velocity = direction.normalized() * current_speed
		play_anim("move")

func play_anim(String) -> void:
	if direction == Vector2.ZERO:
		match anim.animation:
			"side", "frontIdle", "back":
				anim.play(anim.animation)
		return

	if abs(direction.x) > abs(direction.y):
		anim.flip_h = direction.x < 0
		anim.play("side")
	elif direction.y > 0:
		anim.flip_h = false
		anim.play("frontIdle")
	else:
		anim.flip_h = false
		anim.play("back")

# Sambungkan SprintTimer.timeout() -> _on_sprint_timer_timeout()
func _on_SprintTimer_timeout() -> void:
	# sprint habis — matikan sprint dan blok lagi sampai tombol dilepas
	is_sprinting = false
	can_sprint = false

func check_enemy_collision() -> void:
	for i in range(get_slide_collision_count()):
		var collider := get_slide_collision(i).get_collider()
		if collider is Enemy:
			die()
			break
# in Player.gd
var checkpoint_pos: Vector2 = Vector2.ZERO

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	# optional: show small UI text or play sound
	print("Checkpoint set to ", checkpoint_pos)

func respawn_to_checkpoint() -> void:
	global_position = checkpoint_pos
	velocity = Vector2.ZERO
	# optional: invulnerable frames / blink

func _update_flashlight_smooth(target_angle: float) -> void:
	var current: float = $Flashlight.rotation
	var diff := _angle_difference(current, target_angle)

	# Snap instantly if angle change is large (player whips around)
	if diff > deg_to_rad(60):
		$Flashlight.rotation = target_angle
		return

	# Otherwise smooth follow
	var new_angle: float = lerp_angle(current, target_angle, 0.3)
	$Flashlight.rotation = new_angle

func _angle_difference(a: float, b: float) -> float:
	# Godot 4 safe angle difference
	var diff := wrapf(b - a, -PI, PI)
	return abs(diff)

func die() -> void:
	print("Player touched enemy — game over.")
	call_deferred("_go_to_game_over")

func _process(_delta):
	var overlay = get_tree().get_first_node_in_group("Darkness")
	if overlay:
		overlay.set_light_position(global_position)
		overlay.set_light_angle($Flashlight.rotation)

func _go_to_game_over() -> void:
	get_tree().change_scene_to_file("res://scene/game_over.tscn")
