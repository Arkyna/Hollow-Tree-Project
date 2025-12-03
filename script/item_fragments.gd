extends Area2D
class_name ItemFragment

@export_group("Settings")
@export var is_fragment: bool = true
@export var item_type: String = "coin"

@export_group("Feedback (Optional)")
# Use actual node references if they are children, or NodePaths if external
@export var pickup_sound_node: AudioStreamPlayer2D 
@export var pickup_effect_node: Node2D 

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	# 1. Trigger Visual/Audio Feedback
	_play_pickup_feedback()
	
	# 2. Handle Logic (The Hybrid Approach)
	var handled = false
	
	# PRIORITY A: Check the new Global Autoload "Manager"
	# (You said you named the Autoload "Manager" in Project Settings)
	if has_node("/root/Manager"):
		# Accessing the autoload directly by name
		_call_manager_methods(Manager)
		handled = true
		
	# PRIORITY B: Fallback to the old "DemoManager" Group
	elif not handled:
		var dm = get_tree().get_first_node_in_group("DemoManager")
		if dm:
			print("[Fragment] Found legacy DemoManager via Group")
			_call_manager_methods(dm)
			handled = true
			
	# 3. Destroy Object
	_destroy_self()

func _call_manager_methods(target_manager: Node) -> void:
	if is_fragment:
		if target_manager.has_method("collect_fragment"):
			target_manager.collect_fragment()
		else:
			push_error("[Fragment] Manager found but missing 'collect_fragment()'")
	else:
		if target_manager.has_method("add_item"):
			target_manager.add_item() # You can pass item_type here if your manager supports it
		else:
			push_error("[Fragment] Manager found but missing 'add_item()'")

func _play_pickup_feedback() -> void:
	# Play Sound
	if pickup_sound_node:
		pickup_sound_node.play()
	
	# Play/Show Effect
	if pickup_effect_node:
		pickup_effect_node.show()
		if pickup_effect_node.has_method("play"):
			pickup_effect_node.play()

func _destroy_self() -> void:
	# CRITICAL FIX:
	# If we delete the node immediately, the sound won't play.
	# We hide the item, disable collision, wait for sound, THEN delete.
	
	hide() # Make invisible
	set_deferred("monitoring", false) # Stop detecting collisions
	
	if pickup_sound_node and pickup_sound_node.playing:
		await pickup_sound_node.finished
	
	queue_free()
