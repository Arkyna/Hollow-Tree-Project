extends Area2D
class_name Checkpoint

@export var one_time: bool = true
# DRAG THE PARENT NODE (e.g. Stage1_Content) HERE
@export var linked_stage: Node2D 

# --- VISUALS & FEEDBACK ---
@onready var anim_sprite = $AnimatedSprite2D # <--- NEW REFERENCE
@export var feedback_sound: AudioStreamPlayer2D
@export var feedback_particles: CPUParticles2D 

var activated: bool = false

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	# Start with the inactive look
	anim_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	# If already activated and one_time is true, stop here
	if one_time and activated: return
		
	# Check for Player (Ensure your Player script has 'class_name Player')
	if body is Player:
		_activate_checkpoint(body)

func _activate_checkpoint(player: Player) -> void:
	print("Checkpoint: Activated at ", global_position)
	
	# 1. VISUAL: Switch to the active animation
	anim_sprite.play("active") 
	
	# 2. LOGIC: Update Player Spawn
	player.set_checkpoint(global_position)
	
	# 3. MANAGER: Update Stage tracking
	if linked_stage:
		Manager.last_checkpoint_stage = linked_stage
	else:
		if get_parent() is Node2D:
			Manager.last_checkpoint_stage = get_parent()
	
	# 4. FEEDBACK: Sound and Particles
	if feedback_sound: feedback_sound.play()
	if feedback_particles: feedback_particles.emitting = true
	
	# 5. LOCK: Prevent re-triggering
	activated = true
