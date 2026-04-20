extends "res://scripts/maps/map_base.gd"
## Forest Glade — misty blue forest with layered tree parallax.
## 10-layer parallax, stone platforms, water bottom, side vignette.

const BG := "res://assets/textures/backgrounds/forest_blue/"


func _init() -> void:
	map_name = "Forest Glade"
	platform_palette = "stone"
	bg_color = Color(0.15, 0.22, 0.30)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.38, 0.38, 0.40)
	platform_edge_color = Color(0.60, 0.62, 0.65)
	floor_color = Color(0.32, 0.32, 0.34)
	floor_edge_color = Color(0.52, 0.54, 0.56)

	bg_layers = [
		{"path": BG + "00_sky.png",         "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_forest_far.png",  "mode": "bottom_tile", "scroll": 0.08, "y": 180.0},
		{"path": BG + "02_forest_mid_far.png", "mode": "bottom_tile", "scroll": 0.18, "y": 150.0},
		{"path": BG + "03_forest_mid.png",  "mode": "bottom_tile", "scroll": 0.28, "y": 120.0},
		{"path": BG + "04_forest_close.png","mode": "bottom_tile", "scroll": 0.40, "y": 80.0},
		{"path": BG + "05_particles_back.png","mode": "bottom_tile","scroll": 0.45, "y": 0.0, "tint": Color(1,1,1,0.7)},
		{"path": BG + "06_forest_front.png","mode": "bottom_tile", "scroll": 0.55, "y": 40.0},
		{"path": BG + "07_particles_front.png","mode":"bottom_tile","scroll": 0.68, "y": 0.0, "tint": Color(1,1,1,0.6)},
		{"path": BG + "09_mist.png",        "mode": "bottom_tile", "scroll": 0.35, "y": 120.0, "tint": Color(1,1,1,0.55)},
		{"path": BG + "08_bushes.png",      "mode": "bottom_tile", "scroll": 0.85, "y": 40.0},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[900,  1900, 520, 32, true],
		[3600, 1900, 520, 32, true],
		[1900, 1580, 380, 32, true],
		[2600, 1580, 380, 32, true],
		[620,  1380, 300, 32, true],
		[3880, 1380, 300, 32, true],
		[2250, 1120, 480, 32, true],
		[2250,  780, 300, 28, true],
	]

	item_spawns = [
		[2250, 1080], [900, 1870], [3600, 1870], [2250, 750],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(900, 1835),  Vector2(3600, 1835),
	]
