extends CanvasLayer

# DialogBox.gd — Godot 4 GDScript
# Basic features: queue lines, typewriter, skip/fast-forward, speaker name, optional portrait, choices.

@export var chars_per_second: float = 45.0
@export var auto_advance_delay: float = 0.8  # wait after line finished before allowing next

# nodes
@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/VBoxContainer/HBoxContainer/Label
@onready var portrait: TextureRect = $Panel/VBoxContainer/HBoxContainer/TextureRect
@onready var text_label: RichTextLabel = $Panel/VBoxContainer/RichTextLabel
@onready var next_button: Button = $Panel/HBoxContainer/NextButton
@onready var skip_button: Button = $Panel/HBoxContainer/SkipButton

# state
var queue: Array = []
var current_line: String = ""
var current_speaker: String = ""
var current_portrait: Texture2D = null
var typing: bool = false
var _type_task: Callable = null
var _on_finish: Callable = null
var choices_callback: Callable = null

func _ready() -> void:
	panel.visible = false
	portrait.visible = false
	text_label.bbcode_enabled = true
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func show_dialog(lines: Array, on_finish: Callable = null) -> void:
	"""
	lines: array of dictionaries or strings.
	If string: plain text.
	If dictionary: { "text":"...", "speaker":"Name", "portrait":Texture2D, "choices": [ {"text":"Yes", "id":1}, ... ] }
	"""
	_on_finish = on_finish
	queue.clear()
	for item in lines:
		queue.append(item)
	_panel_open()
	_process_next()

func _panel_open() -> void:
	panel.visible = true
	get_tree().set_input_as_handled()  # avoid accidental input
	# pause game? Optional: get_tree().paused = true  (we won't pause by default)

func _panel_close() -> void:
	panel.visible = false
	# optional: get_tree().paused = false
	if _on_finish != null:
		_on_finish.call_deferred()

func _process_next() -> void:
	if queue.size() == 0:
		_panel_close()
		return

	var item = queue.pop_front()
	if typeof(item) == TYPE_STRING:
		current_line = item
		current_speaker = ""
		current_portrait = null
	else:
		current_line = item.get("text", "")
		current_speaker = item.get("speaker", "")
		current_portrait = item.get("portrait", null)
		var choices = item.get("choices", null)
		if choices:
			# show line first then show choices
			_start_typing_and_then_show_choices(current_line, choices)
			return

	# update UI
	_update_header()
	_start_typing(current_line)

func _update_header() -> void:
	if current_speaker == "":
		speaker_label.visible = false
	else:
		speaker_label.visible = true
		speaker_label.text = current_speaker

	if current_portrait:
		portrait.texture = current_portrait
		portrait.visible = true
	else:
		portrait.visible = false

func _start_typing_and_then_show_choices(text: String, choices: Array) -> void:
	_start_typing(text, funcref(self, "_show_choices", [choices]))

func _start_typing(text: String, after: Callable = null) -> void:
	# stop previous
	if typing and _type_task != null:
		_type_task.call_deferred() # noop; just ensure no concurrency
	typing = true
	text_label.clear()
	# typewriter loop
	var wait_time = 1.0 / max(chars_per_second, 1.0)
	var idx = 0
	while idx < text.length():
		# append next char or next utf-8 char properly
		var ch = text.substr(idx, 1)
		text_label.append_bbcode(ch.escapes())
		yield(get_tree().create_timer(wait_time), "timeout")
		idx += 1
	# finished
	typing = false
	# small delay to avoid instant fastforward abuse
	yield(get_tree().create_timer(auto_advance_delay), "timeout")
	if after != null:
		after.call()
	else:
		# wait for next; enable next button visually if needed
		pass

func _show_choices(choices: Array) -> void:
	# Clear any leftover text and show choice buttons beneath. Simpler: use accept dialog or temporary buttons.
	# For the demo, we'll just print choices and pick the first if player presses Next.
	# You can expand this to spawn Buttons dynamically.
	print("CHOICES:", choices)
	# store callback to handle selection — demo picks first on next for now
	choices_callback = func(idx):
		print("Choice selected", idx)
		_process_next()
	# For immediate demo: wait for next to be pressed to confirm index 0 (you can expand)
	# (Implement dynamic choice UI later if needed.)

func _on_next_pressed() -> void:
	if typing:
		# finish the line instantly
		_finish_current_line()
	else:
		_process_next()

func _on_skip_pressed() -> void:
	# skip entire dialog
	queue.clear()
	_panel_close()

func _finish_current_line() -> void:
	# immediately show full text (dump the remainder)
	# naive approach: set full text
	text_label.clear()
	text_label.append_bbcode(current_line.escapes())
	typing = false
	# allow immediate proceed after delay
	yield(get_tree().create_timer(auto_advance_delay), "timeout")
