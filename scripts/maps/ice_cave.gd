extends "res://scripts/maps/map_base.gd"
## Ice Cave — symmetric, enclosed, icy arcs

func _init() -> void:
	map_name = "Ice Cave"
	platform_palette = "ice"
	bg_color = Color(0.08, 0.12, 0.2)
	platform_color = Color(0.35, 0.5, 0.6)
	platform_edge_color = Color(0.6, 0.8, 0.95)
	floor_color = Color(0.3, 0.4, 0.5)
	floor_edge_color = Color(0.5, 0.7, 0.85)

	map_rect = Rect2(0, 0, 4600, 3400)
	danger_left = 300.0
	danger_right = 300.0
	danger_bottom = 500.0
	danger_top = 250.0

	platforms = [
		# Floor
		[1200, 2700, 1600, 50, false],
		[3400, 2700, 1600, 50, false],
		# Level 1
		[700, 2350, 500, 28, true],
		[2300, 2350, 600, 28, true],
		[3900, 2350, 500, 28, true],
		# Level 2
		[1200, 1950, 550, 28, true],
		[2300, 2000, 500, 28, true],
		[3400, 1950, 550, 28, true],
		# Level 3
		[700, 1550, 500, 28, true],
		[2300, 1600, 650, 28, true],
		[3900, 1550, 500, 28, true],
		# Level 4
		[1400, 1200, 550, 28, true],
		[3200, 1200, 550, 28, true],
		# Top
		[2300, 850, 500, 28, true],
		[1000, 900, 400, 28, true],
		[3600, 900, 400, 28, true],
	]

	objects = [
		# Ice ball platforms
		["ball", 500, 1900, 55],
		["ball", 4100, 1900, 55],
		["ball", 2300, 1350, 50],
		# Ice half-pipe arcs
		["arc", 1600, 2550, 180, 200, 340],
		["arc", 3000, 2550, 180, 200, 340],
	]

	spawn_points = [
		Vector2(900, 2630), Vector2(3700, 2630),
		Vector2(1200, 1880), Vector2(3400, 1880),
	]


func _draw_decorations() -> void:
	for i in range(40):
		var ix := fmod(i * 121.0, map_rect.size.x)
		var ih := 25.0 + fmod(i * 19.0, 45.0)
		var iw := 4.0 + fmod(i * 9.0, 7.0)
		var col := Color(0.5, 0.7, 0.9, 0.22)
		draw_polygon(
			PackedVector2Array([
				Vector2(ix - iw, danger_top),
				Vector2(ix + iw, danger_top),
				Vector2(ix, danger_top + ih),
			]),
			PackedColorArray([col, col, col.darkened(0.2)])
		)
	for i in range(10):
		var cy := 500.0 + i * 280.0
		_draw_crystal(Vector2(danger_left + 20, cy), 0.2)
		_draw_crystal(Vector2(map_rect.size.x - danger_right - 20, cy), 0.2)
	for i in range(35):
		var sx := fmod(i * 143.0 + 60.0, map_rect.size.x)
		var sy := fmod(i * 91.0 + 200.0, map_rect.size.y - 500) + 300
		draw_circle(Vector2(sx, sy), 1.8, Color(0.7, 0.85, 1.0, 0.18))


func _draw_crystal(pos: Vector2, alpha: float) -> void:
	var c := Color(0.5, 0.75, 1.0, alpha)
	draw_polygon(
		PackedVector2Array([
			pos + Vector2(0, -28), pos + Vector2(10, 0),
			pos + Vector2(0, 28), pos + Vector2(-10, 0),
		]),
		PackedColorArray([c, c, c, c])
	)
