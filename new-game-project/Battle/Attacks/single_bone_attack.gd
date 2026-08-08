class_name SingleBoneAttack
extends AttackBase

## Minimal test attack: spawns one bone crossing the box, then ends.

@export var bone_scene: PackedScene
@export var bone_speed: float = 220.0
@export var attack_duration: float = 2.0

func _run_attack() -> void:
	var box_rect := get_box_rect()
	var spawn_pos := Vector2(box_rect.position.x - 20.0, box_rect.get_center().y)

	var bone: Bone = spawn_bone(bone_scene, spawn_pos)
	bone.damage = 1
	bone.set_length(60.0)
	bone.fire(Vector2.RIGHT, bone_speed)

	await get_tree().create_timer(attack_duration).timeout

	for child in get_children():
		child.queue_free()

	_finish_attack()
