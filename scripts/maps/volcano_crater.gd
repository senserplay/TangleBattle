extends "res://scripts/maps/map_base.gd"
## Volcano Crater — compact lava-walled arena.
## Touching the walls deals fire damage. Spike pits inside the bowl.
## Lava-crystal strip on main floor.

func _init() -> void:
	map_name = "Volcano Crater"
	platform_palette = "magma"
	bg_color = Color(0.20, 0.05, 0.02)
	bg_theme = "clouds_sunset"
	bg_tint = Color(1.0, 0.55, 0.40)
	platform_color = Color(0.45, 0.20, 0.15)
	platform_edge_color = Color(0.75, 0.35, 0.18)
	floor_color = Color(0.35, 0.16, 0.10)
	floor_edge_color = Color(0.6, 0.30, 0.15)

	fire_walls = true
	map_rect = Rect2(0, 0, 4200, 2800)
	danger_left = 1.0  # walls cover boundaries
	danger_right = 1.0
	danger_bottom = 1.0
	danger_top = 1.0

	platforms = [
		# Main bowl floor — lava-crystal decorated
		[2100, 2350, 2600, 70, false],
		# Two flank ramps up the bowl walls
		[700, 1950, 600, 30, true],
		[3500, 1950, 600, 30, true],
		# Mid suspended slabs
		[1500, 1700, 380, 28, true],
		[2700, 1700, 380, 28, true],
		# Central elevated battle stage
		[2100, 1450, 700, 36, true],
		# Upper ledges
		[1100, 1200, 280, 26, true],
		[3100, 1200, 280, 26, true],
		# Top wide ledge — sniper position
		[2100, 950, 600, 30, true],
	]

	objects = [
		# Solidified lava bombs as rolling-platform balls
		["ball", 1500, 2150, 55],
		["ball", 2700, 2150, 55],
		["ball", 2100, 1300, 40],
	]

	# Spike pits between flank ramps
	hazards = [
		["spikes", 1100, 2310, 240, 30],
		["spikes", 3100, 2310, 240, 30],
	]

	item_spawns = [
		[2100, 850], [2100, 1380], [1500, 1620], [2700, 1620],
	]

	spawn_points = [
		Vector2(1500, 2280), Vector2(2700, 2280),
		Vector2(700, 1880), Vector2(3500, 1880),
	]
