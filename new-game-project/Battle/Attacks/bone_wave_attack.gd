class_name BoneWaveAttack
extends AttackBase

## Example attack: spawns a row of bones outside the left wall of the box
## and sweeps them across to the right, then ends.

@export var bone_scene: PackedScene
@export var bone_count: int = 5
@export var spacing: float = 24.0
@export var bone_speed: float = 220.0
@export var attack_duration: float = 3.0

func _run_attack() -> void:
	var box_rect := get_box_rect()
	var start_y := box_rect.position.y + spacing / 2.0

	for i in bone_count:
		var pos := Vector2(box_rect.position.x - 20.0, start_y + i * spacing)
		var bone: Bone = spawn_bone(bone_scene, pos)
		bone.damage = 1
		bone.fire(Vector2.RIGHT, bone_speed)

	await get_tree().create_timer(attack_duration).timeout

	for child in get_children():
		child.queue_free()

	_finish_attack()
