extends Node2D
class_name BattleBox

enum State { Menu, Blittering }

@onready var buttons: BattleButtons = get_parent().get_node("Buttons")
@onready var text_label: RichTextLabel = $Blitter/Text
var button_choice: int = 0

@onready var states := {
	State.Menu: $States/MenuState,
	State.Blittering: $States/BlitteringState,
}
var current_state: BattleBoxBehaviour

func _ready() -> void:
	buttons.selectbutton.connect(_on_select_button)
	buttons.movesoul.connect(_on_move_soul)
	change_state(State.Menu)

func change_state(new_state: State) -> void:
	if current_state:
		current_state.lose_control()
	current_state = states[new_state]
	current_state.gain_control()

func _on_select_button(id: int) -> void:
	button_choice = id
	change_state(State.Blittering)

func _on_move_soul(newpos: Vector2) -> void:
	get_parent().get_node("Soul").position = newpos
