extends Node2D
## Death effect — yarn ball explodes into falling threads that fade away.

var color: Color = Color.RED
var threads: Array[Dictionary] = []
var lifetime: float = 1.5
var time: float = 0.0


func setup(col: Color, pos: Vector2) -> void:
	color = col
	global_position = pos
	_spawn_threads()


func _spawn_threads() -> void:
	# Main burst of thread segments
	for i in range(18):
		var angle := randf() * TAU
		var speed := randf_range(100.0, 350.0)
		var length := randf_range(12.0, 30.0)
		var rot := randf() * TAU
		var rot_speed := randf_range(-8.0, 8.0)
		var shade := color.lerp(Color.WHITE, randf() * 0.3)
		shade = shade.lerp(color.darkened(0.3), randf() * 0.3)

		threads.append({
			"x": 0.0,
			"y": 0.0,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - randf_range(50.0, 150.0),
			"length": length,
			"rot": rot,
			"rot_speed": rot_speed,
			"color": shade,
			"width": randf_range(1.5, 3.0),
		})

	# Small dot particles
	for i in range(10):
		var angle := randf() * TAU
		var speed := randf_range(60.0, 200.0)
		threads.append({
			"x": 0.0,
			"y": 0.0,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - randf_range(30.0, 100.0),
			"length": 0.0,  # dot, not line
			"rot": 0.0,
			"rot_speed": 0.0,
			"color": color.lightened(0.4),
			"width": randf_range(2.0, 4.0),
		})


func _process(delta: float) -> void:
	time += delta
	if time >= lifetime:
		queue_free()
		return

	var gravity := 600.0
	for t in threads:
		t["vy"] += gravity * delta
		t["x"] += t["vx"] * delta
		t["y"] += t["vy"] * delta
		t["vx"] *= 0.98  # air drag
		t["rot"] += t["rot_speed"] * delta

	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf((time - lifetime * 0.5) / (lifetime * 0.5), 0.0, 1.0)

	for t in threads:
		var pos := Vector2(t["x"], t["y"])
		var col: Color = t["color"]
		col.a = fade

		var length: float = t["length"]
		if length > 1.0:
			# Thread segment
			var rot: float = t["rot"]
			var dir := Vector2(cos(rot), sin(rot))
			var half := dir * length * 0.5
			var w: float = t["width"]
			draw_line(pos - half, pos + half, col, w)
		else:
			# Dot particle
			var w: float = t["width"]
			draw_circle(pos, w * fade, col)
