extends Area2D
class_name Checkpoint

@export var one_time: bool = true
# DRAG THE PARENT NODE (e.g. Stage1_Content) HERE
@export var linked_stage: Node2D 

@export var feedback_sound: AudioStreamPlayer2D
@export var feedback_particles: CPUParticles2D 

var activated: bool = false

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if one_time and activated: return
		
	if body is Player:
		_activate_checkpoint(body)

func _activate_checkpoint(player: Player) -> void:
	print("Checkpoint: Activated at ", global_position)
	player.set_checkpoint(global_position)
	
	# --- NEW: Tell Manager which stage this is ---
	if linked_stage:
		Manager.last_checkpoint_stage = linked_stage
	else:
		# Fallback: Try to guess if the user forgot to assign it
		# Checks if the parent is a Node2D (likely the Stage holder)
		if get_parent() is Node2D:
			Manager.last_checkpoint_stage = get_parent()
	# ---------------------------------------------
	
	if feedback_sound: feedback_sound.play()
	if feedback_particles: feedback_particles.emitting = true
	
	activated = true
