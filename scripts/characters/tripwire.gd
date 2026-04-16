extends Node2D
## Tripwire system — manages two anchor points with an electric wire between them.
## Spawned by the player, holds references to its anchor positions.

var owner_id: int = -1
var anchor_a: Vector2 = Vector2.ZERO
var anchor_b: Vector2 = Vector2.ZERO
var has_b: bool = false
var damage: float = 30.0
var stun_duration: float = 0.8
var knockback: float = 300.0
var lifetime: float = 12.0
var wire_check_radius: float = 15.0
var color: Color = Color(0.3, 0.9, 1.0)
var time: float = 0.0

var hit_cooldowns: Dictionary = {}  # player_id → timer


func setup_anchor_a(pos: Vector2, id: int, col: Color, cfg: Dictionary) -> void:
	owner_id = id
	anchor_a = pos
	global_position = Vector2.ZERO
	color = col.lerp(Color(0.5, 0.8, 1.0), 0.15)
	damage = cfg.get("damage", 30.0)
	stun_duration = cfg.get("stun_duration", 0.8)
	knockback = cfg.get("knockback", 300.0)
	lifetime = cfg.get("lifetime", 12.0)
	wire_check_radius = cfg.get("wire_check_radius", 15.0)


func set_anchor_b(pos: Vector2) -> void:
	anchor_b = pos
	has_b = true


func _ready() -> void:
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


func _physics_process(delta: float) -> void:
	time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Update hit cooldowns
	var to_erase: Array = []
	for pid in hit_cooldowns:
		hit_cooldowns[pid] -= delta
		if hit_cooldowns[pid] <= 0.0:
			to_erase.append(pid)
	for pid in to_erase:
		hit_cooldowns.erase(pid)

	# Only check wire collision if both anchors set
	if has_b:
		_check_wire_hits()

	queue_redraw()


func _check_wire_hits() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id or not p.is_alive:
			continue
		if p.player_id in hit_cooldowns:
			continue

		# Point-to-segment distance
		var dist := _point_to_segment_dist(
			p.global_position, anchor_a, anchor_b
		)
		if dist < wire_check_radius + 24.0:  # 24 = player radius
			p.take_damage(damage)
			p.apply_stun(stun_duration)
			var away: Vector2 = (p.global_position - (anchor_a + anchor_b) / 2.0).normalized()
			p.apply_knockback(away * knockback + Vector2.UP * 150.0)
			hit_cooldowns[p.player_id] = 1.0  # 1s between hits
			SoundManager.play_hit()


func _point_to_segment_dist(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := point - a
	var len_sq := ab.length_squared()
	if len_sq < 0.01:
		return ap.length()
	var t := clampf(ap.dot(ab) / len_sq, 0.0, 1.0)
	var closest := a + ab * t
	return point.distance_to(closest)


func _draw() -> void:
	# Anchor A — glowing dot
	draw_circle(anchor_a, 8.0, Color(color.r, color.g, color.b, 0.7))
	draw_circle(anchor_a, 12.0, Color(color.r, color.g, color.b, 0.15))

	if not has_b:
		return

	# Anchor B
	draw_circle(anchor_b, 8.0, Color(color.r, color.g, color.b, 0.7))
	draw_circle(anchor_b, 12.0, Color(color.r, color.g, color.b, 0.15))

	# Electric wire — zigzag line between A and B
	var dir := (anchor_b - anchor_a)
	var length := dir.length()
	if length < 1.0:
		return
	var norm := dir.normalized()
	var perp := Vector2(-norm.y, norm.x)

	var segs := int(length / 20.0) + 1
	var prev := anchor_a
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var pt := anchor_a + dir * t
		if i < segs:
			# Zigzag offset
			var offset := sin(t * PI * 4.0 + time * 12.0) * 8.0
			pt += perp * offset
		var alpha := 0.6 + sin(time * 8.0 + t * 6.0) * 0.2
		draw_line(prev, pt, Color(color.r, color.g, color.b, alpha), 2.5)
		prev = pt

	# Glow along wire
	var mid := (anchor_a + anchor_b) / 2.0
	draw_circle(mid, 15.0, Color(color.r, color.g, color.b, 0.06))
