extends BattleBoxBehaviour

const SQUARE_SIZE := 140.0
const RESIZE_TIME := 0.25

@export var attacks: Array[PackedScene] = []

var center: Vector2
var initialized := false
var current_attack: AttackBase

var original_sizes := {}
var original_positions := {}
var original_frame_size: Vector2
var original_frame_position: Vector2
var attack_index := 0


func _on_gain_control() -> void:
	Box.box_busy = true
	var soul: SoulBattle = Box.get_parent().get_node("Soul")
	soul.visible = false

	var top: CollisionShape2D = Box.walls["top"]
	var bottom: CollisionShape2D = Box.walls["bottom"]
	var left: CollisionShape2D = Box.walls["left"]
	var right: CollisionShape2D = Box.walls["right"]

	if not initialized:
		center = Vector2(
			(left.position.x + right.position.x) / 2.0,
			(top.position.y + bottom.position.y) / 2.0
		)
		original_sizes = {
			"top": top.shape.size.x, "bottom": bottom.shape.size.x,
			"left": left.shape.size.x, "right": right.shape.size.x,
		}
		original_positions = {
			"top": top.position, "bottom": bottom.position,
			"left": left.position, "right": right.position,
		}
		original_frame_size = Box.box_frame.size
		original_frame_position = Box.box_frame.global_position
		initialized = true

	var tween := create_tween().set_parallel()
	tween.tween_property(top.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(bottom.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(left.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(right.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)

	tween.tween_property(top, "position", Vector2(center.x, center.y - SQUARE_SIZE / 2.0), RESIZE_TIME)
	tween.tween_property(bottom, "position", Vector2(center.x, center.y + SQUARE_SIZE / 2.0), RESIZE_TIME)
	tween.tween_property(left, "position", Vector2(center.x - SQUARE_SIZE / 2.0, center.y), RESIZE_TIME)
	tween.tween_property(right, "position", Vector2(center.x + SQUARE_SIZE / 2.0, center.y), RESIZE_TIME)

	var frame: Control = Box.box_frame
	tween.tween_property(frame, "size", Vector2(SQUARE_SIZE, SQUARE_SIZE), RESIZE_TIME)
	tween.tween_property(frame, "global_position", center - Vector2(SQUARE_SIZE, SQUARE_SIZE) / 2.0, RESIZE_TIME)

	await tween.finished
	Box.box_busy = false

	soul.global_position = center
	soul.menu_disable()
	soul.visible = true

	_run_next_attack()

func _run_next_attack() -> void:
	if attacks.is_empty():
		return
	current_attack = attacks[attack_index].instantiate()
	attack_index = (attack_index + 1) % attacks.size()
	add_child(current_attack)
	current_attack.setup(Box)
	current_attack.attack_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
	current_attack.start_attack()

func _run_random_attack() -> void:
	if attacks.is_empty():
		return
	current_attack = attacks.pick_random().instantiate()
	add_child(current_attack)
	current_attack.setup(Box)
	current_attack.attack_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
	current_attack.start_attack()

func _on_attack_finished() -> void:
	current_attack.queue_free()
	current_attack = null
	Box.change_state(BattleBox.State.Menu)

func _on_lose_control() -> void:
	if current_attack and is_instance_valid(current_attack):
		current_attack.queue_free()
		current_attack = null
	
	Box.box_busy = true

	var top: CollisionShape2D = Box.walls["top"]
	var bottom: CollisionShape2D = Box.walls["bottom"]
	var left: CollisionShape2D = Box.walls["left"]
	var right: CollisionShape2D = Box.walls["right"]

	var tween := create_tween().set_parallel()
	tween.tween_property(top.shape, "size:x", original_sizes["top"], RESIZE_TIME)
	tween.tween_property(bottom.shape, "size:x", original_sizes["bottom"], RESIZE_TIME)
	tween.tween_property(left.shape, "size:x", original_sizes["left"], RESIZE_TIME)
	tween.tween_property(right.shape, "size:x", original_sizes["right"], RESIZE_TIME)

	tween.tween_property(top, "position", original_positions["top"], RESIZE_TIME)
	tween.tween_property(bottom, "position", original_positions["bottom"], RESIZE_TIME)
	tween.tween_property(left, "position", original_positions["left"], RESIZE_TIME)
	tween.tween_property(right, "position", original_positions["right"], RESIZE_TIME)

	tween.tween_property(Box.box_frame, "size", original_frame_size, RESIZE_TIME)
	tween.tween_property(Box.box_frame, "global_position", original_frame_position, RESIZE_TIME)
	tween.finished.connect(func(): Box.box_busy = false)
