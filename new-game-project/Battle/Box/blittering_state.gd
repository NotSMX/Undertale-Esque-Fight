extends BattleBoxBehaviour

var action_text := {
	0: "* Select your target.",
	1: "* What will you do?",
	2: "* What do you need?",
	3: "* They will not let you.",
}

func _on_gain_control() -> void:
	Box.get_parent().get_node("Soul").visible = false
	while Box.box_busy:
		await get_tree().process_frame
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
