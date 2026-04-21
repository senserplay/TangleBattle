extends RefCounted
## Lazy-loaded texture cache for projectile/ability sprite sheets and
## single-frame art under `assets/textures/effects/projectiles/`.
##
## `draw_single()` renders one texture centered on (0, 0) in a canvas
## item's local space at a target size, with optional rotation, flipping
## and modulation.  For animated sprite sheets where a sheet is `N` frames
## laid out horizontally, use `draw_frame()` with an 0-based frame index.

const DIR := "res://assets/textures/effects/projectiles/"

static var _cache: Dictionary = {}


static func _get_tex(tex_name: String) -> Texture2D:
	if _cache.has(tex_name):
		return _cache[tex_name]
	var path: String = DIR + tex_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[tex_name] = tex
	return tex


## Draw a whole single-texture asset centered on `offset` (default (0,0))
## in the canvas item's local space, with the given display width. Aspect
## preserved from the source. `draw_single` resets its own transform at
## the end, so wrapping it in an outer `draw_set_transform` no longer
## works — pass `offset` instead to position the draw.
static func draw_single(
	ci: CanvasItem, tex_name: String, display_w: float,
	rotation: float = 0.0, modulate: Color = Color.WHITE,
	flip_h: bool = false, offset: Vector2 = Vector2.ZERO
) -> void:
	var tex: Texture2D = _get_tex(tex_name)
	if tex == null:
		return
	var native: Vector2 = tex.get_size()
	var scl: float = display_w / native.x
	ci.draw_set_transform(offset, rotation,
		Vector2(-scl if flip_h else scl, scl))
	ci.draw_texture_rect(
		tex,
		Rect2(-native * 0.5, native),
		false, modulate
	)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draw one frame from a horizontally-laid-out sprite sheet. Frame size
## is computed as (tex_w / frame_count, tex_h).
static func draw_frame(
	ci: CanvasItem, tex_name: String, frame_count: int, frame: int,
	display_w: float, rotation: float = 0.0,
	modulate: Color = Color.WHITE
) -> void:
	var tex: Texture2D = _get_tex(tex_name)
	if tex == null or frame_count <= 0:
		return
	var native: Vector2 = tex.get_size()
	var frame_w: float = native.x / frame_count
	var frame_h: float = native.y
	frame = clampi(frame, 0, frame_count - 1)
	var src := Rect2(frame_w * frame, 0.0, frame_w, frame_h)
	var scl: float = display_w / frame_w
	var display_h: float = frame_h * scl
	ci.draw_set_transform(Vector2.ZERO, rotation, Vector2.ONE)
	ci.draw_texture_rect_region(
		tex,
		Rect2(-display_w * 0.5, -display_h * 0.5,
			display_w, display_h),
		src,
		modulate
	)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draw a vertical sprite: (frame count is vertical rather than horizontal).
static func draw_vframe(
	ci: CanvasItem, tex_name: String, frame_count: int, frame: int,
	display_h: float, rotation: float = 0.0,
	modulate: Color = Color.WHITE
) -> void:
	var tex: Texture2D = _get_tex(tex_name)
	if tex == null or frame_count <= 0:
		return
	var native: Vector2 = tex.get_size()
	var frame_w: float = native.x
	var frame_h: float = native.y / frame_count
	frame = clampi(frame, 0, frame_count - 1)
	var src := Rect2(0.0, frame_h * frame, frame_w, frame_h)
	var scl: float = display_h / frame_h
	var display_w: float = frame_w * scl
	ci.draw_set_transform(Vector2.ZERO, rotation, Vector2.ONE)
	ci.draw_texture_rect_region(
		tex,
		Rect2(-display_w * 0.5, -display_h * 0.5,
			display_w, display_h),
		src,
		modulate
	)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
