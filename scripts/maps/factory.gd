extends "res://scripts/maps/map_base.gd"
## Factory — moving conveyor platforms, spike pits, industrial theme

func _init() -> void:
	map_name = "Factory"
	bg_color = Color(0.1, 0.1, 0.12)
	platform_color = Color(0.35, 0.35, 0.38)
	platform_edge_color = Color(0.55, 0.55, 0.6)
	floor_color = Color(0.28, 0.28, 0.32)
	floor_edge_color = Color(0.45, 0.45, 0.5)

	map_rect = Rect2(0, 0, 4800, 3600)
	danger_left = 300.0
	danger_right = 300.0
	danger_bottom = 500.0
	danger_top = 300.0

	platforms = [
		# Floor with spike gap in center
		[1000, 2900, 1400, 50, false],
		[3800, 2900, 1400, 50, false],
		# Mid platforms
		[700, 2400, 500, 28, true],
		[2400, 2300, 600, 28, true],
		[4100, 2400, 500, 28, true],
		# Upper
		[1200, 1800, 550, 28, true],
		[3600, 1800, 550, 28, true],
		# Top
		[2400, 1300, 500, 28, true],
		[900, 1100, 400, 28, true],
		[3900, 1100, 400, 28, true],
		[2400, 700, 400, 28, true],
	]

	objects = [
		["ball", 600, 2100, 55],
		["ball", 4200, 2100, 55],
	]

	hazards = [
		# Spike pit in center floor gap
		["spikes", 2400, 2920, 700, 40],
		# Spikes on ceiling
		["spikes", 2400, 350, 500, 30],
		# Moving platforms — horizontal
		["moving", 1800, 2000, 350, 24, 600, 0, 1.5],
		["moving", 3000, 2000, 350, 24, -600, 0, 1.2],
		# Moving platform — vertical
		["moving", 2400, 1700, 300, 24, 0, -500, 1.0],
	]

	teleports = [
		[600, 2800, 4200, 1000],  # bottom-left to top-right
	]
	item_spawns = [
		[2400, 2200], [1200, 1700], [3600, 1700],
	]

	spawn_points = [
		Vector2(800, 2830), Vector2(4000, 2830),
		Vector2(1200, 1730), Vector2(3600, 1730),
	]


func _draw_decorations() -> void:
	# Gears (decorative circles)
	for gx in [800.0, 2400.0, 4000.0]:
		for gy in [600.0, 1500.0]:
			draw_arc(
				Vector2(gx, gy), 30.0, 0.0, TAU, 16,
				Color(0.3, 0.3, 0.35, 0.2), 3.0
			)
			draw_arc(
				Vector2(gx, gy), 15.0, 0.0, TAU, 10,
				Color(0.35, 0.35, 0.4, 0.15), 2.0
			)

	# Pipes on walls
	for py in [500.0, 1200.0, 1900.0, 2600.0]:
		draw_line(
			Vector2(danger_left + 10, py),
			Vector2(danger_left + 10, py + 200),
			Color(0.4, 0.4, 0.45, 0.3), 6.0
		)
		draw_line(
			Vector2(map_rect.size.x - danger_right - 10, py + 100),
			Vector2(map_rect.size.x - danger_right - 10, py + 300),
			Color(0.4, 0.4, 0.45, 0.3), 6.0
		)

	# Warning stripes near spikes
	var stripe_col := Color(0.9, 0.7, 0.1, 0.15)
	draw_rect(Rect2(2050, 2860, 700, 10), stripe_col)
