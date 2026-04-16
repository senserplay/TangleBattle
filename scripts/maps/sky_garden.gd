extends "res://scripts/maps/map_base.gd"
## Sky Garden — open top, floating islands with ball-planets

func _init() -> void:
	map_name = "Sky Garden"
	bg_color = Color(0.15, 0.2, 0.35)
	platform_color = Color(0.3, 0.5, 0.35)
	platform_edge_color = Color(0.5, 0.8, 0.45)
	floor_color = Color(0.25, 0.4, 0.3)
	floor_edge_color = Color(0.4, 0.65, 0.4)

	map_rect = Rect2(0, 0, 5200, 4000)
	danger_left = 350.0
	danger_right = 350.0
	danger_bottom = 600.0
	danger_top = 0.0

	platforms = [
		# Bottom layer
		[800, 3000, 700, 28, true],
		[2200, 3100, 500, 28, true],
		[3000, 3100, 500, 28, true],
		[4400, 3000, 700, 28, true],
		# Mid-low
		[1400, 2600, 550, 28, true],
		[2600, 2500, 600, 28, true],
		[3800, 2600, 550, 28, true],
		# Mid
		[600, 2100, 500, 28, true],
		[1800, 2100, 450, 28, true],
		[3400, 2100, 450, 28, true],
		[4600, 2100, 500, 28, true],
		# Mid-high
		[1200, 1600, 500, 28, true],
		[2600, 1500, 600, 28, true],
		[4000, 1600, 500, 28, true],
		# High
		[800, 1100, 450, 28, true],
		[2000, 1000, 500, 28, true],
		[3200, 1000, 500, 28, true],
		[4400, 1100, 450, 28, true],
		# Top
		[2600, 600, 400, 28, true],
	]

	objects = [
		# Floating planet-balls
		["ball", 1000, 1800, 80],
		["ball", 4200, 1800, 80],
		["ball", 2600, 1200, 70],
		# Crescent arcs
		["arc", 600, 2700, 200, 240, 340],
		["arc", 4600, 2700, 200, 200, 300],
	]

	spawn_points = [
		Vector2(800, 2930), Vector2(4400, 2930),
		Vector2(1400, 2530), Vector2(3800, 2530),
	]


func _draw_decorations() -> void:
	for cx in [500.0, 1500.0, 2800.0, 3800.0, 4700.0]:
		var cy := 250.0 + fmod(cx * 0.5, 350.0)
		_draw_cloud(Vector2(cx, cy), 0.1)
	for cx in [900.0, 2200.0, 3500.0, 4900.0]:
		var cy := 80.0 + fmod(cx * 0.25, 200.0)
		_draw_cloud(Vector2(cx, cy), 0.06)
	for i in range(60):
		var sx := fmod(i * 137.5, 5200.0)
		var sy := fmod(i * 97.3, 700.0) + 10.0
		draw_circle(Vector2(sx, sy), 1.5, Color(1, 1, 0.9, 0.15 + fmod(i * 0.1, 0.25)))


func _draw_cloud(pos: Vector2, alpha: float) -> void:
	var c := Color(0.7, 0.75, 0.9, alpha)
	draw_circle(pos, 45.0, c)
	draw_circle(pos + Vector2(-35, 10), 32.0, c)
	draw_circle(pos + Vector2(35, 8), 38.0, c)
	draw_circle(pos + Vector2(12, -15), 30.0, c)
