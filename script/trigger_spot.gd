extends Node2D

class_name TriggerSpot

signal activated
signal deactivated

var bodies: int = 0
var is_active: bool = false

@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _on_body_entered(b: Node2D) -> void:
	bodies += 1
	check_is_activated()

func _on_body_exited(b: Node2D) -> void:
	bodies -= 1
	check_is_activated()

func check_is_activated() -> void:
	if bodies > 0 and not is_active:
		is_active = true
		activated.emit()
		print("activated (single-use)")
