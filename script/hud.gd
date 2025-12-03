extends CanvasLayer

@onready var label: RichTextLabel = %FragmentLabel
@onready var lives_label: RichTextLabel = %LivesLabel

func _ready() -> void:
	# 1. Update initial values from the Manager
	if Manager:
		update_lives(Manager.current_lives)
		update_label(Manager.collected_fragments)
		
		# 2. Connect signals
		Manager.fragments_updated.connect(update_label)
		Manager.lives_updated.connect(update_lives)

func update_label(count: int) -> void:
	# Display current count out of the total required amount (e.g., "1 / 3")
	var fragment_text = "Fragments: %d / %d" % [count, Manager.FRAGMENTS_REQUIRED]
	
	# Optional: Highlight green when all are collected
	if count >= Manager.FRAGMENTS_REQUIRED:
		# Assuming RichTextLabel can handle BBCode:
		label.text = "[color=green]%s[/color]" % fragment_text
	else:
		label.text = fragment_text
		
func update_lives(count: int) -> void:
	lives_label.text = "Lives: " + str(count)
