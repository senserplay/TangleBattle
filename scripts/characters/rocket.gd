extends Area2D
## Rocket projectile — explodes on contact, has fire trail.

var owner_id: int = -1
var owner_ref: Node = null
var direction: Vector2 = Vector2.RIGHT
var speed: float = 800.0
var color: Color = Color.WHITE
var lifetime: float = 2.5
var damage: float = 30.0
var knockback: float = 700.0
var knockback_up: float = 350.0
var explosion_radius: float = 120.0
var exploded: bool = false
var homing: float = 0.0  # from Homing Projectiles passive
var phase: bool = false  # from Phase Shot passive

# Trail
var trail_points: Array[Vector2] = []
const TRAIL_MAX := 16
const TRAIL_INTERVAL := 0.015
var trail_timer: float = 0.0


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary
) -> void:
	owner_id = id
	direction = dir.normalized()
	color = col
	speed = cfg.get("rocket_speed", 800.0)
	damage = cfg.get("damage", 30.0)
	knockback = cfg.get("knockback", 700.0)
	knockback_up = cfg.get("knockback_up", 350.0)
	explosion_radius = cfg.get("explosion_radius", 120.0)
	lifetime = cfg.get("lifetime", 2.5)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _physics_process(delta: float) -> void:
	if exploded:
		return

	# Trail
	trail_timer += delta
	if trail_timer >= TRAIL_INTERVAL:
		trail_timer = 0.0
		trail_points.push_front(global_position)
		if trail_points.size() > TRAIL_MAX:
			trail_points.resize(TRAIL_MAX)

	# Homing — steer toward nearest enemy
	if homing > 0.0:
		var best_t: Node2D = null
		var best_d: float = 500.0
		for p in get_tree().get_nodes_in_group("players"):
			if p.player_id == owner_id or not p.is_alive:
				continue
			var d: float = global_position.distance_to(p.global_position)
			if d < best_d:
				best_d = d
				best_t = p
		if best_t != null:
			var desired: Vector2 = (best_t.global_position \
				- global_position).normalized()
			direction = direction.lerp(desired, homing * delta).normalized()

	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return

	if absf(position.x) > 7000 or absf(position.y) > 7000:
		queue_free()
		return

	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if exploded:
		return
	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.player_id == owner_id:
			return
		# Parry — reflect rocket (phase shots ignore shields)
		if not phase and body.has_method("is_parrying") and body.is_parrying():
			direction = -direction
			owner_id = body.player_id
			owner_ref = body
			body.on_parry_reflect()
			global_position += direction * 20.0
			return
		_explode()
	elif body is StaticBody2D:
		if not phase:
			_explode()


func _explode() -> void:
	exploded = true
	SoundManager.play_explosion()
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(6.0)

	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - global_position
		var dist := diff.length()
		if dist < explosion_radius:
			var falloff := 1.0 - dist / explosion_radius
			var away := diff.normalized() if dist > 1.0 else Vector2.UP
			var src: Node = owner_ref if is_instance_valid(owner_ref) else null
			var dmg_mult: float = src.damage_multiplier if src != null else 1.0
			p.take_damage(damage * falloff * dmg_mult, src)
			p.apply_knockback(
				away * knockback * falloff
				+ Vector2.UP * knockback_up * falloff
			)

	queue_redraw()
	await get_tree().create_timer(0.15).timeout
	queue_free()


func _draw() -> void:
	if exploded:
		draw_circle(
			Vector2.ZERO, explosion_radius * 0.4,
			Color(1, 0.6, 0.1, 0.45)
		)
		draw_circle(
			Vector2.ZERO, explosion_radius * 0.2,
			Color(1, 0.9, 0.4, 0.65)
		)
		return

	# Fire trail
	for i in range(trail_points.size()):
		var local_pos: Vector2 = trail_points[i] - global_position
		var t := 1.0 - float(i) / TRAIL_MAX
		var r := 6.0 * t
		# Orange → red → fade
		var trail_col := Color(1.0, 0.6 * t, 0.1, 0.5 * t)
		draw_circle(local_pos, r, trail_col)

	# Rocket body
	var perp := Vector2(-direction.y, direction.x)
	var tip := direction * 10.0
	var tail := -direction * 8.0
	var side := 5.0

	draw_colored_polygon(PackedVector2Array([
		tip,
		tail + perp * side,
		tail - perp * side,
	]), color)

	# Nose highlight
	draw_circle(direction * 6.0, 2.5, Color(1, 1, 0.8, 0.5))

	# Exhaust glow at tail
	draw_circle(-direction * 8.0, 4.0, Color(1, 0.6, 0.1, 0.6))
