class_name Bone
extends Area2D

## Standalone bone hazard - no external base class needed.
## Scene layout: Area2D (this script) > NinePatchRect (visual) + CollisionShape2D (RectangleShape2D)

@export var sprite_path: NodePath = ^"NinePatchRect"
@export var collision_margin: float = 4.0
@export var damage: int = 1
@export var destroy_on_hit: bool = false ## true = one-shot hazard, false = keeps hurting while you're in it

@onready var sprite: NinePatchRect = get_node(sprite_path)
@onready var collision: CollisionShape2D = $CollisionShape2D

var bone_width: float
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	assert(collision.shape is RectangleShape2D, "Bone's CollisionShape2D needs a RectangleShape2D")
	bone_width = collision.shape.size.x
	collision.shape = RectangleShape2D.new()
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# Keep the hitbox matched to however tall the sprite currently is
	# (so tween_height() growing/shrinking the bone stays accurate).
	collision.position.y = sprite.size.y / 2.0
	collision.shape.size = Vector2(bone_width, max(sprite.size.y - collision_margin, 0.0))

func _physics_process(delta: float) -> void:
	position += velocity * delta

## Start the bone moving in a direction at a given speed.
func fire(direction: Vector2, speed: float = 220.0) -> Bone:
	velocity = direction.normalized() * speed
	return self

## Same as fire(), but waits `delay` seconds first. Useful for staggered bone patterns.
func queue_fire(delay: float, direction: Vector2, speed: float = 220.0) -> Bone:
	await get_tree().create_timer(delay).timeout
	fire(direction, speed)
	return self

## Instantly set this bone's length (no animation). Use this from an attack
## right after spawn_bone() to vary length per-instance without editing the
## shared single_bone.tscn template (which would affect every bone).
func set_length(new_length: float) -> void:
	sprite.size.y = new_length

## Animate the bone's height, e.g. to "grow" a warning stub into a full bone.
func tween_height(new_height: float, time: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(sprite, "size:y", new_height, time)
	return tween

func _on_body_entered(body: Node2D) -> void:
	if body is SoulBattle:
		body.take_damage(damage)
		if destroy_on_hit:
			queue_free()
