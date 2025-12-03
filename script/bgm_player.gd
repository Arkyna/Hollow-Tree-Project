extends AudioStreamPlayer

# Use the Inspector to assign your music file to the 'Stream' property
# Make sure the 'Autoplay' property is checked in the Inspector!

func _ready() -> void:
	# If Autoplay is checked in the Inspector, this line is optional.
	if not playing:
		play()
