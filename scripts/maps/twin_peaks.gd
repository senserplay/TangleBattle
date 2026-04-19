extends "res://scripts/maps/map_base.gd"
## Twin Peaks — sunset valley between two mountain silhouettes, abyss below.

func _init() -> void:
	map_name = "Twin Peaks"
	platform_palette = "stone"
	bg_color = Color(0.30, 0.18, 0.30)
	bg_theme = "dawn"
	bg_tint = Color(1.0, 0.85, 0.65)
	death_zone_style = "abyss"
	platform_color = Color(0.40, 0.30, 0.35)
	platform_edge_color = Color(0.65, 0.50, 0.55)
	floor_color = Color(0.32, 0.22, 0.28)
	floor_edge_color = Color(0.5, 0.4, 0.45)

	map_rect = Rect2(0, 0, 5200, 3200)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 350.0
	danger_top = 0.0  # open sky for dawn parallax

	platforms = [
		# Two big mountain plateaus (left + right)
		[1100, 2400, 1500, 80, false],
		[4100, 2400, 1500, 80, false],
		# Stepped slopes climbing the peaks
		[600, 2000, 350, 28, true],
		[4600, 2000, 350, 28, true],
		[1600, 2000, 350, 28, true],
		[3600, 2000, 350, 28, true],
		# Mid valley bridge platforms
		[2200, 2150, 280, 28, true],
		[3000, 2150, 280, 28, true],
		[2600, 1900, 320, 28, true],
		# Twin summit platforms
		[1100, 1500, 480, 32, true],
		[4100, 1500, 480, 32, true],
		# Sky bridge between peaks
		[2200, 1300, 200, 24, true],
		[3000, 1300, 200, 24, true],
		[2600, 1100, 350, 28, true],
		# Crown
		[2600, 700, 280, 28, true],
	]

	objects = [
		["ball", 1100, 1400, 60],
		["ball", 4100, 1400, 60],
	]

	item_spawns = [
		[2600, 1050], [1100, 2300], [4100, 2300], [2600, 1850],
	]

	spawn_points = [
		Vector2(1100, 2330), Vector2(4100, 2330),
		Vector2(1100, 1430), Vector2(4100, 1430),
	]

	teleports = [
		[1100, 1450, 280, 0.0, 4100, 1450, 280, 0.0],
	]
