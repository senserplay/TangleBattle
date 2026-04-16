extends Node2D
## Soul Essence — small homing projectile spawned by Spirit Burst passive.
## Flies through walls, homes aggressively toward nearest enemy.

var owner_id: int = -1
var owner_ref: Node = null
var color: Color = Color.WHITE
var damage: float = 15.0
var speed: float = 2500.0
var homing_strength: float = 15.0  # very strong homing
var delay: float = 0.3  # hover delay before launching
var lifetime: float = 3.0

var direction: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var launched: bool = false
var hit: bool = false

# Trail
var trail: Array[Vector2] = []
const TRAIL_MAX := 10


func _ready() -> void:
	add_to_group("soul_essences")


func setup(id: int, col: Color, dir: Vector2, dmg: float) -> void:
	owner_id = id
	color = col
	direction = dir.normalized()
	damage = dmg


func _physics_process(delta: float) -> void:
	if hit:
		return

	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

	# Delay phase — hover in place with slight wobble
	if time_alive < delay:
		var wobble := sin(time_alive * 20.0) * 3.0
		position += Vector2(wobble * delta * 10.0, -20.0 * delta)
		queue_redraw()
		return

	if not launched:
		launched = true
		SoundManager.play_toss()

	# Aggressive homing toward nearest enemy
	var best_target: Node2D = null
	var best_dist: float = 2000.0
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id or not p.is_alive:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best_target = p

	if best_target != null:
		var desired: Vector2 = (best_target.global_position \
			- global_position).normalized()
		direction = direction.lerp(desired, homing_strength * delta).normalized()

	# Move
	global_position += direction * speed * delta

	if absf(global_position.x) > 8000 or absf(global_position.y) > 8000:
		queue_free()
		return

	# Trail
	trail.push_front(global_position)
	if trail.size() > TRAIL_MAX:
		trail.resize(TRAIL_MAX)

	# Hit detection — check all enemy players
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id or not p.is_alive:
			continue
		var dist: float = global_position.distance_to(p.global_position)
		var hit_r: float = 20.0
		if p.has_method("get_player_radius"):
			hit_r = p.get_player_radius()
		if dist < hit_r + 8.0:
			# Use take_damage so Phoenix/parry/invincibility work
			p.take_damage(damage, owner_ref)
			p._spawn_hit_burst("electric", 4)
			hit = true
			# Small heal to owner
			if owner_ref != null and is_instance_valid(owner_ref) \
				and owner_ref.is_alive:
				owner_ref.heal(damage * 0.5)
			queue_free()
			return

	queue_redraw()


func _draw() -> void:
	if hit:
		return

	# Trail
	for i in range(trail.size()):
		var local_pos: Vector2 = trail[i] - global_position
		var t := 1.0 - float(i) / TRAIL_MAX
		var r := 6.0 * t
		draw_circle(local_pos, r,
			Color(color.r, color.g, color.b, 0.3 * t))

	var pulse := sin(time_alive * 12.0) * 0.15 + 0.85

	# Outer glow
	draw_circle(Vector2.ZERO, 12.0 * pulse,
		Color(color.r, color.g, color.b, 0.15))
	# Core
	draw_circle(Vector2.ZERO, 7.0 * pulse, color)
	# White center
	draw_circle(Vector2.ZERO, 3.0,
		Color(1.0, 1.0, 1.0, 0.7 * pulse))

	# Sparkle lines
	if not launched:
		for i in range(4):
			var a := time_alive * 8.0 + i * TAU / 4.0
			var len := 10.0 + sin(time_alive * 15.0 + i) * 4.0
			draw_line(Vector2.ZERO,
				Vector2(cos(a) * len, sin(a) * len),
				Color(1, 1, 1, 0.3), 1.0)
