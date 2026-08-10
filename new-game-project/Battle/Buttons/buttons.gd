extends Node2D
class_name BattleButtons

var enabled := false

@onready var move: AudioStreamPlayer = $choice
@onready var select: AudioStreamPlayer = $select
@onready var buttons: Array[AnimatedSprite2D] = [$Button1, $Button2, $Button3, $Button4]
var choice := 0
signal movesoul(newpos: Vector2)
signal selectbutton(id: int)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event.is_action_pressed("ui_left"):
		changepos(-1)

	if event.is_action_pressed("ui_right"):
		changepos(1)

	if event.is_action_pressed("ui_accept"):
		disable()
		emit_signal("selectbutton", choice)
		select.play()
		
func changepos(action: int) -> void:
	move.play()
	choice = posmod(choice + action, 4)
	emit_signal("movesoul", buttons[choice].global_position - Vector2(38, 0))
	glow_choice(choice)

func glow_choice(id: int) -> void:
	for i in buttons:
		i.frame = 0
	buttons[id].frame = 1

func enable() -> void:
	enabled = true
	emit_signal("movesoul", buttons[choice].global_position - Vector2(38, 0))
	glow_choice(choice)


func disable() -> void:
	enabled = false

func reset() -> void:
	for i in buttons:
		i.frame = 0
