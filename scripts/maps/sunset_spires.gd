extends "res://scripts/maps/map_base.gd"
## Sunset Spires — two stone towers above an abyss, connected by a portal.
## Tall vertical map, sunset sky, players can teleport between summits.

func _init() -> void:
	map_name = "Sunset Spires"
	platform_palette = "stone"
	bg_color = Color(0.45, 0.25, 0.30)
	bg_theme = "dawn"
	bg_tint = Color(1.0, 0.85, 0.65)
	death_zone_style = "abyss"
	platform_color = Color(0.40, 0.30, 0.35)
	platform_edge_color = Color(0.65, 0.50, 0.55)
	floor_color = Color(0.32, 0.22, 0.28)
	floor_edge_color = Color(0.5, 0.4, 0.45)

	map_rect = Rect2(0, 0, 5000, 3400)
	danger_left = 280.0
	danger_right = 280.0
	danger_bottom = 350.0
	danger_top = 0.0  # open sunset sky above

	platforms = [
		# Two big mountain plateaus (left + right) — base of each spire
		[1100, 2700, 1300, 80, false],
		[3900, 2700, 1300, 80, false],
		# Mid-flank step ledges climbing toward summits
		[700, 2350, 280, 26, true],
		[1500, 2350, 280, 26, true],
		[3500, 2350, 280, 26, true],
		[4300, 2350, 280, 26, true],
		# Tower mid-tier
		[1100, 2000, 600, 28, true],
		[3900, 2000, 600, 28, true],
		# Mid-air valley bridge stones
		[2000, 2200, 220, 26, true],
		[2500, 2050, 240, 26, true],
		[3000, 2200, 220, 26, true],
		# Tower upper-tier
		[1100, 1650, 520, 28, true],
		[3900, 1650, 520, 28, true],
		# Twin summit platforms
		[1100, 1300, 400, 30, true],
		[3900, 1300, 400, 30, true],
		# Sky bridge between peaks
		[2200, 1450, 220, 24, true],
		[2800, 1450, 220, 24, true],
		[2500, 1250, 280, 26, true],
		# Crown above the bridge
		[2500, 850, 320, 26, true],
	]

	objects = [
		# Big rocky orbs at the very tops of each spire
		["ball", 1100, 1180, 60],
		["ball", 3900, 1180, 60],
	]

	item_spawns = [
		[2500, 800], [2500, 1200], [1100, 1580], [3900, 1580],
	]

	spawn_points = [
		Vector2(1100, 2630), Vector2(3900, 2630),
		Vector2(1100, 1580), Vector2(3900, 1580),
	]

	# Summit-to-summit teleport — strategic high-ground swap
	teleports = [
		[1100, 1230, 280, 0.0, 3900, 1230, 280, 0.0],
	]
