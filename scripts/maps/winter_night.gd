extends "res://scripts/maps/map_base.gd"
## Winter Night — dark winter forest at night, 5-layer parallax.
## Wood platforms over deep water.

const BG := "res://assets/textures/backgrounds/winternight/"


func _init() -> void:
	map_name = "Winter Night"
	platform_palette = "wood"
	bg_color = Color(0.08, 0.10, 0.18)
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.45, 0.30, 0.18)
	platform_edge_color = Color(0.70, 0.48, 0.28)
	floor_color = Color(0.38, 0.25, 0.15)
	floor_edge_color = Color(0.60, 0.40, 0.22)

	bg_layers = [
		{"path": BG + "00_sky.png",          "mode": "fill",        "scroll": 0.00},
		{"path": BG + "01_backmountain.png", "mode": "bottom_tile", "scroll": 0.12, "y": 220.0},
		{"path": BG + "02_midmountain.png",  "mode": "bottom_tile", "scroll": 0.28, "y": 170.0},
		{"path": BG + "03_midforest.png",    "mode": "bottom_tile", "scroll": 0.50, "y": 110.0},
		{"path": BG + "04_frontfloor.png",   "mode": "bottom_tile", "scroll": 0.85, "y": 40.0},
	]

	map_rect = Rect2(0, 0, 4500, 2800)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 420.0
	danger_top = 0.0

	platforms = [
		[2250, 2300, 2800, 60, false],
		[950,  1920, 480, 32, true],
		[3550, 1920, 480, 32, true],
		[1850, 1650, 420, 32, true],
		[2650, 1650, 420, 32, true],
		[2250, 1350, 360, 32, true],
		[700,  1170, 280, 32, true],
		[3800, 1170, 280, 32, true],
		[2250,  900, 320, 28, true],
	]

	item_spawns = [
		[2250, 870], [950, 1890], [3550, 1890], [2250, 1320],
	]

	spawn_points = [
		Vector2(1250, 2235), Vector2(3250, 2235),
		Vector2(950, 1855),  Vector2(3550, 1855),
	]
