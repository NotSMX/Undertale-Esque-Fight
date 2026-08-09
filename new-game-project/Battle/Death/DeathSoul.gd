extends AnimatedSprite2D

@export_enum("HUMAN", "MONSTER") var soul_type: int = 0

var human_color := Color.RED
var monster_color := Color.WHITE

func _ready() -> void:
	if soul_type:
		modulate = monster_color
		scale.y = -1
	else:
		modulate = human_color

func die() -> void:
	animation = "death"
	$snap.play()
	await get_tree().create_timer(0.5).timeout
	$shards.emitting = true
	$shatter.play()
	self_modulate.a = 0
	await get_tree().create_timer(2).timeout
