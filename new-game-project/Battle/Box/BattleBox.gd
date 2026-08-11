extends Node2D

class_name BattleBox

enum State { Menu, Acts, Items, Blittering, Defending, Fighting }

@onready var buttons: BattleButtons = get_parent().get_node("Buttons")
@onready var text_label: RichTextLabel = $Blitter/Text
@onready var box_frame: Control = $BoxContainer/NinePatchRect
@onready var click: AudioStreamPlayer = $Sounds/Generic2
@onready var choice: AudioStreamPlayer = $Sounds/choice
@onready var select: AudioStreamPlayer = $Sounds/select
var button_choice: int = 0
var sub_choice: int = 0
var box_busy := false
@onready var states := {
	State.Menu: $Behaviours/MenuState,
	State.Acts: $Behaviours/ActsState,
	State.Items: $Behaviours/ItemsState,
	State.Blittering: $Behaviours/BlitteringState,
	State.Defending: $Behaviours/DefendingState,
	State.Fighting: $Behaviours/FightingState
}
@onready var walls := {
	"top": $BoxContainer/Collisions/Top,
	"bottom": $BoxContainer/Collisions/Bottom,
	"left": $BoxContainer/Collisions/Left,
	"right": $BoxContainer/Collisions/Right,
}
@onready var clip_area: Control = $ClipArea
@onready var precog_overlay: ColorRect = $PrecogOverlay

var precognition_active := false
var precog_tween: Tween

func _process(_delta: float) -> void:
	clip_area.global_position = box_frame.global_position
	clip_area.size = box_frame.size

var current_state: BattleBoxBehaviour
var intro_finished := false

func _ready() -> void:
	$BoxContainer.clip_contents = true
	buttons.selectbutton.connect(_on_select_button)
	buttons.movesoul.connect(_on_move_soul)
	buttons.disable()
	get_parent().get_node("Soul").visible = false

## Fades the cyan precognition overlay in or out and tracks the flag that
## AttackBase.spawn_bone checks so new bones pick up the current state.
func set_precognition_active(active: bool) -> void:
	precognition_active = active

	if precog_tween and precog_tween.is_valid():
		precog_tween.kill()
	precog_tween = create_tween()
	precog_tween.tween_property(precog_overlay, "color:a", 0.22 if active else 0.0, 0.15)

func finish_intro() -> void:
	intro_finished = true
	change_state(State.Menu)
	get_parent().get_node("Soul").visible = true

func change_state(new_state: State) -> void:
	if current_state:
		current_state.lose_control()
	current_state = states[new_state]
	current_state.gain_control()

func _on_select_button(id: int) -> void:
	if not intro_finished:
		return

	button_choice = id
	match id:
		0: change_state(State.Fighting)
		1: change_state(State.Acts)
		2: change_state(State.Items)
		_: change_state(State.Blittering)

func _on_move_soul(newpos: Vector2) -> void:
	if not intro_finished:
		return

	get_parent().get_node("Soul").position = newpos
