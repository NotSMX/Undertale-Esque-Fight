extends BattleBoxBehaviour

var action_text := {
	0: "* You ready your weapon.",
	1: "* You check yourself.",
	2: "* You check your items.",
	3: "* You plead for mercy.",
}

func _on_gain_control() -> void:
	Box.text_label.text = action_text.get(Box.button_choice, "* ???")
