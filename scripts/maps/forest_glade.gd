extends "res://scripts/maps/map_base.gd"
## Forest Glade — daytime forest meadow with grass-topped platforms.
## Open sky overhead, swamp pit below. Symmetric layout, beginner-friendly.

func _init() -> void:
	map_name = "Forest Glade"
	platform_palette = "grass"
	bg_color = Color(0.40, 0.62, 0.74)
	bg_theme = "forest"
	bg_tint = Color(1.0, 1.0, 1.0)
	death_zone_style = "swamp"
	platform_color = Color(0.35, 0.55, 0.30)
	platform_edge_color = Color(0.5, 0.75, 0.40)
	floor_color = Color(0.30, 0.45, 0.25)
	floor_edge_color = Color(0.45, 0.65, 0.35)

	map_rect = Rect2(0, 0, 4400, 2900)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 380.0
	danger_top = 0.0

	platforms = [
		# Big main meadow floor
		[2200, 2500, 2800, 70, false],
		# Symmetric mid grass islands
		[900, 2050, 520, 28, true],
		[3500, 2050, 520, 28, true],
		# Upper canopy ledges
		[1900, 1700, 380, 28, true],
		[2900, 1700, 380, 28, true],
		# Tall flanking pillars
		[600, 1500, 280, 28, true],
		[3800, 1500, 280, 28, true],
		# Crown shelf
		[2200, 1250, 480, 28, true],
		# Top-most lookout
		[2200, 850, 280, 24, true],
	]

	objects = [
		# Decorative log balls
		["ball", 1400, 2200, 45],
		["ball", 3000, 2200, 45],
	]

	item_spawns = [
		[2200, 1200], [900, 2000], [3500, 2000], [2200, 800],
	]

	spawn_points = [
		Vector2(1200, 2430), Vector2(3200, 2430),
		Vector2(900, 1980), Vector2(3500, 1980),
	]
