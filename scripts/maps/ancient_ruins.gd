extends "res://scripts/maps/map_base.gd"
## Ancient Ruins — enclosed forest temple ruins with breakable walls.
## Solid stone walls bound the arena. Multiple destructible columns
## create dynamic combat as the structure crumbles round-by-round.

func _init() -> void:
	map_name = "Ancient Ruins"
	platform_palette = "stone"
	floor_strip = "alien_teal"
	bg_color = Color(0.18, 0.32, 0.20)
	bg_theme = "nature4"
	bg_tint = Color(1.0, 1.0, 1.0)
	platform_color = Color(0.45, 0.42, 0.35)
	platform_edge_color = Color(0.65, 0.60, 0.50)
	floor_color = Color(0.35, 0.32, 0.28)
	floor_edge_color = Color(0.50, 0.45, 0.40)

	use_walls = true
	map_rect = Rect2(0, 0, 4400, 3000)
	danger_left = 1.0
	danger_right = 1.0
	danger_bottom = 1.0
	danger_top = 1.0

	platforms = [
		# Wide ruined floor — strip-decorated
		[2200, 2550, 3600, 70, false],
		# Outer pillar tops (one-way)
		[600, 2150, 320, 30, true],
		[3800, 2150, 320, 30, true],
		# Mid ruin tier — bridges between pillars
		[1300, 2150, 380, 28, true],
		[3100, 2150, 380, 28, true],
		# Inner sanctuary platforms
		[1700, 1850, 460, 30, true],
		[2700, 1850, 460, 30, true],
		[2200, 1600, 380, 28, true],
		# Upper level — open temple roof remnants
		[1000, 1400, 320, 28, true],
		[3400, 1400, 320, 28, true],
		[2200, 1250, 320, 28, true],
		# Top central altar
		[2200, 900, 280, 26, true],
	]

	objects = [
		# Broken column orbs
		["ball", 1300, 2050, 50],
		["ball", 3100, 2050, 50],
	]

	# Destructible inner pillars — break under attacks
	destructibles = [
		[2200, 2300, 100, 200, 5],   # central column
		[1500, 2050, 90, 180, 4],
		[2900, 2050, 90, 180, 4],
	]

	item_spawns = [
		[2200, 850], [2200, 1530], [1700, 1780], [2700, 1780],
	]

	spawn_points = [
		Vector2(1300, 2480), Vector2(3100, 2480),
		Vector2(600, 2080), Vector2(3800, 2080),
	]
