extends Area2D
class_name Checkpoint

@export var one_time: bool = true

# Use direct Node references (Drag and drop in Inspector)
@export var feedback_sound: AudioStreamPlayer2D
@export var feedback_particles: CPUParticles2D # Or Node2D

var activated: bool = false

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Prevent re-triggering if one_time is set
	if one_time and activated:
		return
		
	if body is Player: # Checks class_name Player
		_activate_checkpoint(body)

func _activate_checkpoint(player: Player) -> void:
	print("Checkpoint: Activated at ", global_position)
	
	# 1. Save position to Player
	player.set_checkpoint(global_position)
	
	# 2. Visuals/Audio
	if feedback_sound:
		feedback_sound.play()
	
	if feedback_particles:
		feedback_particles.emitting = true
	
	# 3. Lock it
	activated = true
	
	# Optional: Change sprite frame (e.g., raise a flag)
	# $AnimatedSprite2D.play("active")
