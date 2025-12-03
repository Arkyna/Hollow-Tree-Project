extends Area2D

@export var destination: Marker2D

# --- OPTIMIZATION: Room Management ---
# Drag the "EnemyHolder" node of the NEXT room here.
@export var stage_group_to_enable: Node2D 

# Drag the "EnemyHolder" node of the CURRENT room here.
@export var stage_group_to_disable: Node2D 
# -------------------------------------

# Prevents the teleporter from running twice at the same time
var is_teleporting: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if is_teleporting: return

	if body.is_in_group("Player") or body is Player:
		if destination:
			start_teleport_sequence(body)
		else:
			print("Error: No destination set for this teleporter!")

func start_teleport_sequence(player: Node2D) -> void:
	is_teleporting = true
	
	# 1. Freeze player & Fade Out
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	await Transition.fade_to_black()
	
	# 2. OPTIMIZATION: Swap Active Stages
	# We do this while the screen is black so the player doesn't see enemies popping in/out
	if stage_group_to_disable:
		# "Disabled" stops _process, _physics_process, and input for all children
		stage_group_to_disable.process_mode = Node.PROCESS_MODE_DISABLED
		# Optional: Hide them to save rendering cost too
		stage_group_to_disable.visible = false
		
	if stage_group_to_enable:
		# "Inherit" wakes them up (assuming the scene root is active)
		stage_group_to_enable.process_mode = Node.PROCESS_MODE_INHERIT
		stage_group_to_enable.visible = true
	
	# 3. Teleport Position
	player.global_position = destination.global_position
	
	# 4. Camera Fix (Prevent Zipping)
	var cam = player.get_node_or_null("Camera2D") 
	if cam:
		cam.reset_smoothing()
	
	await get_tree().process_frame
	
	# 5. Fade In & Unlock
	await Transition.fade_to_normal()
	player.set_physics_process(true)
	
	await get_tree().create_timer(0.5).timeout
	is_teleporting = false
