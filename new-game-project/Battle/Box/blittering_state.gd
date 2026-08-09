extends BattleBoxBehaviour

var action_text := {
	0: "* You ready your weapon.",
	1: "* You check yourself.",
	2: "* You check your items.",
	3: "* You plead for mercy.",
}

func _on_gain_control() -> void:
	Box.get_parent().get_node("Soul").visible = false
	type_text(action_text.get(Box.button_choice, "* ???"))

func input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if typing:
		skip_typing()
	else:
		Box.change_state(BattleBox.State.Defending)
	get_viewport().set_input_as_handled()

func _on_lose_control() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	Box.text_label.text = ""
	Box.get_parent().get_node("Soul").visible = true
