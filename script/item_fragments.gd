extends Area2D
class_name ItemFragment

@export var is_fragment: bool = true
@export var item_type: String = "coin"
@export var pickup_sound_path: NodePath = NodePath("")
@export var pickup_effect_path: NodePath = NodePath("")

func _ready() -> void:
	monitoring = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body == null:
		
		return
	if not body.is_in_group("Player"):
		
		return
	
	_play_pickup_feedback()

	# ---- FIND DEMO MANAGER (SIMPLE + BULLETPROOF) ----
	var dm: Node = null

	# 1) Try group lookup first
	dm = get_tree().get_first_node_in_group("DemoManager")

	# 2) If still null, try exact-scene-path lookup (root child)
	if dm == null:
		var cs := get_tree().get_current_scene()
		if cs and cs.has_node("gameManager"):
			dm = cs.get_node("DemoManager")

	# 3) If STILL null, fallback to optional autoload (if user ever uses it)
	if dm == null:
		dm = get_node_or_null("/root/GameManager")
	if dm == null:
		dm = get_node_or_null("/root/DemoManager")

	print("[Fragment DEBUG] dm =", dm)

	# ---- CALL MANAGER ----
	if dm != null:
		if is_fragment:
			if dm.has_method("collect_fragment"):
				print("[Fragment DEBUG] calling collect_fragment()")
				dm.collect_fragment()
			else:
				print("[ERROR] manager missing collect_fragment()")
		else:
			if dm.has_method("add_item"):
				print("[Fragment DEBUG] calling add_item()")
				dm.add_item()
			else:
				print("[ERROR] manager missing add_item()")
	else:
		print("[ERROR] No DemoManager found in scene.")

	queue_free()


func _play_pickup_feedback() -> void:
	if pickup_sound_path != NodePath(""):
		var s := get_node_or_null(pickup_sound_path)
		if s and s is AudioStreamPlayer:
			s.play()

	if pickup_effect_path != NodePath(""):
		var fx := get_node_or_null(pickup_effect_path)
		if fx:
			if fx.has_method("play"):
				fx.play()
			elif fx.has_method("show"):
				fx.show()
