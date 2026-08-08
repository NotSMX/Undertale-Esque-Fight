extends BattleBoxBehaviour

const SQUARE_SIZE := 140.0
const RESIZE_TIME := 0.25
const CENTER := Vector2(320.0, 320.0)

func _on_gain_control() -> void:
	var soul: SoulBattle = Box.get_parent().get_node("Soul")
	soul.visible = false

	var tween := create_tween().set_parallel()

	var top: CollisionShape2D = Box.walls["top"]
	var bottom: CollisionShape2D = Box.walls["bottom"]
	var left: CollisionShape2D = Box.walls["left"]
	var right: CollisionShape2D = Box.walls["right"]

	tween.tween_property(top.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(bottom.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(left.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)
	tween.tween_property(right.shape, "size:x", SQUARE_SIZE, RESIZE_TIME)

	tween.tween_property(top, "position", Vector2(CENTER.x, CENTER.y - SQUARE_SIZE / 2.0), RESIZE_TIME)
	tween.tween_property(bottom, "position", Vector2(CENTER.x, CENTER.y + SQUARE_SIZE / 2.0), RESIZE_TIME)
	tween.tween_property(left, "position", Vector2(CENTER.x - SQUARE_SIZE / 2.0, CENTER.y), RESIZE_TIME)
	tween.tween_property(right, "position", Vector2(CENTER.x + SQUARE_SIZE / 2.0, CENTER.y), RESIZE_TIME)

	var frame: Control = Box.box_frame
	tween.tween_property(frame, "size", Vector2(SQUARE_SIZE, SQUARE_SIZE), RESIZE_TIME)
	tween.tween_property(frame, "global_position", CENTER - Vector2(SQUARE_SIZE, SQUARE_SIZE) / 2.0, RESIZE_TIME)

	await tween.finished

	soul.global_position = CENTER
	soul.menu_disable()
	soul.visible = true

func _on_lose_control() -> void:
	pass
