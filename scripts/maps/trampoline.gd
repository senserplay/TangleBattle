extends "res://scripts/maps/map_base.gd"
## Trampoline — bouncy walls arena. All walls reflect players.
## High-energy chaotic combat.

func _init() -> void:
	map_name = "Trampoline"
	bg_color = Color(0.08, 0.1, 0.18)
	platform_color = Color(0.3, 0.35, 0.5)
	platform_edge_color = Color(0.45, 0.5, 0.7)
	floor_color = Color(0.25, 0.3, 0.45)
	floor_edge_color = Color(0.4, 0.45, 0.65)

	bouncy_walls = true
	map_rect = Rect2(0, 0, 3800, 3000)
	danger_top = 1.0  # top wall for bouncing
	danger_left = 0.0
	danger_right = 0.0
	danger_bottom = 0.0

	platforms = [
		# Central platform
		[1900, 1800, 600, 35, true],
		# Four corner platforms
		[500, 2400, 400, 30, true],
		[3300, 2400, 400, 30, true],
		[500, 1200, 400, 30, true],
		[3300, 1200, 400, 30, true],
		# Mid side
		[1200, 2100, 350, 28, true],
		[2600, 2100, 350, 28, true],
		# Upper mid
		[1200, 1400, 350, 28, true],
		[2600, 1400, 350, 28, true],
		# Top and bottom center
		[1900, 2500, 400, 28, true],
		[1900, 800, 400, 28, true],
	]

	objects = [
		["ball", 1900, 1500, 50],
		["ball", 900, 1800, 35],
		["ball", 2900, 1800, 35],
	]

	hazards = [
		# Moving platforms — bouncing around adds to chaos
		["moving", 1400, 1000, 250, 24, 300, 300, 0.8],
		["moving", 2400, 2300, 250, 24, -300, -200, 0.7],
	]

	spawn_points = [
		Vector2(500, 2330), Vector2(3300, 2330),
		Vector2(500, 1130), Vector2(3300, 1130),
	]


func _draw_decorations() -> void:
	var time_val := float(Engine.get_physics_frames()) * 0.02
	var r := map_rect

	# Neon grid lines on floor/walls — sporty gym feel
	var grid_col := Color(0.2, 0.8, 0.5, 0.04)
	# Horizontal lines
	for i in range(int(r.size.y / 100)):
		var gy := r.position.y + i * 100.0
		draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy),
			grid_col, 1.0)
	# Vertical lines
	for i in range(int(r.size.x / 100)):
		var gx := r.position.x + i * 100.0
		draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y),
			grid_col, 1.0)

	# Pulsing glow circles at wall bounce zones
	var pulse := sin(time_val * 3.0) * 0.03 + 0.05
	# Corners
	for corner in [r.position, Vector2(r.end.x, r.position.y),
		Vector2(r.position.x, r.end.y), r.end]:
		draw_circle(corner, 80.0, Color(0.2, 0.9, 0.6, pulse))

	# Center glow
	var center := Vector2(r.position.x + r.size.x / 2.0,
		r.position.y + r.size.y / 2.0)
	draw_circle(center, 120.0, Color(0.3, 0.5, 1.0, pulse * 0.5))

	# Speed lines — diagonal streaks
	for i in range(8):
		var sx := fmod(i * 500.0 + time_val * 60.0, r.size.x + 400) - 200
		var sy := fmod(i * 370.0 + time_val * 40.0, r.size.y + 400) - 200
		var line_len := 40.0 + sin(time_val + i) * 15.0
		draw_line(
			Vector2(r.position.x + sx, r.position.y + sy),
			Vector2(r.position.x + sx + line_len, r.position.y + sy + line_len),
			Color(0.4, 0.8, 1.0, 0.06), 2.0)
