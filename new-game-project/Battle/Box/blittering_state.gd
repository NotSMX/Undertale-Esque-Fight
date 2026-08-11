extends BattleBoxBehaviour

var action_text := {
	0: "* Select your target.",
	1: "* What will you do?",
	2: "* What do you need?",
	3: "* They will not let you.",
}

var act_text := {
	0: "* You check LR.\n* ATK 5 DEF 5",
	1: "* You shoo them away.",
	2: "* You flex your muscles.",
}

var item_text := {
	0: "* You use the Stick.\n* Nothing happened.",
	1: "* You wrap the bandage.\n* HP fully restored!",
	2: "* You use the item.",
}

func _on_gain_control() -> void:
	Box.get_parent().get_node("Soul").visible = false
	while Box.box_busy:
		await get_tree().process_frame
	var text: String
	match Box.button_choice:
		1: text = act_text.get(Box.sub_choice, "* ???")  # Tactics went through Acts
		2: text = item_text.get(Box.sub_choice, "* ???") # Pact went through Items
		_: text = action_text.get(Box.button_choice, "* ???")
	type_text(text)
	
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
