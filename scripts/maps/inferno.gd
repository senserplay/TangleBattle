extends "res://scripts/maps/map_base.gd"
## Inferno — lava-walled arena. Touching walls deals fire damage.

func _init() -> void:
	map_name = "Inferno"
	bg_color = Color(0.2, 0.05, 0.02)
	platform_color = Color(0.35, 0.2, 0.15)
	platform_edge_color = Color(0.55, 0.3, 0.15)
	floor_color = Color(0.3, 0.15, 0.1)
	floor_edge_color = Color(0.5, 0.25, 0.12)

	fire_walls = true
	map_rect = Rect2(0, 0, 4400, 3400)
	danger_top = 1.0  # create top wall
	danger_left = 0.0
	danger_right = 0.0
	danger_bottom = 0.0

	platforms = [
		# Ground — two halves with gap (lava pit below)
		[800, 3000, 1200, 50, false],
		[3200, 3000, 1200, 50, false],
		# Bridges over lava pit
		[2200, 2800, 400, 25, true],
		# Mid level
		[600, 2400, 500, 30, true],
		[3800, 2400, 500, 30, true],
		[2200, 2200, 700, 30, true],
		# Upper level
		[1200, 1800, 450, 28, true],
		[3200, 1800, 450, 28, true],
		# High platforms
		[2200, 1400, 500, 28, true],
		[800, 1100, 400, 28, true],
		[3600, 1100, 400, 28, true],
		# Top
		[2200, 800, 600, 28, true],
	]

	objects = [
		["ball", 2200, 2600, 50],
		["ball", 1000, 1500, 40],
		["ball", 3400, 1500, 40],
	]

	hazards = [
		# Spikes at the bottom of the lava pit
		["spikes", 2200, 3300, 600, 30],
		# Moving rock platforms over the pit
		["moving", 1700, 2900, 250, 24, 400, 0, 0.7],
		["moving", 2700, 2600, 250, 24, -400, 0, 0.6],
	]

	spawn_points = [
		Vector2(800, 2930), Vector2(3200, 2930),
		Vector2(600, 2330), Vector2(3800, 2330),
	]


func _draw_decorations() -> void:
	var time_val := float(Engine.get_physics_frames()) * 0.02
	var r := map_rect

	# Lava glow from below — gradient at bottom
	for i in range(8):
		var t := float(i) / 8.0
		var glow_y := r.end.y - 200.0 + i * 25.0
		var glow_alpha := (1.0 - t) * 0.08
		draw_rect(Rect2(r.position.x, glow_y, r.size.x, 25.0),
			Color(1.0, 0.3, 0.05, glow_alpha))

	# Floating embers
	for i in range(25):
		var ex := fmod(i * 197.0 + time_val * 20.0 * (1.0 + fmod(i * 0.3, 1.0)),
			r.size.x)
		var ey := fmod(i * 283.0 - time_val * 40.0 * (0.5 + fmod(i * 0.2, 1.0)),
			r.size.y)
		if ey < 0:
			ey += r.size.y
		var ember_size := 2.0 + sin(time_val * 3.0 + i) * 1.0
		draw_circle(Vector2(r.position.x + ex, r.position.y + ey),
			ember_size, Color(1.0, 0.5, 0.1, 0.3))

	# Cracks in the ground
	for i in range(6):
		var cx := r.position.x + 400.0 + i * 600.0
		var cy := r.end.y - 80.0
		var crack_glow := sin(time_val * 2.0 + i * 1.5) * 0.1 + 0.15
		draw_line(Vector2(cx, cy), Vector2(cx + 30, cy + 40),
			Color(1.0, 0.4, 0.1, crack_glow), 2.0)
		draw_line(Vector2(cx + 30, cy + 40), Vector2(cx + 10, cy + 70),
			Color(1.0, 0.3, 0.05, crack_glow * 0.7), 1.5)

	# Heat shimmer effect — subtle wavy lines
	for i in range(5):
		var sy := r.position.y + 400.0 + i * 500.0
		var wave_offset := sin(time_val * 1.5 + i) * 20.0
		draw_line(
			Vector2(r.position.x + 100, sy + wave_offset),
			Vector2(r.end.x - 100, sy + wave_offset + 10),
			Color(1.0, 0.6, 0.2, 0.02), 3.0)
