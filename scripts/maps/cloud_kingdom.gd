extends "res://scripts/maps/map_base.gd"
## Cloud Kingdom — very tall, cloud platforms, periodic wind gusts.

var wind_timer: float = 0.0
const WIND_INTERVAL := 8.0
const WIND_FORCE := 300.0

func _init() -> void:
	map_name = "Cloud Kingdom"
	bg_color = Color(0.4, 0.55, 0.8)
	platform_color = Color(0.85, 0.88, 0.95)
	platform_edge_color = Color(0.95, 0.95, 1.0)
	floor_color = Color(0.75, 0.8, 0.9)
	floor_edge_color = Color(0.9, 0.92, 1.0)

	map_rect = Rect2(0, 0, 4000, 5900)  # very tall!
	danger_left = 300.0
	danger_right = 300.0
	danger_bottom = 600.0
	danger_top = 0.0  # open sky

	platforms = [
		# Ground clouds
		[1000, 5100, 700, 40, true],
		[3000, 5100, 700, 40, true],
		[2000, 4700, 600, 30, true],
		# Ascending cloud staircase
		[700, 4300, 500, 28, true],
		[3300, 4300, 500, 28, true],
		[1500, 3900, 450, 28, true],
		[2500, 3900, 450, 28, true],
		[2000, 3500, 550, 28, true],
		[600, 3100, 400, 28, true],
		[3400, 3100, 400, 28, true],
		[1500, 2700, 450, 28, true],
		[2500, 2700, 450, 28, true],
		[2000, 2300, 500, 28, true],
		[800, 1900, 400, 28, true],
		[3200, 1900, 400, 28, true],
		[2000, 1500, 450, 28, true],
		[1200, 1100, 350, 28, true],
		[2800, 1100, 350, 28, true],
		[2000, 700, 400, 28, true],
	]

	objects = [
		["ball", 2000, 4200, 80],  # big cloud ball
		["ball", 800, 2500, 60],
		["ball", 3200, 2500, 60],
	]

	hazards = [
		# Moving cloud platforms
		["moving", 1200, 3300, 350, 24, 500, 0, 0.6],
		["moving", 2800, 2100, 350, 24, -500, 0, 0.8],
		["moving", 2000, 1200, 300, 24, 0, -400, 0.5],
	]

	events_enabled = true  # wind gusts

	spawn_points = [
		Vector2(1000, 5030), Vector2(3000, 5030),
		Vector2(700, 4230), Vector2(3300, 4230),
	]


func _process(delta: float) -> void:
	super._process(delta)
	# Periodic wind gusts
	wind_timer += delta
	if wind_timer >= WIND_INTERVAL:
		wind_timer = 0.0
		var dir := 1.0 if randf() > 0.5 else -1.0
		for p in get_tree().get_nodes_in_group("players"):
			if p.is_alive:
				p.apply_knockback(Vector2(dir * WIND_FORCE, -80.0))
		SoundManager.play_dash()


func _draw_decorations() -> void:
	# Gradient sky — lighter at top, stop before danger_bottom
	var safe_bottom := map_rect.size.y - danger_bottom
	for gy in range(10):
		var t := float(gy) / 10.0
		var sky_col := bg_color.lerp(Color(0.6, 0.75, 0.95), t)
		var rect_y := safe_bottom * (1.0 - (gy + 1) * 0.1)
		var rect_h := safe_bottom * 0.1
		draw_rect(Rect2(0, rect_y, map_rect.size.x, rect_h), sky_col)

	# Background clouds at different depths
	for i in range(20):
		var cx := fmod(i * 223.0, map_rect.size.x)
		var cy := fmod(i * 307.0 + 200, map_rect.size.y * 0.6)
		var cr := 40.0 + fmod(i * 17.0, 50.0)
		draw_circle(Vector2(cx, cy), cr, Color(1, 1, 1, 0.06))
		draw_circle(Vector2(cx + 30, cy + 10), cr * 0.7, Color(1, 1, 1, 0.04))

	# Sun at top
	draw_circle(Vector2(map_rect.size.x * 0.8, 200), 80.0, Color(1, 0.95, 0.7, 0.08))
	draw_circle(Vector2(map_rect.size.x * 0.8, 200), 50.0, Color(1, 0.9, 0.6, 0.1))

	# Rainbow hint
	for ri in range(5):
		var ra := 600.0 + ri * 20.0
		var _rc: Array[Color] = [
			Color(1, 0.2, 0.2, 0.03), Color(1, 0.5, 0.1, 0.03),
			Color(1, 1, 0.2, 0.03), Color(0.2, 0.8, 0.2, 0.03),
			Color(0.2, 0.3, 1, 0.03),
		]
		var rainbow_col: Color = _rc[ri]
		draw_arc(Vector2(0, 1000), ra, -0.2, PI * 0.5, 20, rainbow_col, 8.0)
