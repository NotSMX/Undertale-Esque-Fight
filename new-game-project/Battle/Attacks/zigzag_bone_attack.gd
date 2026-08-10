class_name ZigzagBoneAttack
extends AttackBase
## Hard attack: bones sweep left-to-right, bouncing diagonally off the
## box's top/bottom edges like a ball, instead of moving in a straight line.

@export var bone_scene: PackedScene
@export var bone_count: int = 4
@export var spacing_delay: float = 0.5 ## time between each bone spawning
@export var bone_speed: float = 200.0
@export var zig_angle_deg: float = 55.0 ## steepness of the diagonal bounce
@export var attack_duration: float = 6.0

func _run_attack() -> void:
	for i in bone_count:
		_spawn_zigzag_bone()
		await get_tree().create_timer(spacing_delay).timeout

	await get_tree().create_timer(attack_duration).timeout
	_finish_attack()

func _spawn_zigzag_bone() -> void:
	var box_rect := get_box_rect()
	var start_y := box_rect.position.y + randf_range(10.0, box_rect.size.y - 10.0)
	var pos := Vector2(box_rect.position.x - 20.0, start_y)

	var bone: Bone = spawn_bone(bone_scene, pos)
	bone.damage = 1

	_zigzag_loop(bone)

func _zigzag_loop(bone: Bone) -> void:
	var box_rect := get_box_rect()
	var angle := deg_to_rad(zig_angle_deg)
	var going_up := true
	bone.fire(Vector2(cos(angle), -sin(angle)), bone_speed)

	while is_instance_valid(bone):
		await get_tree().process_frame
		if not is_instance_valid(bone):
			return
		if going_up and bone.global_position.y <= box_rect.position.y + 5.0:
			going_up = false
			bone.fire(Vector2(cos(angle), sin(angle)), bone_speed)
		elif not going_up and bone.global_position.y >= box_rect.position.y + box_rect.size.y - 5.0:
			going_up = true
			bone.fire(Vector2(cos(angle), -sin(angle)), bone_speed)
