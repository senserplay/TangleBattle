extends "res://scripts/maps/map_base.gd"
## Dungeon — dark map, torch light reveals only local areas.
## Players see limited visibility. Torches on platforms light up zones.

var torch_positions: Array[Vector2] = []
var time: float = 0.0

func _init() -> void:
	map_name = "Dungeon"
	platform_palette = "wood"
	bg_color = Color(0.02, 0.02, 0.04)
	platform_color = Color(0.3, 0.25, 0.2)
	platform_edge_color = Color(0.5, 0.4, 0.3)
	floor_color = Color(0.25, 0.2, 0.15)
	floor_edge_color = Color(0.4, 0.33, 0.22)

	map_rect = Rect2(0, 0, 4400, 3400)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 500.0
	danger_top = 250.0

	platforms = [
		[1100, 2700, 1600, 50, false],
		[3300, 2700, 1600, 50, false],
		[600, 2300, 450, 28, true],
		[2200, 2300, 550, 28, true],
		[3800, 2300, 450, 28, true],
		[1200, 1900, 500, 28, true],
		[3200, 1900, 500, 28, true],
		[2200, 1500, 600, 28, true],
		[700, 1200, 400, 28, true],
		[3700, 1200, 400, 28, true],
		[2200, 900, 450, 28, true],
		[1400, 600, 350, 28, true],
		[3000, 600, 350, 28, true],
	]

	objects = [
		["ball", 500, 2000, 50],
		["ball", 3900, 2000, 50],
	]

	hazards = [
		["spikes", 2200, 2730, 300, 30],
	]

	item_spawns = [
		[2200, 1400], [1200, 1800], [3200, 1800],
	]

	spawn_points = [
		Vector2(800, 2630), Vector2(3600, 2630),
		Vector2(1200, 1830), Vector2(3200, 1830),
	]

	# Torch positions for lighting
	torch_positions = [
		Vector2(600, 2250), Vector2(2200, 2250), Vector2(3800, 2250),
		Vector2(1200, 1850), Vector2(3200, 1850),
		Vector2(2200, 1450), Vector2(700, 1150), Vector2(3700, 1150),
		Vector2(2200, 850),
	]


func _draw_decorations() -> void:
	time += 0.016

	# Dark overlay — drawn AFTER platforms by overriding _draw
	# Torch flames
	for tpos in torch_positions:
		var flicker := sin(time * 6.0 + tpos.x * 0.01) * 0.1 + 0.9
		# Flame
		draw_circle(tpos + Vector2(0, -15), 6.0 * flicker,
			Color(1.0, 0.7, 0.2, 0.6 * flicker))
		draw_circle(tpos + Vector2(0, -15), 3.0,
			Color(1.0, 0.9, 0.5, 0.8))
		# Light radius — warm glow
		draw_circle(tpos, 150.0 * flicker,
			Color(1.0, 0.7, 0.3, 0.03 * flicker))
		draw_circle(tpos, 80.0 * flicker,
			Color(1.0, 0.75, 0.35, 0.05 * flicker))
		# Torch stick
		draw_line(tpos + Vector2(0, -8), tpos + Vector2(0, 15),
			Color(0.4, 0.3, 0.2), 3.0)

	# Cobwebs in corners
	for cx2 in [danger_left + 30.0, map_rect.size.x - danger_right - 30.0]:
		draw_line(Vector2(cx2, danger_top + 20), Vector2(cx2 + 50, danger_top + 60),
			Color(0.5, 0.5, 0.5, 0.1), 1.0)
		draw_line(Vector2(cx2, danger_top + 20), Vector2(cx2 - 30, danger_top + 70),
			Color(0.5, 0.5, 0.5, 0.08), 1.0)

	# Skull decorations
	for sx in [1800.0, 2600.0]:
		draw_circle(Vector2(sx, 2680), 8.0, Color(0.6, 0.55, 0.5, 0.2))
		draw_circle(Vector2(sx - 3, 2676), 2.0, Color(0, 0, 0, 0.3))
		draw_circle(Vector2(sx + 3, 2676), 2.0, Color(0, 0, 0, 0.3))
