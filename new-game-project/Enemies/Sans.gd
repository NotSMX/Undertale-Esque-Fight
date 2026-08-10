extends Enemy
class_name Sans

@onready var body: AnimatedSprite2D = $Sprites/Body
@onready var head: AnimatedSprite2D = $Sprites/Body/Head
## The speech-bubble DialogueControl parented to Sans in Sans.tscn.
@onready var dialogue_box: DialogueControl = $Dialogue
@onready var anim_player: AnimationPlayer = $Animations

## Attack scenes to run on this enemy's turn — same AttackBase scenes your
## DefendingState already uses.
var attacks: Array[PackedScene] = []
## Dialogue shown right before the matching attack in `attacks` (same index).
## Leave an entry null/empty to skip dialogue for that attack.
var attack_dialogues: Array[Dialogues] = []
var attack_index := 0

## -- Intro sequence -------------------------------------------------------
## Line(s) shown right after the "intro" animation, before he takes his
## bandage off.
@export var intro_dialogue: Dialogues
## Line(s) shown once he's sitting in "bandage_idle", before he catches fire.
@export var pre_burn_dialogue: Dialogues

func _ready() -> void:
	# Fire-and-forget: this coroutine never touches Box.change_state or
	# disables the buttons itself, so BattleBox just sits in Menu the whole
	# time and the player can act whenever they want. If you'd rather kick
	# this off from somewhere else (e.g. once the encounter text finishes),
	# delete this line and call _play_intro_sequence() from there instead.
	setup(get_parent().get_node("BattleBox"))
	_play_intro_sequence()

## Plays intro (looping) -> [dialogue] -> take_off_bandage -> bandage_idle
## (looping) -> [dialogue] -> burn -> burn_to_idle -> idle (looping). Runs as
## a background coroutine, not a blocking cutscene: it never calls
## Box.change_state, so the player keeps the menu the entire time. If they
## pick an action while a line is up, that action just waits behind
## Box.box_busy (same as your existing attack pre-dialogue) instead of
## getting cut off or ignored.
##
## intro/bandage_idle/idle are all looping animations and are never awaited
## via animation_finished (Godot doesn't emit that signal for looping
## animations — awaiting it on a looping anim hangs forever). Instead each
## one just keeps looping in place until the next _say()/anim_player.play()
## call moves things along.
func _play_intro_sequence() -> void:
	# Box is assigned by whoever spawns this enemy via setup(), which may
	# happen a frame or two after _ready(). Wait for it so _say() below
	# never touches a null Box.
	while not Box:
		await get_tree().process_frame

	anim_player.play(&"intro") # loops; not awaited — runs until dialogue below starts

	await _say(intro_dialogue)

	anim_player.play(&"take_off_bandage")
	await anim_player.animation_finished
	anim_player.play(&"bandage_idle") # loops; not awaited

	await _say(pre_burn_dialogue)

	anim_player.play(&"burn")
	await anim_player.animation_finished
	anim_player.play(&"burn_to_idle")
	await anim_player.animation_finished
	anim_player.play(&"idle") # loops; not awaited
	Box.finish_intro()

## Shows a line (or lines) in Sans's speech bubble and waits for it to
## finish. Marks the box busy for the duration so a menu choice made
## mid-line queues up rather than interrupting it. No-ops cleanly if no
## dialogue resource was assigned for this step.
func _say(lines: Dialogues) -> void:
	if not lines or lines.dialogues.is_empty():
		return
	Box.box_busy = true
	await dialogue_box.DialogueText(lines)
	Box.box_busy = false

func _on_get_turn() -> void:
	if not enemy_states[current_state].Sparable:
		Box.change_state(BattleBox.State.Blittering) # or however you currently trigger dialogue text
		await dialogue_finished()
		_run_next_attack()
	else:
		await dialogue_finished()
		Box.change_state(BattleBox.State.Menu)

## Placeholder — hook this up to whatever signals your Blittering/typing
## flow already emits when a line finishes.
func dialogue_finished() -> void:
	await get_tree().create_timer(1.0).timeout

## Plays the Dialogues resource paired with `index` (if any) in Sans's speech
## bubble, waiting for the bubble to fade in, type out, and fade back out
## (including the player confirming each line) before returning.
func _play_attack_dialogue(index: int) -> void:
	if index >= attack_dialogues.size():
		return
	await _say(attack_dialogues[index])

func _run_next_attack() -> void:
	if attacks.is_empty():
		Box.change_state(BattleBox.State.Menu)
		return
	var index := attack_index
	attack_index = (attack_index + 1) % attacks.size()
	await _play_attack_dialogue(index)
	var attack: AttackBase = attacks[index].instantiate()
	Box.add_child(attack)
	attack.setup(Box)
	attack.attack_finished.connect(func(): Box.change_state(BattleBox.State.Menu), CONNECT_ONE_SHOT)
	attack.start_attack()

func _set_expression(exp_id: Array) -> void:
	head.frame = exp_id[0]
	body.frame = exp_id[1]

func on_fight_used() -> void:
	change_state(0)

func on_mercy_used() -> void:
	if enemy_states[current_state].Sparable:
		spared.emit(id)

func on_defeat() -> void:
	pass # add a flag/save call here once you have that system
