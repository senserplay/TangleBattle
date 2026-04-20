extends "res://scripts/maps/map_base.gd"
## Desert Dunes — sunset desert with layered dune parallax.
## 9-layer parallax, sand platforms.

const BG := "res://assets/textures/backgrounds/desert/"


func _init() -> void:
	map_name = "Desert Dunes"
	platform_palette = "sand"
	bg_color = Color(0.40, 0.30, 0.25)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.80, 0.65, 0.40)
	platform_edge_color = Color(0.95, 0.80, 0.55)
	floor_color = Color(0.70, 0.55, 0.32)
	floor_edge_color = Color(0.85, 0.72, 0.48)

	bg_layers = [
		{"path": BG + "00_background.png","mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_stars.png",     "mode": "fill",        "scroll": 0.02, "tint": Color(1,1,1,0.6)},
		{"path": BG + "02_sun.png",       "mode": "fill",        "scroll": 0.04},
		{"path": BG + "03_clouds.png",    "mode": "top_tile",    "scroll": 0.10, "y": 120.0},
		{"path": BG + "04_mountains.png", "mode": "bottom_tile", "scroll": 0.18, "y": 160.0},
		{"path": BG + "05_dune_far.png",  "mode": "bottom_tile", "scroll": 0.28, "y": 120.0},
		{"path": BG + "06_dune_mid.png",  "mode": "bottom_tile", "scroll": 0.42, "y": 80.0},
		{"path": BG + "07_dune_close.png","mode": "bottom_tile", "scroll": 0.60, "y": 50.0},
		{"path": BG + "08_dune_front.png","mode": "bottom_tile", "scroll": 0.85, "y": 20.0},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[1000, 1950, 480, 32, true],
		[3500, 1950, 480, 32, true],
		[2250, 1680, 520, 32, true],
		[1400, 1380, 300, 32, true],
		[3100, 1380, 300, 32, true],
		[2250, 1100, 380, 32, true],
		[2250,  800, 260, 28, true],
	]

	item_spawns = [
		[2250, 1070], [1000, 1920], [3500, 1920], [2250, 770],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(1000, 1885), Vector2(3500, 1885),
	]
