extends "res://scripts/maps/map_base.gd"
## Winter Valley — snowy daytime valley with nature layers.
## 10-layer pixel-art parallax, stone platforms.

const BG := "res://assets/textures/backgrounds/winter_pixel/"


func _init() -> void:
	map_name = "Winter Valley"
	platform_palette = "stone"
	bg_color = Color(0.55, 0.70, 0.82)
	bg_tint = Color(1.0, 1.0, 1.0)
	# Slightly slippery frost on stone
	floor_friction_mult = 0.6
	platform_color = Color(0.62, 0.68, 0.72)
	platform_edge_color = Color(0.85, 0.92, 0.98)
	floor_color = Color(0.55, 0.60, 0.64)
	floor_edge_color = Color(0.78, 0.85, 0.92)

	# winter_pixel folder has 10 stacked layers (00..09).
	bg_layers = [
		{"path": BG + "00_layer.png", "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_layer.png", "mode": "bottom_tile", "scroll": 0.08, "y": 220.0},
		{"path": BG + "02_layer.png", "mode": "bottom_tile", "scroll": 0.15, "y": 200.0},
		{"path": BG + "03_layer.png", "mode": "bottom_tile", "scroll": 0.24, "y": 180.0},
		{"path": BG + "04_layer.png", "mode": "bottom_tile", "scroll": 0.34, "y": 140.0},
		{"path": BG + "05_layer.png", "mode": "bottom_tile", "scroll": 0.45, "y": 110.0},
		{"path": BG + "06_layer.png", "mode": "bottom_tile", "scroll": 0.55, "y": 80.0},
		{"path": BG + "07_layer.png", "mode": "bottom_tile", "scroll": 0.65, "y": 60.0},
		{"path": BG + "08_layer.png", "mode": "bottom_tile", "scroll": 0.78, "y": 30.0},
		{"path": BG + "09_layer.png", "mode": "bottom_tile", "scroll": 0.90, "y": 10.0},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[900,  1920, 500, 32, true],
		[3600, 1920, 500, 32, true],
		[2250, 1650, 480, 32, true],
		[1400, 1380, 320, 32, true],
		[3100, 1380, 320, 32, true],
		[2250, 1100, 380, 32, true],
		[2250,  780, 260, 28, true],
	]

	item_spawns = [
		[2250, 1070], [900, 1890], [3600, 1890], [2250, 750],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(900, 1855),  Vector2(3600, 1855),
	]
