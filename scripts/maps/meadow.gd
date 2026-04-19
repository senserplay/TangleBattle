extends "res://scripts/maps/map_base.gd"
## Meadow — peaceful daytime forest, scattered grass islands, swamp pit below.

func _init() -> void:
	map_name = "Meadow"
	platform_palette = "grass"
	bg_color = Color(0.45, 0.65, 0.55)
	bg_theme = "forest"
	bg_tint = Color(1.0, 1.0, 1.0)
	death_zone_style = "swamp"
	platform_color = Color(0.35, 0.55, 0.30)
	platform_edge_color = Color(0.5, 0.75, 0.40)
	floor_color = Color(0.30, 0.45, 0.25)
	floor_edge_color = Color(0.45, 0.65, 0.35)

	map_rect = Rect2(0, 0, 5000, 3200)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 350.0
	danger_top = 0.0  # open sky for forest backdrop

	platforms = [
		# Wide ground island
		[2500, 2600, 2200, 60, false],
		# Mid-tier grass shelves
		[1100, 2100, 500, 28, true],
		[3900, 2100, 500, 28, true],
		[2500, 1900, 700, 28, true],
		# Upper canopy platforms
		[800, 1500, 380, 28, true],
		[4200, 1500, 380, 28, true],
		[1900, 1300, 350, 28, true],
		[3100, 1300, 350, 28, true],
		# Crown platform
		[2500, 850, 500, 28, true],
		[1500, 600, 320, 28, true],
		[3500, 600, 320, 28, true],
	]

	objects = [
		["ball", 2500, 2200, 55],
	]

	item_spawns = [
		[2500, 1800], [1500, 2000], [3500, 2000], [2500, 750],
	]

	spawn_points = [
		Vector2(1600, 2530), Vector2(3400, 2530),
		Vector2(1100, 2030), Vector2(3900, 2030),
	]
