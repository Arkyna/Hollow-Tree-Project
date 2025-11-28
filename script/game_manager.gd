# GameManager.gd  (attach to the same Node that had your old manager)
extends Node
class_name GameManager

@export var fragments_needed: int = 3
@export var initial_hp: int = 3

var items: int = 0
var fragments: int = 0
var player_node: Node = null
var player_hp: int = 0
var checkpoint_pos: Vector2 = Vector2.ZERO

@onready var items_count: Label = $CanvasLayer/ItemLabel
@onready var fragments_label: Label = $CanvasLayer/FragmentsLabel
@onready var hp_label: Label = $CanvasLayer/HPLabel
@onready var game_over_label: Label = $CanvasLayer.get_node_or_null("GameOverLabel")

func _ready() -> void:
	player_hp = initial_hp
	_update_ui()

# ---------- registration / checkpoint ----------
func register_player(node: Node) -> void:
	player_node = node
	if player_node and player_node is Node2D:
		checkpoint_pos = player_node.global_position

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	print("Checkpoint set to ", checkpoint_pos)

func respawn_player() -> void:
	if not player_node:
		player_node = get_tree().get_first_node_in_group("Player")
	if player_node:
		if player_node.has_method("respawn_to_checkpoint"):
			player_node.respawn_to_checkpoint()
		elif player_node is Node2D:
			player_node.global_position = checkpoint_pos

# ---------- items & fragments ----------
func add_item() -> void:
	items += 1
	_update_ui()
	print("Item collected. total:", items)

func collect_fragment() -> void:
	fragments += 1
	_update_ui()
	print("Fragment collected: %d / %d" % [fragments, fragments_needed])
	if fragments >= fragments_needed:
		_on_all_fragments_collected()

func _on_all_fragments_collected() -> void:
	print("All fragments collected! Triggering demo end.")
	var t = get_node_or_null("EndingTrigger")
	if t and t.has_method("activate"):
		t.activate()
	# optional visual reveal - safe call if CanvasLayer exists
	if items_count:
		# show a simple message in Items label (temporary)
		items_count.text = "All fragments collected!"
	# you can expand with a dedicated label/scene transition here

# ---------- HP & damage ----------
# Accept optional captor arg so enemy can call damage_player(self)
func damage_player(captor: Node = null) -> void:
	player_hp -= 1
	if player_hp < 0:
		player_hp = 0
	_update_ui()
	print("Player damaged. HP:", player_hp)
	if player_hp > 0:
		# respawn player and give a short invulnerability via player's method if present
		respawn_player()
	else:
		_game_over()

func _game_over() -> void:
	print("GAME OVER")
	if game_over_label:
		game_over_label.show()
	get_tree().paused = true

# ---------- UI helpers ----------
func _update_ui() -> void:
	if items_count:
		items_count.text = "Items: %d" % items
	if fragments_label:
		fragments_label.text = "Fragments: %d / %d" % [fragments, fragments_needed]
	if hp_label:
		hp_label.text = "HP: %d" % player_hp
