class_name AbilityIcon
extends RefCounted
## Helper for drawing textured ability icons.
## Replaces the old procedural _draw_emblem shape-drawing with a simple
## textured badge loaded from assets/textures/abilities/<name>.png.

const ICON_PATH := "res://assets/textures/abilities/%s.png"

# Ability enum id -> file basename (matches data/abilities.json order)
const NAMES := [
	"yarn_toss",        # 0
	"needle_dash",      # 1
	"yarn_bomb",        # 2
	"thread_pull",      # 3
	"spin_attack",      # 4
	"grenade",          # 5
	"rocket_launcher",  # 6
	"stink_cloud",      # 7
	"spike_armor",      # 8
	"swap",             # 9
	"boomerang",        # 10
	"guided_rocket",    # 11
	"tripwire",         # 12
	"grab_throw",       # 13
	"black_hole",       # 14
	"portal_gate",      # 15
	"heavens_wrath",    # 16
]

static var _cache: Dictionary = {}


static func get_texture(ability_id: int) -> Texture2D:
	if ability_id < 0 or ability_id >= NAMES.size():
		return null
	if _cache.has(ability_id):
		return _cache[ability_id]
	var path := ICON_PATH % NAMES[ability_id]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[ability_id] = tex
	return tex


## Draw ability icon on a CanvasItem at the given center, fitting inside
## a circle of `radius`. `modulate` tints the icon (use darkened for CD
## state). Falls back to a tinted circle if the texture isn't loaded.
static func draw_at(
	canvas: CanvasItem, center: Vector2, radius: float,
	ability_id: int, modulate: Color = Color.WHITE
) -> void:
	var tex: Texture2D = get_texture(ability_id)
	if tex == null:
		# Fallback — colored circle
		canvas.draw_circle(center, radius, modulate)
		return
	var size := radius * 2.0
	var rect := Rect2(center - Vector2(radius, radius), Vector2(size, size))
	canvas.draw_texture_rect(tex, rect, false, modulate)
