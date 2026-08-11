extends BattleBoxBehaviour

## Bone patterns Sans keeps lobbing while you close the distance — reuse the
## same AttackBase scenes DefendingState uses. Keep this lighter/sparser than
## DefendingState's own array; the point isn't to overwhelm you, it's to make
## picking your moment to swing matter.
@export var attacks: Array[PackedScene] = []
@export var attack_interval_range := Vector2(1.4, 2.2)

## How long the duel runs before falling back into a normal Defending phase.
@export var duel_duration := 9.0

## Leave empty to auto-find the first Enemy sibling of BattleBox. Set this if
## you ever have more than one enemy in the scene and need to pick which one
## you're dueling.
@export var enemy_path: NodePath

## The floating damage-number/mini-healthbar popup. It's what actually
## applies the hit — DuelTarget.take_damage() (and, through it, the real
## Enemy) is called from its `damagetarget` signal, not directly from
## _try_attack, so the number and the HP change always land in the same
## frame.
@export var damage_popup_scene: PackedScene = preload("res://Battle/AttackMeter/damage.tscn")

## The in-box stand-in you actually swing at. The real Enemy (Sans) stays up
## in its portrait spot untouched; this is what lives inside the box and
## takes the hits, forwarding them to the real Enemy underneath.
@export var duel_target_scene: PackedScene = preload("res://Battle/Box/duel_target.tscn")

## Two simple one-way platforms for a bit of verticality. Spawned fresh each
## duel and freed when it ends, so they never interfere with Defending's
## box-shrink or any other state.
@export var platform_size := Vector2(90.0, 8.0)
@export var platform_height_fraction := 0.55 ## 0 = ceiling, 1 = floor

## range: how close Soul needs to be when the hit lands.
## damage: flat damage dealt on a landed hit.
## windup: delay between pressing the button and the hit actually resolving
##         (telegraphs the swing — Sans' bones can still catch you here).
## recovery: extra time after the hit resolves before you can act again.
## Heavier attacks hit harder but leave you committed for longer.
var attack_defs := {
	"light": {"range": 34.0, "damage": 4, "windup": 0.08, "recovery": 0.18, "anim": &"attack_light"},
	"medium": {"range": 46.0, "damage": 9, "windup": 0.20, "recovery": 0.35, "anim": &"attack_medium"},
	"heavy": {"range": 60.0, "damage": 16, "windup": 0.38, "recovery": 0.60, "anim": &"attack_heavy"},
}

var enemy: Enemy
var soul: SoulBattle
var duel_target: DuelTarget
var duel_active := false
var attacking := false
var live_attacks: Array[AttackBase] = []
var platform_bodies: Array[CollisionShape2D] = []
var platform_visuals: Array[ColorRect] = []

func _get_enemy() -> Enemy:
	if enemy_path != NodePath():
		var node := Box.get_parent().get_node(enemy_path)
		if node is Enemy:
			return node
	for child in Box.get_parent().get_children():
		if child is Enemy:
			return child
	return null

func _on_gain_control() -> void:
	enemy = _get_enemy()
	soul = Box.get_parent().get_node("Soul")

	if not enemy:
		push_error("FightingState: no Enemy found to duel — check enemy_path")
		Box.change_state(BattleBox.State.Menu)
		return

	duel_active = true
	attacking = false
	live_attacks.clear()

	# All positioning below is derived from the box's own wall collision
	# shapes rather than Sans' (or the box's visual frame's) position — Sans
	# sits up in his portrait spot outside the box entirely, and box_frame's
	# global_position is a Control top-left corner, not floor height. Using
	# the walls keeps Soul, the duel target, and the platforms all correctly
	# grounded inside the box regardless of where anything else is parented.
	var top: CollisionShape2D = Box.walls["top"]
	var bottom: CollisionShape2D = Box.walls["bottom"]
	var left: CollisionShape2D = Box.walls["left"]
	var right: CollisionShape2D = Box.walls["right"]
	var floor_y: float = bottom.global_position.y - bottom.shape.size.y / 2.0
	var ceil_y: float = top.global_position.y + top.shape.size.y / 2.0
	var left_x: float = left.global_position.x
	var right_x: float = right.global_position.x

	_spawn_duel_target(Vector2(right_x - 70.0, floor_y))
	_spawn_platforms(left_x, right_x, ceil_y, floor_y)

	soul.set_mode(SoulBattle.Mode.BLUE)
	soul.attack_locked = false
	soul.set_fighting(true)
	soul.menu_disable()
	soul.global_position = Vector2(left_x + 60.0, floor_y - 9.0)
	soul.visible = true

	_queue_next_enemy_attack()
	get_tree().create_timer(duel_duration).timeout.connect(_end_duel)

func _spawn_duel_target(pos: Vector2) -> void:
	if not duel_target_scene:
		duel_target = null
		return
	duel_target = duel_target_scene.instantiate()
	duel_target.enemy = enemy
	Box.clip_area.add_child(duel_target)
	duel_target.global_position = pos

func _spawn_platforms(left_x: float, right_x: float, ceil_y: float, floor_y: float) -> void:
	var collisions_parent: Node = Box.walls["bottom"].get_parent()
	var mid_y: float = lerp(ceil_y, floor_y, platform_height_fraction)
	var width: float = right_x - left_x
	for x in [left_x + width * 0.28, left_x + width * 0.72]:
		var pos := Vector2(x, mid_y)

		var body_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = platform_size
		body_shape.shape = rect
		body_shape.one_way_collision = true
		collisions_parent.add_child(body_shape)
		body_shape.global_position = pos
		platform_bodies.append(body_shape)

		# Placeholder visual so the platform is actually visible — swap this
		# ColorRect out for a themed sprite/NinePatchRect whenever you like,
		# the collision above doesn't care what's drawn on it.
		var visual := ColorRect.new()
		visual.color = Color(0.55, 0.55, 0.62, 0.9)
		visual.size = platform_size
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Box.clip_area.add_child(visual)
		visual.global_position = pos - platform_size / 2.0
		platform_visuals.append(visual)

func input(event: InputEvent) -> void:
	if not duel_active or attacking:
		return
	if event.is_action_pressed("attack_light"):
		_try_attack("light")
	elif event.is_action_pressed("attack_medium"):
		_try_attack("medium")
	elif event.is_action_pressed("attack_heavy"):
		_try_attack("heavy")

func _try_attack(weight: String) -> void:
	attacking = true
	soul.attack_locked = true
	var def: Dictionary = attack_defs[weight]
	var windup: float = def["windup"]
	var recovery: float = def["recovery"]

	soul.play_attack_anim(def["anim"])
	# The gameplay windup/recovery numbers above are tunable independent of
	# however long you make the clip — but the fighter shouldn't snap back to
	# idle before the swing animation actually finishes playing, so stretch
	# recovery to cover it if the clip runs long.
	if soul.fighter_anim.has_animation(def["anim"]):
		var clip_length: float = soul.fighter_anim.get_animation(def["anim"]).length
		recovery = max(recovery, clip_length - windup)

	await get_tree().create_timer(windup).timeout
	if not duel_active:
		return

	var target_pos: Vector2 = duel_target.global_position if duel_target else enemy.global_position
	if soul.global_position.distance_to(target_pos) <= float(def["range"]):
		_spawn_damage_popup(int(def["damage"]), enemy.global_position)

	await get_tree().create_timer(recovery).timeout
	attacking = false
	if duel_active:
		soul.attack_locked = false

## Shows the floating damage number/bar above the duel target. The popup
## emits `damagetarget` (which is what actually applies the hit) almost
## immediately, and `finished` once its flash animation wraps up.
func _spawn_damage_popup(damage: int, target_pos: Vector2) -> void:
	if not damage_popup_scene:
		if duel_target:
			duel_target.take_damage(damage)
		else:
			enemy.take_damage(damage)
		return
	var popup: DamagePopup = damage_popup_scene.instantiate()
	popup.z_index = 1000
	popup.max_hp = enemy.stats.get("max_hp", 100)
	popup.hp = enemy.stats.get("hp", popup.max_hp)
	popup.damage = damage
	popup.miss = false
	popup.damagetarget.connect(func(amount: int):
		if duel_target:
			duel_target.take_damage(amount)
		else:
			enemy.take_damage(amount)
	)
	popup.finished.connect(popup.queue_free)
	Box.add_child(popup)
	popup.global_position = target_pos + Vector2(0, -80)

func _queue_next_enemy_attack() -> void:
	if not duel_active or attacks.is_empty():
		return
	var wait := randf_range(attack_interval_range.x, attack_interval_range.y)
	get_tree().create_timer(wait).timeout.connect(_fire_enemy_attack)

func _fire_enemy_attack() -> void:
	if not duel_active:
		return
	var scene: PackedScene = attacks[randi() % attacks.size()]
	var atk: AttackBase = scene.instantiate()
	add_child(atk)
	live_attacks.append(atk)
	atk.setup(Box)
	atk.attack_finished.connect(func():
		live_attacks.erase(atk)
		if is_instance_valid(atk):
			atk.queue_free()
	, CONNECT_ONE_SHOT)
	atk.start_attack()
	_queue_next_enemy_attack()

func _end_duel() -> void:
	if not duel_active:
		return
	duel_active = false
	Box.change_state(BattleBox.State.Defending)

func _on_lose_control() -> void:
	duel_active = false
	attacking = false
	if soul:
		soul.attack_locked = false
		soul.set_fighting(false)

	# AttackBase.spawn_bone() parents bones to Box.clip_area, not to the
	# attack node itself — queue_free()ing the attack alone leaves them
	# orphaned on screen forever. Free each attack's bones explicitly first.
	for atk in live_attacks:
		if is_instance_valid(atk):
			for bone in atk.spawned_bones:
				if is_instance_valid(bone):
					bone.queue_free()
			atk.spawned_bones.clear()
			atk.queue_free()
	live_attacks.clear()

	if duel_target and is_instance_valid(duel_target):
		duel_target.queue_free()
	duel_target = null

	for body in platform_bodies:
		if is_instance_valid(body):
			body.queue_free()
	platform_bodies.clear()

	for visual in platform_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	platform_visuals.clear()
