extends Area2D
class_name Checkpoint

@export var one_time: bool = true           # if true, activates only once
@export var effect_node_path: NodePath = NodePath("") # optional visual node to toggle
@export var sound_node_path: NodePath = NodePath("")  # optional AudioStreamPlayer

var activated: bool = false

func _ready() -> void:
	monitoring = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not body:
		return
	if not body.is_in_group("Player"):
		return

	# set player checkpoint
	if body.has_method("set_checkpoint"):
		body.set_checkpoint(global_position)  # the player stores checkpoint_pos
	else:
		print("Checkpoint: player has no set_checkpoint() method")

	# UI/Audio/Visual feedback
	_play_feedback()

	# optionally mark as activated so it won't trigger again
	if one_time:
		activated = true
		monitoring = false
		set_deferred("collision_layer", 0)  # disable collisions so it won't retrigger accidentally

func _play_feedback() -> void:
	# visual effect
	if effect_node_path != NodePath(""):
		var n = get_node_or_null(effect_node_path)
		if n:
			if n.has_method("play"):
				n.play()
			elif n.has_method("show"):
				n.show()

	# sound effect
	if sound_node_path != NodePath(""):
		var s = get_node_or_null(sound_node_path)
		if s and s is AudioStreamPlayer:
			s.play()

	# quick print for debug
	print("Checkpoint activated at ", global_position)
