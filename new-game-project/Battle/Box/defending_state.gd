extends BattleBoxBehaviour

const SQUARE_SIZE := 140.0
const RESIZE_TIME := 0.25

var center: Vector2
var initialized := false

func _on_gain_control() -> void:
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

	soul.global_position = center
	soul.menu_disable()
	soul.visible = true

func _on_lose_control() -> void:
	pass
