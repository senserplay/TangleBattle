extends Camera2D
## Dynamic camera with screen shake support.

const PADDING := 300.0
const MIN_ZOOM := 0.25
const MAX_ZOOM := 0.7
const SMOOTH_POS := 12.0
const SMOOTH_ZOOM := 6.0
const VIEWPORT_REF := Vector2(1920, 1080)

var map_ref: Node2D = null

# Screen shake
var shake_amount: float = 0.0
var shake_decay: float = 8.0
var shake_time: float = 0.0


func add_shake(intensity: float) -> void:
	if not GameManager.screen_shake_enabled:
		return
	shake_amount = maxf(shake_amount, intensity)


func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	var alive_positions: Array[Vector2] = []

	for p in players:
		if not p.is_alive:
			continue
		var pos: Vector2 = p.global_position
		if map_ref != null and "danger_top" in map_ref:
			var d_top: float = map_ref.danger_top
			if d_top <= 0.0:
				var map_top: float = map_ref.map_rect.position.y
				pos.y = maxf(pos.y, map_top)
		alive_positions.append(pos)

	if alive_positions.is_empty():
		return

	var bbox_min := alive_positions[0]
	var bbox_max := alive_positions[0]
	for pos in alive_positions:
		bbox_min.x = minf(bbox_min.x, pos.x)
		bbox_min.y = minf(bbox_min.y, pos.y)
		bbox_max.x = maxf(bbox_max.x, pos.x)
		bbox_max.y = maxf(bbox_max.y, pos.y)

	var target_center := (bbox_min + bbox_max) / 2.0
	var required_w := (bbox_max.x - bbox_min.x) + PADDING * 2.0
	var required_h := (bbox_max.y - bbox_min.y) + PADDING * 2.0

	var zoom_x := VIEWPORT_REF.x / maxf(required_w, 1.0)
	var zoom_y := VIEWPORT_REF.y / maxf(required_h, 1.0)
	var target_zoom := minf(zoom_x, zoom_y)

	var min_allowed := MIN_ZOOM
	if map_ref != null and "map_rect" in map_ref:
		var mr: Rect2 = map_ref.map_rect
		var map_min_zoom_x := VIEWPORT_REF.x / (mr.size.x + 200.0)
		var map_min_zoom_y := VIEWPORT_REF.y / (mr.size.y + 200.0)
		min_allowed = maxf(min_allowed, minf(map_min_zoom_x, map_min_zoom_y))

	target_zoom = clampf(target_zoom, min_allowed, MAX_ZOOM)

	var dist_to_target := position.distance_to(target_center)
	var pos_speed := SMOOTH_POS + dist_to_target * 0.02
	var zoom_diff := absf(zoom.x - target_zoom)
	var z_speed := SMOOTH_ZOOM + zoom_diff * 8.0

	var t_pos := clampf(delta * pos_speed, 0.0, 1.0)
	var t_zoom := clampf(delta * z_speed, 0.0, 1.0)

	position = position.lerp(target_center, t_pos)
	var new_zoom := lerpf(zoom.x, target_zoom, t_zoom)
	zoom = Vector2(new_zoom, new_zoom)

	# Screen shake
	if shake_amount > 0.3:
		shake_time += delta * 30.0
		offset = Vector2(
			sin(shake_time * 1.1) * shake_amount,
			cos(shake_time * 1.7) * shake_amount * 0.8
		)
		shake_amount = move_toward(shake_amount, 0.0, shake_decay * delta)
	else:
		shake_amount = 0.0
		offset = offset.lerp(Vector2.ZERO, delta * 10.0)

	_ensure_players_visible(alive_positions)

	if map_ref != null and "map_rect" in map_ref:
		var mr: Rect2 = map_ref.map_rect
		var half_view := VIEWPORT_REF / (2.0 * zoom.x)
		position.x = clampf(position.x,
			mr.position.x + half_view.x - 100,
			mr.end.x - half_view.x + 100)
		position.y = clampf(position.y,
			mr.position.y + half_view.y - 100,
			mr.end.y - half_view.y + 100)


func _ensure_players_visible(positions: Array[Vector2]) -> void:
	var half_view := VIEWPORT_REF / (2.0 * zoom.x)
	var cam_rect := Rect2(
		position.x - half_view.x, position.y - half_view.y,
		half_view.x * 2.0, half_view.y * 2.0)
	var margin := 50.0
	var safe := Rect2(
		cam_rect.position.x + margin, cam_rect.position.y + margin,
		cam_rect.size.x - margin * 2.0, cam_rect.size.y - margin * 2.0)
	for pos in positions:
		if not safe.has_point(pos):
			var emergency_zoom := zoom.x * 0.97
			emergency_zoom = maxf(emergency_zoom, MIN_ZOOM)
			zoom = Vector2(emergency_zoom, emergency_zoom)
			position = position.lerp(pos, 0.15)
			return
