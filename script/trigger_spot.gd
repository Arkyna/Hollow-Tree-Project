extends Node2D
class_name TriggerSpot

signal activated
signal deactivated

# SETTINGS
@export var one_shot: bool = false # If true, never deactivates once triggered

# STATE
var active_bodies: int = 0
var is_active: bool = false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# OPTIMIZATION: Check group to ignore random debris/enemies triggers
	if body.is_in_group("Player") or body is Player:
		active_bodies += 1
		_update_state()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body is Player:
		active_bodies -= 1
		_update_state()

func _update_state() -> void:
	# If one_shot is on and we are already active, do nothing
	if one_shot and is_active:
		return

	# If we have bodies inside, we should be active
	var should_be_active = active_bodies > 0
	
	if should_be_active and not is_active:
		is_active = true
		activated.emit()
		print("Trigger: Activated")
		
	elif not should_be_active and is_active:
		is_active = false
		deactivated.emit()
		print("Trigger: Deactivated")
