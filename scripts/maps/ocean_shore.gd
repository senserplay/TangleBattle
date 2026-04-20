extends "res://scripts/maps/map_base.gd"
## Ocean Shore — sunset beach with waves and distant mountains.
## 7-layer parallax, sand platforms.

const BG := "res://assets/textures/backgrounds/ocean/"


func _init() -> void:
	map_name = "Ocean Shore"
	platform_palette = "sand"
	bg_color = Color(0.42, 0.55, 0.68)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.85, 0.72, 0.48)
	platform_edge_color = Color(1.00, 0.88, 0.62)
	floor_color = Color(0.72, 0.60, 0.38)
	floor_edge_color = Color(0.90, 0.78, 0.52)

	bg_layers = [
		{"path": BG + "00_sky_sun.png",    "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_sun_light.png",  "mode": "fill",        "scroll": 0.05, "tint": Color(1,1,1,0.85)},
		{"path": BG + "02_clouds.png",     "mode": "top_tile",    "scroll": 0.10, "y": 120.0},
		{"path": BG + "03_mountains.png",  "mode": "bottom_tile", "scroll": 0.22, "y": 180.0},
		{"path": BG + "04_sea.png",        "mode": "bottom_tile", "scroll": 0.42, "y": 100.0},
		{"path": BG + "05_sand.png",       "mode": "bottom_tile", "scroll": 0.70, "y": 40.0},
		{"path": BG + "06_wave.png",       "mode": "bottom_tile", "scroll": 0.90, "y": 10.0, "tint": Color(1,1,1,0.85)},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[950,  1950, 480, 32, true],
		[3550, 1950, 480, 32, true],
		[1850, 1650, 420, 32, true],
		[2650, 1650, 420, 32, true],
		[750,  1350, 300, 32, true],
		[3750, 1350, 300, 32, true],
		[2250, 1080, 420, 32, true],
		[2250,  780, 280, 28, true],
	]

	item_spawns = [
		[2250, 1050], [950, 1920], [3550, 1920], [2250, 750],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(950, 1885),  Vector2(3550, 1885),
	]
