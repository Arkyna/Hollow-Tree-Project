extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

# You can change this number to control the speed easily
var fade_duration: float = 1.5

func fade_to_black() -> void:
	var tween = create_tween()
	# Change the last argument to your new duration
	tween.tween_property(color_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

func fade_to_normal() -> void:
	var tween = create_tween()
	# Change the last argument here too
	tween.tween_property(color_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
