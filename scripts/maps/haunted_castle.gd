extends "res://scripts/maps/map_base.gd"
## Haunted Castle — moonlit spooky castle grounds with deep fog.
## 11-layer parallax, stone platforms.

const BG := "res://assets/textures/backgrounds/halloween/"


func _init() -> void:
	map_name = "Haunted Castle"
	platform_palette = "stone"
	bg_color = Color(0.08, 0.06, 0.14)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.30, 0.30, 0.36)
	platform_edge_color = Color(0.55, 0.50, 0.65)
	floor_color = Color(0.24, 0.24, 0.30)
	floor_edge_color = Color(0.45, 0.42, 0.55)

	bg_layers = [
		{"path": BG + "00_castle_bg.png", "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_moon.png",      "mode": "fill",        "scroll": 0.04, "tint": Color(1,1,1,0.95)},
		{"path": BG + "02_clouds.png",    "mode": "top_tile",    "scroll": 0.10, "y": 120.0, "tint": Color(1,1,1,0.75)},
		{"path": BG + "03_fog_back1.png", "mode": "bottom_tile", "scroll": 0.18, "y": 200.0, "tint": Color(1,1,1,0.55)},
		{"path": BG + "04_fog_back2.png", "mode": "bottom_tile", "scroll": 0.25, "y": 170.0, "tint": Color(1,1,1,0.50)},
		{"path": BG + "05_castle.png",    "mode": "bottom_tile", "scroll": 0.35, "y": 180.0},
		{"path": BG + "06_trees1.png",    "mode": "bottom_tile", "scroll": 0.50, "y": 120.0},
		{"path": BG + "07_trees2.png",    "mode": "bottom_tile", "scroll": 0.60, "y": 80.0},
		{"path": BG + "08_fog_front1.png","mode": "bottom_tile", "scroll": 0.70, "y": 50.0, "tint": Color(1,1,1,0.60)},
		{"path": BG + "09_fog_front2.png","mode": "bottom_tile", "scroll": 0.80, "y": 30.0, "tint": Color(1,1,1,0.55)},
		{"path": BG + "10_land.png",      "mode": "bottom_tile", "scroll": 0.92, "y": 10.0},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[900,  1940, 500, 32, true],
		[3600, 1940, 500, 32, true],
		[1850, 1640, 420, 32, true],
		[2650, 1640, 420, 32, true],
		[650,  1380, 300, 32, true],
		[3850, 1380, 300, 32, true],
		[2250, 1100, 460, 32, true],
		[2250,  780, 300, 28, true],
	]

	item_spawns = [
		[2250, 1070], [900, 1910], [3600, 1910], [2250, 750],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(900, 1875),  Vector2(3600, 1875),
	]
