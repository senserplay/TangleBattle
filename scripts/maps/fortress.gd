extends "res://scripts/maps/map_base.gd"
## Fortress — enclosed stone arena with solid walls instead of danger zones.
## Features sticky ceiling blocks that can't be passed from below.

func _init() -> void:
	map_name = "Fortress"
	platform_palette = "wood"
	bg_color = Color(0.15, 0.12, 0.1)
	bg_theme = "dawn"
	bg_tint = Color(0.85, 0.75, 0.65)
	platform_color = Color(0.4, 0.35, 0.28)
	platform_edge_color = Color(0.55, 0.48, 0.38)
	floor_color = Color(0.35, 0.28, 0.22)
	floor_edge_color = Color(0.5, 0.4, 0.32)

	use_walls = true
	map_rect = Rect2(0, 0, 4200, 3200)
	danger_top = 1.0  # create top wall
	danger_left = 0.0
	danger_right = 0.0
	danger_bottom = 0.0

	platforms = [
		# Ground floor
		[600, 2900, 1200, 50, false],
		[2700, 2900, 1200, 50, false],
		# Mid floor — wide central
		[2100, 2400, 900, 35, true],
		# Side ledges
		[400, 2100, 600, 30, true],
		[3800, 2100, 600, 30, true],
		# Upper mid
		[1400, 1700, 500, 30, true],
		[2800, 1700, 500, 30, true],
		# Central high
		[2100, 1300, 600, 30, true],
		# Side upper
		[500, 1000, 450, 28, true],
		[3700, 1000, 450, 28, true],
		# Ceiling sticky blocks — solid, can't pass from below
		[1200, 600, 400, 40, "sticky"],
		[2800, 600, 400, 40, "sticky"],
		[2000, 400, 500, 40, "sticky"],
	]

	objects = [
		["ball", 2100, 2000, 60],
		["ball", 900, 1500, 45],
		["ball", 3300, 1500, 45],
	]

	hazards = [
		# Moving platform in the middle gap
		["moving", 1800, 2650, 350, 24, 600, 0, 0.5],
	]

	spawn_points = [
		Vector2(600, 2830), Vector2(2700, 2830),
		Vector2(400, 2030), Vector2(3800, 2030),
	]


func _draw_decorations() -> void:
	# Dark stone interior — torches on walls
	var time_val := float(Engine.get_physics_frames()) * 0.02
	var r := map_rect

	# Torch positions on walls
	var torch_positions: Array[Vector2] = [
		Vector2(r.position.x + 30, 800),
		Vector2(r.position.x + 30, 1600),
		Vector2(r.position.x + 30, 2400),
		Vector2(r.end.x - 30, 800),
		Vector2(r.end.x - 30, 1600),
		Vector2(r.end.x - 30, 2400),
	]
	for tp in torch_positions:
		# Torch base
		draw_rect(Rect2(tp.x - 4, tp.y, 8, 20),
			Color(0.45, 0.3, 0.15))
		# Flame
		var flicker := sin(time_val * 5.0 + tp.x * 0.01) * 3.0
		draw_circle(Vector2(tp.x + flicker, tp.y - 5),
			8.0, Color(1.0, 0.6, 0.1, 0.4))
		draw_circle(Vector2(tp.x, tp.y - 8),
			5.0, Color(1.0, 0.8, 0.2, 0.5))
		# Light glow
		draw_circle(tp, 60.0, Color(1.0, 0.7, 0.3, 0.03))

	# Stone floor pattern
	for i in range(int(r.size.x / 80)):
		var sx := r.position.x + i * 80.0
		draw_line(Vector2(sx, r.end.y - 5),
			Vector2(sx, r.end.y), Color(0.25, 0.2, 0.15, 0.3), 1.0)

	# Banner decorations on walls
	for by in [1200, 2000]:
		# Left banner
		draw_rect(Rect2(r.position.x + 5, by, 25, 80),
			Color(0.6, 0.15, 0.1, 0.4))
		# Right banner
		draw_rect(Rect2(r.end.x - 30, by, 25, 80),
			Color(0.6, 0.15, 0.1, 0.4))
