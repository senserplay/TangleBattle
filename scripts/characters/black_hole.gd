extends Node2D
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


func setup_from_config(id: int, cfg: Dictionary) -> void:
	owner_id = id
	max_radius = cfg.get("max_radius", 250.0)
	expand_time = cfg.get("expand_time", 2.5)
	active_duration = cfg.get("active_duration", 8.0)
	pull_force = cfg.get("pull_force", 350.0)
	drain_per_sec = cfg.get("drain_per_sec", 5.0)
	total_lifetime = expand_time + active_duration


func _ready() -> void:
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= total_lifetime:
		queue_free()
		return

	if time_alive < expand_time:
		# Expanding phase — grow radius, pull starts immediately but weaker
		var t := time_alive / expand_time
		current_radius = max_radius * t * t  # ease-in
	else:
		current_radius = max_radius

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
	var remaining := total_lifetime - time_alive
	if remaining < 1.0:
		fade = remaining

	var time_val := time_alive * 2.0

	# Black core
	var core_r := current_radius * 0.3
	draw_circle(Vector2.ZERO, core_r,
		Color(0.02, 0.0, 0.05, 0.9 * fade))

	# Dark fill
	draw_circle(Vector2.ZERO, current_radius * 0.6,
		Color(0.05, 0.0, 0.1, 0.4 * fade))

	# Accretion disk — rotating arcs
	var disk_count := 3
	for i in range(disk_count):
		var arc_start := time_val * (1.5 + i * 0.3) + i * TAU / disk_count
		var arc_span := PI * 0.6
		var arc_r := current_radius * (0.5 + i * 0.15)
		var arc_col := Color(0.6, 0.2, 0.8, 0.3 * fade) if i % 2 == 0 \
			else Color(0.9, 0.4, 0.1, 0.25 * fade)
		draw_arc(Vector2.ZERO, arc_r, arc_start, arc_start + arc_span,
			12, arc_col, 3.0 - i * 0.5)

	# Outer ring — pulsing
	var pulse := 0.7 + sin(time_val * 3.0) * 0.15
	draw_arc(Vector2.ZERO, current_radius * pulse, 0.0, TAU, 24,
		Color(0.4, 0.1, 0.6, 0.25 * fade), 2.0)
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 24,
		Color(0.3, 0.05, 0.5, 0.15 * fade), 1.5)

	# Particles being sucked in
	for i in range(16):
		var angle := time_val * (0.8 + fmod(i * 0.13, 0.6)) \
			+ i * TAU / 16.0
		var t := fmod(time_alive * 0.5 + i * 0.12, 1.0)
		var dist := current_radius * (1.0 - t)
		var px := cos(angle) * dist
		var py := sin(angle) * dist
		var ps := 2.0 + t * 2.0
		var alpha := (1.0 - t) * 0.4 * fade
		draw_circle(Vector2(px, py), ps,
			Color(0.5, 0.2, 0.8, alpha))

	# Warning ring during expand phase
	if time_alive < expand_time:
		var warn_pulse := sin(time_val * 5.0) * 0.3 + 0.5
		draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 24,
			Color(0.8, 0.2, 0.2, warn_pulse * 0.3 * fade), 2.0)

	# Center glow
	draw_circle(Vector2.ZERO, core_r * 0.5,
		Color(0.4, 0.1, 0.6, 0.3 * fade))
