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

# --- Precognition trail ---
var bounce_top: float = -INF ## y bound to reflect off of (for attacks that bounce, e.g. zigzag)
var bounce_bottom: float = INF
var precog_duration: float = 1.5
var precog_steps: int = 24
var precog_trail: Line2D = null
var precog_ghost: Node2D = null
var precog_ghost_sprite: NinePatchRect = null

func _ready() -> void:
	assert(collision.shape is RectangleShape2D, "Bone's CollisionShape2D needs a RectangleShape2D")
	bone_width = collision.shape.size.x
	collision.shape = RectangleShape2D.new()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	collision.position.y = sprite.size.y / 2.0
	collision.shape.size = Vector2(bone_width, max(sprite.size.y - collision_margin, 0.0))

	if precog_trail:
		precog_trail.points = get_predicted_points(precog_duration, precog_steps)

	if precog_ghost:
		var points := get_predicted_points(precog_duration, precog_steps)
		precog_ghost.global_position = points[-1]
		precog_ghost.rotation = rotation
		precog_ghost_sprite.size = sprite.size

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

## Sets the y-range this bone reflects off of, for attacks that bounce
## (e.g. ZigzagBoneAttack). Leave unset for straight-line bones.
func set_bounce_bounds(top: float, bottom: float) -> void:
	bounce_top = top
	bounce_bottom = bottom

## Shows or hides the fading "future path" preview (a line for the overall
## shape plus a ghost clone at the far end showing the real hitbox at that
## moment). Creates both lazily on first use. Safe to call any time after
## the bone is in the tree.
func set_precog_trail_visible(shown: bool, duration: float = 1.5, steps: int = 24, width: float = 4.0) -> void:
	precog_duration = duration
	precog_steps = steps

	if shown and not precog_trail:
		_create_precog_trail(width)
	if shown and not precog_ghost:
		_create_precog_ghost()

	if precog_trail:
		precog_trail.visible = shown
	if precog_ghost:
		precog_ghost.visible = shown

func _create_precog_trail(width: float) -> void:
	precog_trail = Line2D.new()
	precog_trail.top_level = true # draw in world space, ignore this bone's own transform
	precog_trail.width = width
	precog_trail.z_index = 5 # above the box frame (z_index 1) and the bone itself

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.55))
	gradient.set_color(1, Color(1, 1, 1, 0.0))
	precog_trail.gradient = gradient

	add_child(precog_trail)

## A dimmed duplicate of the real sprite, positioned at the far end of the
## predicted path each frame. Wrapped in its own top-level Node2D so the
## duplicated sprite keeps its original offsets untouched - it lines up
## with the real bone's silhouette automatically, no manual offset math.
func _create_precog_ghost() -> void:
	precog_ghost = Node2D.new()
	precog_ghost.top_level = true
	precog_ghost.z_index = 5
	add_child(precog_ghost)

	precog_ghost_sprite = sprite.duplicate() as NinePatchRect
	precog_ghost_sprite.modulate = Color(1, 1, 1, 0.45)
	precog_ghost_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	precog_ghost.add_child(precog_ghost_sprite)

## Simulates this bone's straight-line movement `duration` seconds ahead,
## reflecting velocity.y off bounce_top/bounce_bottom if they're set.
## Same math as _physics_process, just run forward without touching real state.
func get_predicted_points(duration: float, steps: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	var pos := global_position
	var vel := velocity
	var dt := duration / float(steps)

	points.append(pos)
	for i in steps:
		pos += vel * dt
		if pos.y <= bounce_top:
			pos.y = bounce_top + (bounce_top - pos.y)
			vel.y = -vel.y
		elif pos.y >= bounce_bottom:
			pos.y = bounce_bottom - (pos.y - bounce_bottom)
			vel.y = -vel.y
		points.append(pos)

	return points
