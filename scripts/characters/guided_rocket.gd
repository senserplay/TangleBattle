extends Area2D
## Guided Rocket — player steers it with aim while it flies.

var owner_id: int = -1
var owner_ref: Node = null
var color: Color = Color.WHITE
var direction: Vector2 = Vector2.RIGHT
var rocket_speed: float = 500.0
var turn_speed: float = 4.0
var damage: float = 40.0
var knockback: float = 800.0
var knockback_up: float = 400.0
var explosion_radius: float = 150.0
var lifetime: float = 3.5
var exploded: bool = false
var homing: float = 0.0  # from Homing Projectiles passive
var phase: bool = false  # from Phase Shot passive
var steering: bool = true  # true while player holds button
var boosted: bool = false
# Ricochet passive — additional explosions after the first. Each bounce
# re-launches the rocket in a yarn-toss-style reflected direction when
# it hit a wall, or a random direction otherwise. Steering/boost are
# cleared on bounce; homing (if active) continues.
var max_bounces: int = 0
var bounces_left: int = 0
var max_lifetime: float = 3.5
var last_hit_body: Node = null
# Scales visual + collision + explosion radius by damage_multiplier.
var size_mult: float = 1.0
# Absolute ceiling for scaled explosion radius (see grenade.gd).
# Sized for a 5× guided rocket (cfg 150 × 5 = 750).
const MAX_EXPLOSION_RADIUS := 750.0
var effective_reach: float = 0.0

const BOOST_MULTIPLIER := 3.0

var trail: Array[Vector2] = []
const TRAIL_MAX := 18


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary
) -> void:
	owner_id = id
	direction = dir.normalized()
	color = col
	rocket_speed = cfg.get("rocket_speed", 500.0)
	turn_speed = cfg.get("turn_speed", 4.0)
	damage = cfg.get("damage", 40.0)
	knockback = cfg.get("knockback", 800.0)
	knockback_up = cfg.get("knockback_up", 400.0)
	explosion_radius = cfg.get("explosion_radius", 150.0)
	lifetime = cfg.get("lifetime", 3.5)
	max_lifetime = lifetime


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("ability_entities")
	bounces_left = max_bounces
	_apply_size_mult()


func _apply_size_mult() -> void:
	if size_mult == 1.0:
		return
	# Explosion reach is computed in _explode using size_mult + Wide
	# Impact — don't bake size_mult into explosion_radius here.
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col != null and col.shape is CircleShape2D:
		var new_shape: CircleShape2D = col.shape.duplicate()
		new_shape.radius *= size_mult
		col.shape = new_shape


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _physics_process(delta: float) -> void:
	if exploded:
		return

	# Steer toward owner's aim direction (only while holding button)
	if steering and owner_ref != null and is_instance_valid(owner_ref):
		var target_dir: Vector2 = owner_ref.aim_direction
		var current_angle := direction.angle()
		var target_angle := target_dir.angle()
		var diff := angle_difference(current_angle, target_angle)
		var max_turn := turn_speed * delta
		var actual_turn := clampf(diff, -max_turn, max_turn)
		direction = direction.rotated(actual_turn).normalized()

	# Homing passive — adds to manual steering
	if homing > 0.0 and not steering:
		var best_t: Node2D = null
		var best_d: float = 600.0
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

	# Trail
	trail.push_front(global_position)
	if trail.size() > TRAIL_MAX:
		trail.resize(TRAIL_MAX)

	var spd := rocket_speed * (BOOST_MULTIPLIER if boosted else 1.0)
	position += direction * spd * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return

	if absf(position.x) > 7000 or absf(position.y) > 7000:
		queue_free()
		return

	queue_redraw()


func boost() -> void:
	steering = false
	boosted = true
	SoundManager.play_dash()


func _on_body_entered(body: Node2D) -> void:
	if exploded:
		return
	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.player_id == owner_id:
			return
		# Parry — reflect guided rocket (phase shots ignore shields)
		if not phase and body.has_method("is_parrying") and body.is_parrying():
			direction = -direction
			owner_id = body.player_id
			owner_ref = body
			body.on_parry_reflect()
			global_position += direction * 20.0
			return
		last_hit_body = body
		_explode()
	elif body is StaticBody2D:
		if not phase:
			last_hit_body = body
			_explode()


func _explode() -> void:
	exploded = true
	SoundManager.play_explosion()
	# Unified retro explosion sprite (same as grenade)
	var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
	SpriteEffect.spawn(get_tree().current_scene, "retro_explosion",
		global_position, 0.6, 2.5)
	SpriteEffect.spawn(get_tree().current_scene, "retro_burst",
		global_position, 0.5, 2.0, 0.0,
		Color(1.0, 0.85, 0.3))
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(8.0)
	# Classic linear-falloff explosion (see grenade.gd): base
	# explosion_radius × size_mult × Wide Impact, clamped to
	# MAX_EXPLOSION_RADIUS (5× base cfg).
	var src: Node = owner_ref if is_instance_valid(owner_ref) else null
	var dmg_mult: float = src.damage_multiplier if src != null else 1.0
	var wide: float = src.radius_multiplier if src != null else 1.0
	var r: float = minf(explosion_radius * size_mult * wide,
		MAX_EXPLOSION_RADIUS)
	effective_reach = r
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - global_position
		var dist := diff.length()
		if dist >= r:
			continue
		var falloff: float = 1.0 - dist / r
		var away := diff.normalized() if dist > 1.0 else Vector2.UP
		p.take_damage(damage * falloff * dmg_mult, src)
		p.apply_knockback(
			away * knockback * falloff
			+ Vector2.UP * knockback_up * falloff
		)
	queue_redraw()
	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		return
	if bounces_left > 0:
		bounces_left -= 1
		_rebounce_guided()
		return
	queue_free()


func _rebounce_guided() -> void:
	var new_dir: Vector2
	if last_hit_body != null and is_instance_valid(last_hit_body) \
		and last_hit_body is StaticBody2D:
		var normal := _surface_normal_at_hit()
		new_dir = direction.bounce(normal).normalized()
		global_position += normal * 20.0
	else:
		var ang := randf() * TAU
		new_dir = Vector2(cos(ang), sin(ang))
	direction = new_dir
	lifetime = max_lifetime
	# Steering/boost are consumed — bounced rocket flies on its own
	# (homing can still act if the passive is active).
	steering = false
	boosted = false
	exploded = false
	last_hit_body = null
	queue_redraw()


func _surface_normal_at_hit() -> Vector2:
	## Raycast along the flight line to recover the real wall normal
	## at the explosion point. Falls back to Vector2.UP on a miss.
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var start: Vector2 = global_position - direction * 80.0
	var end: Vector2 = global_position + direction * 40.0
	var query := PhysicsRayQueryParameters2D.create(start, end, 1)
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)
	if not result.is_empty():
		var n: Vector2 = result.get("normal", Vector2.UP)
		if n.length_squared() > 0.01:
			return n.normalized()
	return Vector2.UP


func _draw() -> void:
	if exploded:
		# Visual tied to real outer reach (see grenade.gd).
		draw_circle(Vector2.ZERO, effective_reach * 0.4, Color(1, 0.6, 0.1, 0.45))
		draw_circle(Vector2.ZERO, effective_reach * 0.2, Color(1, 0.9, 0.4, 0.65))
		return

	# Fire trail
	for i in range(trail.size()):
		var local: Vector2 = trail[i] - global_position
		var t := 1.0 - float(i) / TRAIL_MAX
		draw_circle(local, 5.0 * size_mult * t,
			Color(1.0, 0.5 * t, 0.1, 0.5 * t))

	# Rocket body — all offsets scale with size_mult
	var perp := Vector2(-direction.y, direction.x)
	var tip := direction * 12.0 * size_mult
	var tail := -direction * 10.0 * size_mult
	draw_colored_polygon(PackedVector2Array([
		tip, tail + perp * 6.0 * size_mult, tail - perp * 6.0 * size_mult,
	]), color)

	# Exhaust
	draw_circle(-direction * 10.0 * size_mult, 5.0 * size_mult,
		Color(1, 0.5, 0.1, 0.7))
	# Nose
	draw_circle(direction * 8.0 * size_mult, 3.0 * size_mult,
		Color(1, 1, 0.8, 0.5))
