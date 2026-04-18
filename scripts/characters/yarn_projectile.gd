extends Area2D

var owner_id: int = -1
var owner_ref: Node = null  # reference to owner player for passives
var direction: Vector2 = Vector2.RIGHT
var speed: float = 900.0
var color: Color = Color.WHITE
var lifetime: float = 3.0
var damage: float = 35.0
var knockback: float = 800.0
var knockback_up: float = 200.0
var stun_duration: float = 0.5
var max_bounces: int = 0  # from Ricochet passive
var bounces_left: int = 0
var homing: float = 0.0  # from Homing Projectiles passive
var phase: bool = false  # from Phase Shot passive

# Trail
var trail_points: Array[Vector2] = []
const TRAIL_MAX := 12
const TRAIL_INTERVAL := 0.02
var trail_timer: float = 0.0


func setup(id: int, dir: Vector2, spd: float, col: Color) -> void:
	owner_id = id
	direction = dir.normalized()
	speed = spd
	color = col


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary
) -> void:
	owner_id = id
	direction = dir.normalized()
	color = col
	speed = cfg.get("speed", 900.0)
	damage = cfg.get("damage", 35.0)
	knockback = cfg.get("knockback", 800.0)
	knockback_up = cfg.get("knockback_up", 200.0)
	stun_duration = cfg.get("stun_duration", 0.5)
	lifetime = cfg.get("lifetime", 3.0)


func _ready() -> void:
	bounces_left = max_bounces
	body_entered.connect(_on_body_entered)
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _physics_process(delta: float) -> void:
	# Trail
	trail_timer += delta
	if trail_timer >= TRAIL_INTERVAL:
		trail_timer = 0.0
		trail_points.push_front(global_position)
		if trail_points.size() > TRAIL_MAX:
			trail_points.resize(TRAIL_MAX)

	# Homing — steer toward nearest enemy
	if homing > 0.0:
		var best_target: Node2D = null
		var best_dist: float = 600.0  # max homing range
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
			direction = direction.lerp(desired, homing * delta).normalized()

	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if absf(position.x) > 7000 or absf(position.y) > 7000:
		queue_free()
		return

	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("apply_knockback"):
		if body.player_id == owner_id:
			return
		# Parry — reflect projectile back (phase shots ignore shields)
		if not phase and body.has_method("is_parrying") and body.is_parrying():
			direction = -direction
			owner_id = body.player_id
			owner_ref = body
			body.on_parry_reflect()
			global_position += direction * 20.0
			return
		var src: Node = owner_ref if is_instance_valid(owner_ref) else null
		var dmg_mult: float = src.damage_multiplier if src != null else 1.0
		body.take_damage(damage * dmg_mult, src)
		body.apply_knockback(
			direction * knockback + Vector2.UP * knockback_up
		)
		body.apply_stun(stun_duration)
		# Hit impact sprite
		var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
		SpriteEffect.spawn(get_tree().current_scene, "slash9",
			global_position, 0.3, 0.3, 0.0, color)
		queue_free()
	elif body is StaticBody2D:
		if phase:
			return
		if bounces_left > 0:
			bounces_left -= 1
			# Reflect direction off surface normal (approximate)
			var to_body: Vector2 = body.global_position - global_position
			var normal := -to_body.normalized()
			direction = direction.bounce(normal).normalized()
			# Nudge away from surface
			global_position += normal * 5.0
		else:
			queue_free()


func _draw() -> void:
	# Trail
	for i in range(trail_points.size()):
		var local_pos: Vector2 = trail_points[i] - global_position
		var t := 1.0 - float(i) / TRAIL_MAX
		var r := 10.0 * t
		var alpha := 0.4 * t
		draw_circle(local_pos, r, Color(color.r, color.g, color.b, alpha))

	# Body
	draw_circle(Vector2.ZERO, 12.0, color)
	# Shine
	draw_circle(Vector2(-3, -3), 4.0, Color(1, 1, 1, 0.4))
	# Yarn pattern
	var dark := color.darkened(0.3)
	draw_line(Vector2(-5, -3), Vector2(5, 3), dark, 2.0)
	draw_line(Vector2(-4, 4), Vector2(4, -4), dark, 2.0)
