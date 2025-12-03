extends Node2D
class_name BlockSpot

# OPTIMIZATION: Direct Reference
# Drag your TriggerSpot node into this slot in the Inspector.
# No more searching by string names!
@export var trigger_node: TriggerSpot

@onready var sprite: Sprite2D = $Sprite2D
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collider: CollisionShape2D = $StaticBody2D/CollisionShape2D

var is_open: bool = false

func _ready() -> void:
	if trigger_node:
		# Connect signals directly to the referenced node
		trigger_node.activated.connect(open_spot)
		trigger_node.deactivated.connect(close_spot)
		
		# Sync state immediately (in case trigger is already active)
		if trigger_node.is_active:
			open_spot()
	else:
		push_warning("BlockSpot '%s' is missing a linked TriggerNode!" % name)

func open_spot() -> void:
	if is_open: return
	is_open = true
	
	sprite.visible = false
	collider.set_deferred("disabled", true)
	# Clear collision layers to ensure absolutely nothing hits it
	static_body.collision_layer = 0
	static_body.collision_mask = 0
	
	print("%s opened" % name)

func close_spot() -> void:
	if not is_open: return
	is_open = false
	
	sprite.visible = true
	collider.set_deferred("disabled", false)
	# Restore collision (Assuming Layer 1, change if your walls are different)
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	
	print("%s closed" % name)
