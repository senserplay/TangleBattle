extends "res://scripts/maps/map_base.gd"
## Volcano — jagged platforms, lava, open top

func _init() -> void:
	map_name = "Volcano"
	platform_palette = "magma"
	bg_color = Color(0.18, 0.08, 0.05)
	platform_color = Color(0.4, 0.25, 0.15)
	platform_edge_color = Color(0.8, 0.4, 0.15)
	floor_color = Color(0.35, 0.18, 0.1)
	floor_edge_color = Color(0.6, 0.3, 0.1)

	map_rect = Rect2(0, 0, 4400, 3800)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 600.0
	danger_top = 0.0

	platforms = [
		# Floor fragments
		[700, 3000, 800, 50, false],
		[3700, 3000, 800, 50, false],
		[2200, 3050, 400, 40, false],
		# Level 1
		[1400, 2600, 500, 28, true],
		[3000, 2600, 500, 28, true],
		# Level 2
		[600, 2200, 450, 28, true],
		[2200, 2200, 600, 28, true],
		[3800, 2200, 450, 28, true],
		# Level 3
		[1200, 1800, 500, 28, true],
		[2800, 1800, 500, 28, true],
		# Level 4
		[500, 1400, 400, 28, true],
		[2000, 1400, 550, 28, true],
		[3500, 1400, 400, 28, true],
		# Level 5
		[1500, 1000, 500, 28, true],
		[2900, 1000, 500, 28, true],
		# Top
		[2200, 600, 400, 28, true],
		[800, 700, 350, 28, true],
		[3600, 700, 350, 28, true],
	]

	objects = [
		# Lava rocks (ball platforms)
		["ball", 1800, 2800, 50],
		["ball", 2600, 2800, 50],
		# Rocky arcs
		["arc", 1200, 1200, 200, 220, 320],
		["arc", 3200, 1200, 200, 220, 320],
	]

	parallax_layers = [
		{"scroll": 0.15, "color": Color(0.4, 0.1, 0.02, 0.06), "elements": [
			[600, 600, 100], [2200, 400, 120], [3800, 700, 90],
			[1400, 1200, 80], [3000, 1000, 110],
		]},
		{"scroll": 0.4, "color": Color(0.6, 0.15, 0.05, 0.04), "elements": [
			[800, 1500, 50, "diamond"], [2000, 2000, 40, "diamond"],
			[3500, 1800, 45, "diamond"], [1500, 2500, 35, "diamond"],
		]},
	]

	spawn_points = [
		Vector2(700, 2930), Vector2(3700, 2930),
		Vector2(1400, 2530), Vector2(3000, 2530),
	]


func _draw_decorations() -> void:
	var lava_y := map_rect.end.y - danger_bottom
	for i in range(30):
		draw_circle(
			Vector2(i * 160.0 + 20, lava_y + 150), 60.0,
			Color(1.0, 0.3, 0.05, 0.05)
		)
	draw_rect(Rect2(0, lava_y + 50, map_rect.size.x, 350), Color(0.9, 0.2, 0.05, 0.2))
	draw_line(Vector2(0, lava_y + 40), Vector2(map_rect.size.x, lava_y + 40), Color(1.0, 0.6, 0.1, 0.35), 3.0)
	for i in range(30):
		var ex := fmod(i * 203.0, map_rect.size.x)
		var ey := fmod(i * 127.0, 1800.0) + 600.0
		draw_circle(Vector2(ex, ey), 2.5, Color(1.0, 0.5, 0.1, 0.15 + fmod(i * 0.08, 0.2)))
