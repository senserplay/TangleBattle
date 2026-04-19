extends "res://scripts/maps/map_base.gd"
## Jungle — vines, moving leaf platforms, spike thorns, open top

func _init() -> void:
	map_name = "Jungle"
	platform_palette = "grass"
	bg_color = Color(0.05, 0.12, 0.06)
	bg_theme = "forest"
	bg_tint = Color(1.0, 1.0, 1.0)
	death_zone_style = "swamp"
	platform_color = Color(0.35, 0.25, 0.15)
	platform_edge_color = Color(0.5, 0.4, 0.2)
	floor_color = Color(0.3, 0.2, 0.1)
	floor_edge_color = Color(0.45, 0.35, 0.18)

	map_rect = Rect2(0, 0, 5000, 4000)
	danger_left = 300.0
	danger_right = 300.0
	danger_bottom = 550.0
	danger_top = 0.0  # open top

	platforms = [
		# Ground
		[1300, 3200, 1800, 50, false],
		[3700, 3200, 1800, 50, false],
		# Tree branches
		[700, 2700, 500, 28, true],
		[2500, 2600, 600, 28, true],
		[4300, 2700, 500, 28, true],
		[1200, 2200, 450, 28, true],
		[3800, 2200, 450, 28, true],
		[2500, 1800, 550, 28, true],
		[800, 1500, 400, 28, true],
		[4200, 1500, 400, 28, true],
		[2500, 1100, 400, 28, true],
		[1500, 800, 350, 28, true],
		[3500, 800, 350, 28, true],
	]

	objects = [
		["ball", 500, 2400, 60],  # coconut
		["ball", 4500, 2400, 60],
		["ball", 2500, 1500, 50],
		["arc", 1800, 2800, 200, 210, 330],
		["arc", 3200, 2800, 200, 210, 330],
	]

	hazards = [
		# Thorn spikes on ground gaps
		["spikes", 2500, 3230, 400, 30],
		# Moving vine platforms
		["moving", 1800, 1900, 280, 22, 0, -400, 0.8],
		["moving", 3200, 1900, 280, 22, 0, -400, 1.1],
		# Swinging platform
		["moving", 2500, 2300, 300, 22, 500, 0, 0.7],
	]

	destructibles = [
		[1800, 2600, 300, 22, 3],  # breaks after 3 hits
		[3200, 2600, 300, 22, 3],
	]
	item_spawns = [
		[2500, 1400], [1200, 2100], [3800, 2100],
	]

	spawn_points = [
		Vector2(1000, 3130), Vector2(4000, 3130),
		Vector2(700, 2630), Vector2(4300, 2630),
	]


func _draw_decorations() -> void:
	# Vines hanging from top
	for i in range(15):
		var vx := fmod(i * 367.0, map_rect.size.x)
		var vine_len := 100.0 + fmod(i * 53.0, 300.0)
		var col := Color(0.2, 0.45, 0.15, 0.3)
		draw_line(Vector2(vx, 0), Vector2(vx + 15, vine_len), col, 2.5)
		# Leaves
		if i % 3 == 0:
			draw_circle(Vector2(vx + 10, vine_len * 0.6), 8.0,
				Color(0.15, 0.5, 0.1, 0.25))

	# Mushrooms on floor
	for mx in [600.0, 1800.0, 3200.0, 4400.0]:
		draw_circle(Vector2(mx, 3180), 12.0, Color(0.6, 0.15, 0.1, 0.3))
		draw_rect(Rect2(mx - 3, 3180, 6, 20), Color(0.5, 0.4, 0.3, 0.25))

	# Fireflies
	for i in range(20):
		var fx := fmod(i * 263.0, map_rect.size.x)
		var fy := fmod(i * 181.0, map_rect.size.y * 0.7) + 200
		draw_circle(Vector2(fx, fy), 2.0, Color(0.8, 1.0, 0.3, 0.2))
