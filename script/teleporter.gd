extends Area2D

@export var destination: Marker2D

func _on_body_entered(body):
	if body.name == "player":
		if destination:
			body.global_position = destination.global_position
		else:
			print("Error: No destination set for this teleporter!")
