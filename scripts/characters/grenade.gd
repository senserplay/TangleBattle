extends CharacterBody2D

const ProjectileSprites := preload("res://scripts/characters/projectile_sprites.gd")
## Grenade with proper independent velocity and bounce physics.

var owner_id: int = -1
var owner_ref: Node = null
var color: Color = Color.WHITE
var exploded: bool = false

var fuse_time: float = 2.0
var timer: float = 2.0
# Visual spin accumulator — driven by horizontal velocity each physics
# frame. Sign follows the flight direction, magnitude scales with speed
# so fast throws spin faster than slow lobs.
var spin_angle: float = 0.0
var bounce_damping: float = 0.5
var explosion_radius: float = 180.0
var damage: float = 50.0
var knockback: float = 1100.0
var knockback_up: float = 500.0
var player_detect_radius: float = 20.0
var owner_safe_time: float = 0.3

# Independent throw velocity — set on first frame
var throw_dir: Vector2 = Vector2.RIGHT
var throw_speed: float = 1000.0
var initialized: bool = false
var homing: float = 0.0  # from Homing Projectiles passive
var has_bounced: bool = false
# Ricochet passive — number of *additional* explosions after the first.
# On each re-bounce the grenade launches in a random direction at high
# speed and its fuse re-arms; re-explodes on fuse expiry or player hit.
var max_bounces: int = 0
var bounces_left: int = 0
# Scales visual size, physical collision, explosion radius AND contact
# detection radius by the owner's damage_multiplier — set at spawn.
var size_mult: float = 1.0

const GRAVITY := 980.0


func setup(id: int, dir: Vector2, speed: float, col: Color) -> void:
	owner_id = id
	throw_dir = dir.normalized()
	throw_speed = speed
	color = col


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary,
	spd: float = -1.0
) -> void:
	owner_id = id
	color = col
	throw_dir = dir.normalized()
	throw_speed = spd if spd > 0.0 else cfg.get("max_throw_speed", 2000.0)
	bounce_damping = cfg.get("bounce_damping", 0.5)
	fuse_time = cfg.get("fuse_time", 2.0)
	timer = fuse_time
	owner_safe_time = cfg.get("owner_safe_time", 0.3)
	explosion_radius = cfg.get("explosion_radius", 180.0)
	damage = cfg.get("damage", 50.0)
	knockback = cfg.get("knockback", 1100.0)
	knockback_up = cfg.get("knockback_up", 500.0)
	player_detect_radius = cfg.get("player_detect_radius", 20.0)


func _ready() -> void:
	add_to_group("ability_entities")
	bounces_left = max_bounces
	_apply_size_mult()


func _apply_size_mult() -> void:
	if size_mult == 1.0:
		return
	# Explosion extent is computed on demand in _explode (it also folds
	# in Wide Impact), so we no longer pre-scale `explosion_radius`.
	# Contact detection and physical collision still scale here so the
	# grenade actually feels bigger while flying.
	player_detect_radius *= size_mult
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

	# Set velocity on first physics frame — after being added to scene
	# This ensures player's velocity doesn't contaminate the grenade
	if not initialized:
		velocity = throw_dir * throw_speed
		initialized = true

	# Homing — steer toward nearest enemy before first bounce
	if homing > 0.0 and not has_bounced:
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
			var spd := velocity.length()
			var cur_dir := velocity.normalized()
			cur_dir = cur_dir.lerp(desired, homing * delta * 0.5).normalized()
			velocity = cur_dir * spd

	# Gravity (scaled by current map's gravity_multiplier — e.g. 0 in space)
	var grav_mul: float = 1.0
	var game := get_tree().current_scene
	if game != null and "current_map" in game and game.current_map != null:
		if "gravity_multiplier" in game.current_map:
			grav_mul = game.current_map.gravity_multiplier
	velocity.y += GRAVITY * delta * grav_mul

	# Accumulate visual spin — rate proportional to horizontal speed,
	# sign follows flight direction (right → CW, left → CCW). Vertical
	# motion adds a small extra spin so a straight-down drop still wobbles.
	var horiz: float = velocity.x
	var vert_bias: float = absf(velocity.y) * 0.15 * signf(velocity.x)
	var spin_speed: float = (horiz + vert_bias) * 0.0045
	spin_angle += spin_speed * delta

	# Save pre-slide state for bounce + swept contact detection
	var vel_before := velocity
	var prev_pos := global_position
	move_and_slide()

	# Bounce using collision normals
	if get_slide_collision_count() > 0:
		has_bounced = true
		var collision := get_slide_collision(0)
		var normal := collision.get_normal()
		velocity = vel_before.bounce(normal) * bounce_damping

	# Explode on player contact — swept segment [prev_pos → global_position]
	# vs player circle so fast throws can't tunnel past the detection zone
	# between two physics frames.
	var seg: Vector2 = global_position - prev_pos
	var seg_len_sq: float = seg.length_squared()
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var p_radius: float = p.get_player_radius() if p.has_method("get_player_radius") else 24.0
		var hit_r: float = player_detect_radius + p_radius
		var closest: Vector2 = global_position
		if seg_len_sq > 0.01:
			var to_p: Vector2 = p.global_position - prev_pos
			var t: float = clampf(to_p.dot(seg) / seg_len_sq, 0.0, 1.0)
			closest = prev_pos + seg * t
		var min_dist: float = closest.distance_to(p.global_position)
		if min_dist < hit_r:
			# Parry — kick grenade away (use current position for kick dir)
			if p.has_method("is_parrying") and p.is_parrying():
				var kick_dir: Vector2 = (global_position - p.global_position).normalized()
				velocity = kick_dir * 1200.0 + Vector2.UP * 400.0
				owner_id = p.player_id
				owner_ref = p
				p.on_parry_reflect()
				return
			if p.player_id == owner_id:
				# Owner — only explode after safe time
				if timer < fuse_time - owner_safe_time:
					_explode()
					return
			else:
				# Enemy — always explode immediately
				_explode()
				return

	timer -= delta
	if timer <= 0.0:
		_explode()

	if absf(global_position.x) > 8000 or absf(global_position.y) > 8000:
		queue_free()
		return

	queue_redraw()


func _explode() -> void:
	exploded = true
	SoundManager.play_explosion()
	# Unified retro explosion sprite
	var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
	SpriteEffect.spawn(get_tree().current_scene, "retro_explosion",
		global_position, 0.6, 2.5)
	SpriteEffect.spawn(get_tree().current_scene, "retro_burst",
		global_position, 0.5, 2.0, 0.0,
		Color(1.0, 0.85, 0.3))
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(10.0)
	# Vibrate all nearby players' controllers
	for p in get_tree().get_nodes_in_group("players"):
		if p.has_method("vibrate"):
			var dist := global_position.distance_to(p.global_position)
			if dist < 500.0:
				var intensity := 1.0 - dist / 500.0
				p.vibrate(intensity * 0.4, intensity * 0.8, 0.25)
	# Explosion reach is driven by the projectile's SIZE, not directly
	# by damage — size_mult is already damage-capped at 5× elsewhere,
	# and Wide Impact (owner.radius_multiplier) stacks on top.
	# Two zones:
	#   dist ≤ r           → full damage + full knockback.
	#   r < dist < 2·r     → linear falloff from 1 to 0.
	#   dist ≥ 2·r         → out of reach, skip.
	var src: Node = owner_ref if is_instance_valid(owner_ref) else null
	var dmg_mult: float = src.damage_multiplier if src != null else 1.0
	var wide: float = src.radius_multiplier if src != null else 1.0
	var r: float = explosion_radius * size_mult * wide
	var max_reach: float = 2.0 * r
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - global_position
		var dist := diff.length()
		if dist >= max_reach:
			continue
		var falloff: float
		if dist <= r:
			falloff = 1.0
		else:
			falloff = 1.0 - (dist - r) / r
		var away := diff.normalized() if dist > 1.0 else Vector2.UP
		p.take_damage(damage * falloff * dmg_mult, src)
		p.apply_knockback(
			away * knockback * falloff
			+ Vector2.UP * knockback_up * falloff
		)
	queue_redraw()
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		return
	# Ricochet passive: re-launch in a random direction and re-arm fuse.
	# Each bounce counts as one extra explosion. Direction is purely
	# random — the grenade's bounces don't care about surface normals.
	if bounces_left > 0:
		bounces_left -= 1
		_rebounce_grenade()
		return
	queue_free()


func _rebounce_grenade() -> void:
	var ang := randf() * TAU
	var spd: float = maxf(throw_speed * 1.2, 1500.0)
	throw_dir = Vector2(cos(ang), sin(ang))
	throw_speed = spd
	velocity = throw_dir * spd
	initialized = true  # velocity already set, skip first-frame init
	has_bounced = false
	timer = fuse_time
	exploded = false
	queue_redraw()


func _draw() -> void:
	if exploded:
		# Stylised fireball layers (no art asset for explosion yet).
		draw_circle(
			Vector2.ZERO, explosion_radius * 0.5, Color(1, 0.7, 0.1, 0.4)
		)
		draw_circle(
			Vector2.ZERO, explosion_radius * 0.3, Color(1, 0.9, 0.3, 0.6)
		)
		draw_circle(
			Vector2.ZERO, explosion_radius * 0.15, Color(1, 1, 0.8, 0.8)
		)
		return

	# Flicker white each fuse pulse to telegraph imminent boom.
	var flash_rate := 0.3 * (timer / fuse_time) + 0.05
	var flash := fmod(timer, flash_rate) < flash_rate * 0.5
	var mod: Color = Color.WHITE if not flash else Color(1.4, 1.4, 1.2, 1.0)
	# spin_angle is driven by velocity in _physics_process — direction
	# and speed of spin now match the actual flight trajectory.
	ProjectileSprites.draw_single(self, "grenade.png",
		44.0 * size_mult, spin_angle, mod)
