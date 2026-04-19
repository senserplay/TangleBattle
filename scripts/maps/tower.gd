extends "res://scripts/maps/map_base.gd"
## Tower — very tall, zigzag, open top, ball landings

func _init() -> void:
	map_name = "Tower"
	platform_palette = "stone"
	bg_color = Color(0.1, 0.08, 0.14)
	bg_theme = "dawn"
	bg_tint = Color(0.70, 0.65, 0.85)
	death_zone_style = "abyss"
	platform_color = Color(0.4, 0.35, 0.45)
	platform_edge_color = Color(0.65, 0.55, 0.75)
	floor_color = Color(0.3, 0.25, 0.35)
	floor_edge_color = Color(0.5, 0.4, 0.6)

	map_rect = Rect2(0, 0, 3600, 5200)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 550.0
	danger_top = 0.0

	platforms = [
		# Ground
		[1800, 4400, 1200, 50, false],
		# Zigzag going up
		[700, 4050, 550, 28, true],
		[2900, 4050, 550, 28, true],
		[1300, 3650, 500, 28, true],
		[2300, 3650, 500, 28, true],
		[700, 3250, 550, 28, true],
		[2900, 3250, 550, 28, true],
		[1300, 2850, 500, 28, true],
		[2300, 2850, 500, 28, true],
		[1800, 2450, 600, 28, true],
		[600, 2100, 450, 28, true],
		[3000, 2100, 450, 28, true],
		[1800, 1700, 550, 28, true],
		[700, 1350, 450, 28, true],
		[2900, 1350, 450, 28, true],
		[1800, 1000, 500, 28, true],
		[1100, 650, 400, 28, true],
		[2500, 650, 400, 28, true],
	]

	objects = [
		# Ball landings at turns
		["ball", 500, 3450, 50],
		["ball", 3100, 3450, 50],
		["ball", 500, 2650, 50],
		["ball", 3100, 2650, 50],
		# Arc platforms at mid-tower
		["arc", 1800, 2100, 200, 210, 330],
	]

	spawn_points = [
		Vector2(1500, 4330), Vector2(2100, 4330),
		Vector2(700, 3980), Vector2(2900, 3980),
	]


func _draw_decorations() -> void:
	for i in range(25):
		var by := i * 200.0 + 40.0
		draw_rect(Rect2(danger_left - 10, by, 35, 55), Color(0.2, 0.18, 0.25, 0.2))
		draw_rect(
			Rect2(map_rect.size.x - danger_right - 25, by + 100, 35, 55),
			Color(0.2, 0.18, 0.25, 0.2)
		)
	for tx in [danger_left + 70.0, map_rect.size.x - danger_right - 70.0]:
		for ty in [800.0, 1600.0, 2400.0, 3200.0, 4000.0]:
			draw_circle(Vector2(tx, ty), 7.0, Color(1.0, 0.7, 0.2, 0.35))
			draw_circle(Vector2(tx, ty), 14.0, Color(1.0, 0.6, 0.1, 0.06))
			draw_line(Vector2(tx, ty + 7), Vector2(tx, ty + 35), Color(0.4, 0.3, 0.2), 3.0)
