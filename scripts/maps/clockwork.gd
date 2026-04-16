extends "res://scripts/maps/map_base.gd"
## Clockwork — rotating gear platforms, swinging pendulums.

var clock_time: float = 0.0

func _init() -> void:
	map_name = "Clockwork"
	bg_color = Color(0.12, 0.1, 0.08)
	platform_color = Color(0.5, 0.4, 0.3)
	platform_edge_color = Color(0.7, 0.6, 0.45)
	floor_color = Color(0.4, 0.32, 0.22)
	floor_edge_color = Color(0.6, 0.5, 0.35)

	map_rect = Rect2(0, 0, 4800, 3600)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 500.0
	danger_top = 250.0

	platforms = [
		# Base
		[1200, 2900, 1600, 50, false],
		[3600, 2900, 1600, 50, false],
		# Static platforms between gears
		[2400, 2400, 400, 28, true],
		[800, 2000, 400, 28, true],
		[4000, 2000, 400, 28, true],
		[2400, 1600, 450, 28, true],
		[1400, 1200, 350, 28, true],
		[3400, 1200, 350, 28, true],
		[2400, 800, 400, 28, true],
	]

	objects = [
		# Gear ball platforms — rotate around center
		["ball", 1600, 2200, 70],  # big gear
		["ball", 3200, 2200, 70],
		["ball", 2400, 1200, 60],
	]

	hazards = [
		# Pendulum platforms — swing side to side
		["moving", 1200, 1700, 300, 24, 800, 0, 0.5],
		["moving", 3600, 1700, 300, 24, -800, 0, 0.5],
		# Vertical piston
		["moving", 2400, 2000, 250, 24, 0, -500, 0.8],
		# Spikes at bottom center
		["spikes", 2400, 2930, 400, 30],
	]

	destructibles = [
		[1800, 1800, 250, 22, 4],
		[3000, 1800, 250, 22, 4],
	]

	item_spawns = [
		[2400, 1500], [1200, 1900], [3600, 1900],
	]

	spawn_points = [
		Vector2(900, 2830), Vector2(3900, 2830),
		Vector2(2200, 2330), Vector2(2600, 2330),
	]


func _process(delta: float) -> void:
	super._process(delta)
	clock_time += delta


func _draw_decorations() -> void:
	# Large background gears (decorative, rotating)
	for gi in range(6):
		var gx := fmod(gi * 900.0 + 400, map_rect.size.x)
		var gy := fmod(gi * 600.0 + 300, map_rect.size.y - 400) + 200
		var gr := 80.0 + fmod(gi * 30.0, 60.0)
		var rot := clock_time * (0.3 + gi * 0.1) * (1.0 if gi % 2 == 0 else -1.0)
		var col := Color(0.3, 0.25, 0.18, 0.08)
		# Gear teeth
		var teeth := 8 + gi % 4
		for ti in range(teeth):
			var ta := rot + ti * TAU / teeth
			var inner := Vector2(gx + cos(ta) * gr * 0.8, gy + sin(ta) * gr * 0.8)
			var outer := Vector2(gx + cos(ta) * gr, gy + sin(ta) * gr)
			draw_line(inner, outer, col, 4.0)
		draw_arc(Vector2(gx, gy), gr * 0.8, 0.0, TAU, 16, col, 2.0)
		draw_circle(Vector2(gx, gy), gr * 0.2, col)

	# Pendulum chains (visual)
	for px in [1200.0, 3600.0]:
		var anchor_y := danger_top + 50.0
		draw_line(Vector2(px, anchor_y), Vector2(px, anchor_y + 200),
			Color(0.4, 0.35, 0.25, 0.2), 2.0)

	# Clock face in center
	var ccx := map_rect.size.x / 2.0
	var ccy := 500.0
	draw_arc(Vector2(ccx, ccy), 60.0, 0.0, TAU, 20,
		Color(0.5, 0.4, 0.3, 0.1), 3.0)
	# Hour hand
	var hour_angle := clock_time * 0.1
	draw_line(Vector2(ccx, ccy),
		Vector2(ccx + cos(hour_angle) * 35, ccy + sin(hour_angle) * 35),
		Color(0.5, 0.4, 0.3, 0.15), 3.0)
	# Minute hand
	var min_angle := clock_time * 0.5
	draw_line(Vector2(ccx, ccy),
		Vector2(ccx + cos(min_angle) * 50, ccy + sin(min_angle) * 50),
		Color(0.5, 0.4, 0.3, 0.1), 2.0)
