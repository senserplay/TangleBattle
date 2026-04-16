@tool
extends EditorScript
## Run this in Godot Editor (File → Run) to generate PNG assets.
## Assets are saved to res://assets/sprites/ and res://assets/icons/

const SIZE := 128  # sprite size in pixels
const ICON_SIZE := 64


func _run() -> void:
	print("=== Generating assets ===")
	_generate_yarn_balls()
	_generate_platforms()
	_generate_ability_icons()
	_generate_particles()
	_generate_ui()
	print("=== Done! ===")


func _generate_yarn_balls() -> void:
	var colors: Array[Color] = [
		Color(0.9, 0.2, 0.2),   # red
		Color(0.2, 0.4, 0.9),   # blue
		Color(0.2, 0.8, 0.3),   # green
		Color(0.95, 0.85, 0.1), # yellow
		Color(0.9, 0.4, 0.1),   # orange
		Color(0.7, 0.2, 0.9),   # purple
		Color(0.1, 0.8, 0.8),   # cyan
		Color(0.9, 0.3, 0.6),   # pink
	]
	var names: Array[String] = [
		"red", "blue", "green", "yellow",
		"orange", "purple", "cyan", "pink"
	]

	for ci in range(colors.size()):
		var img := _create_yarn_ball(colors[ci], SIZE)
		var path := "res://assets/sprites/yarn_ball_%s.png" % names[ci]
		img.save_png(path)
		print("  Saved: ", path)

	# Hurt flash version (white tint)
	var hurt_img := _create_yarn_ball(Color.WHITE, SIZE)
	hurt_img.save_png("res://assets/sprites/yarn_ball_hurt.png")
	print("  Saved: yarn_ball_hurt.png")


func _create_yarn_ball(base_color: Color, sz: int) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(sz / 2.0, sz / 2.0)
	var radius := sz / 2.0 - 4.0
	var dark := base_color.darkened(0.3)
	var light := base_color.lightened(0.25)

	# Background — transparent
	img.fill(Color(0, 0, 0, 0))

	# Draw filled circle with soft edge
	for y in range(sz):
		for x in range(sz):
			var pos := Vector2(x + 0.5, y + 0.5)
			var dist := pos.distance_to(center)
			if dist <= radius:
				# Gradient from light (top-left) to dark (bottom-right)
				var nx := (pos.x - center.x) / radius
				var ny := (pos.y - center.y) / radius
				var shade := clampf(0.5 - nx * 0.2 - ny * 0.25, 0.0, 1.0)
				var col := dark.lerp(light, shade)
				# Soft edge
				if dist > radius - 2.0:
					col.a = clampf((radius - dist) / 2.0, 0.0, 1.0)
				img.set_pixel(x, y, col)

	# Yarn thread lines
	for i in range(8):
		var angle := i * TAU / 8.0 + 0.3
		var from := center + Vector2(cos(angle), sin(angle)) * radius * 0.35
		var to := center + Vector2(cos(angle + 1.2), sin(angle + 1.2)) * radius * 0.85
		_draw_line_on_image(img, from, to, dark, 2.0, radius, center)

	# Eyes
	var eye_offset := radius * 0.22
	var eye_y := center.y - radius * 0.15
	_draw_circle_on_image(img, Vector2(center.x - eye_offset, eye_y),
		radius * 0.17, Color.WHITE)
	_draw_circle_on_image(img, Vector2(center.x + eye_offset, eye_y),
		radius * 0.17, Color.WHITE)
	# Pupils
	_draw_circle_on_image(img, Vector2(center.x - eye_offset + 2, eye_y),
		radius * 0.09, Color.BLACK)
	_draw_circle_on_image(img, Vector2(center.x + eye_offset + 2, eye_y),
		radius * 0.09, Color.BLACK)

	# Highlight spot (top-left)
	_draw_circle_on_image(img,
		Vector2(center.x - radius * 0.3, center.y - radius * 0.3),
		radius * 0.12, Color(1, 1, 1, 0.3))

	return img


func _generate_platforms() -> void:
	# Generate platform tile strips
	var themes: Array[Dictionary] = [
		{"name": "wood", "color": Color(0.45, 0.3, 0.2), "edge": Color(0.6, 0.45, 0.3)},
		{"name": "stone", "color": Color(0.35, 0.35, 0.38), "edge": Color(0.5, 0.5, 0.55)},
		{"name": "ice", "color": Color(0.5, 0.7, 0.85), "edge": Color(0.7, 0.85, 0.95)},
		{"name": "lava", "color": Color(0.4, 0.2, 0.15), "edge": Color(0.7, 0.35, 0.15)},
		{"name": "cloud", "color": Color(0.85, 0.88, 0.95), "edge": Color(0.95, 0.95, 1.0)},
	]

	for theme in themes:
		var img := _create_platform_tile(theme["color"], theme["edge"], 256, 32)
		var path := "res://assets/sprites/platform_%s.png" % theme["name"]
		img.save_png(path)
		print("  Saved: ", path)


func _create_platform_tile(fill: Color, edge: Color, w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var dark := fill.darkened(0.2)
	var light := fill.lightened(0.15)
	var corner_r := h / 2.0

	for y in range(h):
		for x in range(w):
			# Rounded rectangle check
			var in_rect := true
			if x < corner_r:
				var dx := corner_r - x
				var dy := absf(y - h / 2.0)
				if dx * dx + dy * dy > corner_r * corner_r:
					in_rect = false
			elif x > w - corner_r:
				var dx := x - (w - corner_r)
				var dy := absf(y - h / 2.0)
				if dx * dx + dy * dy > corner_r * corner_r:
					in_rect = false

			if in_rect:
				# Vertical gradient
				var t := float(y) / h
				var col := light.lerp(dark, t)
				# Top edge highlight
				if y < 3:
					col = edge.lightened(0.1)
				elif y > h - 3:
					col = dark.darkened(0.1)
				# Surface texture noise
				var noise_val := sin(x * 0.3 + y * 0.5) * 0.03
				col = col.lightened(noise_val)
				img.set_pixel(x, y, col)

	return img


func _generate_ability_icons() -> void:
	var abilities: Array[Dictionary] = [
		{"name": "yarn_toss", "color": Color(0.4, 0.8, 1.0)},
		{"name": "needle_dash", "color": Color(1.0, 0.3, 0.3)},
		{"name": "yarn_bomb", "color": Color(1.0, 0.4, 0.6)},
		{"name": "grenade", "color": Color(0.8, 0.3, 0.1)},
		{"name": "rocket", "color": Color(1.0, 0.35, 0.1)},
		{"name": "boomerang", "color": Color(0.2, 0.7, 0.9)},
		{"name": "spin", "color": Color(1.0, 0.8, 0.2)},
		{"name": "swap", "color": Color(0.9, 0.3, 0.9)},
		{"name": "grab", "color": Color(0.7, 0.5, 0.2)},
		{"name": "stink", "color": Color(0.3, 0.75, 0.15)},
		{"name": "spike", "color": Color(0.85, 0.85, 0.85)},
		{"name": "tripwire", "color": Color(0.3, 0.9, 1.0)},
		{"name": "pull", "color": Color(0.5, 1.0, 0.5)},
		{"name": "guided", "color": Color(1.0, 0.5, 0.0)},
	]

	for ab in abilities:
		var img := _create_ability_icon(ab["color"], ICON_SIZE)
		var path := "res://assets/icons/ability_%s.png" % ab["name"]
		img.save_png(path)
		print("  Saved: ", path)


func _create_ability_icon(col: Color, sz: int) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center := Vector2(sz / 2.0, sz / 2.0)
	var radius := sz / 2.0 - 3.0

	# Background circle
	_draw_circle_on_image(img, center, radius, Color(0.12, 0.1, 0.18, 0.9))
	# Color ring
	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if dist > radius - 3.0 and dist <= radius:
				img.set_pixel(x, y, col)
	# Inner glow
	_draw_circle_on_image(img, center, radius * 0.6,
		Color(col.r, col.g, col.b, 0.15))
	# Center dot
	_draw_circle_on_image(img, center, radius * 0.2, col.lightened(0.2))

	return img


func _generate_particles() -> void:
	# Dust particle
	var dust := _create_soft_circle(16, Color(0.7, 0.65, 0.5, 0.6))
	dust.save_png("res://assets/sprites/particle_dust.png")
	print("  Saved: particle_dust.png")

	# Spark particle
	var spark := _create_soft_circle(12, Color(1, 0.9, 0.5, 0.8))
	spark.save_png("res://assets/sprites/particle_spark.png")
	print("  Saved: particle_spark.png")

	# Fire particle
	var fire := _create_soft_circle(16, Color(1, 0.5, 0.1, 0.7))
	fire.save_png("res://assets/sprites/particle_fire.png")
	print("  Saved: particle_fire.png")

	# Smoke
	var smoke := _create_soft_circle(24, Color(0.3, 0.3, 0.3, 0.4))
	smoke.save_png("res://assets/sprites/particle_smoke.png")
	print("  Saved: particle_smoke.png")


func _generate_ui() -> void:
	# Button background
	var btn := _create_rounded_rect(200, 50, Color(0.2, 0.15, 0.3), Color(0.5, 0.4, 0.7), 12)
	btn.save_png("res://assets/sprites/ui_button.png")
	print("  Saved: ui_button.png")

	# Card background
	var card := _create_rounded_rect(200, 300, Color(0.15, 0.12, 0.2), Color(0.4, 0.35, 0.55), 8)
	card.save_png("res://assets/sprites/ui_card.png")
	print("  Saved: ui_card.png")

	# Panel background
	var panel := _create_rounded_rect(400, 300, Color(0.12, 0.1, 0.18, 0.95), Color(0.35, 0.3, 0.5), 10)
	panel.save_png("res://assets/sprites/ui_panel.png")
	print("  Saved: ui_panel.png")


# ══════════ HELPER DRAWING FUNCTIONS ══════════

func _draw_circle_on_image(
	img: Image, center: Vector2, radius: float, col: Color
) -> void:
	var r2 := radius * radius
	var min_x := maxi(0, int(center.x - radius - 1))
	var max_x := mini(img.get_width() - 1, int(center.x + radius + 1))
	var min_y := maxi(0, int(center.y - radius - 1))
	var max_y := mini(img.get_height() - 1, int(center.y + radius + 1))

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := x + 0.5 - center.x
			var dy := y + 0.5 - center.y
			var dist_sq := dx * dx + dy * dy
			if dist_sq <= r2:
				var existing := img.get_pixel(x, y)
				var alpha := col.a
				# Soft edge
				var dist := sqrt(dist_sq)
				if dist > radius - 1.5:
					alpha *= clampf((radius - dist) / 1.5, 0.0, 1.0)
				var blended := existing.lerp(Color(col.r, col.g, col.b, 1.0), alpha)
				blended.a = maxf(existing.a, alpha)
				img.set_pixel(x, y, blended)


func _draw_line_on_image(
	img: Image, from: Vector2, to: Vector2, col: Color,
	width: float, clip_radius: float, clip_center: Vector2
) -> void:
	var steps := int(from.distance_to(to) * 2)
	for i in range(steps):
		var t := float(i) / maxf(steps - 1, 1)
		var pos := from.lerp(to, t)
		# Clip to circle
		if pos.distance_to(clip_center) > clip_radius - 1:
			continue
		var px := int(pos.x)
		var py := int(pos.y)
		var hw := int(width / 2.0)
		for dy in range(-hw, hw + 1):
			for dx in range(-hw, hw + 1):
				var fx := px + dx
				var fy := py + dy
				if fx >= 0 and fx < img.get_width() and fy >= 0 and fy < img.get_height():
					var existing := img.get_pixel(fx, fy)
					if existing.a > 0.01:
						var blended := existing.lerp(col, col.a * 0.5)
						img.set_pixel(fx, fy, blended)


func _create_soft_circle(sz: int, col: Color) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(sz / 2.0, sz / 2.0)
	var radius := sz / 2.0 - 1.0

	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if dist <= radius:
				var falloff := 1.0 - (dist / radius)
				falloff = falloff * falloff  # quadratic falloff
				var c := col
				c.a = col.a * falloff
				img.set_pixel(x, y, c)

	return img


func _create_rounded_rect(
	w: int, h: int, fill: Color, edge: Color, corner: int
) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(h):
		for x in range(w):
			var in_rect := true
			# Check corners
			if x < corner and y < corner:
				if Vector2(x, y).distance_to(Vector2(corner, corner)) > corner:
					in_rect = false
			elif x > w - corner - 1 and y < corner:
				if Vector2(x, y).distance_to(Vector2(w - corner - 1, corner)) > corner:
					in_rect = false
			elif x < corner and y > h - corner - 1:
				if Vector2(x, y).distance_to(Vector2(corner, h - corner - 1)) > corner:
					in_rect = false
			elif x > w - corner - 1 and y > h - corner - 1:
				if Vector2(x, y).distance_to(Vector2(w - corner - 1, h - corner - 1)) > corner:
					in_rect = false

			if in_rect:
				# Border check
				if x < 2 or x > w - 3 or y < 2 or y > h - 3:
					img.set_pixel(x, y, edge)
				else:
					img.set_pixel(x, y, fill)

	return img
