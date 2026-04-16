extends Node2D
## Heaven's Wrath — massive light pillars rain down from sky.
## Pillars spawn from player position toward aim direction, hitting the ground.
## They pass through platforms and deal damage on contact.

var owner_id: int = -1
var owner_ref: Node = null
var damage: float = 30.0
var pillar_count: int = 6
var pillar_spacing: float = 120.0
var pillar_width: float = 60.0
var pillar_delay: float = 0.12  # delay between each pillar
var pillar_speed: float = 3000.0  # fall speed (very fast)

var aim_dir: Vector2 = Vector2.RIGHT
var start_pos: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var map_top: float = 0.0
var map_bottom: float = 3200.0

# Active pillar state
var pillars: Array[Dictionary] = []
var spawn_timer: float = 0.0
var pillars_spawned: int = 0
var time_alive: float = 0.0
const TOTAL_LIFETIME := 4.0  # total visual lifetime


func setup_from_config(
	id: int, dir: Vector2, col: Color, cfg: Dictionary
) -> void:
	owner_id = id
	aim_dir = Vector2(dir.x, 0.0).normalized()
	if aim_dir.length() < 0.1:
		aim_dir = Vector2.RIGHT
	color = col
	damage = cfg.get("damage", 30.0)
	pillar_count = int(cfg.get("pillar_count", 6))
	pillar_spacing = cfg.get("pillar_spacing", 120.0)
	pillar_width = cfg.get("pillar_width", 60.0)
	pillar_delay = cfg.get("pillar_delay", 0.12)
	pillar_speed = cfg.get("pillar_speed", 3000.0)


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _ready() -> void:
	add_to_group("ability_entities")
	# Get map bounds
	var game := get_tree().current_scene
	if game != null and "current_map" in game and game.current_map != null:
		var mr: Rect2 = game.current_map.map_rect
		map_top = mr.position.y - 200.0
		map_bottom = mr.end.y + 200.0


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= TOTAL_LIFETIME:
		queue_free()
		return

	# Spawn pillars sequentially
	if pillars_spawned < pillar_count:
		spawn_timer += delta
		if spawn_timer >= pillar_delay:
			spawn_timer -= pillar_delay
			_spawn_pillar(pillars_spawned)
			pillars_spawned += 1

	# Update pillars
	for p in pillars:
		if p["phase"] == "falling":
			p["y"] += pillar_speed * delta
			if p["y"] >= map_bottom:
				p["phase"] = "impact"
				p["impact_timer"] = 0.5
				_deal_damage(p["x"], p["w"])
				SoundManager.play_explosion()
		elif p["phase"] == "impact":
			p["impact_timer"] -= delta
			if p["impact_timer"] <= 0.0:
				p["phase"] = "fading"
				p["fade_timer"] = 0.8
		elif p["phase"] == "fading":
			p["fade_timer"] -= delta

	queue_redraw()


func _spawn_pillar(index: int) -> void:
	var offset_x: float = (index + 1) * pillar_spacing * aim_dir.x
	var px: float = start_pos.x + offset_x
	var pw: float = pillar_width * (1.0 - index * 0.05)  # slightly narrower each
	pillars.append({
		"x": px,
		"w": maxf(pw, 30.0),
		"y": map_top,  # starts above map
		"phase": "falling",
		"impact_timer": 0.0,
		"fade_timer": 0.0,
		"index": index,
	})


func _deal_damage(px: float, pw: float) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive or p.player_id == owner_id:
			continue
		var dx: float = absf(p.global_position.x - px)
		if dx < pw * 0.6:
			var src: Node = owner_ref if is_instance_valid(owner_ref) else null
			var dmg_mult: float = src.damage_multiplier if src != null else 1.0
			p.take_damage(damage * dmg_mult, src)
			p.apply_knockback(Vector2(0, -400.0))


func _draw() -> void:
	for p in pillars:
		var px: float = p["x"]
		var pw: float = p["w"]
		var phase: String = p["phase"]

		if phase == "falling":
			# Light beam falling from sky
			var beam_top: float = map_top
			var beam_bottom: float = p["y"]
			var beam_height: float = beam_bottom - beam_top

			if beam_height < 1.0:
				continue

			# Main beam — bright white-gold center
			var hw := pw * 0.5
			# Core (bright)
			draw_rect(Rect2(px - hw * 0.3, beam_top, pw * 0.3, beam_height),
				Color(1.0, 0.95, 0.8, 0.6))
			# Glow (wider, semi-transparent)
			draw_rect(Rect2(px - hw, beam_top, pw, beam_height),
				Color(1.0, 0.9, 0.7, 0.15))
			# Outer glow
			draw_rect(Rect2(px - hw * 1.5, beam_top, pw * 1.5, beam_height),
				Color(1.0, 0.85, 0.6, 0.05))

			# Leading edge — bright flash at bottom
			draw_circle(Vector2(px, beam_bottom), pw * 0.4,
				Color(1.0, 1.0, 0.9, 0.7))

		elif phase == "impact":
			# Full pillar with impact flash
			var alpha: float = p["impact_timer"] / 0.5
			var height := map_bottom - map_top

			# Core beam
			draw_rect(Rect2(px - pw * 0.15, map_top, pw * 0.3, height),
				Color(1.0, 0.95, 0.8, 0.5 * alpha))
			# Glow
			draw_rect(Rect2(px - pw * 0.5, map_top, pw, height),
				Color(1.0, 0.9, 0.7, 0.12 * alpha))

			# Impact flash at bottom — expanding ring
			var ring_r := pw * (1.5 - alpha * 0.5)
			draw_arc(Vector2(px, map_bottom - 20),
				ring_r, 0.0, TAU, 16,
				Color(1.0, 0.95, 0.7, 0.4 * alpha), 3.0)
			draw_circle(Vector2(px, map_bottom - 20),
				pw * 0.3 * alpha,
				Color(1.0, 1.0, 0.9, 0.6 * alpha))

			# Dissipation near bottom — fading particles
			for i in range(4):
				var scatter_x := px + randf_range(-pw, pw)
				var scatter_y := map_bottom - 40.0 - i * 30.0
				draw_circle(Vector2(scatter_x, scatter_y),
					6.0 * alpha, Color(1.0, 0.9, 0.7, 0.2 * alpha))

		elif phase == "fading":
			if p["fade_timer"] <= 0.0:
				continue
			var alpha: float = p["fade_timer"] / 0.8
			var height := map_bottom - map_top

			# Fading afterglow — thin line
			draw_rect(Rect2(px - 2, map_top, 4, height),
				Color(1.0, 0.95, 0.85, 0.15 * alpha))
			# Scattered light particles floating up
			var t := time_alive * 2.0
			for i in range(3):
				var fy := map_bottom - fmod(t * 100 + i * 200, height)
				draw_circle(Vector2(px + sin(t + i) * 15.0, fy),
					3.0 * alpha,
					Color(1.0, 0.95, 0.8, 0.2 * alpha))
