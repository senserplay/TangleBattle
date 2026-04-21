extends Node2D

const ProjectileSprites := preload("res://scripts/characters/projectile_sprites.gd")
## Black Hole — expands over 2.5s while pulling, then drains for 8s.
## Drains HP from enemies and heals the owner (lifesteal).

var owner_id: int = -1
var owner_ref: Node = null  # reference to owner for healing
var max_radius: float = 250.0
var expand_time: float = 2.5
var active_duration: float = 8.0
var pull_force: float = 350.0
var drain_per_sec: float = 5.0

var time_alive: float = 0.0
var total_lifetime: float = 10.5
var current_radius: float = 0.0
# Shrink back to a dot in the last `shrink_time` seconds — the 7-frame
# sprite replays in reverse while radius decays. Included in total_lifetime.
var shrink_time: float = 1.2


func setup_from_config(id: int, cfg: Dictionary) -> void:
	owner_id = id
	max_radius = cfg.get("max_radius", 250.0)
	expand_time = cfg.get("expand_time", 2.5)
	active_duration = cfg.get("active_duration", 8.0)
	pull_force = cfg.get("pull_force", 350.0)
	drain_per_sec = cfg.get("drain_per_sec", 5.0)
	shrink_time = cfg.get("shrink_time", 1.2)
	# Lifetime covers growth, active, and shrink phases in that order.
	total_lifetime = expand_time + active_duration + shrink_time


func _ready() -> void:
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


var _swirl_timer: float = 0.0


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= total_lifetime:
		queue_free()
		return

	# Periodic swirl effect — purple spiraling sprite
	_swirl_timer -= delta
	if _swirl_timer <= 0.0:
		_swirl_timer = 0.4
		var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
		var sc := current_radius / 250.0
		SpriteEffect.spawn(get_tree().current_scene, "cartoon_10",
			global_position, 0.6, sc, randf() * TAU,
			Color(0.6, 0.3, 0.9, 0.9), 4.0)

	# Three phases: grow (0..expand_time), hold (..total-shrink), shrink (last shrink_time).
	var shrink_start: float = total_lifetime - shrink_time
	if time_alive < expand_time:
		# Expanding phase — grow radius, pull starts immediately but weaker
		var t := time_alive / expand_time
		current_radius = max_radius * t * t  # ease-in
	elif time_alive < shrink_start:
		current_radius = max_radius
	else:
		# Shrink phase — ease-out back to zero
		var t := (time_alive - shrink_start) / shrink_time
		var k := 1.0 - t
		current_radius = max_radius * k * k

	# Pull and drain during ALL phases (not just active)
	_pull_and_drain(delta)
	queue_redraw()


func _pull_and_drain(delta: float) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		var diff: Vector2 = global_position - p.global_position
		var dist := diff.length()
		if dist < current_radius and dist > 5.0:
			# Pull ALL players toward center (including owner)
			var pull_strength := (1.0 - dist / current_radius) * pull_force
			p.velocity += diff.normalized() * pull_strength * delta * 60.0
			# Drain HP — only enemies, not owner
			if p.player_id == owner_id:
				continue
			# Drain HP — direct damage, no passive effects
			var drain := drain_per_sec * delta
			p.hp -= drain
			p.hit_flash_timer = 0.02
			# Lifesteal — heal owner
			if owner_ref != null and is_instance_valid(owner_ref) \
				and owner_ref.is_alive:
				owner_ref.heal(drain)
			if p.hp <= 0.0:
				p.hp = 0.0
				p.die()


func _draw() -> void:
	if current_radius < 1.0:
		return

	var fade := 1.0

	var time_val := time_alive * 2.0

	# Animated vortex — 7 per-frame PNGs, content-centered.
	# Phase-based frame index:
	#   grow  : frames 0..6 over expand_time
	#   hold  : frame 6 (rotating)
	#   shrink: frames 6..0 over shrink_time (reverse)
	var shrink_start: float = total_lifetime - shrink_time
	var frame: int = 6
	if time_alive < expand_time:
		var t: float = time_alive / expand_time
		frame = clampi(int(t * 7.0), 0, 6)
	elif time_alive >= shrink_start:
		var t: float = (time_alive - shrink_start) / shrink_time
		frame = clampi(6 - int(t * 7.0), 0, 6)
	var rot: float = time_alive * 0.9
	var tex_name: String = "black_hole_%d.png" % frame
	ProjectileSprites.draw_single(self, tex_name,
		current_radius * 2.4, rot, Color(1, 1, 1, fade))

	# Extra particle pulls for motion juice (on top of the sprite).
	for i in range(14):
		var angle := time_val * (0.8 + fmod(i * 0.13, 0.6)) \
			+ i * TAU / 14.0
		var t := fmod(time_alive * 0.5 + i * 0.12, 1.0)
		var dist := current_radius * (1.0 - t)
		var px := cos(angle) * dist
		var py := sin(angle) * dist
		var ps := 2.0 + t * 2.2
		var alpha := (1.0 - t) * 0.45 * fade
		draw_circle(Vector2(px, py), ps,
			Color(0.65, 0.3, 0.95, alpha))

	# Warning ring during expand phase.
	if time_alive < expand_time:
		var warn_pulse := sin(time_val * 5.0) * 0.3 + 0.5
		draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 32,
			Color(0.85, 0.25, 0.25, warn_pulse * 0.35 * fade), 2.0)
