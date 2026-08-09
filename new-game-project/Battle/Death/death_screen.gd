extends Node2D
class_name DeathScreen

@export var death_soul_scene: PackedScene = preload("res://Battle/Death/death_soul.tscn")
@export var retry_scene_path: String = ""
@export var death_position: Vector2 = Vector2.ZERO

@onready var background: ColorRect = $UI/Background
@onready var retry_label: Label = $UI/RetryLabel

var death_soul: AnimatedSprite2D
var ready_to_retry := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	background.color = Color.BLACK
	retry_label.modulate.a = 0.0

	death_soul = death_soul_scene.instantiate()
	$UI.add_child(death_soul)
	death_soul.position = get_viewport().canvas_transform * death_position

	await get_tree().create_timer(0.5).timeout
	await death_soul.die()

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(retry_label, "modulate:a", 1.0, 0.6)
	await tw.finished
	ready_to_retry = true

func _unhandled_input(event: InputEvent) -> void:
	if ready_to_retry and event.is_action_pressed("ui_accept"):
		_retry()

func _retry() -> void:
	get_tree().paused = false
	if retry_scene_path != "":
		get_tree().change_scene_to_file(retry_scene_path)
	else:
		get_tree().reload_current_scene()
