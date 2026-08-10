class_name Bone
extends Area2D

@export var sprite_path: NodePath = ^"NinePatchRect"
@export var collision_margin: float = 4.0
@export var damage: int = 1
@export var tick_interval: float = 0.033 ## seconds between damage ticks while the soul stays inside
@export var destroy_on_hit: bool = false ## true = one-shot hazard (uses invincibility, destroys on touch); false = ticks damage while overlapping, ignoring invincibility

@onready var sprite: NinePatchRect = get_node(sprite_path)
@onready var collision: CollisionShape2D = $CollisionShape2D

var bone_width: float
var velocity: Vector2 = Vector2.ZERO
var bodies_inside: Array[SoulBattle] = []
var tick_timer := 0.0

func _ready() -> void:
	assert(collision.shape is RectangleShape2D, "Bone's CollisionShape2D needs a RectangleShape2D")
	bone_width = collision.shape.size.x
	collision.shape = RectangleShape2D.new()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	collision.position.y = sprite.size.y / 2.0
	collision.shape.size = Vector2(bone_width, max(sprite.size.y - collision_margin, 0.0))

	if destroy_on_hit or bodies_inside.is_empty():
		return
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		for body in bodies_inside:
			if is_instance_valid(body):
				body.take_tick_damage(damage, false)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func fire(direction: Vector2, speed: float = 220.0) -> Bone:
	velocity = direction.normalized() * speed
	return self

func queue_fire(delay: float, direction: Vector2, speed: float = 220.0) -> Bone:
	await get_tree().create_timer(delay).timeout
	fire(direction, speed)
	return self

func set_length(new_length: float) -> void:
	sprite.size.y = new_length

func tween_height(new_height: float, time: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(sprite, "size:y", new_height, time)
	return tween

func _on_body_entered(body: Node2D) -> void:
	if body is SoulBattle:
		if destroy_on_hit:
			body.take_damage(damage)
			queue_free()
		else:
			bodies_inside.append(body)
			tick_timer = tick_interval

			# First contact with this Bone?
			body.take_tick_damage(damage, true)
			
func _on_body_exited(body: Node2D) -> void:
	if body is SoulBattle and bodies_inside.has(body):
		bodies_inside.erase(body)
