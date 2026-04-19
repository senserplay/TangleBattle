extends "res://scripts/maps/map_base.gd"
## Workshop — warm enclosed arena, lots of platforms

func _init() -> void:
	map_name = "Workshop"
	platform_palette = "wood"
	bg_color = Color(0.14, 0.11, 0.16)
	bg_theme = "dawn"
	bg_tint = Color(0.55, 0.50, 0.60)
	death_zone_style = "abyss"
	platform_color = Color(0.45, 0.3, 0.2)
	platform_edge_color = Color(0.7, 0.5, 0.3)
	floor_color = Color(0.35, 0.22, 0.15)
	floor_edge_color = Color(0.55, 0.38, 0.25)

	map_rect = Rect2(0, 0, 4800, 3600)
	danger_left = 300.0
	danger_right = 300.0
	danger_bottom = 500.0
	danger_top = 300.0

	platforms = [
		# Floor
		[1200, 2900, 1800, 50, false],
		[3600, 2900, 1800, 50, false],
		# Level 1
		[600, 2500, 500, 28, true],
		[1800, 2450, 600, 28, true],
		[3000, 2450, 600, 28, true],
		[4200, 2500, 500, 28, true],
		# Level 2
		[1000, 2000, 550, 28, true],
		[2400, 2100, 700, 28, true],
		[3800, 2000, 550, 28, true],
		# Level 3
		[600, 1600, 450, 28, true],
		[1700, 1650, 500, 28, true],
		[3100, 1650, 500, 28, true],
		[4200, 1600, 450, 28, true],
		# Level 4
		[1200, 1200, 600, 28, true],
		[2400, 1300, 500, 28, true],
		[3600, 1200, 600, 28, true],
		# Top
		[2400, 800, 550, 28, true],
		[1000, 900, 400, 28, true],
		[3800, 900, 400, 28, true],
	]

	objects = [
		# Yarn ball platforms
		["ball", 800, 2200, 60],
		["ball", 4000, 2200, 60],
		# Curved shelves
		["arc", 2400, 1700, 250, 200, 340],
	]

	# Parallax — warm wooden shelves in background
	parallax_layers = [
		{"scroll": 0.2, "color": Color(0.25, 0.18, 0.12, 0.08), "elements": [
			[800, 800, 60], [2000, 600, 80], [3500, 900, 70],
			[1200, 1400, 50], [3800, 1200, 65], [600, 2000, 55],
		]},
		{"scroll": 0.5, "color": Color(0.3, 0.22, 0.15, 0.06), "elements": [
			[500, 500, 40, "rect"], [1500, 1000, 50, "rect"],
			[2800, 700, 45, "rect"], [4000, 1500, 55, "rect"],
		]},
	]

	spawn_points = [
		Vector2(900, 2830), Vector2(3900, 2830),
		Vector2(2100, 2380), Vector2(2700, 2380),
	]


func _draw_decorations() -> void:
	for lx in [1200.0, 2400.0, 3600.0]:
		draw_line(Vector2(lx, 300), Vector2(lx, 500), Color(0.3, 0.25, 0.2), 2.0)
		draw_circle(Vector2(lx, 510), 12.0, Color(1.0, 0.85, 0.4, 0.5))
		draw_circle(Vector2(lx, 510), 30.0, Color(1.0, 0.85, 0.4, 0.05))
	for bx in [500.0, 1500.0, 2400.0, 3300.0, 4300.0]:
		draw_circle(Vector2(bx, 2870), 14.0, Color(0.5, 0.3, 0.4, 0.3))
