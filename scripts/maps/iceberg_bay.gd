extends "res://scripts/maps/map_base.gd"
## Iceberg Bay — frozen sea with mountain parallax and iceberg silhouettes.
## 7-layer parallax, lava_ice platforms (icy surface).

const BG := "res://assets/textures/backgrounds/iceberg/"


func _init() -> void:
	map_name = "Iceberg Bay"
	platform_palette = "lava_ice"
	bg_color = Color(0.55, 0.72, 0.86)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.78, 0.88, 0.95)
	platform_edge_color = Color(0.95, 0.98, 1.00)
	floor_color = Color(0.60, 0.78, 0.92)
	floor_edge_color = Color(0.80, 0.92, 1.00)

	bg_layers = [
		{"path": BG + "00_sky.png",             "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_cloud.png",           "mode": "top_tile",    "scroll": 0.08, "y": 120.0},
		{"path": BG + "02_mountains.png",       "mode": "bottom_tile", "scroll": 0.20, "y": 200.0},
		{"path": BG + "03_iceberg_reflex.png",  "mode": "bottom_tile", "scroll": 0.38, "y": 100.0},
		{"path": BG + "04_iceberg.png",         "mode": "bottom_tile", "scroll": 0.55, "y": 50.0},
		{"path": BG + "05_water_reflex.png",    "mode": "bottom_tile", "scroll": 0.75, "y": 30.0, "tint": Color(1,1,1,0.75)},
		{"path": BG + "06_water.png",           "mode": "bottom_tile", "scroll": 0.90, "y": 10.0, "tint": Color(1,1,1,0.5)},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[800,  1940, 500, 32, true],
		[3700, 1940, 500, 32, true],
		[2250, 1680, 500, 32, true],
		[1350, 1360, 320, 32, true],
		[3150, 1360, 320, 32, true],
		[2250, 1080, 400, 32, true],
		[2250,  760, 260, 28, true],
	]

	item_spawns = [
		[2250, 1050], [800, 1910], [3700, 1910], [2250, 730],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(800, 1875),  Vector2(3700, 1875),
	]
