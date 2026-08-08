extends BattleBoxBehaviour

var action_text := {
	0: "* You ready your weapon.",
	1: "* You check yourself.",
	2: "* You check your items.",
	3: "* You plead for mercy.",
}

const CHARS_PER_SEC := 30.0

var typing := false
var type_tween: Tween

func _on_gain_control() -> void:
	Box.get_parent().get_node("Soul").visible = false

	var text: String = action_text.get(Box.button_choice, "* ???")
	Box.text_label.text = text
	Box.text_label.visible_characters = 0
	var char_count := Box.text_label.get_total_character_count()

	typing = true
	type_tween = create_tween()
	type_tween.tween_property(Box.text_label, "visible_characters", char_count, char_count / CHARS_PER_SEC)
	type_tween.finished.connect(func(): typing = false)

func input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if typing:
		type_tween.kill()
		Box.text_label.visible_characters = -1
		typing = false
	else:
		Box.change_state(BattleBox.State.Defending)
	get_viewport().set_input_as_handled()

func _on_lose_control() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	Box.text_label.text = ""
	Box.get_parent().get_node("Soul").visible = true
