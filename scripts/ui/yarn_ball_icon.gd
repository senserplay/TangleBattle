class_name YarnBallIcon
extends RefCounted
## Static helper to draw the yarn-ball character icon (body texture +
## happy-face overlay) on any CanvasItem. Used everywhere outside the
## live game scene where we previously drew procedural circles.

const BODY_PATH := "res://assets/characters/body/yarn_ball.png"
const FACE_PATH := "res://assets/characters/face/face_happy.png"

static var _body: Texture2D = null
static var _face: Texture2D = null


static func get_body() -> Texture2D:
	if _body == null and ResourceLoader.exists(BODY_PATH):
		_body = load(BODY_PATH)
	return _body


static func get_face() -> Texture2D:
	if _face == null and ResourceLoader.exists(FACE_PATH):
		_face = load(FACE_PATH)
	return _face


## Draw a yarn-ball icon at `center` with given `radius`, tinted to `color`.
## Optional `with_face` adds the happy face overlay (default true).
static func draw_at(
	canvas: CanvasItem, center: Vector2, radius: float,
	color: Color, with_face: bool = true
) -> void:
	var body := get_body()
	if body == null:
		# Texture missing → fall back to procedural circle
		canvas.draw_circle(center, radius, color)
		return
	var d := radius * 2.0
	var rect := Rect2(center - Vector2(d * 0.5, d * 0.5), Vector2(d, d))
	canvas.draw_texture_rect(body, rect, false, color)

	if with_face:
		var face := get_face()
		if face != null:
			# Face fits within ~75% of ball, centered slightly above center
			var fd := d * 0.75
			var face_center := center + Vector2(0.0, -radius * 0.10)
			var face_rect := Rect2(
				face_center - Vector2(fd * 0.5, fd * 0.5),
				Vector2(fd, fd)
			)
			canvas.draw_texture_rect(face, face_rect, false, Color.WHITE)
