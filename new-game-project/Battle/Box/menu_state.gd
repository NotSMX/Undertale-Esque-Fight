extends BattleBoxBehaviour

func _on_gain_control() -> void:
	while Box.box_busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	if not is_inside_tree(): return
	type_text("* Joe Mama.")
	Box.buttons.enable()
	Box.get_node("../Soul").menu_enable()

func _on_lose_control() -> void:
	Box.buttons.disable()
	Box.buttons.reset()
