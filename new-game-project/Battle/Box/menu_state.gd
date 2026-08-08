extends BattleBoxBehaviour

func _on_gain_control() -> void:
	Box.buttons.enable()
	Box.get_node("../Soul").menu_enable()

func _on_lose_control() -> void:
	Box.buttons.disable()
	Box.buttons.reset()
