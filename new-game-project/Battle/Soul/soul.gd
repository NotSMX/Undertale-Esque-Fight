extends CharacterBody2D
class_name SoulBattle

const speed: float = 160.0
const gravity: float = 3.25
const jump := [8.0, 5.0, 2.5, 170.0]

enum Mode { RED, BLUE }

var mode: Mode = Mode.RED
var inputs := Vector2.ZERO
var motion := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	set_physics_process(false)
	red()

func _physics_process(_delta: float) -> void:
	match mode:
		Mode.RED:
			red()
		Mode.BLUE:
			blue()
	velocity = motion
	move_and_slide()

func get_slow_down() -> int:
	return int(Input.is_action_pressed("ui_cancel")) + 1

func red() -> void:
	sprite.modulate = Color.RED
	var slow_down := get_slow_down()
	inputs = Vector2(
		Input.get_action_raw_strength("ui_right") - Input.get_action_raw_strength("ui_left"),
		Input.get_action_raw_strength("ui_down") - Input.get_action_raw_strength("ui_up")
	)
	motion = speed * inputs / slow_down

func blue() -> void:
	sprite.modulate = Color.BLUE
	var slow_down := get_slow_down()
	inputs = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.is_action_pressed("ui_up")
	)
	if not is_on_floor():
		motion.y += gravity
	motion.x = speed * ceil(inputs.x) / slow_down
	if is_on_floor():
		if motion.y > 0: motion.y = 0
		if inputs.y:
			motion.y -= jump[3]
	else:
		if motion.y > 0:
			motion.y += gravity * (jump[2] - 1.0)
		elif not inputs.y:
			if motion.y < 20:
				motion.y = lerpf(motion.y, 0, (jump[1] - 1.0) / 20.0)
			else:
				motion.y = lerpf(motion.y, 20, (jump[0] - 1.0) / 20.0)

func set_mode(new_mode: Mode) -> void:
	mode = new_mode

func menu_enable() -> void:
	set_physics_process(false)

func menu_disable() -> void:
	set_physics_process(true)
	z_index = 10
