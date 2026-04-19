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
## Map events enabled
var events_enabled: bool = false
var event_timer: float = 0.0
const EVENT_INTERVAL := 20.0

## Parallax layers: [{color, elements: [{x, y, size, shape}], scroll_factor}]
## scroll_factor: 0.0 = static, 1.0 = moves with camera
var parallax_layers: Array = []

var bg_color: Color = Color(0.12, 0.1, 0.15)
var platform_color: Color = Color(0.35, 0.25, 0.2)
var platform_edge_color: Color = Color(0.6, 0.45, 0.3)
var floor_color: Color = Color(0.3, 0.2, 0.18)
var floor_edge_color: Color = Color(0.5, 0.35, 0.25)
var map_name: String = "Unknown"

## Textured background theme — empty = plain bg_color only.
## Themes: "forest", "dawn", "clouds_blue", "clouds_sunset", "space",
##         "nature1".."nature8" (single image stretched).
## bg_tint multiplies all layer colors so the same theme can be re-used across
## maps with different moods (sunset/night/dawn/dusk).
var bg_theme: String = ""
var bg_tint: Color = Color.WHITE

## Death-zone visual style. Used only when zones are active (no walls).
## "default" — red striped (legacy)
## "lava"     — molten orange/yellow with bubbles & glow
## "void"     — deep purple-black with twinkling void particles
## "abyss"    — black ink with falling drips
## "stars"    — dark space with stars (open-top space maps)
## "spikes"   — red zone with jagged tooth silhouette
## "swamp"    — toxic green sludge with bubbles
## "mist"     — pale blue cold mist
var death_zone_style: String = "default"

# Platform material: "" (default capsule) or "grass"/"stone"/"wood"/"ice"/"magma"
# The palette textures are themselves decorative landscape strips, so they
# already provide grass/ice/lava deco on top of the platform body.
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

# Global zone shrink — starts after SHRINK_GLOBAL_DELAY seconds
const SHRINK_GLOBAL_DELAY := 120.0
const SHRINK_GLOBAL_SPEED := 20.0
const SHRINK_MIN_SAFE := 600.0
var global_shrink_timer: float = 0.0


func _ready() -> void:
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
			map_rect.position.x - 500, map_rect.position.y - 500,
			map_rect.size.x + 1000, map_rect.size.y + 1000
		),
		bg_color
	)
	_draw_themed_background()
	_draw_parallax()
	_draw_themed_danger_zones()
	_draw_walls()
	_draw_decorations()
	_draw_platforms()
	_draw_objects()
	_draw_hazards()


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


# ══════════════════ THEMED BACKGROUND (textured parallax) ══════════════════
# Per-layer fields:
#   path     : res:// texture path
#   scroll   : 0.0 = static (locked to map), 1.0 = follows camera (no parallax)
#   anchor_y : 0.0 = top of map, 1.0 = bottom
#   offset_y : pixel offset added to anchor_y position
#   scale    : pixel scale of the texture (4.0 default for pixel art)
#   tint     : Color modulation
#   mode     : "tile_x" (horizontal repeat band)
#              "stretch_full" (one stretched copy spanning the bg rect)
const BG_THEMES := {
	"forest": {
		"base": Color(0.40, 0.62, 0.74),
		"layers": [
			# Sky base (928x793) — stretched to fill bg
			["res://assets/textures/backgrounds/forest/00_sky.png", 0.0, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"],
			# Single foreground tree band — scattered across map
			["res://assets/textures/backgrounds/forest/08_front_trees.png", 0.35, 1.0, 250.0, 8.0, Color(0.92,0.98,0.95,0.92), "scatter_x"],
		],
	},
	"dawn": {
		"base": Color(0.45, 0.25, 0.30),
		"layers": [
			# Sky gradient + sun (1980x1080) — fills bg natively
			["res://assets/textures/backgrounds/dawn/02.png", 0.0, 0.0, 0.0, 1.5, Color.WHITE, "stretch_full"],
			# Single horizon: red landscape silhouette (1980x1080) at small scale
			["res://assets/textures/backgrounds/dawn/07.png", 0.10, 1.0, 200.0, 2.0, Color(1,1,1,0.95), "tile_x"],
		],
	},
	"clouds_blue": {
		"base": Color(0.20, 0.55, 0.85),
		"layers": [
			["res://assets/textures/backgrounds/clouds_blue/00_sky.png", 0.0, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"],
			# Single big cumulus cloud band — scattered, sparse
			["res://assets/textures/backgrounds/clouds_blue/03_close.png", 0.25, 0.75, 0.0, 10.0, Color(1,1,1,0.80), "scatter_x"],
		],
	},
	"clouds_sunset": {
		"base": Color(0.45, 0.25, 0.45),
		"layers": [
			["res://assets/textures/backgrounds/clouds_sunset/00_sky.png", 0.0, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"],
			["res://assets/textures/backgrounds/clouds_sunset/03_close.png", 0.25, 0.75, 0.0, 10.0, Color(1,1,1,0.80), "scatter_x"],
		],
	},
	"space": {
		"base": Color(0.02, 0.02, 0.08),
		# Procedural stars — texture is a 144x9 strip, unsuitable for tiling.
		# scroll_factor encodes density (lower = sparser): 0.08 → distant stars
		"layers": [
			["", 0.05, 0.0, 0.0, 1.0, Color(1.0, 0.95, 0.85, 0.80), "stars_proc"],
			["", 0.20, 0.0, 0.0, 1.0, Color(0.85, 0.90, 1.0, 0.50), "stars_proc"],
		],
	},
	"nature1":  { "base": Color(0.30,0.55,0.50), "layers": [ ["res://assets/textures/backgrounds/nature/n1_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature2":  { "base": Color(0.20,0.30,0.45), "layers": [ ["res://assets/textures/backgrounds/nature/n2_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature3":  { "base": Color(0.55,0.35,0.40), "layers": [ ["res://assets/textures/backgrounds/nature/n3_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature4":  { "base": Color(0.40,0.55,0.55), "layers": [ ["res://assets/textures/backgrounds/nature/n4_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature5":  { "base": Color(0.30,0.30,0.40), "layers": [ ["res://assets/textures/backgrounds/nature/n5_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature6":  { "base": Color(0.55,0.45,0.30), "layers": [ ["res://assets/textures/backgrounds/nature/n6_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature7":  { "base": Color(0.20,0.15,0.20), "layers": [ ["res://assets/textures/backgrounds/nature/n7_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
	"nature8":  { "base": Color(0.50,0.65,0.65), "layers": [ ["res://assets/textures/backgrounds/nature/n8_full.png", 0.10, 0.0, 0.0, 1.0, Color.WHITE, "stretch_full"] ] },
}

# theme_name -> Array of [Texture2D, scroll, anchor_y, offset_y, scale, tint, mode]
static var _bg_layer_cache: Dictionary = {}


static func _get_theme_layers(theme_name: String) -> Array:
	if _bg_layer_cache.has(theme_name):
		return _bg_layer_cache[theme_name]
	if not BG_THEMES.has(theme_name):
		_bg_layer_cache[theme_name] = []
		return []
	var loaded: Array = []
	for cfg in BG_THEMES[theme_name]["layers"]:
		var path: String = cfg[0]
		var tex: Texture2D = null
		if path != "" and ResourceLoader.exists(path):
			tex = load(path)
		# Procedural modes (e.g. stars_proc) accept null tex
		if tex != null or cfg[6] == "stars_proc":
			loaded.append([tex, cfg[1], cfg[2], cfg[3], cfg[4], cfg[5], cfg[6]])
	_bg_layer_cache[theme_name] = loaded
	return loaded


func _draw_themed_background() -> void:
	if bg_theme == "" or not BG_THEMES.has(bg_theme):
		return
	var theme: Dictionary = BG_THEMES[bg_theme]
	var base_col: Color = theme.get("base", Color.BLACK) * bg_tint
	base_col.a = 1.0

	# Big sky fill rect (extended past map so danger-zone blackout doesn't clip)
	var bg_rect := Rect2(
		map_rect.position.x - 3500, map_rect.position.y - 3500,
		map_rect.size.x + 7000, map_rect.size.y + 7000
	)
	draw_rect(bg_rect, base_col)

	var cam := get_viewport().get_camera_2d()
	var cam_pos: Vector2 = cam.position if cam != null else (map_rect.position + map_rect.size / 2.0)
	var center: Vector2 = map_rect.position + map_rect.size / 2.0

	for layer in _get_theme_layers(bg_theme):
		var tex: Texture2D = layer[0]
		var scroll: float = layer[1]
		var anchor_y: float = layer[2]
		var offset_y: float = layer[3]
		var tex_scale: float = layer[4]
		var tint: Color = layer[5] * bg_tint
		var mode: String = layer[6]
		var tex_size: Vector2 = (tex.get_size() * tex_scale) if tex != null else Vector2.ZERO
		var parallax := (cam_pos - center) * (1.0 - scroll)

		match mode:
			"stretch_full":
				# Stretch one copy across the entire extended bg rect
				var dst := Rect2(
					bg_rect.position + parallax * 0.3,
					bg_rect.size
				)
				draw_texture_rect(tex, dst, false, tint)
			"tile_x":
				# Horizontal band, anchored vertically; tiled across full width
				var y_top := map_rect.position.y + map_rect.size.y * anchor_y \
					+ offset_y - tex_size.y + parallax.y * 0.3
				var band_w := map_rect.size.x + 4000.0
				var x_start := map_rect.position.x - 2000.0 \
					+ fmod(parallax.x, tex_size.x) - tex_size.x
				var dst := Rect2(Vector2(x_start, y_top),
					Vector2(band_w + tex_size.x * 2, tex_size.y))
				draw_texture_rect(tex, dst, true, tint)
			"tile_xy":
				# Stars-like — tile in both directions across whole bg
				var x0 := bg_rect.position.x + fmod(parallax.x, tex_size.x) - tex_size.x
				var y0 := bg_rect.position.y + fmod(parallax.y, tex_size.y) - tex_size.y
				var dst2 := Rect2(Vector2(x0, y0),
					bg_rect.size + tex_size * 2.0)
				draw_texture_rect(tex, dst2, true, tint)
			"stars_proc":
				# Deterministic procedural starfield, viewport-culled.
				# Only iterates cells inside the visible camera area + margin
				# instead of the full extended bg_rect — keeps frame cost
				# bounded regardless of map size.
				var vp := get_viewport()
				var vp_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(1920, 1080)
				var view_rect := Rect2(cam_pos - vp_size, vp_size * 2.0)
				var seed_off: int = int(scroll * 1000.0) + 7
				var spacing_px: float = 320.0 + (1.0 - scroll) * 220.0
				# Convert visible area into cell-grid range, with
				# parallax-shifted origin so positions stay deterministic.
				var origin := bg_rect.position - parallax
				var col_min: int = int(floor((view_rect.position.x - origin.x) / spacing_px)) - 1
				var col_max: int = int(ceil((view_rect.end.x - origin.x) / spacing_px)) + 1
				var row_min: int = int(floor((view_rect.position.y - origin.y) / spacing_px)) - 1
				var row_max: int = int(ceil((view_rect.end.y - origin.y) / spacing_px)) + 1
				var twinkle_t: float = float(Engine.get_physics_frames()) * 0.02
				for cx in range(col_min, col_max):
					for cy in range(row_min, row_max):
						var idx: int = cx * 977 + cy * 31 + seed_off
						var rs_seed: float = sin(float(idx) * 39.347) * 43758.5453
						var rs: float = rs_seed - floor(rs_seed)
						# Skip 75% of cells for sparsity
						if rs > 0.25:
							continue
						var rx_seed: float = sin(float(idx) * 12.9898) * 43758.5453
						var ry_seed: float = sin(float(idx) * 78.233) * 43758.5453
						var rx: float = rx_seed - floor(rx_seed)
						var ry: float = ry_seed - floor(ry_seed)
						var sx: float = origin.x + (float(cx) + rx) * spacing_px + parallax.x
						var sy: float = origin.y + (float(cy) + ry) * spacing_px + parallax.y
						var radius: float = 1.8 + rs * 6.0
						var twink: float = sin(twinkle_t * 1.7 + float(idx) * 0.7) * 0.35 + 0.65
						var col := Color(tint.r, tint.g, tint.b, tint.a * twink)
						draw_circle(Vector2(sx, sy), radius, col)
			"scatter_x":
				# Big varied silhouettes — instances at deterministic random
				# positions, scales, and flips. Less repetitive than tile_x.
				var spacing: float = tex_size.x * 0.65
				var n_copies: int = int(
					(map_rect.size.x + 4000.0) / spacing) + 2
				var base_x: float = map_rect.position.x - 2000.0 + parallax.x
				for i in range(n_copies):
					# Deterministic pseudo-random per instance
					var seed_a: float = sin(float(i) * 78.233 + scroll * 173.0) * 43758.5453
					var seed_b: float = sin(float(i) * 12.997 + scroll * 91.4) * 22845.3
					var rand_a: float = seed_a - floor(seed_a)
					var rand_b: float = seed_b - floor(seed_b)
					# Size variation 0.85 .. 1.30
					var s_scale: float = tex_scale * (0.85 + rand_a * 0.45)
					var s_size: Vector2 = tex.get_size() * s_scale
					# Horizontal jitter ±35% of spacing
					var jitter: float = (rand_b - 0.5) * spacing * 0.7
					var sx: float = base_x + i * spacing + jitter - s_size.x * 0.5
					var sy: float = map_rect.position.y \
						+ map_rect.size.y * anchor_y + offset_y \
						- s_size.y + parallax.y * 0.3
					var dst3 := Rect2(Vector2(sx, sy), s_size)
					# Flip half horizontally
					if int(rand_a * 100.0) % 2 == 1:
						dst3.position.x += s_size.x
						dst3.size.x = -s_size.x
					draw_texture_rect(tex, dst3, false, tint)


func _draw_themed_danger_zones() -> void:
	if use_walls or fire_walls or bouncy_walls:
		return
	var r := map_rect
	var ext := 2000.0
	var rects: Array[Rect2] = []
	if danger_left > 0:
		rects.append(Rect2(r.position.x - ext, r.position.y - ext,
			danger_left + ext, r.size.y + ext * 2))
	if danger_right > 0:
		rects.append(Rect2(r.end.x - danger_right, r.position.y - ext,
			danger_right + ext, r.size.y + ext * 2))
	if danger_bottom > 0:
		rects.append(Rect2(r.position.x - ext, r.end.y - danger_bottom,
			r.size.x + ext * 2, danger_bottom + ext))
	if danger_top > 0:
		rects.append(Rect2(r.position.x - ext, r.position.y - ext,
			r.size.x + ext * 2, danger_top + ext))
	for rect in rects:
		match death_zone_style:
			"lava":     _draw_dz_lava(rect)
			"void":     _draw_dz_void(rect)
			"abyss":    _draw_dz_abyss(rect)
			"stars":    _draw_dz_stars(rect)
			"spikes":   _draw_dz_spikes(rect)
			"swamp":    _draw_dz_swamp(rect)
			"mist":     _draw_dz_mist(rect)
			_:          _draw_dz_default(rect)


## Soft gradient strip on the map-facing edge of a danger-zone rect.
## Bleeds the zone color into the playable area so the boundary isn't a hard
## stripe. Pass the dominant fill color (with full alpha) and fade distance.
func _dz_soft_edge(rect: Rect2, color: Color, fade_dist: float = 180.0) -> void:
	var horizontal := rect.size.x > rect.size.y
	var steps := 16
	if horizontal:
		var top_facing := rect.position.y < map_rect.position.y - 100.0
		var edge_y: float = rect.end.y if top_facing else rect.position.y
		var dir: float = 1.0 if top_facing else -1.0
		for i in range(steps):
			var t0: float = float(i) / steps
			var t1: float = float(i + 1) / steps
			var alpha: float = color.a * pow(1.0 - t0, 1.6)
			var col := Color(color.r, color.g, color.b, alpha)
			var y_a: float = edge_y + dir * t0 * fade_dist
			var y_b: float = edge_y + dir * t1 * fade_dist
			draw_rect(Rect2(
				Vector2(rect.position.x, minf(y_a, y_b)),
				Vector2(rect.size.x, absf(y_b - y_a))), col)
	else:
		var left_facing := rect.position.x < map_rect.position.x - 100.0
		var edge_x: float = rect.end.x if left_facing else rect.position.x
		var dir: float = 1.0 if left_facing else -1.0
		for i in range(steps):
			var t0: float = float(i) / steps
			var t1: float = float(i + 1) / steps
			var alpha: float = color.a * pow(1.0 - t0, 1.6)
			var col := Color(color.r, color.g, color.b, alpha)
			var x_a: float = edge_x + dir * t0 * fade_dist
			var x_b: float = edge_x + dir * t1 * fade_dist
			draw_rect(Rect2(
				Vector2(minf(x_a, x_b), rect.position.y),
				Vector2(absf(x_b - x_a), rect.size.y)), col)


func _draw_dz_default(rect: Rect2) -> void:
	var dc := Color(0.9, 0.1, 0.05, 0.12)
	var de := Color(0.9, 0.1, 0.05, 0.3)
	_draw_danger_rect(rect, dc, de)
	_dz_soft_edge(rect, Color(0.9, 0.1, 0.05, 0.4), 120.0)


func _draw_dz_lava(rect: Rect2) -> void:
	# Hot orange/yellow gradient with bubbles + glowing edge
	var t := float(Engine.get_physics_frames()) * 0.02
	var fill := Color(0.95, 0.30, 0.05, 0.55)
	var deep := Color(0.55, 0.05, 0.0, 0.85)
	draw_rect(rect, deep)
	# Lighter core (top edge)
	var glow_h := minf(rect.size.y, 80.0)
	for i in range(12):
		var ratio := float(i) / 12.0
		var col := fill.lerp(Color(1.0, 0.85, 0.35, 0.25), ratio)
		var y := rect.position.y if rect.size.y < 600 else rect.end.y - glow_h
		# Determine edge based on rect orientation (approx wider-than-tall = top/bottom)
		if rect.size.x > rect.size.y:
			# bottom or top zone
			var top_edge := absf(rect.position.y) > absf(rect.end.y - map_rect.end.y)
			var ey := (rect.end.y - i * 4.0) if not top_edge else (rect.position.y + i * 4.0)
			draw_line(Vector2(rect.position.x, ey), Vector2(rect.end.x, ey), col, 3.0)
		else:
			var right_edge := rect.position.x > map_rect.end.x - 1000.0
			var ex := (rect.position.x + i * 4.0) if right_edge else (rect.end.x - i * 4.0)
			draw_line(Vector2(ex, rect.position.y), Vector2(ex, rect.end.y), col, 3.0)
	# Animated bubbles
	for bi in range(20):
		var phase := float(bi) * 0.7 + t
		var bx := rect.position.x + fmod(bi * 263.0, rect.size.x)
		var by := rect.end.y - fmod(phase * 50.0, minf(rect.size.y, 400.0)) - 20.0
		var br := 4.0 + sin(phase * 3.0) * 2.0
		draw_circle(Vector2(bx, by), br, Color(1.0, 0.7, 0.2, 0.5))
	_dz_soft_edge(rect, Color(0.85, 0.25, 0.05, 0.85), 220.0)


func _draw_dz_void(rect: Rect2) -> void:
	# Deep purple-black with subtle twinkles
	draw_rect(rect, Color(0.04, 0.02, 0.10, 0.92))
	var t := float(Engine.get_physics_frames()) * 0.03
	for i in range(60):
		var sx := rect.position.x + fmod(i * 173.0, rect.size.x)
		var sy := rect.position.y + fmod(i * 271.0, rect.size.y)
		var twink := (sin(t * 2.0 + i * 1.7) * 0.5 + 0.5) * 0.8
		draw_circle(Vector2(sx, sy), 1.5, Color(0.7, 0.5, 1.0, twink))
	_dz_soft_edge(rect, Color(0.04, 0.02, 0.10, 0.9), 200.0)


func _draw_dz_abyss(rect: Rect2) -> void:
	# Black ink with falling drips, hot purple edge
	draw_rect(rect, Color(0.02, 0.01, 0.04, 0.95))
	var t := float(Engine.get_physics_frames()) * 0.025
	# Edge glow on side facing map
	var edge_col := Color(0.6, 0.1, 0.7, 0.6)
	if rect.size.x > rect.size.y:
		var top_edge := rect.position.y < map_rect.position.y - 100.0
		var ey := rect.end.y if top_edge else rect.position.y
		draw_line(Vector2(rect.position.x, ey), Vector2(rect.end.x, ey), edge_col, 2.0)
		# Falling drips
		for i in range(15):
			var dx := rect.position.x + fmod(i * 311.0, rect.size.x)
			var dy_from := ey
			var drip := fmod(t * 80.0 + i * 23.0, 120.0)
			var dy := dy_from + (drip if not top_edge else -drip)
			draw_line(Vector2(dx, dy_from), Vector2(dx, dy),
				Color(0.5, 0.1, 0.6, 0.4), 1.5)
	else:
		var right_edge := rect.position.x > map_rect.end.x - 100.0
		var ex := rect.end.x if not right_edge else rect.position.x
		draw_line(Vector2(ex, rect.position.y), Vector2(ex, rect.end.y), edge_col, 2.0)
	_dz_soft_edge(rect, Color(0.02, 0.01, 0.04, 0.95), 220.0)


func _draw_dz_stars(rect: Rect2) -> void:
	# Open space — translucent dark veil so the proc-starfield bg shows
	# through. We skip extra star particles here because the bg already
	# provides them; just darken slightly + soft fade.
	draw_rect(rect, Color(0.02, 0.02, 0.06, 0.40))
	_dz_soft_edge(rect, Color(0.02, 0.02, 0.06, 0.55), 240.0)


func _draw_dz_spikes(rect: Rect2) -> void:
	# Red zone with jagged tooth silhouette on map-facing edge
	draw_rect(rect, Color(0.6, 0.05, 0.02, 0.55))
	var spike_w := 36.0
	var spike_h := 28.0
	var horizontal := rect.size.x > rect.size.y
	if horizontal:
		var top_edge := rect.position.y < map_rect.position.y - 100.0
		var ey := rect.end.y if top_edge else rect.position.y
		var ey_tip := ey + (spike_h if top_edge else -spike_h)
		var x := rect.position.x
		while x < rect.end.x:
			var pts := PackedVector2Array([
				Vector2(x, ey),
				Vector2(x + spike_w * 0.5, ey_tip),
				Vector2(x + spike_w, ey),
			])
			draw_colored_polygon(pts, Color(0.85, 0.15, 0.05, 0.85))
			x += spike_w
	else:
		var right_edge := rect.position.x > map_rect.end.x - 100.0
		var ex := rect.position.x if right_edge else rect.end.x
		var ex_tip := ex + (spike_h if right_edge else -spike_h)
		var y := rect.position.y
		while y < rect.end.y:
			var pts := PackedVector2Array([
				Vector2(ex, y),
				Vector2(ex_tip, y + spike_w * 0.5),
				Vector2(ex, y + spike_w),
			])
			draw_colored_polygon(pts, Color(0.85, 0.15, 0.05, 0.85))
			y += spike_w
	_dz_soft_edge(rect, Color(0.6, 0.05, 0.02, 0.6), 140.0)


func _draw_dz_swamp(rect: Rect2) -> void:
	# Toxic green sludge with slow bubbles
	draw_rect(rect, Color(0.10, 0.22, 0.05, 0.85))
	var t := float(Engine.get_physics_frames()) * 0.018
	# Surface line
	if rect.size.x > rect.size.y:
		var top_edge := rect.position.y < map_rect.position.y - 100.0
		var ey := rect.end.y if top_edge else rect.position.y
		var wave := 6.0
		var step := 24.0
		var x := rect.position.x
		while x < rect.end.x:
			var dy := sin(t * 2.0 + x * 0.02) * wave
			draw_line(Vector2(x, ey + dy), Vector2(x + step, ey + dy),
				Color(0.4, 0.8, 0.2, 0.7), 3.0)
			x += step
	for bi in range(15):
		var phase := float(bi) * 0.6 + t
		var bx := rect.position.x + fmod(bi * 251.0, rect.size.x)
		var by := rect.position.y + fmod(phase * 45.0, rect.size.y)
		draw_circle(Vector2(bx, by), 3.5, Color(0.4, 0.85, 0.3, 0.6))
	_dz_soft_edge(rect, Color(0.10, 0.22, 0.05, 0.85), 200.0)


func _draw_dz_mist(rect: Rect2) -> void:
	# Cold blue mist
	draw_rect(rect, Color(0.55, 0.75, 0.95, 0.35))
	var t := float(Engine.get_physics_frames()) * 0.015
	for i in range(25):
		var phase := float(i) * 0.4 + t
		var px := rect.position.x + fmod(i * 173.0 + phase * 30.0,
			rect.size.x + 200.0) - 100.0
		var py := rect.position.y + fmod(i * 211.0, rect.size.y)
		var pr := 28.0 + sin(phase) * 8.0
		draw_circle(Vector2(px, py), pr, Color(0.95, 0.98, 1.0, 0.18))
	_dz_soft_edge(rect, Color(0.55, 0.75, 0.95, 0.35), 260.0)


func _draw_danger_rect(rect: Rect2, fill: Color, edge: Color) -> void:
	draw_rect(rect, fill)
	var stripe_gap := 60.0
	var x := rect.position.x
	while x < rect.end.x + rect.size.y:
		draw_line(
			Vector2(x, rect.position.y),
			Vector2(x - rect.size.y, rect.end.y),
			Color(0.9, 0.1, 0.05, 0.08), 2.0
		)
		x += stripe_gap
	draw_rect(rect, edge, false, 2.0)


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
	var r := minf(hh, hw * 0.15)
	r = clampf(r, 4.0, 20.0)

	# Build rounded-rect polygon (capsule)
	var pts: PackedVector2Array = []
	var segs := 6
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

	# UVs: stretch-to-fit the entire texture across the platform.
	# This avoids visible repeat-seams that appeared when wide platforms
	# tiled the texture multiple times.
	var uvs: PackedVector2Array = []
	for p in pts:
		var u: float = (p.x - (cx - hw)) / w
		var v: float = (p.y - (cy - hh)) / h
		uvs.append(Vector2(u, v))

	var colors := PackedColorArray([Color.WHITE])
	draw_polygon(pts, colors, uvs, tex)

	# Edge outline + top highlight + bottom shadow for crisp readability
	var edge: Color = _get_palette_edge(palette)
	# Outline
	for i in range(pts.size()):
		var i2 := (i + 1) % pts.size()
		draw_line(pts[i], pts[i2], edge, 1.5)
	# Top highlight
	draw_line(
		Vector2(cx - hw + r, cy - hh),
		Vector2(cx + hw - r, cy - hh),
		edge.lightened(0.35), 2.0
	)
	# Bottom shadow
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

	# Map events
	if events_enabled:
		event_timer += delta
		if event_timer >= EVENT_INTERVAL:
			event_timer = 0.0
			_trigger_random_event()

	# Item spawning
	if item_spawns.size() > 0 and Engine.get_physics_frames() % 900 == 0:
		_spawn_random_item()

	# Only redraw if dynamic elements exist (moving platforms, items,
	# teleports, walls, themed bg parallax, or animated danger zones)
	if not hazards.is_empty() or not teleports.is_empty() \
		or not item_spawns.is_empty() or events_enabled \
		or fire_walls or bouncy_walls \
		or bg_theme != "" or death_zone_style != "default":
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
	# Damage all players near impact line
	await get_tree().create_timer(1.0).timeout  # warning delay
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		if absf(p.global_position.x - x) < 80.0:
			p.take_damage(40.0)
			p.apply_knockback(Vector2(0, -500))
	SoundManager.play_explosion()
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(6.0)


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
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(target) and target.is_alive:
		target.take_damage(30.0)
		target.apply_stun(0.5)
		SoundManager.play_hit()


func _event_wave() -> void:
	# Horizontal wind pushes all players
	var dir := 1.0 if randf() > 0.5 else -1.0
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_alive:
			p.apply_knockback(Vector2(dir * 400.0, -100.0))
	SoundManager.play_dash()


func _draw_decorations() -> void:
	pass
