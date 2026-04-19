extends "res://scripts/maps/map_base.gd"
## Deep Space — scattered asteroids in open void.
## Two portal pairs link distant edges. Open boundaries on all sides
## (death by drifting into the star-field void).

func _init() -> void:
	map_name = "Deep Space"
	platform_palette = "stone"
	bg_color = Color(0.02, 0.02, 0.08)
	bg_theme = "space"
	bg_tint = Color(1.0, 1.0, 1.0)
	death_zone_style = "stars"
	platform_color = Color(0.30, 0.34, 0.45)
	platform_edge_color = Color(0.55, 0.65, 0.85)
	floor_color = Color(0.25, 0.28, 0.40)
	floor_edge_color = Color(0.45, 0.55, 0.75)

	map_rect = Rect2(0, 0, 5400, 3200)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 350.0
	danger_top = 250.0  # space is open in ALL directions

	platforms = [
		# Big anchor asteroid in center-bottom
		[2700, 2650, 1100, 50, false],
		# Mid-tier asteroid clusters
		[900, 2300, 480, 30, true],
		[4500, 2300, 480, 30, true],
		[2000, 2100, 360, 28, true],
		[3400, 2100, 360, 28, true],
		# Upper drifting rocks
		[1300, 1750, 320, 26, true],
		[4100, 1750, 320, 26, true],
		[2700, 1700, 420, 28, true],
		# Way up rocks
		[700, 1350, 260, 24, true],
		[4700, 1350, 260, 24, true],
		[2000, 1300, 280, 26, true],
		[3400, 1300, 280, 26, true],
		# Top central asteroid
		[2700, 950, 380, 28, true],
		# Tiny far-edge stones — risky
		[400, 800, 180, 22, true],
		[5000, 800, 180, 22, true],
	]

	objects = [
		# Spherical asteroid balls
		["ball", 1700, 1950, 55],
		["ball", 3700, 1950, 55],
		["ball", 2700, 800, 45],
	]

	# Two portal pairs — diagonal warps
	teleports = [
		# Top-left summit ↔ bottom-right
		[400, 700, 200, 0.0, 5000, 700, 200, 0.0],
		# Bottom-left ↔ top-right (corner-to-corner space jump)
		[700, 1280, 220, 0.0, 4700, 1280, 220, 0.0],
	]

	item_spawns = [
		[2700, 850], [2700, 1620], [900, 2230], [4500, 2230],
	]

	spawn_points = [
		Vector2(2200, 2580), Vector2(3200, 2580),
		Vector2(900, 2230), Vector2(4500, 2230),
	]
