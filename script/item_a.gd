extends Area2D

@export var manager_path: NodePath
@onready var game_manager = get_node(manager_path)

func _ready():
	monitoring = true
	monitorable = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		print("Item ready, body_entered connected")

func _on_body_entered(body):
	print("BODY ENTERED:", body.name)
	if body.is_in_group("Player"):
		print("Player detected. Item picked.")
		game_manager.add_item()
		queue_free()
