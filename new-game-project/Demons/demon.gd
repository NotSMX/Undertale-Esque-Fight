extends CharacterBody2D

enum DemonSide { LEFT, RIGHT }

@export var side: DemonSide = DemonSide.RIGHT
@export var hidden_offset: float = 250.0
@export var tween_duration: float = 0.6

@onready var animations: AnimationPlayer = $Animations

var home_position: Vector2
var hidden_position: Vector2
var active_tween: Tween


func _ready() -> void:
	home_position = position

	var direction := -1.0 if side == DemonSide.LEFT else 1.0
	hidden_position = home_position + Vector2(hidden_offset * direction, 0.0)

	position = hidden_position
	visible = false

	animations.play(&"idle")

	# Items screen isn't active yet, so the demon starts hidden.
	set_items_screen_active(false)


func set_items_screen_active(active: bool) -> void:
	# active = the items screen is up, so the demon should be shown.
	var target := home_position if active else hidden_position

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Becoming visible happens immediately so the slide-in is seen; becoming
	# invisible only happens once the slide-out finishes.
	if active:
		visible = true

	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC)
	active_tween.set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "position", target, tween_duration)

	if not active:
		active_tween.finished.connect(func() -> void: visible = false)

	if animations.current_animation != "idle":
		animations.play(&"idle")
