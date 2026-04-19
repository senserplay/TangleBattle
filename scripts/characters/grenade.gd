extends CharacterBody2D
## Grenade with proper independent velocity and bounce physics.

var owner_id: int = -1
var owner_ref: Node = null
var color: Color = Color.WHITE
var exploded: bool = false

var fuse_time: float = 2.0
var timer: float = 2.0
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

	# Save pre-slide velocity for bounce calculation
	var vel_before := velocity
	move_and_slide()

	# Bounce using collision normals
	if get_slide_collision_count() > 0:
		has_bounced = true
		var collision := get_slide_collision(0)
		var normal := collision.get_normal()
		velocity = vel_before.bounce(normal) * bounce_damping

	# Explode on player contact
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - global_position
		var p_radius: float = p.get_player_radius() if p.has_method("get_player_radius") else 24.0
		if diff.length() < player_detect_radius + p_radius:
			# Parry — kick grenade away
			if p.has_method("is_parrying") and p.is_parrying():
				var kick_dir: Vector2 = diff.normalized() * -1.0
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
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _draw() -> void:
	if exploded:
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

	var flash_rate := 0.3 * (timer / fuse_time) + 0.05
	var flash := fmod(timer, flash_rate) < flash_rate * 0.5
	var body_col := color if not flash else Color.WHITE

	draw_circle(Vector2.ZERO, 14.0, body_col)
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.15))
	draw_line(Vector2(0, -14), Vector2(5, -22), Color(0.5, 0.35, 0.2), 2.5)
	if flash:
		draw_circle(Vector2(5, -22), 4.0, Color(1, 0.9, 0.3))
		draw_circle(Vector2(5, -22), 6.0, Color(1, 0.8, 0.2, 0.3))
