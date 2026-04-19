extends "res://scripts/maps/map_base.gd"
## Frozen Lake — wide icy plain with floating ice shards above.
## Bouncy walls deflect players in chaotic patterns. Ice-crystal floor strip.

func _init() -> void:
	map_name = "Frozen Lake"
	platform_palette = "ice"
	bg_color = Color(0.20, 0.45, 0.70)
	bg_theme = "clouds_blue"
	bg_tint = Color(0.65, 0.78, 0.95)
	platform_color = Color(0.45, 0.65, 0.80)
	platform_edge_color = Color(0.75, 0.88, 1.0)
	floor_color = Color(0.35, 0.55, 0.70)
	floor_edge_color = Color(0.60, 0.80, 0.95)

	bouncy_walls = true
	map_rect = Rect2(0, 0, 4800, 2700)
	danger_left = 1.0
	danger_right = 1.0
	danger_bottom = 1.0
	danger_top = 1.0

	platforms = [
		# Wide frozen lake floor with ice deco
		[2400, 2300, 4000, 70, false],
		# Mid floating ice shelves
		[800, 1900, 480, 30, true],
		[4000, 1900, 480, 30, true],
		[2400, 1850, 600, 32, true],
		# Upper shards (smaller, scattered)
		[1500, 1500, 280, 26, true],
		[3300, 1500, 280, 26, true],
		[2400, 1350, 240, 24, true],
		# Top suspended ice
		[700, 1100, 220, 24, true],
		[4100, 1100, 220, 24, true],
		[2400, 900, 320, 26, true],
	]

	objects = [
		# Ice-block balls scattered on lake
		["ball", 1500, 2150, 55],
		["ball", 3300, 2150, 55],
		["ball", 2400, 700, 45],
	]

	item_spawns = [
		[2400, 850], [2400, 1280], [1500, 1430], [3300, 1430],
	]

	spawn_points = [
		Vector2(1200, 2230), Vector2(3600, 2230),
		Vector2(800, 1830), Vector2(4000, 1830),
	]
