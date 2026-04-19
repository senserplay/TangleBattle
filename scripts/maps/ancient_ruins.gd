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
		# Two raised stone-block plinths flanking center (false = solid stone)
		[1400, 2350, 280, 130, false],
		[3000, 2350, 280, 130, false],
		# Outer pillar tops (one-way)
		[600, 2150, 320, 30, true],
		[3800, 2150, 320, 30, true],
		# Mid ruin tier — bridges between plinths and outer pillars
		[1000, 2050, 320, 26, true],
		[3400, 2050, 320, 26, true],
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
		# Carved temple orbs on plinths
		["ball", 1400, 2240, 55],
		["ball", 3000, 2240, 55],
		# Sky orb above the altar
		["ball", 2200, 700, 45],
	]

	item_spawns = [
		[2200, 850], [2200, 1530], [1700, 1780], [2700, 1780],
	]

	spawn_points = [
		Vector2(1300, 2480), Vector2(3100, 2480),
		Vector2(600, 2080), Vector2(3800, 2080),
	]
