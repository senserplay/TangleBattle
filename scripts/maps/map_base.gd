extends Node2D
## Base map class with multiple platform shape types.
##
## Platform format: [x, y, width, height, one_way, shape]
## shape: "rect" (default), "circle", "arc_left", "arc_right"
## Rect platforms are drawn as rounded capsules.
## Circle platforms are ball-shaped.
## Arc platforms are curved half-pipes.

var platforms: Array = []
## Extra objects: [type, x, y, params...]
## "ball" — circle platform: [x, y, radius]
## "arc" — curved platform: [x, y, radius, start_angle, end_angle]
var objects: Array = []
## Hazards: [type, x, y, params...]
## "spikes" — instant kill zone: [x, y, width, height]
## "moving" — moving platform: [x, y, w, h, move_x, move_y, speed]
var hazards: Array = []
## Teleport pairs: [[x1, y1, x2, y2]]
var teleports: Array = []
## Destructible platforms: [x, y, w, h, hp]
var destructibles: Array = []
## Item spawn points: [x, y] — items spawn randomly at these positions
var item_spawns: Array = []
## Map events: which random hazard fires every EVENT_INTERVAL seconds.
## "none"      — no periodic events
## "wind"      — horizontal gust knockback
## "meteor"    — falling meteor damage in a random column
## "lightning" — strike a random player (damage + stun)
## "all"       — pick one of the three at random each interval
var event_type: String = "none"
var events_enabled: bool = false  # legacy flag, kept in sync with event_type
var event_timer: float = 0.0
const EVENT_INTERVAL := 20.0
# Event warning banner — big text on screen when an event fires.
var event_banner_text: String = ""
var event_banner_timer: float = 0.0
var event_banner_color: Color = Color(1, 0.85, 0.3)

# Event visuals — start time in seconds (-1 = inactive). _draw reads
# these to render the falling meteor / zigzag bolt / wind streaks.
var _meteor_start_t: float = -1.0
var _meteor_x: float = 0.0
var _meteor_y_spawn: float = 0.0
var _meteor_y_impact: float = 0.0
const METEOR_FALL_DUR: float = 1.0
const METEOR_EXPLODE_DUR: float = 0.5
var _lightning_start_t: float = -1.0
var _lightning_target: Vector2 = Vector2.ZERO
var _lightning_origin: Vector2 = Vector2.ZERO
const LIGHTNING_DUR: float = 0.8
var _wind_start_t: float = -1.0
var _wind_dir: float = 1.0
const WIND_DUR: float = 1.0

## Parallax layers: [{color, elements: [{x, y, size, shape}], scroll_factor}]
## scroll_factor: 0.0 = static, 1.0 = moves with camera
var parallax_layers: Array = []

var bg_color: Color = Color(0.12, 0.1, 0.15)
var platform_color: Color = Color(0.35, 0.25, 0.2)
var platform_edge_color: Color = Color(0.6, 0.45, 0.3)
var floor_color: Color = Color(0.3, 0.2, 0.18)
var floor_edge_color: Color = Color(0.5, 0.35, 0.25)
var map_name: String = "Unknown"

## Parallax background layers. Each map fills this from its _init().
## Layer dict keys:
##   path   : String res://... texture path
##   scroll : float  0.0 = locked to screen (sky), 1.0 = locked to world (fg)
##   mode   : String "fill"        — stretch across bg, vertical parallax damped
##                   "bottom_tile" — tile horizontally, bottom-anchored band
##                   "top_tile"    — tile horizontally, top-anchored band
##   y      : float  pixel offset added to anchor position
##   scale  : float  per-layer scale multiplier (defaults to 1.0)
##   tint   : Color  color multiplier (defaults to WHITE)
var bg_layers: Array = []
var bg_tint: Color = Color.WHITE

# Platform material: "" (default capsule) or "stone"/"wood"/"sand"/"lava_ice"/"water"
# Each palette is a seamless landscape strip texture applied to the capsule.
var platform_palette: String = ""

var spawn_points: Array[Vector2] = [
	Vector2(800, 2600), Vector2(4000, 2600),
	Vector2(2000, 1800), Vector2(2800, 1800),
]

var map_rect: Rect2 = Rect2(0, 0, 4800, 3200)
var danger_left: float = 300.0
var danger_right: float = 300.0
var danger_bottom: float = 300.0
var danger_top: float = 0.0
var kill_margin: float = 200.0

var use_walls: bool = false       # solid walls instead of danger zones
var fire_walls: bool = false      # walls deal fire damage on touch
var bouncy_walls: bool = false    # walls bounce players off
var wall_thickness: float = 40.0  # thickness of wall collision

# Per-map physics tweaks read by player.gd / projectile scripts.
# 0.0 = zero-G (e.g. Deep Space); 1.0 = normal Earth gravity.
var gravity_multiplier: float = 1.0
# 1.0 = normal ground friction; 0.15 = ice (slides far before stopping).
var floor_friction_mult: float = 1.0

# Global zone shrink — starts after SHRINK_GLOBAL_DELAY seconds
const SHRINK_GLOBAL_DELAY := 120.0
const SHRINK_GLOBAL_SPEED := 20.0
const SHRINK_MIN_SAFE := 600.0
var global_shrink_timer: float = 0.0


func _ready() -> void:
	# Enable GPU-level texture repeat for this CanvasItem. A single
	# draw_polygon renders the full rounded capsule with UVs 0..N (N =
	# number of tile copies); the GPU sampler wraps UV > 1.0 natively
	# via GL_REPEAT. The strip textures are pixel-identical at col 0 vs
	# col tex_w-1 (verified), so LINEAR filter samples the same pair on
	# both sides of each tile boundary — zero visible seam.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for data in platforms:
		if data.size() > 4 and data[4] is String and data[4] == "sticky":
			_create_platform(data[0], data[1], data[2], data[3], false)
		elif data.size() > 4 and data[4] is bool:
			_create_platform(data[0], data[1], data[2], data[3], data[4])
		else:
			_create_platform(data[0], data[1], data[2], data[3], false)
	for obj in objects:
		var type: String = obj[0]
		match type:
			"ball":
				_create_ball(obj[1], obj[2], obj[3])
			"arc":
				_create_arc_platform(obj[1], obj[2], obj[3], obj[4], obj[5])
	for haz in hazards:
		var type: String = haz[0]
		match type:
			"spikes":
				_create_spikes(haz[1], haz[2], haz[3], haz[4])
			"moving":
				_create_moving_platform(haz[1], haz[2], haz[3], haz[4],
					haz[5], haz[6], haz[7])
	for tp in teleports:
		if tp.size() >= 8:
			_create_teleport_pair_v2(tp[0], tp[1], tp[2], tp[3], tp[4], tp[5], tp[6], tp[7])
		else:
			_create_teleport_pair(tp[0], tp[1], tp[2], tp[3])
	for dplat in destructibles:
		_create_destructible(dplat[0], dplat[1], dplat[2], dplat[3], dplat[4])
	if use_walls or fire_walls or bouncy_walls:
		_create_walls()


func _create_platform(
	x: float, y: float, w: float, h: float, one_way: bool
) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	if one_way:
		col.one_way_collision = true
	body.add_child(col)
	add_child(body)


## ══════ WALLS ══════
func _create_walls() -> void:
	var r := map_rect
	var t := wall_thickness
	var cx := r.position.x + r.size.x / 2.0
	var cy := r.position.y + r.size.y / 2.0

	var wall_configs: Array = [
		# [pos_x, pos_y, size_x, size_y]
		[r.position.x - t / 2.0, cy, t, r.size.y + 200.0],        # left
		[r.end.x + t / 2.0, cy, t, r.size.y + 200.0],             # right
		[cx, r.end.y + t / 2.0, r.size.x + 200.0, t],              # bottom
	]
	if danger_top > 0:
		wall_configs.append([cx, r.position.y - t / 2.0, r.size.x + 200.0, t])  # top

	var phys_mat: PhysicsMaterial = null
	if bouncy_walls:
		phys_mat = PhysicsMaterial.new()
		phys_mat.bounce = 1.5
		phys_mat.friction = 0.0

	for wc in wall_configs:
		var body := StaticBody2D.new()
		body.position = Vector2(wc[0], wc[1])
		body.collision_layer = 1
		body.collision_mask = 0
		if bouncy_walls and phys_mat != null:
			body.physics_material_override = phys_mat
		var shape := RectangleShape2D.new()
		shape.size = Vector2(wc[2], wc[3])
		var col := CollisionShape2D.new()
		col.shape = shape
		body.add_child(col)
		body.add_to_group("map_walls")
		add_child(body)


func _create_ball(x: float, y: float, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _create_arc_platform(
	x: float, y: float, radius: float,
	start_deg: float, end_deg: float
) -> void:
	# Approximate arc with multiple small segment bodies
	var start_rad := deg_to_rad(start_deg)
	var end_rad := deg_to_rad(end_deg)
	var segments := 8
	var span := end_rad - start_rad
	for i in range(segments):
		var a0 := start_rad + span * float(i) / segments
		var a1 := start_rad + span * float(i + 1) / segments
		var mid_a := (a0 + a1) / 2.0
		var seg_len := radius * absf(a1 - a0)

		var body := StaticBody2D.new()
		var cx := x + cos(mid_a) * radius
		var cy := y + sin(mid_a) * radius
		body.position = Vector2(cx, cy)
		body.rotation = mid_a + PI / 2.0

		var shape := RectangleShape2D.new()
		shape.size = Vector2(seg_len + 4, 20)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.one_way_collision = true
		body.add_child(col)
		add_child(body)


func _draw() -> void:
	draw_rect(
		Rect2(
			map_rect.position.x - 3500, map_rect.position.y - 3500,
			map_rect.size.x + 7000, map_rect.size.y + 7000
		),
		bg_color
	)
	_draw_parallax_background()
	_draw_parallax()
	_draw_decorations()
	_draw_platforms()
	_draw_objects()
	_draw_hazards()
	# Borders draw LAST so water + side vignette sit over everything else
	_draw_water_floor()
	_draw_side_vignette()
	_draw_walls()
	_draw_event_vfx()
	_draw_event_banner()


func _draw_event_vfx() -> void:
	var now: float = _event_time()
	# ───── Meteor ─────
	if _meteor_start_t >= 0.0:
		var el: float = now - _meteor_start_t
		if el < METEOR_FALL_DUR + METEOR_EXPLODE_DUR:
			if el < METEOR_FALL_DUR:
				var k: float = el / METEOR_FALL_DUR
				# Ease-in: fast near impact
				var y: float = lerpf(_meteor_y_spawn, _meteor_y_impact, k * k)
				# Trailing fire
				for i in range(10):
					var tk: float = k - i * 0.025
					if tk < 0.0:
						continue
					var yi: float = lerpf(_meteor_y_spawn, _meteor_y_impact, tk * tk)
					var r: float = 18.0 - i * 1.3
					var col := Color(1.0, 0.5 + i * 0.04, 0.1, 0.9 - i * 0.08)
					draw_circle(Vector2(_meteor_x, yi), maxf(r, 3.0), col)
				# Main rock
				draw_circle(Vector2(_meteor_x, y), 22.0, Color(0.25, 0.15, 0.08))
				draw_circle(Vector2(_meteor_x, y), 18.0, Color(0.45, 0.25, 0.12))
				draw_arc(Vector2(_meteor_x, y), 24.0, 0, TAU, 16,
					Color(1.0, 0.6, 0.1, 0.8), 3.0)
			else:
				# Explosion — expanding fireball + shockwave ring
				var ek: float = (el - METEOR_FALL_DUR) / METEOR_EXPLODE_DUR
				var fade: float = 1.0 - ek
				var radius: float = 30.0 + ek * 200.0
				# Fireball layers
				draw_circle(Vector2(_meteor_x, _meteor_y_impact),
					radius * 0.7, Color(1.0, 0.4, 0.1, 0.7 * fade))
				draw_circle(Vector2(_meteor_x, _meteor_y_impact),
					radius * 0.4, Color(1.0, 0.9, 0.3, 0.85 * fade))
				# Shockwave ring
				draw_arc(Vector2(_meteor_x, _meteor_y_impact),
					radius, 0, TAU, 32,
					Color(1.0, 0.7, 0.3, fade), 4.0)
				# Bits of debris
				for i in range(14):
					var ang: float = float(i) * TAU / 14.0
					var dx: float = cos(ang) * radius * 0.9
					var dy: float = sin(ang) * radius * 0.9 - ek * 100.0
					draw_circle(
						Vector2(_meteor_x + dx, _meteor_y_impact + dy),
						4.0 + ek * 6.0,
						Color(0.6, 0.3, 0.15, fade))
		else:
			_meteor_start_t = -1.0
	# ───── Lightning ─────
	if _lightning_start_t >= 0.0:
		var el: float = now - _lightning_start_t
		if el < LIGHTNING_DUR:
			var k: float = el / LIGHTNING_DUR
			var fade: float = 1.0 - k
			# Pre-strike (first 0.5s) = warning zap chain
			# Post-strike (after 0.5s) = fading blast
			var n_segs := 14
			var origin := _lightning_origin
			var target := _lightning_target
			var pts: PackedVector2Array = []
			pts.append(origin)
			for i in range(1, n_segs):
				var ti: float = float(i) / n_segs
				var lp: Vector2 = origin.lerp(target, ti)
				# Deterministic wobble on the X so the bolt keeps its shape
				var seed_x: float = sin(float(i) * 17.3
					+ _lightning_start_t * 9.1) * 43758.5453
				var r: float = seed_x - floor(seed_x)
				lp.x += (r - 0.5) * 80.0
				pts.append(lp)
			pts.append(target)
			# Outer glow
			for j in range(pts.size() - 1):
				draw_line(pts[j], pts[j + 1],
					Color(0.8, 0.95, 1.0, 0.35 * fade), 14.0)
			# Inner core — bright white
			for j in range(pts.size() - 1):
				draw_line(pts[j], pts[j + 1],
					Color(1.0, 1.0, 1.0, 0.95 * fade), 5.0)
			# Impact ring
			var ring_r: float = 12.0 + k * 60.0
			draw_arc(target, ring_r, 0, TAU, 24,
				Color(1.0, 1.0, 0.4, 0.8 * fade), 3.0)
			draw_circle(target, 20.0 * fade,
				Color(1.0, 1.0, 0.9, 0.6 * fade))
		else:
			_lightning_start_t = -1.0
	# ───── Wind ─────
	if _wind_start_t >= 0.0:
		var el: float = now - _wind_start_t
		if el < WIND_DUR:
			var cam := get_viewport().get_camera_2d()
			if cam != null:
				var vp: Vector2 = get_viewport().get_visible_rect().size
				var cam_pos: Vector2 = cam.position
				var k: float = el / WIND_DUR
				var fade: float = 1.0 - k
				# 20 horizontal streak lines moving in wind direction
				for i in range(20):
					var seed_y: float = sin(float(i) * 29.7) * 43758.5453
					var ry: float = seed_y - floor(seed_y)
					var yy: float = cam_pos.y - vp.y * 0.5 + ry * vp.y
					var seed_w: float = sin(float(i) * 13.1) * 43758.5453
					var rw: float = seed_w - floor(seed_w)
					var streak_len: float = 150.0 + rw * 120.0
					var speed: float = 900.0 + rw * 400.0
					# Position of streak center — moves in wind_dir
					var offset: float = (el * speed) * _wind_dir
					var x_center: float = cam_pos.x \
						- vp.x * 0.5 + ((float(i) * 173.7) + offset)
					# Wrap horizontally across visible area + buffer
					var wrap_w: float = vp.x + streak_len * 2.0
					x_center = cam_pos.x - vp.x * 0.5 \
						+ fposmod(x_center - (cam_pos.x - vp.x * 0.5), wrap_w)
					var p1 := Vector2(x_center, yy)
					var p2 := Vector2(x_center + streak_len * _wind_dir, yy)
					var col := Color(1.0, 1.0, 1.0, 0.35 * fade)
					draw_line(p1, p2, col, 2.0)
		else:
			_wind_start_t = -1.0


func _draw_event_banner() -> void:
	if event_banner_timer <= 0.0 or event_banner_text == "":
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# Banner anchored near top of screen, in world space via camera pos.
	var cx: float = cam.position.x
	var cy: float = cam.position.y - vp.y * 0.35
	var fade: float = clampf(event_banner_timer * 1.5, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var fs := 58
	var text_sz := font.get_string_size(event_banner_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var box_w: float = text_sz.x + 80.0
	var box_h: float = text_sz.y + 30.0
	# Background plate (world-space coords scaled by camera zoom)
	var bg_col := Color(0.08, 0.05, 0.12, 0.80 * fade)
	draw_rect(Rect2(
		cx - box_w * 0.5, cy - box_h * 0.5,
		box_w, box_h), bg_col)
	var edge := event_banner_color
	edge.a = 0.95 * fade
	draw_rect(Rect2(
		cx - box_w * 0.5, cy - box_h * 0.5,
		box_w, box_h), edge, false, 3.0)
	var text_col := event_banner_color
	text_col.a = fade
	draw_string(font,
		Vector2(cx - text_sz.x * 0.5, cy + text_sz.y * 0.25),
		event_banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)


func _draw_parallax() -> void:
	if parallax_layers.is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cam_pos := cam.position
	var center := map_rect.position + map_rect.size / 2.0

	for layer in parallax_layers:
		var scroll: float = layer.get("scroll", 0.3)
		var col: Color = layer.get("color", Color(0.2, 0.2, 0.3, 0.1))
		var elements: Array = layer.get("elements", [])
		var parallax_offset := (cam_pos - center) * (1.0 - scroll)

		for elem in elements:
			var ex: float = elem[0] + parallax_offset.x
			var ey: float = elem[1] + parallax_offset.y
			var esize: float = elem[2]
			var eshape: String = elem[3] if elem.size() > 3 else "circle"

			match eshape:
				"circle":
					draw_circle(Vector2(ex, ey), esize, col)
				"rect":
					draw_rect(
						Rect2(ex - esize, ey - esize * 0.5,
							esize * 2, esize),
						col
					)
				"diamond":
					draw_colored_polygon(PackedVector2Array([
						Vector2(ex, ey - esize),
						Vector2(ex + esize * 0.6, ey),
						Vector2(ex, ey + esize),
						Vector2(ex - esize * 0.6, ey),
					]), col)


# ══════════════════ PARALLAX BACKGROUND ══════════════════
# Per-map `bg_layers` drives multi-layer scrolling backdrop. See layer dict
# spec at the top of the file.

# Texture cache shared across map instances so layers only load once.
static var _bg_tex_cache: Dictionary = {}


static func _load_bg_tex(path: String) -> Texture2D:
	if _bg_tex_cache.has(path):
		return _bg_tex_cache[path]
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path)
	_bg_tex_cache[path] = tex
	return tex


func _draw_parallax_background() -> void:
	if bg_layers.is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	var cam_pos: Vector2 = cam.position if cam != null \
		else (map_rect.position + map_rect.size / 2.0)
	var center: Vector2 = map_rect.position + map_rect.size / 2.0

	for layer in bg_layers:
		var path: String = layer.get("path", "")
		var tex: Texture2D = _load_bg_tex(path)
		if tex == null:
			continue
		var scroll: float = layer.get("scroll", 0.3)
		var mode: String = layer.get("mode", "bottom_tile")
		var y_off: float = layer.get("y", 0.0)
		var tex_scale: float = layer.get("scale", 1.0)
		var tint: Color = (layer.get("tint", Color.WHITE) as Color) * bg_tint
		tint.a = (layer.get("tint", Color.WHITE) as Color).a
		var parallax := (cam_pos - center) * (1.0 - scroll)

		match mode:
			"fill":
				# Aspect-preserved cover: upscale so texture completely
				# covers map + parallax buffer on both axes (whichever
				# dimension is tighter wins), centered on the map. Prevents
				# the grotesque distortion that happens when a compact
				# texture (e.g. 1440×807) is stretched across the full
				# off-screen bg rect.
				var native := tex.get_size()
				var want_h: float = map_rect.size.y + 1500.0
				var want_w: float = map_rect.size.x + 3000.0
				var eff_scale: float = maxf(
					want_w / native.x, want_h / native.y) * tex_scale
				var eff_size: Vector2 = native * eff_scale
				var map_cx := map_rect.position.x + map_rect.size.x / 2.0
				var map_cy := map_rect.position.y + map_rect.size.y / 2.0
				var dst := Rect2(
					Vector2(map_cx - eff_size.x / 2.0,
						map_cy - eff_size.y / 2.0) + parallax * 0.25,
					eff_size
				)
				draw_texture_rect(tex, dst, false, tint)
			"bottom_tile":
				# Single stretched copy anchored to the bottom, aspect
				# preserved. Height targets map_h + buffer, capped at
				# `max_scale` (default 2.5x) so small decorative textures
				# (e.g. 225×340 castle) don't blow up into huge blobs.
				# Width scales from that scale factor — centered horizontally,
				# with the sky layer (fill mode) filling any edge gap.
				var native := tex.get_size()
				var max_scale: float = layer.get("max_scale", 4.0)
				var want_h: float = map_rect.size.y + 1200.0
				var auto_scale: float = want_h / native.y
				var eff_scale: float = minf(auto_scale, max_scale) * tex_scale
				var eff_size: Vector2 = native * eff_scale
				# If the texture is too small, its width at eff_scale may
				# not cover the whole map. That's intentional — anything
				# above/beside is filled by the sky layer (`fill` mode).
				# Don't force-stretch X, which would distort the art.
				var y_top := map_rect.end.y + y_off - eff_size.y \
					+ parallax.y * 0.25
				var map_cx := map_rect.position.x + map_rect.size.x / 2.0
				var x_start := map_cx - eff_size.x / 2.0 + parallax.x * 0.25
				var dst := Rect2(Vector2(x_start, y_top), eff_size)
				draw_texture_rect(tex, dst, false, tint)
			"top_tile":
				var native := tex.get_size()
				var max_scale: float = layer.get("max_scale", 4.0)
				var want_h: float = map_rect.size.y + 1200.0
				var auto_scale: float = want_h / native.y
				var eff_scale: float = minf(auto_scale, max_scale) * tex_scale
				var eff_size: Vector2 = native * eff_scale
				if eff_size.x < map_rect.size.x + 3000.0:
					eff_size.x = map_rect.size.x + 3000.0
				var y_top := map_rect.position.y + y_off \
					+ parallax.y * 0.25
				var map_cx := map_rect.position.x + map_rect.size.x / 2.0
				var x_start := map_cx - eff_size.x / 2.0 + parallax.x * 0.25
				var dst := Rect2(Vector2(x_start, y_top), eff_size)
				draw_texture_rect(tex, dst, false, tint)


# ══════════════════ MAP BORDERS — water floor + side vignette ══════════════════

# Shared water texture (loaded once)
static var _water_tex: Texture2D = null


static func _get_water_tex() -> Texture2D:
	if _water_tex != null:
		return _water_tex
	var path := "res://assets/textures/platforms/water.png"
	if ResourceLoader.exists(path):
		_water_tex = load(path)
	return _water_tex


func _draw_water_floor() -> void:
	# Dark-water kill zone with an animated wavy surface — the border
	# itself undulates so the waterline reads as actual waves, not a
	# flat line. The fill below is solid dark blue; no "ice" texture.
	if danger_bottom <= 0.0:
		return
	var r := map_rect
	var top_y := r.end.y - danger_bottom
	var x0 := r.position.x - 4000.0
	var band_w := r.size.x + 8000.0
	var total_h := danger_bottom + 2200.0

	# Wave parameters — animated.
	var t := float(Engine.get_physics_frames()) * 0.03
	var wave_amp: float = 14.0
	var wavelen: float = 220.0
	var step: float = 22.0
	var n_seg: int = int(band_w / step) + 2

	# Build wavy top edge. Two superimposed sine waves for an organic look.
	var top_pts: PackedVector2Array = []
	for i in range(n_seg + 1):
		var x: float = x0 + i * step
		var phase := x / wavelen * TAU
		var w1 := sin(phase + t * 1.3) * wave_amp
		var w2 := sin(phase * 1.8 + t * 0.9) * wave_amp * 0.35
		top_pts.append(Vector2(x, top_y + w1 + w2))

	# Dark deep-water body: polygon with wavy top, rectangular sides/bottom.
	var deep_pts: PackedVector2Array = []
	deep_pts.append_array(top_pts)
	deep_pts.append(Vector2(x0 + band_w, top_y + total_h))
	deep_pts.append(Vector2(x0, top_y + total_h))
	draw_colored_polygon(deep_pts, Color(0.06, 0.14, 0.24, 1.0))

	# Brighter surface strip (same wavy top, shorter): lets the surface
	# read as mid-blue above a darker depth.
	var surf_h: float = 48.0
	var surf_pts: PackedVector2Array = []
	surf_pts.append_array(top_pts)
	# Second edge: wavy line offset down by surf_h (same shape)
	for i in range(top_pts.size() - 1, -1, -1):
		surf_pts.append(Vector2(top_pts[i].x, top_pts[i].y + surf_h))
	draw_colored_polygon(surf_pts, Color(0.14, 0.35, 0.52, 0.85))

	# Bright wavy highlight exactly on the surface line.
	draw_polyline(top_pts, Color(0.55, 0.82, 0.95, 0.85), 3.0, true)

	# Secondary dimmer wave a few px below — gives the waterline depth.
	var sec_pts: PackedVector2Array = []
	for p in top_pts:
		sec_pts.append(Vector2(p.x, p.y + 7.0))
	draw_polyline(sec_pts, Color(0.42, 0.70, 0.90, 0.35), 2.0, true)


func _draw_side_vignette() -> void:
	var r := map_rect
	var fade_left: float = maxf(danger_left, 120.0)
	var fade_right: float = maxf(danger_right, 120.0)
	var steps := 24

	# Left vignette — dark on outside, transparent toward map center.
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var alpha := 0.85 * pow(1.0 - t0, 1.6)
		var col := Color(0.0, 0.0, 0.0, alpha)
		var x_a := r.position.x + t0 * fade_left
		var x_b := r.position.x + t1 * fade_left
		draw_rect(
			Rect2(Vector2(x_a - 4000.0, r.position.y - 3000.0),
				Vector2((x_b - x_a) + 4000.0, r.size.y + 6000.0)),
			col
		)

	# Right vignette
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var alpha := 0.85 * pow(1.0 - t0, 1.6)
		var col := Color(0.0, 0.0, 0.0, alpha)
		var x_a := r.end.x - t0 * fade_right
		var x_b := r.end.x - t1 * fade_right
		draw_rect(
			Rect2(Vector2(x_b, r.position.y - 3000.0),
				Vector2((x_a - x_b) + 4000.0, r.size.y + 6000.0)),
			col
		)



func _draw_walls() -> void:
	if not (use_walls or fire_walls or bouncy_walls):
		return
	var r := map_rect
	var t := wall_thickness
	var time_val := float(Engine.get_physics_frames()) * 0.02

	if bouncy_walls:
		var bc := Color(0.2, 0.9, 0.6, 0.7)
		draw_rect(Rect2(r.position.x - t, r.position.y - 100, t, r.size.y + 200), bc.darkened(0.4))
		draw_rect(Rect2(r.end.x, r.position.y - 100, t, r.size.y + 200), bc.darkened(0.4))
		draw_rect(Rect2(r.position.x - 100, r.end.y, r.size.x + 200, t), bc.darkened(0.4))
		if danger_top > 0:
			draw_rect(Rect2(r.position.x - 100, r.position.y - t, r.size.x + 200, t), bc.darkened(0.4))
		# Spring zigzag lines on left and right walls
		for i in range(int(r.size.y / 40)):
			var y_pos := r.position.y + i * 40.0
			draw_line(Vector2(r.position.x - 5, y_pos), Vector2(r.position.x - t + 5, y_pos + 20), bc, 2.0)
			draw_line(Vector2(r.end.x + 5, y_pos), Vector2(r.end.x + t - 5, y_pos + 20), bc, 2.0)
	elif fire_walls:
		var fc := Color(0.9, 0.3, 0.05, 0.6)
		draw_rect(Rect2(r.position.x - t, r.position.y - 100, t, r.size.y + 200), fc.darkened(0.5))
		draw_rect(Rect2(r.end.x, r.position.y - 100, t, r.size.y + 200), fc.darkened(0.5))
		draw_rect(Rect2(r.position.x - 100, r.end.y, r.size.x + 200, t), fc.darkened(0.5))
		if danger_top > 0:
			draw_rect(Rect2(r.position.x - 100, r.position.y - t, r.size.x + 200, t), fc.darkened(0.5))
		# Flame particles on left and right walls
		for i in range(int(r.size.y / 30)):
			var y_pos := r.position.y + i * 30.0
			var flicker := sin(time_val * 4.0 + i * 1.5) * 5.0
			draw_circle(Vector2(r.position.x + flicker, y_pos), 4.0 + sin(time_val + i) * 2.0, Color(1, 0.5, 0.1, 0.4))
			draw_circle(Vector2(r.end.x + flicker, y_pos), 4.0 + sin(time_val + i) * 2.0, Color(1, 0.5, 0.1, 0.4))
	else:
		# Stone walls
		var wc := Color(0.4, 0.35, 0.3, 0.8)
		draw_rect(Rect2(r.position.x - t, r.position.y - 100, t, r.size.y + 200), wc)
		draw_rect(Rect2(r.end.x, r.position.y - 100, t, r.size.y + 200), wc)
		draw_rect(Rect2(r.position.x - 100, r.end.y, r.size.x + 200, t), wc)
		if danger_top > 0:
			draw_rect(Rect2(r.position.x - 100, r.position.y - t, r.size.x + 200, t), wc)
		# Brick pattern on left and right walls
		for i in range(int(r.size.y / 25)):
			var y_pos := r.position.y + i * 25.0
			draw_line(Vector2(r.position.x - t, y_pos), Vector2(r.position.x, y_pos), Color(0.3, 0.25, 0.2, 0.3), 1.0)
			draw_line(Vector2(r.end.x, y_pos), Vector2(r.end.x + t, y_pos), Color(0.3, 0.25, 0.2, 0.3), 1.0)


func _draw_platforms() -> void:
	for data in platforms:
		var x: float = data[0]
		var y: float = data[1]
		var w: float = data[2]
		var h: float = data[3]
		var platform_type = data[4] if data.size() > 4 else false
		if platform_type is String and platform_type == "sticky":
			# Purple/web-textured sticky platforms
			var sticky_fill := Color(0.45, 0.15, 0.55, 0.9)
			var sticky_edge := Color(0.7, 0.3, 0.8, 1.0)
			_draw_capsule(x, y, w, h, sticky_fill, sticky_edge)
			var hw := w / 2.0
			var hh := h / 2.0
			var web_gap := 30.0
			var xi := x - hw
			while xi < x + hw:
				draw_line(Vector2(xi, y - hh), Vector2(xi + web_gap * 0.5, y + hh),
					Color(0.8, 0.4, 1.0, 0.25), 1.0)
				xi += web_gap
		elif platform_palette != "":
			_draw_themed_platform(x, y, w, h, platform_palette)
		elif platform_type is bool and platform_type:
			_draw_capsule(x, y, w, h, platform_color, platform_edge_color)
		else:
			_draw_capsule(x, y, w, h, floor_color, floor_edge_color)


# ══════════════════ TEXTURED THEMED PLATFORMS ══════════════════

# Cache loaded platform textures by palette name
static var _palette_tex_cache: Dictionary = {}


static func _get_palette_texture(palette: String) -> Texture2D:
	if _palette_tex_cache.has(palette):
		return _palette_tex_cache[palette]
	var path := "res://assets/textures/platforms/%s.png" % palette
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_palette_tex_cache[palette] = tex
	return tex


# Edge color per palette for outline / shadows
static func _get_palette_edge(palette: String) -> Color:
	match palette:
		"grass": return Color(0.25, 0.18, 0.08)
		"stone": return Color(0.30, 0.30, 0.32)
		"wood":  return Color(0.30, 0.18, 0.08)
		"ice":   return Color(0.30, 0.55, 0.80)
		"magma": return Color(0.30, 0.10, 0.05)
		_: return Color(0.2, 0.2, 0.2)


func _draw_themed_platform(
	cx: float, cy: float, w: float, h: float, palette: String
) -> void:
	var tex: Texture2D = _get_palette_texture(palette)
	if tex == null:
		_draw_capsule(cx, cy, w, h, platform_color, platform_edge_color)
		return

	var hw := w / 2.0
	var hh := h / 2.0
	var r := minf(hh * 0.95, h * 0.45)
	r = clampf(r, 6.0, 26.0)
	var segs := 12

	# Build the full rounded capsule polygon.
	var pts: PackedVector2Array = []
	for i in range(segs + 1):
		var a := PI + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx - hw + r + cos(a) * r, cy - hh + r + sin(a) * r))
	for i in range(segs + 1):
		var a := -PI / 2.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx + hw - r + cos(a) * r, cy - hh + r + sin(a) * r))
	for i in range(segs + 1):
		var a := 0.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx + hw - r + cos(a) * r, cy + hh - r + sin(a) * r))
	for i in range(segs + 1):
		var a := PI / 2.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx - hw + r + cos(a) * r, cy + hh - r + sin(a) * r))

	# Solid base fill underneath the polygon — guards against any 1-px
	# anti-alias falloff on the rounded arc edges; the color is chosen
	# to blend with the texture's dominant mid-tone so hairline joints
	# disappear under it.
	draw_colored_polygon(pts, platform_color)

	# One textured polygon spanning the WHOLE capsule (including the
	# rounded corners). UV.x goes 0..u_max where u_max = w / tile_w;
	# GPU sampler wraps UV>1 via GL_REPEAT (texture_repeat=ENABLED in
	# _ready). UV.y goes 0..1 across platform height.
	var tex_size: Vector2 = tex.get_size()
	var scl: float = h / tex_size.y
	var tile_w: float = tex_size.x * scl
	var u_max: float = w / tile_w
	var uvs: PackedVector2Array = []
	for p in pts:
		var u: float = ((p.x - (cx - hw)) / w) * u_max
		var v: float = (p.y - (cy - hh)) / h
		uvs.append(Vector2(u, v))
	draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)

	# Edge outline + top highlight + bottom shadow.
	var edge: Color = _get_palette_edge(palette)
	for i in range(pts.size()):
		var i2 := (i + 1) % pts.size()
		draw_line(pts[i], pts[i2], edge, 2.0)
	draw_line(
		Vector2(cx - hw + r, cy - hh),
		Vector2(cx + hw - r, cy - hh),
		edge.lightened(0.35), 2.0
	)
	draw_line(
		Vector2(cx - hw + r, cy + hh),
		Vector2(cx + hw - r, cy + hh),
		edge.darkened(0.3), 2.0
	)


func _draw_objects() -> void:
	for obj in objects:
		var type: String = obj[0]
		match type:
			"ball":
				_draw_ball(obj[1], obj[2], obj[3])
			"arc":
				_draw_arc(obj[1], obj[2], obj[3], obj[4], obj[5])


## ══════ CAPSULE (rounded rectangle) ══════
func _draw_capsule(
	cx: float, cy: float, w: float, h: float,
	fill: Color, edge: Color
) -> void:
	var hw := w / 2.0
	var hh := h / 2.0
	var r := minf(hh, hw * 0.15)  # corner radius — subtle rounding
	r = clampf(r, 4.0, 20.0)

	# Build rounded rect polygon
	var pts: PackedVector2Array = []
	var segs := 6

	# Top-left corner
	for i in range(segs + 1):
		var a := PI + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx - hw + r + cos(a) * r, cy - hh + r + sin(a) * r))
	# Top-right corner
	for i in range(segs + 1):
		var a := -PI / 2.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx + hw - r + cos(a) * r, cy - hh + r + sin(a) * r))
	# Bottom-right corner
	for i in range(segs + 1):
		var a := 0.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx + hw - r + cos(a) * r, cy + hh - r + sin(a) * r))
	# Bottom-left corner
	for i in range(segs + 1):
		var a := PI / 2.0 + float(i) / segs * (PI / 2.0)
		pts.append(Vector2(cx - hw + r + cos(a) * r, cy + hh - r + sin(a) * r))

	draw_colored_polygon(pts, fill)

	# Top highlight
	draw_line(
		Vector2(cx - hw + r, cy - hh),
		Vector2(cx + hw - r, cy - hh),
		edge.lightened(0.2), 3.0
	)
	# Bottom shadow
	draw_line(
		Vector2(cx - hw + r, cy + hh),
		Vector2(cx + hw - r, cy + hh),
		fill.darkened(0.3), 2.0
	)
	# Outline
	for i in range(pts.size()):
		var i2 := (i + 1) % pts.size()
		draw_line(pts[i], pts[i2], edge, 1.5)

	# Surface texture
	@warning_ignore("integer_division")
	var line_count: int = int(w / 50.0)
	for i in range(line_count):
		var t := float(i + 1) / (line_count + 1)
		var lx := cx - hw + t * w
		draw_line(
			Vector2(lx, cy - hh + 3), Vector2(lx + 12, cy - hh + 3),
			edge.darkened(0.15), 1.0
		)


## ══════ BALL (circle platform) ══════
func _draw_ball(x: float, y: float, radius: float) -> void:
	var fill := platform_color.lightened(0.1)
	var edge := platform_edge_color

	# Main circle
	var segs := 24
	var pts: PackedVector2Array = []
	for i in range(segs):
		var a := float(i) * TAU / segs
		pts.append(Vector2(x + cos(a) * radius, y + sin(a) * radius))
	draw_colored_polygon(pts, fill)

	# Highlight arc on top
	@warning_ignore("integer_division")
	var half: int = segs / 2
	for i in range(half):
		var a0 := PI + float(i) * PI / float(half)
		var a1 := PI + float(i + 1) * PI / float(half)
		draw_line(
			Vector2(x + cos(a0) * radius, y + sin(a0) * radius),
			Vector2(x + cos(a1) * radius, y + sin(a1) * radius),
			edge.lightened(0.2), 3.0
		)

	# Shadow on bottom
	for i in range(half):
		var a0 := float(i) * PI / float(half)
		var a1 := float(i + 1) * PI / float(half)
		draw_line(
			Vector2(x + cos(a0) * radius, y + sin(a0) * radius),
			Vector2(x + cos(a1) * radius, y + sin(a1) * radius),
			fill.darkened(0.3), 2.0
		)

	# Outline
	draw_arc(Vector2(x, y), radius, 0.0, TAU, segs, edge, 1.5)

	# Shine spot
	draw_circle(
		Vector2(x - radius * 0.3, y - radius * 0.3),
		radius * 0.2, Color(1, 1, 1, 0.15)
	)


## ══════ ARC (curved platform) ══════
func _draw_arc(
	x: float, y: float, radius: float,
	start_deg: float, end_deg: float
) -> void:
	var fill := platform_color
	var edge := platform_edge_color
	var start_rad := deg_to_rad(start_deg)
	var end_rad := deg_to_rad(end_deg)
	var segs := 16
	var thickness := 20.0

	# Outer and inner arcs to form a thick curve
	for i in range(segs):
		var a0 := start_rad + (end_rad - start_rad) * float(i) / segs
		var a1 := start_rad + (end_rad - start_rad) * float(i + 1) / segs
		var outer0 := Vector2(x + cos(a0) * radius, y + sin(a0) * radius)
		var outer1 := Vector2(x + cos(a1) * radius, y + sin(a1) * radius)
		var inner0 := Vector2(
			x + cos(a0) * (radius - thickness),
			y + sin(a0) * (radius - thickness)
		)
		var inner1 := Vector2(
			x + cos(a1) * (radius - thickness),
			y + sin(a1) * (radius - thickness)
		)
		draw_colored_polygon(
			PackedVector2Array([outer0, outer1, inner1, inner0]), fill
		)

	# Outer edge line
	for i in range(segs):
		var a0 := start_rad + (end_rad - start_rad) * float(i) / segs
		var a1 := start_rad + (end_rad - start_rad) * float(i + 1) / segs
		draw_line(
			Vector2(x + cos(a0) * radius, y + sin(a0) * radius),
			Vector2(x + cos(a1) * radius, y + sin(a1) * radius),
			edge, 2.0
		)
	# Inner edge
	for i in range(segs):
		var a0 := start_rad + (end_rad - start_rad) * float(i) / segs
		var a1 := start_rad + (end_rad - start_rad) * float(i + 1) / segs
		draw_line(
			Vector2(x + cos(a0) * (radius - thickness), y + sin(a0) * (radius - thickness)),
			Vector2(x + cos(a1) * (radius - thickness), y + sin(a1) * (radius - thickness)),
			edge.darkened(0.2), 1.5
		)


## ══════ BOUNDS HELPERS ══════
func get_safe_rect() -> Rect2:
	return Rect2(
		map_rect.position.x + danger_left,
		map_rect.position.y + danger_top,
		map_rect.size.x - danger_left - danger_right,
		map_rect.size.y - danger_top - danger_bottom,
	)


func is_in_danger_zone(pos: Vector2) -> bool:
	if use_walls or fire_walls or bouncy_walls:
		return false
	if pos.x < map_rect.position.x + danger_left:
		return true
	if pos.x > map_rect.end.x - danger_right:
		return true
	if pos.y > map_rect.end.y - danger_bottom:
		return true
	if danger_top > 0 and pos.y < map_rect.position.y + danger_top:
		return true
	return false


func is_past_kill_zone(pos: Vector2) -> bool:
	if use_walls or fire_walls or bouncy_walls:
		return false
	if pos.x < map_rect.position.x - kill_margin:
		return true
	if pos.x > map_rect.end.x + kill_margin:
		return true
	if pos.y > map_rect.end.y + kill_margin:
		return true
	if danger_top > 0 and pos.y < map_rect.position.y - kill_margin:
		return true
	return false


## ══════ SPIKES (instant kill) ══════
func _create_spikes(x: float, y: float, w: float, h: float) -> void:
	var area := Area2D.new()
	area.position = Vector2(x, y)
	area.collision_layer = 0
	area.collision_mask = 2  # detect players
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D and body.has_method("die"):
			if body.is_alive:
				body.die()
	)
	area.add_to_group("hazards")
	add_child(area)


## ══════ MOVING PLATFORMS ══════
func _create_moving_platform(
	x: float, y: float, w: float, h: float,
	move_x: float, move_y: float, speed: float
) -> void:
	var body := AnimatableBody2D.new()
	body.position = Vector2(x, y)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.one_way_collision = true
	body.add_child(col)
	body.add_to_group("moving_platforms")
	# Store movement data as metadata
	body.set_meta("origin", Vector2(x, y))
	body.set_meta("move_vec", Vector2(move_x, move_y))
	body.set_meta("speed", speed)
	body.set_meta("time", randf() * TAU)  # random phase
	add_child(body)


func _process(delta: float) -> void:
	# Animate moving platforms
	for node in get_tree().get_nodes_in_group("moving_platforms"):
		if not node.has_meta("origin"):
			continue
		var origin: Vector2 = node.get_meta("origin")
		var move_vec: Vector2 = node.get_meta("move_vec")
		var spd: float = node.get_meta("speed")
		var t: float = node.get_meta("time") + delta * spd
		node.set_meta("time", t)
		var offset := sin(t) * 0.5 + 0.5  # 0 to 1 oscillation
		node.position = origin + move_vec * offset

	# Global zone shrink after 120 seconds (disabled when walls are active)
	if not (use_walls or fire_walls or bouncy_walls):
		global_shrink_timer += delta
		if global_shrink_timer > SHRINK_GLOBAL_DELAY:
			var safe_w := map_rect.size.x - danger_left - danger_right
			var safe_h := map_rect.size.y - danger_top - danger_bottom
			if safe_w > SHRINK_MIN_SAFE:
				danger_left += SHRINK_GLOBAL_SPEED * delta * 0.5
				danger_right += SHRINK_GLOBAL_SPEED * delta * 0.5
			if safe_h > SHRINK_MIN_SAFE:
				if danger_top > 0:
					danger_top += SHRINK_GLOBAL_SPEED * delta * 0.3
				danger_bottom += SHRINK_GLOBAL_SPEED * delta * 0.3

	# Fire wall damage
	if fire_walls:
		for p in get_tree().get_nodes_in_group("players"):
			if not p.is_alive:
				continue
			var px: float = p.global_position.x
			var py: float = p.global_position.y
			if px < map_rect.position.x + 10 or px > map_rect.end.x - 10 \
					or py > map_rect.end.y - 10 \
					or (danger_top > 0 and py < map_rect.position.y + 10):
				p._apply_fire_burn(5.0, 0.3, 0.6)

	# Bouncy wall collision response
	if bouncy_walls:
		for p in get_tree().get_nodes_in_group("players"):
			if not p.is_alive:
				continue
			var r_val: float = p.get_player_radius()
			if p.global_position.x < map_rect.position.x + r_val:
				p.global_position.x = map_rect.position.x + r_val
				p.velocity.x = absf(p.velocity.x) * 1.2 + 200.0
			elif p.global_position.x > map_rect.end.x - r_val:
				p.global_position.x = map_rect.end.x - r_val
				p.velocity.x = -absf(p.velocity.x) * 1.2 - 200.0
			if p.global_position.y > map_rect.end.y - r_val:
				p.global_position.y = map_rect.end.y - r_val
				p.velocity.y = -absf(p.velocity.y) * 1.0 - 150.0

	# Decay event banner display timer
	if event_banner_timer > 0.0:
		event_banner_timer -= delta
	# Map events (legacy events_enabled flag implies "all")
	if event_type == "none" and events_enabled:
		event_type = "all"
	if event_type != "" and event_type != "none":
		event_timer += delta
		if event_timer >= EVENT_INTERVAL:
			event_timer = 0.0
			match event_type:
				"wind":      _event_wave()
				"meteor":    _event_meteor()
				"lightning": _event_lightning()
				_:           _trigger_random_event()

	# Item spawning
	if item_spawns.size() > 0 and Engine.get_physics_frames() % 900 == 0:
		_spawn_random_item()

	# Always redraw — parallax background + animated water border need
	# per-frame updates for smooth camera follow and wave bob.
	queue_redraw()


func _draw_hazards() -> void:
	# Draw spikes
	for haz in hazards:
		if haz[0] == "spikes":
			_draw_spike_visual(haz[1], haz[2], haz[3], haz[4])

	# Draw moving platforms
	for node in get_tree().get_nodes_in_group("moving_platforms"):
		if not is_instance_valid(node):
			continue
		var pos: Vector2 = node.position
		var shape: CollisionShape2D = node.get_child(0)
		if shape != null and shape.shape is RectangleShape2D:
			var sz: Vector2 = shape.shape.size
			_draw_capsule(pos.x, pos.y, sz.x, sz.y,
				platform_color.lerp(Color(0.4, 0.6, 0.8), 0.3),
				platform_edge_color.lerp(Color(0.5, 0.7, 0.9), 0.3))

	# Draw teleport portals
	var time := float(Engine.get_physics_frames()) * 0.016
	for tp in get_tree().get_nodes_in_group("teleports"):
		if not is_instance_valid(tp):
			continue
		var tpos: Vector2 = tp.position
		var pulse := sin(time * 3.0) * 0.15 + 0.85
		var portal_h: float = tp.get_meta("height") if tp.has_meta("height") else 0.0
		if portal_h > 0.0:
			# Rectangular/oval portal (v2 format)
			var portal_angle: float = tp.get_meta("angle")
			var hw := 15.0
			var hh := portal_h / 2.0
			# Draw rotated oval using polygon approximation
			var segs := 16
			var pts: PackedVector2Array = []
			for si in range(segs):
				var a := float(si) * TAU / segs
				var lx := cos(a) * hw * pulse
				var ly := sin(a) * hh * pulse
				var rad := deg_to_rad(portal_angle)
				pts.append(tpos + Vector2(
					lx * cos(rad) - ly * sin(rad),
					lx * sin(rad) + ly * cos(rad)
				))
			draw_colored_polygon(pts, Color(0.4, 0.2, 0.8, 0.25))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.4, 0.2, 0.8, 0.7), 2.5)
			# Inner glow oval
			var pts2: PackedVector2Array = []
			for si in range(segs):
				var a := float(si) * TAU / segs
				var lx := cos(a) * hw * 0.55
				var ly := sin(a) * hh * 0.55
				var rad := deg_to_rad(portal_angle)
				pts2.append(tpos + Vector2(
					lx * cos(rad) - ly * sin(rad),
					lx * sin(rad) + ly * cos(rad)
				))
			draw_colored_polygon(pts2, Color(0.6, 0.3, 1.0, 0.2))
			# Particle wisps
			for pi in range(5):
				var pa := time * 2.0 + pi * TAU / 5.0
				var px := tpos.x + cos(pa) * hw * 0.8
				var py := tpos.y + sin(pa) * hh * 0.8
				draw_circle(Vector2(px, py), 3.0, Color(0.7, 0.4, 1.0, 0.4))
		else:
			# Old circular portal
			draw_arc(tpos, 25.0 * pulse, 0.0, TAU, 16,
				Color(0.4, 0.2, 0.8, 0.5), 3.0)
			draw_arc(tpos, 15.0, 0.0, TAU, 12,
				Color(0.6, 0.3, 1.0, 0.3), 2.0)
		# Cooldown decay
		var cd: float = tp.get_meta("cooldown")
		if cd > 0.0:
			tp.set_meta("cooldown", cd - 0.016)

	# Draw destructible platforms
	for dplat in get_tree().get_nodes_in_group("destructible_platforms"):
		if not is_instance_valid(dplat):
			continue
		var dpos: Vector2 = dplat.position
		var dsz: Vector2 = dplat.get_meta("size")
		var dhp: int = dplat.get_meta("hp")
		var dmax: int = dplat.get_meta("max_hp")
		var hp_ratio: float = float(dhp) / maxf(dmax, 1)
		var crack_col := platform_color.lerp(Color(0.5, 0.2, 0.1), 1.0 - hp_ratio)
		_draw_capsule(dpos.x, dpos.y, dsz.x, dsz.y, crack_col,
			platform_edge_color.darkened(0.3 * (1.0 - hp_ratio)))

	# Draw items
	for item in get_tree().get_nodes_in_group("map_items"):
		if not is_instance_valid(item):
			continue
		var ipos: Vector2 = item.position
		var itype: int = item.get_meta("item_type")
		var bob := sin(time * 3.0 + ipos.x * 0.01) * 5.0
		ipos.y += bob
		match itype:
			0:  # Health — green cross
				draw_circle(ipos, 16.0, Color(0.1, 0.08, 0.14, 0.8))
				draw_line(ipos + Vector2(-6, 0), ipos + Vector2(6, 0),
					Color(0.2, 0.9, 0.2), 3.0)
				draw_line(ipos + Vector2(0, -6), ipos + Vector2(0, 6),
					Color(0.2, 0.9, 0.2), 3.0)
				draw_arc(ipos, 16.0, 0.0, TAU, 12, Color(0.2, 0.9, 0.2, 0.5), 2.0)
			1:  # Speed — yellow lightning
				draw_circle(ipos, 16.0, Color(0.1, 0.08, 0.14, 0.8))
				draw_line(ipos + Vector2(-3, -8), ipos + Vector2(2, -1),
					Color(1, 0.85, 0.2), 2.5)
				draw_line(ipos + Vector2(2, -1), ipos + Vector2(-2, 1),
					Color(1, 0.85, 0.2), 2.5)
				draw_line(ipos + Vector2(-2, 1), ipos + Vector2(3, 8),
					Color(1, 0.85, 0.2), 2.5)
				draw_arc(ipos, 16.0, 0.0, TAU, 12, Color(1, 0.85, 0.2, 0.5), 2.0)
			2:  # CD Reset — blue clock
				draw_circle(ipos, 16.0, Color(0.1, 0.08, 0.14, 0.8))
				draw_arc(ipos, 8.0, 0.0, TAU, 10, Color(0.3, 0.5, 1.0), 2.0)
				draw_line(ipos, ipos + Vector2(0, -6), Color(0.3, 0.5, 1.0), 2.0)
				draw_line(ipos, ipos + Vector2(5, 0), Color(0.3, 0.5, 1.0), 1.5)
				draw_arc(ipos, 16.0, 0.0, TAU, 12, Color(0.3, 0.5, 1.0, 0.5), 2.0)


func _draw_spike_visual(x: float, y: float, w: float, h: float) -> void:
	var spike_count := int(w / 20.0)
	var spike_w := w / maxf(spike_count, 1)
	for i in range(spike_count):
		var sx := x - w / 2.0 + i * spike_w + spike_w / 2.0
		# Triangle spike pointing up
		var pts := PackedVector2Array([
			Vector2(sx - spike_w * 0.4, y + h / 2.0),
			Vector2(sx, y - h / 2.0),
			Vector2(sx + spike_w * 0.4, y + h / 2.0),
		])
		draw_colored_polygon(pts, Color(0.8, 0.15, 0.1, 0.9))
		# Highlight
		draw_line(
			Vector2(sx - spike_w * 0.4, y + h / 2.0),
			Vector2(sx, y - h / 2.0),
			Color(1, 0.3, 0.2, 0.5), 1.5
		)


## ══════ TELEPORTS ══════
func _create_teleport_pair(x1: float, y1: float, x2: float, y2: float) -> void:
	var portal_a := Area2D.new()
	portal_a.position = Vector2(x1, y1)
	portal_a.collision_layer = 0
	portal_a.collision_mask = 2
	var shape_a := CircleShape2D.new()
	shape_a.radius = 30.0
	var col_a := CollisionShape2D.new()
	col_a.shape = shape_a
	portal_a.add_child(col_a)
	portal_a.set_meta("target", Vector2(x2, y2))
	portal_a.set_meta("cooldown", 0.0)
	portal_a.add_to_group("teleports")

	var portal_b := Area2D.new()
	portal_b.position = Vector2(x2, y2)
	portal_b.collision_layer = 0
	portal_b.collision_mask = 2
	var shape_b := CircleShape2D.new()
	shape_b.radius = 30.0
	var col_b := CollisionShape2D.new()
	col_b.shape = shape_b
	portal_b.add_child(col_b)
	portal_b.set_meta("target", Vector2(x1, y1))
	portal_b.set_meta("cooldown", 0.0)
	portal_b.add_to_group("teleports")

	portal_a.body_entered.connect(func(body: Node2D) -> void:
		_teleport_body(body, portal_a))
	portal_b.body_entered.connect(func(body: Node2D) -> void:
		_teleport_body(body, portal_b))

	add_child(portal_a)
	add_child(portal_b)


func _teleport_body(body: Node2D, portal: Area2D) -> void:
	if not body is CharacterBody2D or not body.has_method("die"):
		return
	var cd: float = portal.get_meta("cooldown")
	if cd > 0.0:
		return
	# Cut active grapple so teleport actually moves the player rather than
	# being yanked back by the rope anchor.
	if body.has_method("_release_grapple"):
		body._release_grapple()
	var target: Vector2 = portal.get_meta("target")
	body.global_position = target
	portal.set_meta("cooldown", 1.0)
	# Set cooldown on target portal too
	for tp in get_tree().get_nodes_in_group("teleports"):
		if tp.position.distance_to(target) < 5.0:
			tp.set_meta("cooldown", 1.0)
	SoundManager.play_blink()


## Rectangular portal pair with optional height and rotation angle
func _create_teleport_pair_v2(
	x1: float, y1: float, h1: float, angle1: float,
	x2: float, y2: float, h2: float, angle2: float
) -> void:
	var portal_a := Area2D.new()
	portal_a.position = Vector2(x1, y1)
	portal_a.rotation_degrees = angle1
	portal_a.collision_layer = 0
	portal_a.collision_mask = 2
	var shape_a := RectangleShape2D.new()
	shape_a.size = Vector2(30.0, h1)
	var col_a := CollisionShape2D.new()
	col_a.shape = shape_a
	portal_a.add_child(col_a)
	portal_a.set_meta("target", Vector2(x2, y2))
	portal_a.set_meta("cooldown", 0.0)
	portal_a.set_meta("height", h1)
	portal_a.set_meta("angle", angle1)
	portal_a.add_to_group("teleports")

	var portal_b := Area2D.new()
	portal_b.position = Vector2(x2, y2)
	portal_b.rotation_degrees = angle2
	portal_b.collision_layer = 0
	portal_b.collision_mask = 2
	var shape_b := RectangleShape2D.new()
	shape_b.size = Vector2(30.0, h2)
	var col_b := CollisionShape2D.new()
	col_b.shape = shape_b
	portal_b.add_child(col_b)
	portal_b.set_meta("target", Vector2(x1, y1))
	portal_b.set_meta("cooldown", 0.0)
	portal_b.set_meta("height", h2)
	portal_b.set_meta("angle", angle2)
	portal_b.add_to_group("teleports")

	portal_a.body_entered.connect(func(body: Node2D) -> void:
		_teleport_body(body, portal_a))
	portal_b.body_entered.connect(func(body: Node2D) -> void:
		_teleport_body(body, portal_b))

	add_child(portal_a)
	add_child(portal_b)


## ══════ DESTRUCTIBLE PLATFORMS ══════
func _create_destructible(
	x: float, y: float, w: float, h: float, plat_hp: int
) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.one_way_collision = true
	body.add_child(col)
	body.set_meta("hp", plat_hp)
	body.set_meta("max_hp", plat_hp)
	body.set_meta("size", Vector2(w, h))
	body.add_to_group("destructible_platforms")
	add_child(body)


func damage_platform_at(pos: Vector2) -> void:
	for plat in get_tree().get_nodes_in_group("destructible_platforms"):
		var sz: Vector2 = plat.get_meta("size")
		var dist := pos.distance_to(plat.position)
		if dist < maxf(sz.x, sz.y):
			var hp: int = plat.get_meta("hp") - 1
			plat.set_meta("hp", hp)
			if hp <= 0:
				plat.queue_free()
			break


## ══════ ITEMS ══════
func _spawn_random_item() -> void:
	if item_spawns.is_empty():
		return
	var idx: int = randi_range(0, item_spawns.size() - 1)
	var spawn_pos: Vector2 = Vector2(item_spawns[idx][0], item_spawns[idx][1])
	# Check if item already near this spot
	for existing in get_tree().get_nodes_in_group("map_items"):
		if existing.global_position.distance_to(spawn_pos) < 100:
			return
	var item_type: int = randi_range(0, 2)  # 0=health, 1=speed, 2=cd_reset
	var item := Area2D.new()
	item.position = spawn_pos
	item.collision_layer = 0
	item.collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var col := CollisionShape2D.new()
	col.shape = shape
	item.add_child(col)
	item.set_meta("item_type", item_type)
	item.set_meta("time", 0.0)
	item.add_to_group("map_items")
	item.body_entered.connect(func(body: Node2D) -> void:
		_pickup_item(body, item))
	add_child(item)


func _pickup_item(body: Node2D, item: Area2D) -> void:
	if not body is CharacterBody2D or not body.has_method("heal"):
		return
	var itype: int = item.get_meta("item_type")
	match itype:
		0:  # Health
			body.heal(body.MAX_HP * 0.3)
		1:  # Speed boost
			body.base_speed_mult *= 1.3
			# Revert after 5 seconds
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				if is_instance_valid(body):
					body.base_speed_mult /= 1.3)
		2:  # Cooldown reset
			for ci in range(body.ability_cds.size()):
				body.ability_cds[ci] = 0.0
	SoundManager.play_shield()
	item.queue_free()


## ══════ MAP EVENTS ══════
func _trigger_random_event() -> void:
	var event: int = randi_range(0, 2)
	match event:
		0:
			_event_meteor()
		1:
			_event_lightning()
		2:
			_event_wave()


func _event_meteor() -> void:
	# Random meteor falls from top
	var x := randf_range(
		map_rect.position.x + danger_left + 200,
		map_rect.end.x - danger_right - 200
	)
	_show_event_banner("☄ METEOR INCOMING ☄", Color(1.0, 0.45, 0.2), 1.8)
	# Kick off falling meteor visual — _draw reads these.
	_meteor_x = x
	_meteor_y_impact = map_rect.end.y - danger_bottom - 20.0
	_meteor_y_spawn = map_rect.position.y - 200.0
	_meteor_start_t = _event_time()
	# Damage all players near impact line
	await get_tree().create_timer(METEOR_FALL_DUR).timeout
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		if absf(p.global_position.x - x) < 140.0:
			p.take_damage(40.0)
			p.apply_knockback(Vector2(0, -500))
	SoundManager.play_explosion()
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(8.0)


func _event_lightning() -> void:
	# Strike a random player
	var players := get_tree().get_nodes_in_group("players")
	var alive: Array = []
	for p in players:
		if p.is_alive:
			alive.append(p)
	if alive.is_empty():
		return
	var target: CharacterBody2D = alive[randi_range(0, alive.size() - 1)]
	_show_event_banner("⚡ LIGHTNING STRIKE ⚡", Color(1.0, 0.95, 0.5), 1.2)
	_lightning_target = target.global_position
	_lightning_origin = Vector2(_lightning_target.x,
		map_rect.position.y - 200.0)
	_lightning_start_t = _event_time()
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(target) and target.is_alive:
		target.take_damage(30.0)
		target.apply_stun(0.5)
		SoundManager.play_hit()


func _event_wave() -> void:
	# Horizontal wind pushes all players
	var dir := 1.0 if randf() > 0.5 else -1.0
	var arrow: String = "→→→" if dir > 0 else "←←←"
	_show_event_banner("💨 STRONG WIND  " + arrow, Color(0.6, 0.9, 1.0), 1.2)
	_wind_dir = dir
	_wind_start_t = _event_time()
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_alive:
			p.apply_knockback(Vector2(dir * 400.0, -100.0))
	SoundManager.play_dash()


func _show_event_banner(text: String, color: Color, dur: float) -> void:
	event_banner_text = text
	event_banner_color = color
	event_banner_timer = dur


func _event_time() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _draw_decorations() -> void:
	pass
