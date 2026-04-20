extends Node2D

const ProjectileSprites := preload("res://scripts/characters/projectile_sprites.gd")
## Boomerang — flies out, then returns to owner. Passes through platforms.

var owner_id: int = -1
var owner_ref: Node = null
var color: Color = Color.WHITE
var direction: Vector2 = Vector2.RIGHT
var speed: float = 700.0
var return_speed: float = 800.0
var fly_distance: float = 600.0
var damage: float = 25.0
var knockback: float = 500.0
var knockback_up: float = 200.0
var hit_radius: float = 96.0
var return_radius: float = 40.0
var homing: float = 0.0  # from Homing Projectiles passive
var lifetime: float = 4.0

var traveled: float = 0.0
var returning: bool = false
var spin: float = 0.0
var hit_players: Dictionary = {}  # player_id → phase (0=outgoing, 1=returning)

# Vortex trail effect
var trail_timer: float = 0.0
const TRAIL_INTERVAL := 0.06
var _vortex_scene: PackedScene = preload(
	"res://scenes/effects/sprite_effect.tscn")

# Trail
var trail: Array[Vector2] = []
const TRAIL_MAX := 10


func _ready() -> void:
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary
) -> void:
	owner_id = id
	direction = dir.normalized()
	color = col
	speed = cfg.get("speed", 700.0)
	return_speed = cfg.get("return_speed", 800.0)
	fly_distance = cfg.get("fly_distance", 600.0)
	damage = cfg.get("damage", 25.0)
	knockback = cfg.get("knockback", 500.0)
	knockback_up = cfg.get("knockback_up", 200.0)
	hit_radius = cfg.get("hit_radius", 96.0)
	return_radius = cfg.get("return_radius", 40.0)
	lifetime = cfg.get("lifetime", 4.0)


func _physics_process(delta: float) -> void:
	spin += delta * 12.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Vortex trail effect — spawn periodically
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = TRAIL_INTERVAL
		var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
		# Cyan horizontal slash for vortex
		SpriteEffect.spawn(get_tree().current_scene, "cartoon_4",
			global_position, 0.35, 0.25, spin, color, 8.0)

	# Trail
	trail.push_front(global_position)
	if trail.size() > TRAIL_MAX:
		trail.resize(TRAIL_MAX)

	if not returning:
		# Homing — steer toward nearest enemy in outgoing phase
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
		# Fly outward
		global_position += direction * speed * delta
		traveled += speed * delta
		if traveled >= fly_distance:
			returning = true
			hit_players.clear()  # allow hitting again on return
	else:
		# Return to owner
		if owner_ref != null and is_instance_valid(owner_ref):
			var to_owner: Vector2 = owner_ref.global_position - global_position
			var dist := to_owner.length()
			var catch_r: float = return_radius
			if owner_ref.has_method("get_player_radius"):
				catch_r = maxf(return_radius, owner_ref.get_player_radius() + 10.0)
			if dist < catch_r:
				queue_free()
				return
			direction = to_owner.normalized()
			global_position += direction * return_speed * delta
		else:
			queue_free()
			return

	# Hit detection — check all players
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id or not p.is_alive:
			continue
		var pid: int = p.player_id
		if pid in hit_players:
			continue
		var dist := global_position.distance_to(p.global_position)
		if dist < hit_radius:
			# Parry — reflect boomerang
			if p.has_method("is_parrying") and p.is_parrying():
				direction = -direction
				owner_id = p.player_id
				owner_ref = p
				returning = false
				hit_players.clear()
				p.on_parry_reflect()
				break
			var src: Node = owner_ref if is_instance_valid(owner_ref) else null
			var dmg_mult: float = src.damage_multiplier if src != null else 1.0
			p.take_damage(damage * dmg_mult, src)
			var kb_dir: Vector2 = (p.global_position - global_position).normalized()
			p.apply_knockback(kb_dir * knockback + Vector2.UP * knockback_up)
			hit_players[pid] = 1
			SoundManager.play_hit()

	if absf(global_position.x) > 8000 or absf(global_position.y) > 8000:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	# Trail orbs that fade with distance, tinted to the owner's color.
	for i in range(trail.size()):
		var local: Vector2 = trail[i] - global_position
		var t := 1.0 - float(i) / TRAIL_MAX
		draw_circle(local, 10.0 * t,
			Color(color.r, color.g, color.b, 0.3 * t))

	# Textured boomerang, spins with `spin`, tinted to owner color.
	ProjectileSprites.draw_single(self, "boomerang.png", 72.0, spin, color)
