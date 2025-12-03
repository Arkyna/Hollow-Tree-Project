extends Area2D

@export var destination: Marker2D

# Prevents the teleporter from running twice at the same time
var is_teleporting: bool = false

func _ready() -> void:
	# Connect the signal if not already connected via Editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# 1. STOP if we are already busy
	if is_teleporting:
		return

	# 2. Check if it is the player
	if body.is_in_group("Player") or body is Player:
		if destination:
			start_teleport_sequence(body)
		else:
			print("Error: No destination set for this teleporter!")

func start_teleport_sequence(player: Node2D) -> void:
	# 3. Lock the door
	is_teleporting = true
	
	# 4. Freeze the player & Fade Out
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	await Transition.fade_to_black()
	
	# 5. Move the player (Hidden by the darkness)
	player.global_position = destination.global_position
	
	# --- THE FIX FOR ZIPPING ---
	# We find the camera and force it to snap instantly
	var cam = player.get_node_or_null("Camera2D") 
	# If your camera is named differently (e.g. "PlayerCamera"), change the name above!
	
	if cam:
		cam.reset_smoothing()
	
	# Wait 1 frame to let the camera update its position before we show the screen
	await get_tree().process_frame
	# ---------------------------
	
	# 6. Fade the screen back to normal
	await Transition.fade_to_normal()
	
	# 7. Unfreeze the player
	player.set_physics_process(true)
	
	# 8. Unlock the door (Cooldown)
	await get_tree().create_timer(0.5).timeout
	is_teleporting = false
