extends Node2D
class_name DuelTarget

## Set by FightingState right after instancing. Hits register visually on
## this stand-in (it's what actually sits inside the box and gets swung at),
## but HP/stats/death all still live on the real Enemy — take_damage() here
## just forwards to it and plays a local flinch.
var enemy: Enemy

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	anim.play(&"idle")

func take_damage(amount: int) -> void:
	if enemy:
		enemy.take_damage(amount)
	_flinch()

func _flinch() -> void:
	var base_x: float = sprite.position.x
	var tw := create_tween().set_loops(4)
	tw.tween_property(sprite, "position:x", -4, 0.02).as_relative()
	tw.tween_property(sprite, "position:x", 4, 0.02).as_relative()
	await tw.finished
	sprite.position.x = base_x
