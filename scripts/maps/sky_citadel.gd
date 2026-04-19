extends "res://scripts/maps/map_base.gd"
## Sky Citadel — drifting cloud islands above an endless sky.
## Periodic wind events shove players sideways. Open all directions.

var wind_timer: float = 0.0
var wind_strength: float = 0.0
var wind_direction: float = 0.0
const WIND_INTERVAL := 11.0
const WIND_FORCE := 320.0
const WIND_DURATION := 1.6

func _init() -> void:
	map_name = "Sky Citadel"
	platform_palette = "ice"
	bg_color = Color(0.20, 0.55, 0.85)
	bg_theme = "clouds_blue"
	bg_tint = Color(1.0, 1.0, 1.0)
	death_zone_style = "mist"
	platform_color = Color(0.85, 0.92, 1.0)
	platform_edge_color = Color(1.0, 1.0, 1.0)
	floor_color = Color(0.70, 0.85, 0.95)
	floor_edge_color = Color(0.95, 0.97, 1.0)

	map_rect = Rect2(0, 0, 5000, 3000)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 380.0
	danger_top = 0.0  # open sky above and below

	platforms = [
		# Three big floating cloud islands — primary stages
		[1200, 2300, 850, 50, false],
		[3800, 2300, 850, 50, false],
		[2500, 2050, 600, 40, false],
		# Lower long platform — last-resort recovery shelf
		[2500, 2600, 1100, 36, false],
		# Mid-tier puffy clouds (one-way)
		[800, 1850, 320, 24, true],
		[4200, 1850, 320, 24, true],
		[1700, 1600, 280, 24, true],
		[3300, 1600, 280, 24, true],
		# Upper drifting clouds
		[2500, 1400, 380, 26, true],
		[1100, 1200, 260, 22, true],
		[3900, 1200, 260, 22, true],
		[2500, 950, 300, 24, true],
		# Top-most lookout cloud
		[2500, 600, 220, 22, true],
	]

	objects = [
		# Cloud puff balls
		["ball", 1700, 1300, 50],
		["ball", 3300, 1300, 50],
	]

	item_spawns = [
		[2500, 550], [2500, 900], [1200, 2230], [3800, 2230],
	]

	spawn_points = [
		Vector2(1200, 2230), Vector2(3800, 2230),
		Vector2(1700, 1530), Vector2(3300, 1530),
	]


func _process(delta: float) -> void:
	super._process(delta)
	wind_timer += delta
	if wind_timer >= WIND_INTERVAL and wind_strength <= 0.0:
		wind_timer = 0.0
		wind_strength = WIND_DURATION
		wind_direction = 1.0 if randf() > 0.5 else -1.0
	if wind_strength > 0.0:
		wind_strength -= delta
		for p in get_tree().get_nodes_in_group("players"):
			if p.is_alive:
				p.velocity.x += wind_direction * WIND_FORCE * delta * 5.0


func _draw_decorations() -> void:
	# Wind warning text + visual streaks
	if wind_strength > 0.0:
		var alpha: float = clampf(wind_strength / WIND_DURATION, 0.0, 1.0)
		var streak_col := Color(0.95, 0.97, 1.0, alpha * 0.65)
		var t := float(Engine.get_physics_frames()) * 0.04
		for i in range(20):
			var sy: float = 200.0 + i * 130.0
			var phase: float = sin(t + i * 0.7) * 30.0
			var sx: float = fmod(t * wind_direction * 800.0 + i * 213.0,
				map_rect.size.x + 400.0) - 200.0
			draw_line(Vector2(sx, sy + phase),
				Vector2(sx + wind_direction * 120.0, sy + phase),
				streak_col, 2.5)
