class_name AttackBase
extends Node2D
signal attack_finished

var Box: BattleBox
var soul: SoulBattle

## Called by DefendingState right after instancing, before start_attack().
func setup(box: BattleBox) -> void:
	Box = box
	soul = Box.get_parent().get_node("Soul")

func start_attack() -> void:
	_run_attack()

## Override this in subclasses to spawn bones / move things / whatever.
func _run_attack() -> void:
	_finish_attack()

func _finish_attack() -> void:
	attack_finished.emit()

## Convenience helper for subclasses.
func spawn_bone(bone_scene: PackedScene, position: Vector2, rotation_deg: float = 0.0) -> Node2D:
	var bone := bone_scene.instantiate()
	add_child(bone)
	bone.global_position = position
	bone.rotation_degrees = rotation_deg
	return bone

## Convenience: the current pixel rect of the (possibly shrunk) battle box.
func get_box_rect() -> Rect2:
	return Box.box_frame.get_global_rect()
