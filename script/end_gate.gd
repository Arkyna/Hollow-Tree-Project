extends StaticBody2D

@export var required_fragments: int = 3
@export var open_texture: Texture2D 

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_open: bool = false

func _ready() -> void:
	_check_gate_condition(Manager.collected_fragments)
	
	Manager.fragments_updated.connect(_check_gate_condition)

func _check_gate_condition(current_count: int) -> void:
	if is_open: return
	
	if current_count >= required_fragments:
		open_gate()

func open_gate() -> void:
	is_open = true
	print("Gate: Opened!")
	
	# 1. Disable Physics (So player can walk through)
	collision.set_deferred("disabled", true)
	
	# 2. Visual Change
	if open_texture:
		# Option A: Swap the image (Solid Door -> Open Door)
		sprite.texture = open_texture
	else:
		# Option B: Fade out (Solid -> Ghostly/Invisible)
		# We use a Tween to make it look smooth
		var tween = create_tween()
		# Fade opacity (alpha) to 0.3 (30% visible) over 1 second
		tween.tween_property(sprite, "modulate:a", 0.2, 1.0)
