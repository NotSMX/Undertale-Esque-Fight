extends Node2D

class_name BattleBox

enum State { Menu, Blittering, Defending }

@onready var buttons: BattleButtons = get_parent().get_node("Buttons")
@onready var text_label: RichTextLabel = $Blitter/Text
@onready var box_frame: Control = $BoxContainer/NinePatchRect
@onready var click: AudioStreamPlayer = $Sounds/Generic2
var button_choice: int = 0
var box_busy := false
@onready var states := {
	State.Menu: $Behaviours/MenuState,
	State.Blittering: $Behaviours/BlitteringState,
	State.Defending: $Behaviours/DefendingState
}
@onready var walls := {
	"top": $BoxContainer/Collisions/Top,
	"bottom": $BoxContainer/Collisions/Bottom,
	"left": $BoxContainer/Collisions/Left,
	"right": $BoxContainer/Collisions/Right,
}
@onready var clip_area: Control = $ClipArea

func _process(_delta: float) -> void:
	clip_area.global_position = box_frame.global_position
	clip_area.size = box_frame.size
	
var current_state: BattleBoxBehaviour

func _ready() -> void:
	$BoxContainer.clip_contents = true
	print("BoxContainer rect: ", $BoxContainer.get_global_rect())
	print("NinePatchRect rect: ", box_frame.get_global_rect())
	print("clip_contents: ", $BoxContainer.clip_contents)
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
