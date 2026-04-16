extends SceneTree
## Run with: godot --headless --script res://scripts/tools/generate_assets.gd

const SIZE := 128
const ICON_SIZE := 64


func _init() -> void:
	print("=== TangleBattle Asset Generator ===")
	_ensure_dirs()
	_generate_yarn_balls()
	_generate_platforms()
	_generate_ability_icons()
	_generate_particles()
	_generate_ui()
	print("=== Done! All assets in res://assets/ ===")
	quit()


func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	DirAccess.make_dir_recursive_absolute("res://assets/icons")


func _generate_yarn_balls() -> void:
	var colors: Array[Dictionary] = [
		{"name": "red", "color": Color(0.9, 0.2, 0.2)},
		{"name": "blue", "color": Color(0.2, 0.4, 0.9)},
		{"name": "green", "color": Color(0.2, 0.8, 0.3)},
		{"name": "yellow", "color": Color(0.95, 0.85, 0.1)},
		{"name": "orange", "color": Color(0.9, 0.4, 0.1)},
		{"name": "purple", "color": Color(0.7, 0.2, 0.9)},
		{"name": "cyan", "color": Color(0.1, 0.8, 0.8)},
		{"name": "pink", "color": Color(0.9, 0.3, 0.6)},
		{"name": "grey", "color": Color(0.5, 0.5, 0.5)},
		{"name": "white", "color": Color(0.92, 0.92, 0.95)},
	]
	for entry in colors:
		var img := _create_yarn_ball(entry["color"], SIZE)
		var path := "res://assets/sprites/yarn_%s.png" % entry["name"]
		img.save_png(path)
		print("  [sprite] ", path)

	# Hurt flash
	var hurt := _create_yarn_ball(Color(1, 1, 1), SIZE)
	hurt.save_png("res://assets/sprites/yarn_hurt.png")
	print("  [sprite] yarn_hurt.png")


func _create_yarn_ball(base: Color, sz: int) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(sz / 2.0, sz / 2.0)
	var rad := sz / 2.0 - 4.0
	var dark := base.darkened(0.3)
	var light := base.lightened(0.25)

	# Body circle with shading
	for y in range(sz):
		for x in range(sz):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			if d <= rad:
				var nx := (p.x - c.x) / rad
				var ny := (p.y - c.y) / rad
				var shade := clampf(0.5 - nx * 0.2 - ny * 0.25, 0.0, 1.0)
				var col := dark.lerp(light, shade)
				if d > rad - 2.0:
					col.a = clampf((rad - d) / 2.0, 0.0, 1.0)
				img.set_pixel(x, y, col)

	# Thread lines
	for i in range(8):
		var a := i * TAU / 8.0 + 0.3
		var from := c + Vector2(cos(a), sin(a)) * rad * 0.35
		var to := c + Vector2(cos(a + 1.2), sin(a + 1.2)) * rad * 0.85
		_line(img, from, to, dark, 2, rad, c)

	# Eyes
	var ey := c.y - rad * 0.15
	var eo := rad * 0.22
	_circle(img, Vector2(c.x - eo, ey), rad * 0.17, Color.WHITE)
	_circle(img, Vector2(c.x + eo, ey), rad * 0.17, Color.WHITE)
	_circle(img, Vector2(c.x - eo + 2, ey), rad * 0.09, Color.BLACK)
	_circle(img, Vector2(c.x + eo + 2, ey), rad * 0.09, Color.BLACK)

	# Shine
	_circle(img, Vector2(c.x - rad * 0.3, c.y - rad * 0.3),
		rad * 0.12, Color(1, 1, 1, 0.3))

	return img


func _generate_platforms() -> void:
	var themes: Array[Dictionary] = [
		{"n": "wood", "c": Color(0.45, 0.3, 0.2), "e": Color(0.6, 0.45, 0.3)},
		{"n": "stone", "c": Color(0.35, 0.35, 0.38), "e": Color(0.5, 0.5, 0.55)},
		{"n": "ice", "c": Color(0.5, 0.7, 0.85), "e": Color(0.7, 0.85, 0.95)},
		{"n": "lava", "c": Color(0.4, 0.2, 0.15), "e": Color(0.7, 0.35, 0.15)},
		{"n": "cloud", "c": Color(0.85, 0.88, 0.95), "e": Color(0.95, 0.95, 1.0)},
		{"n": "metal", "c": Color(0.35, 0.38, 0.42), "e": Color(0.55, 0.58, 0.65)},
		{"n": "coral", "c": Color(0.35, 0.25, 0.2), "e": Color(0.5, 0.4, 0.25)},
		{"n": "crystal", "c": Color(0.35, 0.35, 0.5), "e": Color(0.55, 0.55, 0.8)},
	]
	for t in themes:
		var img := _create_platform(t["c"], t["e"], 256, 32)
		img.save_png("res://assets/sprites/plat_%s.png" % t["n"])
		print("  [sprite] plat_%s.png" % t["n"])


func _create_platform(fill: Color, edge: Color, w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cr := h / 2.0
	var dk := fill.darkened(0.2)
	var lt := fill.lightened(0.15)

	for y in range(h):
		for x in range(w):
			var inside := true
			if x < cr:
				if Vector2(x, y).distance_to(Vector2(cr, h / 2.0)) > cr:
					inside = false
			elif x > w - cr:
				if Vector2(x, y).distance_to(Vector2(w - cr, h / 2.0)) > cr:
					inside = false
			if inside:
				var t := float(y) / h
				var col := lt.lerp(dk, t)
				if y < 3:
					col = edge.lightened(0.1)
				elif y > h - 3:
					col = dk.darkened(0.1)
				col = col.lightened(sin(x * 0.3 + y * 0.5) * 0.03)
				img.set_pixel(x, y, col)
	return img


func _generate_ability_icons() -> void:
	var abs: Array[Dictionary] = [
		{"n": "yarn_toss", "c": Color(0.4, 0.8, 1.0)},
		{"n": "needle_dash", "c": Color(1.0, 0.3, 0.3)},
		{"n": "yarn_bomb", "c": Color(1.0, 0.4, 0.6)},
		{"n": "grenade", "c": Color(0.8, 0.3, 0.1)},
		{"n": "rocket_launcher", "c": Color(1.0, 0.35, 0.1)},
		{"n": "boomerang", "c": Color(0.2, 0.7, 0.9)},
		{"n": "spin_attack", "c": Color(1.0, 0.8, 0.2)},
		{"n": "swap", "c": Color(0.9, 0.3, 0.9)},
		{"n": "grab_throw", "c": Color(0.7, 0.5, 0.2)},
		{"n": "stink_cloud", "c": Color(0.3, 0.75, 0.15)},
		{"n": "spike_armor", "c": Color(0.85, 0.85, 0.85)},
		{"n": "tripwire", "c": Color(0.3, 0.9, 1.0)},
		{"n": "thread_pull", "c": Color(0.5, 1.0, 0.5)},
		{"n": "guided_rocket", "c": Color(1.0, 0.5, 0.0)},
	]
	for ab in abs:
		var img := _create_icon(ab["c"], ICON_SIZE)
		img.save_png("res://assets/icons/ab_%s.png" % ab["n"])
		print("  [icon] ab_%s.png" % ab["n"])


func _create_icon(col: Color, sz: int) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(sz / 2.0, sz / 2.0)
	var r := sz / 2.0 - 3.0

	_circle(img, c, r, Color(0.12, 0.1, 0.18, 0.9))
	# Ring
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > r - 3.0 and d <= r:
				img.set_pixel(x, y, col)
	_circle(img, c, r * 0.55, Color(col.r, col.g, col.b, 0.12))
	_circle(img, c, r * 0.2, col.lightened(0.2))
	return img


func _generate_particles() -> void:
	var particles: Array[Dictionary] = [
		{"n": "dust", "c": Color(0.7, 0.65, 0.5, 0.6), "s": 16},
		{"n": "spark", "c": Color(1, 0.9, 0.5, 0.8), "s": 12},
		{"n": "fire", "c": Color(1, 0.5, 0.1, 0.7), "s": 16},
		{"n": "smoke", "c": Color(0.3, 0.3, 0.3, 0.4), "s": 24},
		{"n": "poison", "c": Color(0.3, 0.8, 0.15, 0.5), "s": 14},
		{"n": "electric", "c": Color(0.3, 0.7, 1, 0.7), "s": 10},
	]
	for p in particles:
		var img := _soft_circle(p["s"], p["c"])
		img.save_png("res://assets/sprites/pt_%s.png" % p["n"])
		print("  [particle] pt_%s.png" % p["n"])


func _generate_ui() -> void:
	var ui_items: Array[Dictionary] = [
		{"n": "button", "w": 200, "h": 50, "c": Color(0.2, 0.15, 0.3), "e": Color(0.5, 0.4, 0.7)},
		{"n": "card", "w": 200, "h": 300, "c": Color(0.15, 0.12, 0.2), "e": Color(0.4, 0.35, 0.55)},
		{"n": "panel", "w": 400, "h": 300, "c": Color(0.12, 0.1, 0.18, 0.95), "e": Color(0.35, 0.3, 0.5)},
	]
	for u in ui_items:
		var img := _rounded_rect(u["w"], u["h"], u["c"], u["e"], 10)
		img.save_png("res://assets/sprites/ui_%s.png" % u["n"])
		print("  [ui] ui_%s.png" % u["n"])


# ══════ Helpers ══════

func _circle(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var r2 := radius * radius
	var x0 := maxi(0, int(center.x - radius - 1))
	var x1 := mini(img.get_width() - 1, int(center.x + radius + 1))
	var y0 := maxi(0, int(center.y - radius - 1))
	var y1 := mini(img.get_height() - 1, int(center.y + radius + 1))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := x + 0.5 - center.x
			var dy := y + 0.5 - center.y
			var dsq := dx * dx + dy * dy
			if dsq <= r2:
				var existing := img.get_pixel(x, y)
				var a := col.a
				var d := sqrt(dsq)
				if d > radius - 1.5:
					a *= clampf((radius - d) / 1.5, 0.0, 1.0)
				var blended := existing.lerp(Color(col.r, col.g, col.b, 1.0), a)
				blended.a = maxf(existing.a, a)
				img.set_pixel(x, y, blended)


func _line(
	img: Image, from: Vector2, to: Vector2, col: Color,
	w: int, clip_r: float, clip_c: Vector2
) -> void:
	var steps := int(from.distance_to(to) * 2)
	for i in range(steps):
		var t := float(i) / maxf(steps - 1, 1)
		var p := from.lerp(to, t)
		if p.distance_to(clip_c) > clip_r - 1:
			continue
		for dy in range(-w, w + 1):
			for dx in range(-w, w + 1):
				var px := int(p.x) + dx
				var py := int(p.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					var ex := img.get_pixel(px, py)
					if ex.a > 0.01:
						img.set_pixel(px, py, ex.lerp(col, col.a * 0.5))


func _soft_circle(sz: int, col: Color) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(sz / 2.0, sz / 2.0)
	var r := sz / 2.0 - 1.0
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r:
				var f := 1.0 - d / r
				var cc := col
				cc.a = col.a * f * f
				img.set_pixel(x, y, cc)
	return img


func _rounded_rect(w: int, h: int, fill: Color, edge: Color, cr: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		for x in range(w):
			var inside := true
			if x < cr and y < cr:
				if Vector2(x, y).distance_to(Vector2(cr, cr)) > cr:
					inside = false
			elif x > w - cr - 1 and y < cr:
				if Vector2(x, y).distance_to(Vector2(w - cr - 1, cr)) > cr:
					inside = false
			elif x < cr and y > h - cr - 1:
				if Vector2(x, y).distance_to(Vector2(cr, h - cr - 1)) > cr:
					inside = false
			elif x > w - cr - 1 and y > h - cr - 1:
				if Vector2(x, y).distance_to(Vector2(w - cr - 1, h - cr - 1)) > cr:
					inside = false
			if inside:
				if x < 2 or x > w - 3 or y < 2 or y > h - 3:
					img.set_pixel(x, y, edge)
				else:
					img.set_pixel(x, y, fill)
	return img
