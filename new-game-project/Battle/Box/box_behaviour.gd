class_name BattleBoxBehaviour extends Node

@onready var Box: BattleBox = get_parent().get_parent()
var enabled := false

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
