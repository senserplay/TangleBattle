class_name PlayerGrapple
extends Node
## Grapple hook logic extracted from player.gd.

var player: CharacterBody2D


func setup(p: CharacterBody2D) -> void:
	player = p


func start_grapple() -> void:
	if player.grapple_shooting or player.grapple_retracting:
		return
	# Block grapple while grabbed by an enemy — rope would interfere with carry
	if player.is_grabbed:
		return
	player.grapple_shooting = true
	player.grapple_retracting = false
	# Always use aim_direction (crosshair) for grapple direction
	player.grapple_shoot_dir = player.aim_direction
	player.grapple_tip = player.global_position
	SoundManager.play_grapple()


func update_grapple_shot(delta: float) -> void:
	if not player.grapple_shooting and not player.grapple_retracting:
		return

	if player.grapple_shooting:
		# Advance tip
		player.grapple_tip += player.grapple_shoot_dir \
			* player.GRAPPLE_SHOOT_SPEED * player.grapple_speed_mult * delta

		# Check if hit a platform (raycast from prev to current tip)
		var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
		var prev_tip: Vector2 = player.grapple_tip - player.grapple_shoot_dir \
			* player.GRAPPLE_SHOOT_SPEED * player.grapple_speed_mult * delta
		var query := PhysicsRayQueryParameters2D.create(
			prev_tip, player.grapple_tip, 1
		)
		query.exclude = [player.get_rid()]
		query.collide_with_bodies = true
		var result := space.intersect_ray(query)

		if not result.is_empty():
			# Hit a platform — attach!
			player.grapple_shooting = false
			player.grapple_retracting = false
			player.grapple_target_player = null
			player.grapple_point = result.position
			# Store body reference for moving platform tracking
			var collider: Node2D = result.collider
			if is_instance_valid(collider):
				player.grapple_target_body = collider
				player.grapple_local_point = collider.to_local(result.position)
			else:
				player.grapple_target_body = null
			player.grapple_length = player.global_position.distance_to(
				player.grapple_point)
			player.is_grappling = true
			return

		# Check if hit a player
		for p in get_tree().get_nodes_in_group("players"):
			if p == player or not p.is_alive:
				continue
			var dist: float = player.grapple_tip.distance_to(p.global_position)
			if dist < 30.0:
				player.grapple_shooting = false
				player.grapple_retracting = false
				player.grapple_target_player = p
				player.grapple_point = p.global_position
				player.grapple_length = player.global_position.distance_to(
					player.grapple_point)
				player.is_grappling = true
				return

		# Check if reached max range — start retracting
		var travel: float = player.grapple_tip.distance_to(player.global_position)
		if travel >= player.GRAPPLE_MAX_RANGE * player.grapple_range_mult:
			player.grapple_shooting = false
			player.grapple_retracting = true

	elif player.grapple_retracting:
		# Pull tip back toward player
		var to_player: Vector2 = player.global_position - player.grapple_tip
		var dist := to_player.length()
		if dist < player.GRAPPLE_RETRACT_SPEED * delta:
			# Arrived back
			player.grapple_retracting = false
			player.grapple_tip = player.global_position
		else:
			player.grapple_tip += to_player.normalized() \
				* player.GRAPPLE_RETRACT_SPEED * delta


func handle_grapple(delta: float) -> void:
	var prefix := "p%d_" % player.player_id
	if player.is_on_floor():
		release_grapple()
		return
	# Update grapple point — follow moving targets
	if player.grapple_target_player != null:
		if not is_instance_valid(player.grapple_target_player) \
			or not player.grapple_target_player.is_alive:
			release_grapple()
			return
		player.grapple_point = player.grapple_target_player.global_position
	elif player.grapple_target_body != null:
		if not is_instance_valid(player.grapple_target_body):
			release_grapple()
			return
		# Track moving platform — update global point from local
		player.grapple_point = player.grapple_target_body.to_global(
			player.grapple_local_point)

	player.velocity.y += player.GRAVITY * delta * player._map_gravity_mult()
	var direction := 0.0
	if Input.is_action_pressed(prefix + "left"):
		direction -= 1.0
	if Input.is_action_pressed(prefix + "right"):
		direction += 1.0
	player.velocity.x += direction * player.GRAPPLE_SWING_FORCE * delta
	player.move_and_slide()

	var to_anchor: Vector2 = player.grapple_point - player.global_position
	var current_dist := to_anchor.length()
	if current_dist > player.grapple_length:
		var correction := to_anchor.normalized()
		player.global_position = player.grapple_point \
			- correction * player.grapple_length
		var vel_along: float = player.velocity.dot(correction)
		if vel_along < 0.0:
			player.velocity -= correction * vel_along
	player.grapple_length = maxf(
		player.grapple_length - player.GRAPPLE_REEL_SPEED * delta,
		player.GRAPPLE_MIN_LENGTH
	)

	# Fire Thread passive — damage enemies touching the rope
	if player.fire_thread_active and player.is_grappling:
		for p in get_tree().get_nodes_in_group("players"):
			if p == player or not p.is_alive:
				continue
			var dist := _point_to_segment(
				p.global_position, player.global_position, player.grapple_point
			)
			if dist < 30.0:  # rope hit radius
				p._apply_fire_burn(
					player.fire_burn_damage,
					player.fire_burn_tick,
					player.fire_burn_duration
				)


func find_grapple_player(aim_dir: Vector2) -> CharacterBody2D:
	var best_player: CharacterBody2D = null
	var best_dot: float = 0.7
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive:
			continue
		var to_p: Vector2 = p.global_position - player.global_position
		var dist := to_p.length()
		if dist > player.GRAPPLE_MAX_RANGE * player.grapple_range_mult \
			or dist < 10.0:
			continue
		var dot := to_p.normalized().dot(aim_dir)
		if dot > best_dot:
			best_dot = dot
			best_player = p
	return best_player


func release_grapple() -> void:
	player.is_grappling = false
	player.grapple_shooting = false
	player.grapple_retracting = false
	player.grapple_point = Vector2.ZERO
	player.grapple_target_player = null
	player.grapple_target_body = null
	player.grapple_local_point = Vector2.ZERO


func _point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := point - a
	var len_sq := ab.length_squared()
	if len_sq < 0.01:
		return ap.length()
	var t := clampf(ap.dot(ab) / len_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)
