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
@onready var hurtsound: AudioStreamPlayer = $Hurt
@export var max_hp: int = 99
var hp: int = max_hp
var kr: int = 0
var krtime: float = 0.5
const DeathScreenScene := preload("res://Battle/Death/death_screen.tscn")
const INVINCIBILITY_TIME := 0.5
var invincible := false

signal hurt(amount: int)
signal died

func _ready() -> void:
	set_physics_process(false)
	red()
	died.connect(_on_died)
	$KrTimer.timeout.connect(_on_kr_tick)

func take_damage(amount: int) -> void:
	if invincible or amount <= 0:
		return
	hurtsound.play()
	hp = max(hp - amount, 0)
	hurt.emit(amount)
	_flash_invincible()
	if hp <= 0:
		died.emit()

func take_tick_damage(amount: int, initial_hit: bool) -> void:
	if amount <= 0:
		return

	hurtsound.play()

	hp = max(hp - amount, 0)

	if initial_hit:
		kr = min(kr + 6, 40)
	else:
		kr = min(kr + 1, 40)

	hurt.emit(amount)

	if hp <= 0:
		died.emit()

	if kr > 0 and $KrTimer.is_stopped():
		$KrTimer.start()

func _flash_invincible() -> void:
	invincible = true
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.2, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	tween.set_loops(int(INVINCIBILITY_TIME / 0.1))
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	invincible = false
	sprite.modulate.a = 1.0

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
	
func _on_died() -> void:
	set_physics_process(false)
	set_process_input(false)
	visible = false
	var death_screen := DeathScreenScene.instantiate()
	death_screen.death_position = global_position
	get_tree().current_scene.add_child(death_screen)
	
func _on_kr_tick() -> void:
	if kr <= 0:
		$KrTimer.stop()
		return

	kr -= 1
	hp = max(hp - 1, 1)

	if hp <= 1:
		kr = 0
		$KrTimer.stop()
		
func _process(delta: float) -> void:
	$KrTimer.wait_time = krtime / 3.0 if kr > 30 else krtime
