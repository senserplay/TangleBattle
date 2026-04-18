extends Node2D
## Standalone animated sprite effect.
## Plays through PNG frames in assets/effects/<name>/ and frees itself.

const SCENE_PATH := "res://scenes/effects/sprite_effect.tscn"


static func spawn(parent: Node, effect: String, pos: Vector2,
		dur: float = 0.5, sc: float = 1.0,
		rot: float = 0.0, mod: Color = Color.WHITE,
		spin: float = 0.0) -> Node2D:
	## Spawn a sprite effect at a world position. Returns the node for chaining.
	var fx_scene: PackedScene = load(SCENE_PATH)
	var fx: Node2D = fx_scene.instantiate()
	fx.global_position = pos
	parent.add_child(fx)
	fx.setup(effect, dur, sc, rot, mod, spin)
	return fx

var effect_name: String = ""
var duration: float = 0.5
var time_alive: float = 0.0
var spr_scale: float = 1.0
var spr_rotation: float = 0.0
var modulate_color: Color = Color.WHITE
var spin_speed: float = 0.0  # extra rotation speed (rad/s)
var loop: bool = false  # if true, loops frames within duration
var frames: Array = []

# Static cache shared across all instances
static var _cache: Dictionary = {}


static func get_frames(effect: String) -> Array:
	if _cache.has(effect):
		return _cache[effect]
	var arr: Array = []
	var path := "res://assets/effects/%s/" % effect
	var dir := DirAccess.open(path)
	if dir == null:
		_cache[effect] = arr
		return arr
	dir.list_dir_begin()
	var files: Array[String] = []
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if f.ends_with(".png") and not f.ends_with(".import"):
			files.append(f)
	dir.list_dir_end()
	files.sort()
	for f in files:
		var tex: Texture2D = load(path + f)
		if tex != null:
			arr.append(tex)
	_cache[effect] = arr
	return arr


func setup(name: String, dur: float, sc: float = 1.0,
		rot: float = 0.0, mod: Color = Color.WHITE,
		spin: float = 0.0, do_loop: bool = false) -> void:
	effect_name = name
	duration = dur
	spr_scale = sc
	spr_rotation = rot
	modulate_color = mod
	spin_speed = spin
	loop = do_loop
	frames = get_frames(name)


func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= duration and not loop:
		queue_free()
		return
	if spin_speed != 0.0:
		spr_rotation += spin_speed * delta
	queue_redraw()


func _draw() -> void:
	if frames.is_empty():
		return
	var t: float = time_alive / duration
	if loop:
		t = fmod(t, 1.0)
	else:
		t = clampf(t, 0.0, 1.0)
	var idx: int = clampi(int(t * frames.size()), 0, frames.size() - 1)
	var tex: Texture2D = frames[idx]
	if tex == null:
		return
	var sz: Vector2 = tex.get_size()
	# Fade out in last 30% if not looping
	var alpha := modulate_color.a
	if not loop and t > 0.7:
		alpha *= 1.0 - (t - 0.7) / 0.3
	var col := Color(modulate_color.r, modulate_color.g,
		modulate_color.b, alpha)
	draw_set_transform(Vector2.ZERO, spr_rotation,
		Vector2(spr_scale, spr_scale))
	draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
