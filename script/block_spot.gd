extends Node2D
class_name BlockSpot

var is_open := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collider: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _ready() -> void:
	# Look for triggerSpot inside this node's parent (trigger1, trigger2, etc.)
	var trigger := get_parent().get_node_or_null("triggerSpot")
	if trigger:
		trigger.activated.connect(_on_trigger_activated)
		trigger.deactivated.connect(_on_trigger_deactivated)
	else:
		push_warning("%s: no triggerSpot found in %s" % [name, get_parent().name])

func _on_trigger_activated() -> void:
	open_spot()

func _on_trigger_deactivated() -> void:
	close_spot()

func open_spot() -> void:
	if is_open: return
	is_open = true
	sprite.visible = false
	collider.set_deferred("disabled", true)
	static_body.collision_layer = 0
	static_body.collision_mask = 0
	print("%s opened" % name)

func close_spot() -> void:
	if not is_open: return
	is_open = false
	sprite.visible = true
	collider.set_deferred("disabled", false)
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	print("%s closed" % name)
