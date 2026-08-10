extends RichTextLabel
class_name AdvancedTextTyper

@export var click_path: NodePath
@export var interval: float = 0.045

@onready var click_sound: AudioStreamPlayer = get_node_or_null(click_path)

var currentfont: Font
var entire_text_bbcode: String = ""
var typing := false
var pauses: Array = []

signal started_typing(line_index: int)
signal expression_set(expr: Array)
signal finished_all_texts
signal confirm

func _ready() -> void:
	bbcode_enabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		confirm.emit()

## Override in a subclass (like EnemySpeech) to swap which AudioStreamPlayer plays per character.
func _get_click_sound() -> AudioStreamPlayer:
	return click_sound

func type_buffer(dialogues: Dialogues, index: int) -> void:
	var line: DialogueLine = dialogues.dialogues[index]
	if currentfont:
		add_theme_font_override("normal_font", currentfont)
	text = entire_text_bbcode + line.text
	visible_characters = 0
	var char_count := get_total_character_count()
	typing = true

	var pause_map := {}
	for p: PauseMarker in pauses:
		pause_map[p.char_index] = p.duration

	var skip := false
	var skip_callable := func(): skip = true
	confirm.connect(skip_callable)

	for c in char_count:
		if skip:
			visible_characters = char_count
			break
		visible_characters = c + 1
		var sound := _get_click_sound()
		if sound:
			sound.play()
		if pause_map.has(c):
			await get_tree().create_timer(pause_map[c]).timeout
		else:
			await get_tree().create_timer(interval).timeout

	confirm.disconnect(skip_callable)
	typing = false
