class_name BattleBoxBehaviour extends Node

@onready var Box: BattleBox = get_parent().get_parent()
var enabled := false
const CHARS_PER_SEC := 30.0
var typing := false
var type_tween: Tween

func gain_control() -> void:
	enabled = true
	_on_gain_control()

func lose_control() -> void:
	enabled = false
	_on_lose_control()

func _on_gain_control() -> void:
	pass

func _on_lose_control() -> void:
	pass

func _input(event: InputEvent) -> void:
	if !enabled:
		return
	input(event)

func input(_event: InputEvent) -> void:
	pass
	
func type_text(text: String) -> void:
	Box.text_label.text = text
	Box.text_label.visible_characters = 0
	var char_count := Box.text_label.get_total_character_count()
	typing = true
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	type_tween = create_tween()
	type_tween.tween_method(_on_type_step, 0, char_count, char_count / CHARS_PER_SEC)
	type_tween.finished.connect(func(): typing = false)

func _on_type_step(count: int) -> void:
	if count > Box.text_label.visible_characters:
		Box.click.play()
	Box.text_label.visible_characters = count

func skip_typing() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	Box.text_label.visible_characters = -1
	typing = false
