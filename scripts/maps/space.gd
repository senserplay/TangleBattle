extends "res://scripts/maps/map_base.gd"
## Space station — low gravity feel, moving platforms, laser spikes

func _init() -> void:
	map_name = "Space"
	platform_palette = "ice"
	bg_color = Color(0.02, 0.02, 0.06)
	bg_theme = "space"
	death_zone_style = "stars"
	platform_color = Color(0.3, 0.35, 0.45)
	platform_edge_color = Color(0.5, 0.6, 0.8)
	floor_color = Color(0.25, 0.3, 0.4)
	floor_edge_color = Color(0.4, 0.5, 0.7)

	map_rect = Rect2(0, 0, 5200, 3800)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 500.0
	danger_top = 0.0  # open top — space

	platforms = [
		# Station floor segments
		[1000, 3100, 1200, 50, false],
		[4200, 3100, 1200, 50, false],
		# Floating modules
		[2600, 2700, 500, 28, true],
		[800, 2400, 450, 28, true],
		[4400, 2400, 450, 28, true],
		[1800, 2000, 400, 28, true],
		[3400, 2000, 400, 28, true],
		[2600, 1600, 550, 28, true],
		[600, 1300, 400, 28, true],
		[4600, 1300, 400, 28, true],
		[2600, 1000, 400, 28, true],
		[1600, 700, 350, 28, true],
		[3600, 700, 350, 28, true],
	]

	objects = [
		["ball", 2600, 2200, 70],  # satellite
		["ball", 1200, 1700, 50],
		["ball", 4000, 1700, 50],
	]

	hazards = [
		# Laser spikes between floor segments
		["spikes", 2600, 3120, 600, 35],
		# Moving station modules
		["moving", 2000, 2400, 300, 24, 500, -200, 0.9],
		["moving", 3200, 2400, 300, 24, -500, -200, 1.1],
		# Vertical elevator
		["moving", 2600, 1800, 250, 24, 0, -600, 0.6],
	]

	events_enabled = true  # meteors, lightning, wind
	teleports = [
		[800, 2300, 4400, 1200],  # cross-station portal
	]
	item_spawns = [
		[2600, 2500], [1800, 1800], [3400, 1800],
	]

	parallax_layers = [
		{"scroll": 0.1, "color": Color(0.15, 0.1, 0.3, 0.04), "elements": [
			[1000, 500, 150], [3000, 300, 200], [4500, 800, 120],
		]},
		{"scroll": 0.3, "color": Color(0.2, 0.3, 0.5, 0.03), "elements": [
			[500, 1000, 60, "diamond"], [2000, 700, 50, "diamond"],
			[3500, 1200, 70, "diamond"], [4800, 600, 45, "diamond"],
		]},
	]

	spawn_points = [
		Vector2(800, 3030), Vector2(4400, 3030),
		Vector2(2600, 2630), Vector2(2600, 1530),
	]


func _draw_decorations() -> void:
	# Stars — lots of them
	for i in range(80):
		var sx := fmod(i * 137.5, map_rect.size.x)
		var sy := fmod(i * 97.3, map_rect.size.y)
		var brightness := 0.15 + fmod(i * 0.13, 0.35)
		var star_size := 1.0 + fmod(i * 0.07, 1.5)
		draw_circle(Vector2(sx, sy), star_size, Color(1, 1, 0.95, brightness))

	# Nebula patches
	for i in range(5):
		var nx := fmod(i * 1100.0 + 300, map_rect.size.x)
		var ny := fmod(i * 700.0 + 200, map_rect.size.y)
		draw_circle(Vector2(nx, ny), 80.0, Color(0.3, 0.1, 0.5, 0.04))
		draw_circle(Vector2(nx + 30, ny - 20), 50.0, Color(0.1, 0.2, 0.5, 0.03))

	# Station windows (glowing rectangles on walls)
	for wy in [800.0, 1600.0, 2400.0]:
		draw_rect(Rect2(danger_left + 20, wy, 40, 60),
			Color(0.3, 0.5, 0.8, 0.12))
		draw_rect(Rect2(map_rect.size.x - danger_right - 60, wy + 200, 40, 60),
			Color(0.3, 0.5, 0.8, 0.12))

	# Earth in background
	draw_circle(Vector2(4500, 500), 120.0, Color(0.15, 0.3, 0.6, 0.08))
	draw_arc(Vector2(4500, 500), 120.0, 0.0, TAU, 24, Color(0.2, 0.4, 0.7, 0.06), 2.0)
