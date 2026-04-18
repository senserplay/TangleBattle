extends "res://scripts/maps/map_base.gd"
## Mirror — perfectly symmetric, portals connect the two halves.

func _init() -> void:
	map_name = "Mirror"
	platform_palette = "ice"
	bg_color = Color(0.08, 0.08, 0.15)
	platform_color = Color(0.35, 0.35, 0.5)
	platform_edge_color = Color(0.55, 0.55, 0.8)
	floor_color = Color(0.3, 0.3, 0.45)
	floor_edge_color = Color(0.45, 0.45, 0.7)

	var w := 4800.0
	var h := 3400.0
	var hw := w / 2.0  # half width for symmetry

	map_rect = Rect2(0, 0, w, h)
	danger_left = 250.0
	danger_right = 250.0
	danger_bottom = 500.0
	danger_top = 250.0

	# Perfectly symmetric platforms
	platforms = [
		# Floor — two halves
		[hw * 0.5, 2700, 1200, 50, false],
		[w - hw * 0.5, 2700, 1200, 50, false],
		# Level 1 — symmetric
		[600, 2300, 400, 28, true],
		[w - 600, 2300, 400, 28, true],
		[hw * 0.7, 2000, 450, 28, true],
		[w - hw * 0.7, 2000, 450, 28, true],
		# Level 2
		[hw * 0.4, 1600, 400, 28, true],
		[w - hw * 0.4, 1600, 400, 28, true],
		[hw, 1700, 500, 28, true],  # center bridge
		# Level 3
		[hw * 0.6, 1200, 350, 28, true],
		[w - hw * 0.6, 1200, 350, 28, true],
		# Top
		[hw * 0.5, 800, 300, 28, true],
		[w - hw * 0.5, 800, 300, 28, true],
		[hw, 500, 400, 28, true],  # center top
	]

	objects = [
		["ball", hw * 0.3, 1900, 55],
		["ball", w - hw * 0.3, 1900, 55],
	]

	# Portals connecting the two halves
	teleports = [
		[500, 1500, w - 500, 1500],  # left wall → right wall
		[hw * 0.4, 900, w - hw * 0.4, 900],  # upper crossing
	]

	hazards = [
		# Mirror spike pit in center
		["spikes", hw, 2730, 300, 30],
		# Symmetric moving platforms
		["moving", hw * 0.6, 1400, 280, 24, 0, -400, 0.7],
		["moving", w - hw * 0.6, 1400, 280, 24, 0, -400, 0.7],
	]

	item_spawns = [
		[hw, 1600], [hw * 0.5, 1100], [w - hw * 0.5, 1100],
	]

	spawn_points = [
		Vector2(hw * 0.5, 2630), Vector2(w - hw * 0.5, 2630),
		Vector2(hw * 0.7, 1930), Vector2(w - hw * 0.7, 1930),
	]


func _draw_decorations() -> void:
	var hw := map_rect.size.x / 2.0

	# Mirror line in center — glowing divider
	draw_line(
		Vector2(hw, danger_top + 20), Vector2(hw, map_rect.size.y - danger_bottom - 20),
		Color(0.5, 0.5, 0.9, 0.08), 4.0
	)
	# Dashed center line
	var dy := danger_top + 40.0
	while dy < map_rect.size.y - danger_bottom - 40:
		draw_line(Vector2(hw, dy), Vector2(hw, dy + 20),
			Color(0.5, 0.5, 0.9, 0.12), 2.0)
		dy += 40.0

	# Mirror reflections — faint copies of platforms on opposite side
	for data in platforms:
		var x: float = data[0]
		var y: float = data[1]
		var mirror_x := map_rect.size.x - x
		if absf(x - mirror_x) > 100:  # don't draw center ones
			draw_circle(Vector2(mirror_x, y), 15.0,
				Color(0.4, 0.4, 0.7, 0.02))

	# Crystal decorations
	for ci in range(8):
		var cx := fmod(ci * 600.0 + 200, map_rect.size.x)
		var cy := fmod(ci * 400.0 + 300, map_rect.size.y - 600) + 300
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - 15), Vector2(cx + 8, cy),
			Vector2(cx, cy + 15), Vector2(cx - 8, cy),
		]), Color(0.4, 0.4, 0.8, 0.06))
