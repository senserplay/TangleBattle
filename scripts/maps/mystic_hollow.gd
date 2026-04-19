extends "res://scripts/maps/map_base.gd"
## Mystic Hollow — purple-amethyst arena under a violet sunset sky.
## Spike pits flank the lower platforms. Cross portals teleport
## attackers to mirror-position. Atmospheric "void" death zones.

func _init() -> void:
	map_name = "Mystic Hollow"
	platform_palette = "stone"
	floor_strip = "amethyst_purple"
	bg_color = Color(0.20, 0.10, 0.30)
	bg_theme = "clouds_sunset"
	bg_tint = Color(0.75, 0.60, 1.00)
	death_zone_style = "void"
	platform_color = Color(0.40, 0.28, 0.50)
	platform_edge_color = Color(0.65, 0.50, 0.85)
	floor_color = Color(0.32, 0.20, 0.42)
	floor_edge_color = Color(0.55, 0.40, 0.70)

	map_rect = Rect2(0, 0, 4800, 3000)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 350.0
	danger_top = 280.0  # void on top too — eerie enclosure

	platforms = [
		# Main amethyst floor
		[2400, 2500, 3000, 70, false],
		# Mid-flank spike-flanked ledges
		[800, 2100, 480, 28, true],
		[4000, 2100, 480, 28, true],
		# Center mid arch platforms
		[1700, 1900, 380, 28, true],
		[3100, 1900, 380, 28, true],
		[2400, 1700, 460, 28, true],
		# Upper crystalline shelves
		[1100, 1450, 320, 26, true],
		[3700, 1450, 320, 26, true],
		[2400, 1300, 320, 26, true],
		# Top crown
		[1500, 950, 240, 24, true],
		[3300, 950, 240, 24, true],
		[2400, 700, 280, 26, true],
	]

	objects = [
		# Floating amethyst orbs
		["ball", 1700, 1750, 45],
		["ball", 3100, 1750, 45],
		["ball", 2400, 550, 50],
	]

	# Spike pits between mid ledges and main floor
	hazards = [
		["spikes", 1300, 2460, 240, 30],
		["spikes", 3500, 2460, 240, 30],
	]

	# Cross-portal: top-left summit ↔ top-right summit
	teleports = [
		[1500, 870, 220, 0.0, 3300, 870, 220, 0.0],
	]

	item_spawns = [
		[2400, 600], [2400, 1620], [1100, 1380], [3700, 1380],
	]

	spawn_points = [
		Vector2(1500, 2430), Vector2(3300, 2430),
		Vector2(800, 2030), Vector2(4000, 2030),
	]
