extends CanvasLayer

@onready var label: RichTextLabel = %FragmentLabel
@onready var lives_label: RichTextLabel = %LivesLabel # <--- New

func _ready() -> void:
	update_lives(Manager.current_lives)
	update_label(Manager.collected_fragments)
	Manager.fragments_updated.connect(update_label)
	Manager.lives_updated.connect(update_lives)

func update_label(count: int) -> void:
	label.text = "Fragments: " + str(count)
func update_lives(count: int) -> void:
	lives_label.text = "Lives: " + str(count)
