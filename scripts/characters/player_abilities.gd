class_name PlayerAbilities
extends Node
## Ability dispatch and individual ability logic extracted from player.gd.

var player: CharacterBody2D

var _yarn_projectile_scene: PackedScene = preload(
	"res://scenes/characters/yarn_projectile.tscn")
var _grenade_scene: PackedScene = preload(
	"res://scenes/characters/grenade.tscn")
var _rocket_scene: PackedScene = preload(
	"res://scenes/characters/rocket.tscn")
var _stink_cloud_scene: PackedScene = preload(
	"res://scenes/characters/stink_cloud.tscn")
var _boomerang_scene: PackedScene = preload(
	"res://scenes/characters/boomerang.tscn")
var _guided_rocket_scene: PackedScene = preload(
	"res://scenes/characters/guided_rocket.tscn")
var _tripwire_scene: PackedScene = preload(
	"res://scenes/characters/tripwire.tscn")
var _black_hole_scene: PackedScene = preload(
	"res://scenes/characters/black_hole.tscn")
var _soul_essence_scene: PackedScene = preload(
	"res://scenes/characters/soul_essence.tscn")
var _heavens_wrath_scene: PackedScene = preload(
	"res://scenes/characters/heavens_wrath.tscn")


func setup(p: CharacterBody2D) -> void:
	player = p


func _can_spawn_ability(ab_id: int) -> bool:
	var limit := 5
	if player.ability_ids[0] == player.ability_ids[1] \
		and player.ability_ids[0] == ab_id:
		limit = 10
	var current: int = player.ability_entity_count.get(ab_id, 0)
	return current < limit


func _track_entity(node: Node, ab_id: int) -> void:
	## Mark a spawned entity for limit tracking.
	node.set_meta("owner_player", player)
	node.set_meta("ability_id", ab_id)
	var count: int = player.ability_entity_count.get(ab_id, 0)
	player.ability_entity_count[ab_id] = count + 1


func handle_abilities() -> void:
	if player.stun_timer > 0.0 or player.dash_timer > 0.0 \
		or player.is_grabbed:
		return
	var prefix := "p%d_" % player.player_id

	# Parry
	if Input.is_action_pressed(prefix + "parry") \
		and player.parry_cooldown <= 0.0:
		player.parry_timer = player.PARRY_WINDOW
		player.parry_cooldown = player.PARRY_CD * player.parry_cd_multiplier
		player.parry_visual = 0.3
		SoundManager.play_shield()
		# Angry/determined face during parry
		player.trigger_face_event("angry", 0.4)
		# Set custom spawn point — only if player has extra lives
		if player.extra_lives > 0 and not player.spawn_point_used_this_life:
			player.custom_spawn_point = player.global_position
			player.has_custom_spawn = true
		# Spirit Burst passive — spawn 5 homing essences
		if player.spirit_burst_count > 0:
			_spawn_spirit_burst()
		# Parry Burst — additional parries
		if player.parry_burst_count > 0:
			_burst_parry(player.parry_burst_count)

	# Handle grenade charging
	if player.charge_slot >= 0:
		_handle_charge(prefix)
		return

	# Handle guided rocket steering — release to boost
	if player.guided_rocket_slot >= 0:
		var action := prefix + (
			"attack1" if player.guided_rocket_slot == 0 else "attack2")
		if not Input.is_action_pressed(action):
			# Released — boost the rocket
			if player.guided_rocket_ref != null \
				and is_instance_valid(player.guided_rocket_ref) \
				and not player.guided_rocket_ref.exploded:
				player.guided_rocket_ref.boost()
			player.guided_rocket_ref = null
			player.guided_rocket_slot = -1

	# Handle grab — waiting or holding
	if player.grab_slot >= 0:
		var grab_action := prefix + (
			"attack1" if player.grab_slot == 0 else "attack2")

		# Released button without grabbing → cancel
		if not Input.is_action_pressed(grab_action):
			if player.grabbed_player != null:
				_release_grab()
			else:
				player.grab_slot = -1
			return

		if player.grabbed_player != null:
			# Holding grabbed player — carry them
			player.grab_hold_timer += player.get_physics_process_delta_time()
			if is_instance_valid(player.grabbed_player) \
				and player.grabbed_player.is_alive:
				var carry_offset: Vector2 = player.aim_direction \
					* (player.get_player_radius() + 20.0)
				player.grabbed_player.global_position = \
					player.global_position + carry_offset
				player.grabbed_player.velocity = Vector2.ZERO
			# Timeout → auto throw
			if player.grab_hold_timer >= player.GRAB_MAX_HOLD:
				_release_grab()
		else:
			# Waiting for enemy to enter radius — scan each frame
			_try_grab_nearby()

		return  # don't use other abilities while grab active

	if Input.is_action_just_pressed(prefix + "attack1"):
		_try_ability(0, prefix)
	if Input.is_action_just_pressed(prefix + "attack2"):
		_try_ability(1, prefix)


func _try_ability(slot: int, _prefix: String) -> void:
	if player.ability_cds[slot] > 0.0:
		return
	var ab_id: int = player.ability_ids[slot]
	# Guided rocket — track slot for release detection
	if ab_id == AbilityRegistry.GUIDED_ROCKET:
		player.guided_rocket_slot = slot
	# Grab throw — hold to grab, release to throw (cooldown on release)
	if ab_id == AbilityRegistry.GRAB_THROW:
		player.grab_slot = slot
		_try_grab_nearby()
		return
	# Grenade uses charge mechanic
	if ab_id == AbilityRegistry.GRENADE:
		player.charge_slot = slot
		player.charge_timer = 0.0
		return
	_use_ability(slot)


func _handle_charge(prefix: String) -> void:
	var action := prefix + (
		"attack1" if player.charge_slot == 0 else "attack2")
	var cfg := AbilityRegistry.get_data(AbilityRegistry.GRENADE)
	var overcharge: float = cfg.get("overcharge_time", 2.5)

	player.charge_timer += player.get_physics_process_delta_time()

	# Overcharge — explode in hand!
	if player.charge_timer >= overcharge:
		SoundManager.play_explosion()
		player.take_damage(cfg["damage"] * 0.5)
		player.apply_knockback(Vector2.UP * 400.0)
		var oc_slot: int = player.charge_slot
		player.ability_cds[player.charge_slot] = cfg["cooldown"]
		player.charge_slot = -1
		player.charge_timer = 0.0
		if GameManager.game_mode == GameManager.GameMode.CHAOS:
			player.ability_ids[oc_slot] = randi_range(
				0, AbilityRegistry.ABILITY_COUNT - 1)
		return

	# Released — throw with charge power
	if not Input.is_action_pressed(action):
		_throw_grenade()
	return


func _use_ability(slot: int) -> void:
	if player.ability_cds[slot] > 0.0:
		return
	var ab_id: int = player.ability_ids[slot]
	var data: Dictionary = AbilityRegistry.get_data(ab_id)

	# Target-required abilities return false if no target → no cooldown
	var success := true
	match ab_id:
		AbilityRegistry.YARN_TOSS: _ab_yarn_toss()
		AbilityRegistry.NEEDLE_DASH: _ab_needle_dash()
		AbilityRegistry.YARN_BOMB: _ab_yarn_bomb()
		AbilityRegistry.THREAD_PULL: success = _ab_thread_pull()
		AbilityRegistry.SPIN_ATTACK: _ab_spin_attack()
		AbilityRegistry.GRENADE: _ab_grenade()
		AbilityRegistry.ROCKET_LAUNCHER: _ab_rocket_launcher()
		AbilityRegistry.STINK_CLOUD: _ab_stink_cloud()
		AbilityRegistry.SPIKE_ARMOR: _ab_spike_armor()
		AbilityRegistry.SWAP: success = _ab_swap()
		AbilityRegistry.BOOMERANG: _ab_boomerang()
		AbilityRegistry.GUIDED_ROCKET: _ab_guided_rocket()
		AbilityRegistry.TRIPWIRE: success = _ab_tripwire()
		AbilityRegistry.GRAB_THROW: success = _ab_grab_throw()
		AbilityRegistry.BLACK_HOLE: _ab_black_hole()
		AbilityRegistry.PORTAL_GATE: success = _ab_portal_gate()
		AbilityRegistry.HEAVENS_WRATH: _ab_heavens_wrath()

	if success:
		player.ability_cds[slot] = maxf(
			data["cooldown"] * player.cd_multiplier - player.cd_flat, 0.1)
		# Focus face flash on ability cast (skipped for needle dash which
		# already triggers focus for the dash duration).
		if ab_id != AbilityRegistry.NEEDLE_DASH:
			player.trigger_face_event("focus", 0.4)
		# Chaos mode — replace used ability with a random one
		if GameManager.game_mode == GameManager.GameMode.CHAOS:
			player.ability_ids[slot] = randi_range(
				0, AbilityRegistry.ABILITY_COUNT - 1)


# ══════════════════ INDIVIDUAL ABILITIES ══════════════════

func _ab_yarn_toss() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.YARN_TOSS)
	SoundManager.play_toss()
	player._add_sprite_vfx("cartoon_9", 0.3,
		player.global_position + player.aim_direction * 30.0,
		0.4, player.aim_direction.angle())
	if not _can_spawn_ability(AbilityRegistry.YARN_TOSS):
		return
	var proj: Area2D = _yarn_projectile_scene.instantiate()
	proj.setup_from_config(
		player.player_id, player.aim_direction, player.player_color, cfg)
	proj.owner_ref = player
	proj.max_bounces = player.ricochet_bounces
	proj.speed *= player.projectile_speed_mult
	proj.homing = player.homing_strength
	proj.phase = player.phase_shot
	proj.global_position = player.global_position \
		+ player.aim_direction * (player.get_player_radius() + 8.0)
	get_tree().current_scene.add_child(proj)
	_track_entity(proj, AbilityRegistry.YARN_TOSS)
	# Burst fire — extra shots with delay
	if player.burst_count > 0:
		_burst_yarn_toss(cfg, player.burst_count)


func _burst_yarn_toss(cfg: Dictionary, count: int) -> void:
	for _i in range(count):
		await get_tree().create_timer(0.12).timeout
		if not is_instance_valid(player) or not player.is_alive:
			return
		if not _can_spawn_ability(AbilityRegistry.YARN_TOSS):
			return
		var spread := randf_range(-0.09, 0.09)
		var dir: Vector2 = player.aim_direction.rotated(spread)
		var p2: Area2D = _yarn_projectile_scene.instantiate()
		p2.setup_from_config(player.player_id, dir, player.player_color, cfg)
		p2.owner_ref = player
		p2.max_bounces = player.ricochet_bounces
		p2.speed *= player.projectile_speed_mult
		p2.homing = player.homing_strength
		p2.phase = player.phase_shot
		p2.global_position = player.global_position \
			+ dir * (player.get_player_radius() + 8.0)
		get_tree().current_scene.add_child(p2)
		_track_entity(p2, AbilityRegistry.YARN_TOSS)
		SoundManager.play_toss()


func _ab_needle_dash() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.NEEDLE_DASH)
	SoundManager.play_dash()
	player._add_vfx("dash_trail", 0.3, {"dir": player.aim_direction})
	player._add_sprite_vfx("slash5", 0.35,
		player.global_position + player.aim_direction * 40.0,
		0.5, player.aim_direction.angle())
	player.dash_dir = player.aim_direction
	player.dash_timer = cfg["dash_duration"]
	player.dash_hit_ids.clear()
	var dash_spd: float = cfg["dash_speed"]
	player.velocity = player.dash_dir * dash_spd + player.velocity * 0.5
	player.vibrate(0.3, 0.5, 0.15)
	player._spawn_dust(4)
	# Focus face during dash
	player.trigger_face_event("focus", cfg["dash_duration"] + 0.1)


func _ab_yarn_bomb() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.YARN_BOMB)
	SoundManager.play_explosion()
	var exp_range: float = cfg["explosion_range"]
	var target: Vector2 = player.global_position \
		+ player.aim_direction * exp_range
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - target
		if diff.length() < cfg["explosion_radius"] * player.radius_multiplier:
			var away := diff.normalized()
			p.take_damage(cfg["damage"] * player.damage_multiplier, player)
			p.apply_knockback(
				away * cfg["knockback"]
				+ Vector2.UP * cfg["knockback_up"]
			)
	var exp_radius: float = cfg["explosion_radius"] * player.radius_multiplier
	player._add_vfx("bomb_ring", 0.4, {"pos": target, "radius": exp_radius})
	player._add_sprite_vfx("retro_explosion", 0.5, target,
		exp_radius / 70.0, 0.0)
	player._add_sprite_vfx("retro_burst", 0.4, target,
		exp_radius / 80.0, 0.0,
		Color(1.0, 0.85, 0.3))


func _ab_thread_pull() -> bool:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.THREAD_PULL)
	var best: CharacterBody2D = null
	var best_dot: float = cfg["aim_threshold"]
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive:
			continue
		var to_p: Vector2 = p.global_position - player.global_position
		if to_p.length() > cfg["max_range"]:
			continue
		var dot := to_p.normalized().dot(player.aim_direction)
		if dot > best_dot:
			best_dot = dot
			best = p
	if best == null:
		return false
	SoundManager.play_whip()
	player._add_vfx("pull_thread", 0.35,
		{"target": best.global_position})
	var pull_dir := (player.global_position - best.global_position) \
		.normalized()
	best.apply_knockback(
		pull_dir * cfg["pull_force"] + Vector2.UP * cfg["pull_up"]
	)
	best.take_damage(cfg["damage"] * player.damage_multiplier, player)
	return true


func _ab_spin_attack() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.SPIN_ATTACK)
	SoundManager.play_whip()
	player.spin_visual_timer = cfg.get("visual_duration", 0.2)
	var spin_r: float = cfg["radius"] * player.radius_multiplier
	player._add_vfx("spin_lines", 0.35, {"radius": spin_r})
	player._add_sprite_vfx("cartoon_3", 0.4,
		player.global_position, spin_r / 250.0, 0.0)
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive:
			continue
		var to_p: Vector2 = p.global_position - player.global_position
		if to_p.length() <= cfg["radius"] * player.radius_multiplier:
			p.take_damage(cfg["damage"] * player.damage_multiplier, player)
			p.apply_knockback(
				to_p.normalized() * cfg["knockback"]
				+ Vector2.UP * cfg["knockback_up"]
			)


func _ab_grenade() -> void:
	# Grenade is handled by charge mechanic in _try_ability/_handle_charge
	pass


func _throw_grenade() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.GRENADE)
	var charge_time: float = cfg.get("charge_time", 1.0)
	var min_spd: float = cfg.get("min_throw_speed", 300.0)
	var max_spd: float = cfg.get("max_throw_speed", 900.0)

	var charge_ratio := clampf(player.charge_timer / charge_time, 0.0, 1.0)
	var throw_speed := lerpf(min_spd, max_spd, charge_ratio)

	if not _can_spawn_ability(AbilityRegistry.GRENADE):
		player.charge_slot = -1
		player.charge_timer = 0.0
		return
	SoundManager.play_toss()
	var gren: CharacterBody2D = _grenade_scene.instantiate()
	gren.setup_from_config(
		player.player_id, player.aim_direction, player.player_color,
		cfg, throw_speed
	)
	gren.owner_ref = player
	gren.homing = player.homing_strength
	gren.global_position = player.global_position \
		+ player.aim_direction * (maxf(player.get_player_radius(), 24.0) + 30.0)
	get_tree().current_scene.add_child(gren)
	_track_entity(gren, AbilityRegistry.GRENADE)

	var throw_slot: int = player.charge_slot
	player.ability_cds[player.charge_slot] = cfg["cooldown"]
	player.charge_slot = -1
	player.charge_timer = 0.0
	if GameManager.game_mode == GameManager.GameMode.CHAOS:
		player.ability_ids[throw_slot] = randi_range(
			0, AbilityRegistry.ABILITY_COUNT - 1)


func _ab_stink_cloud() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.STINK_CLOUD)
	if not _can_spawn_ability(AbilityRegistry.STINK_CLOUD):
		return
	SoundManager.play_toss()
	player._add_vfx("stink_puff", 0.4)
	player._add_sprite_vfx("cartoon_6", 0.6,
		player.global_position, 0.4, 0.0)
	var cloud: Node2D = _stink_cloud_scene.instantiate()
	cloud.setup_from_config(player.player_id, cfg)
	cloud.cloud_radius *= player.radius_multiplier
	cloud.global_position = player.global_position
	get_tree().current_scene.add_child(cloud)
	_track_entity(cloud, AbilityRegistry.STINK_CLOUD)


func _ab_spike_armor() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.SPIKE_ARMOR)
	SoundManager.play_shield()
	player.spike_armor_timer = cfg["armor_duration"]
	player.spike_armor_max = cfg["armor_duration"]
	player.spike_contact_cds.clear()
	player._add_sprite_vfx("cartoon_5", 0.4,
		player.global_position, 0.3, 0.0)


func _ab_swap() -> bool:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.SWAP)
	var max_range: float = cfg["max_range"] * player.radius_multiplier
	var threshold: float = cfg["aim_threshold"]
	var invuln_time: float = cfg.get("swap_invuln", 0.3)

	var best: CharacterBody2D = null
	var best_dot: float = threshold
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive:
			continue
		var to_p: Vector2 = p.global_position - player.global_position
		if to_p.length() > max_range:
			continue
		var dot := to_p.normalized().dot(player.aim_direction)
		if dot > best_dot:
			best_dot = dot
			best = p

	if best == null:
		return false

	SoundManager.play_blink()

	# Cut both players' grapples so the swap actually relocates them
	# (otherwise the rope anchor would yank them back).
	if player.is_grappling or player.grapple_shooting:
		player._release_grapple()
	if best.is_grappling or best.grapple_shooting:
		best._release_grapple()

	# Capture positions and velocities RIGHT NOW
	var my_pos: Vector2 = player.global_position
	var their_pos: Vector2 = best.global_position
	var my_vel: Vector2 = player.velocity
	var their_vel: Vector2 = best.velocity

	# Swap positions — only set global_position (not local position)
	player.global_position = their_pos
	best.global_position = my_pos
	# Swap velocities — full exchange
	player.velocity = their_vel
	best.velocity = my_vel

	# Generous invulnerability to survive any overlap
	player.invincible_timer = maxf(player.invincible_timer, invuln_time)
	player.is_invincible = true
	player.danger_timer = 0.0
	best.invincible_timer = maxf(best.invincible_timer, invuln_time)
	best.is_invincible = true
	best.danger_timer = 0.0

	player._spawn_dust(5)
	if best.has_method("_spawn_dust"):
		best._spawn_dust(5)
	# Swap burst VFX anchored at BOTH world positions — doesn't follow
	# either player after the teleport, stays at the two endpoints.
	var swap_fx: GDScript = load("res://scripts/effects/swap_effect.gd")
	swap_fx.spawn(get_tree().current_scene, my_pos)
	swap_fx.spawn(get_tree().current_scene, their_pos)
	return true


func _ab_boomerang() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.BOOMERANG)
	if not _can_spawn_ability(AbilityRegistry.BOOMERANG):
		return
	SoundManager.play_toss()
	player._add_sprite_vfx("cartoon_4", 0.3,
		player.global_position + player.aim_direction * 30.0,
		0.45, player.aim_direction.angle())
	var boom: Node2D = _boomerang_scene.instantiate()
	boom.setup_from_config(
		player.player_id, player.aim_direction, player.player_color, cfg)
	boom.owner_ref = player
	boom.homing = player.homing_strength
	boom.global_position = player.global_position \
		+ player.aim_direction * (player.get_player_radius() + 10.0)
	get_tree().current_scene.add_child(boom)
	_track_entity(boom, AbilityRegistry.BOOMERANG)
	# Burst fire — extra boomerangs with delay
	if player.burst_count > 0:
		_burst_boomerang(cfg, player.burst_count)


func _burst_boomerang(cfg: Dictionary, count: int) -> void:
	for _i in range(count):
		await get_tree().create_timer(0.15).timeout
		if not is_instance_valid(player) or not player.is_alive:
			return
		if not _can_spawn_ability(AbilityRegistry.BOOMERANG):
			return
		var spread := randf_range(-0.1, 0.1)
		var dir: Vector2 = player.aim_direction.rotated(spread)
		var b2: Node2D = _boomerang_scene.instantiate()
		b2.setup_from_config(player.player_id, dir, player.player_color, cfg)
		b2.owner_ref = player
		b2.homing = player.homing_strength
		b2.global_position = player.global_position \
			+ dir * (player.get_player_radius() + 10.0)
		get_tree().current_scene.add_child(b2)
		_track_entity(b2, AbilityRegistry.BOOMERANG)
		SoundManager.play_toss()


func _burst_rockets(cfg: Dictionary, count: int) -> void:
	var spread_rad: float = deg_to_rad(cfg.get("spread_angle", 30.0))
	for _i in range(count):
		await get_tree().create_timer(0.15).timeout
		if not is_instance_valid(player) or not player.is_alive:
			return
		if not _can_spawn_ability(AbilityRegistry.ROCKET_LAUNCHER):
			return
		SoundManager.play_explosion()
		var base_dir: Vector2 = player.aim_direction.rotated(
			randf_range(-0.1, 0.1))
		var dirs: Array[Vector2] = [
			base_dir,
			base_dir.rotated(-spread_rad),
			base_dir.rotated(spread_rad),
		]
		var first_r2: Area2D = null
		for dir in dirs:
			var r2: Area2D = _rocket_scene.instantiate()
			r2.setup_from_config(
				player.player_id, dir, player.player_color, cfg)
			r2.owner_ref = player
			r2.homing = player.homing_strength
			r2.phase = player.phase_shot
			r2.global_position = player.global_position \
				+ dir * (player.get_player_radius() + 10.0)
			get_tree().current_scene.add_child(r2)
			if first_r2 == null:
				first_r2 = r2
		_track_entity(first_r2, AbilityRegistry.ROCKET_LAUNCHER)


func _ab_guided_rocket() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.GUIDED_ROCKET)
	if not _can_spawn_ability(AbilityRegistry.GUIDED_ROCKET):
		return
	SoundManager.play_toss()
	player._add_sprite_vfx("slash", 0.25,
		player.global_position + player.aim_direction * 40.0,
		0.4, player.aim_direction.angle())
	var rocket: Area2D = _guided_rocket_scene.instantiate()
	rocket.setup_from_config(
		player.player_id, player.aim_direction, player.player_color, cfg)
	rocket.owner_ref = player
	rocket.homing = player.homing_strength
	rocket.phase = player.phase_shot
	rocket.global_position = player.global_position \
		+ player.aim_direction * (player.get_player_radius() + 10.0)
	get_tree().current_scene.add_child(rocket)
	_track_entity(rocket, AbilityRegistry.GUIDED_ROCKET)
	player.guided_rocket_ref = rocket


func _ab_tripwire() -> bool:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.TRIPWIRE)

	# Raycast to find platform
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	var cast_range: float = cfg.get("cast_range", 500.0)
	var query := PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + player.aim_direction * cast_range, 1
	)
	query.exclude = [player.get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false

	SoundManager.play_toss()

	var hit_pos: Vector2 = result.position
	player._add_vfx("pull_thread", 0.3, {"target": hit_pos})

	var wire_completed := false
	if player.tripwire_node == null \
		or not is_instance_valid(player.tripwire_node):
		# First anchor — create new tripwire (don't swap in chaos)
		if not _can_spawn_ability(AbilityRegistry.TRIPWIRE):
			return true  # still consume cooldown
		var tw: Node2D = _tripwire_scene.instantiate()
		tw.setup_anchor_a(hit_pos, player.player_id, player.player_color, cfg)
		get_tree().current_scene.add_child(tw)
		_track_entity(tw, AbilityRegistry.TRIPWIRE)
		player.tripwire_node = tw
	else:
		if not player.tripwire_node.has_b:
			# Second anchor — activate wire (swap OK)
			player.tripwire_node.set_anchor_b(hit_pos)
			wire_completed = true
		else:
			# Third anchor — remove first tripwire, create new pair
			var old_b: Vector2 = player.tripwire_node.anchor_b
			player.tripwire_node.queue_free()
			if not _can_spawn_ability(AbilityRegistry.TRIPWIRE):
				return true  # still consume cooldown
			var tw: Node2D = _tripwire_scene.instantiate()
			tw.setup_anchor_a(
				old_b, player.player_id, player.player_color, cfg)
			tw.set_anchor_b(hit_pos)
			get_tree().current_scene.add_child(tw)
			_track_entity(tw, AbilityRegistry.TRIPWIRE)
			player.tripwire_node = tw
			wire_completed = true
	# In Chaos mode: only apply cooldown+swap when wire is completed
	# First anchor in chaos = free (no cd, no swap) to allow completion
	if GameManager.game_mode == GameManager.GameMode.CHAOS \
		and not wire_completed:
		return false
	return true


func _ab_rocket_launcher() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.ROCKET_LAUNCHER)
	if not _can_spawn_ability(AbilityRegistry.ROCKET_LAUNCHER):
		return
	SoundManager.play_explosion()
	player._add_vfx("muzzle_flash", 0.2,
		{"dir": player.aim_direction, "color": Color(1, 0.5, 0.1)})
	var spread_rad: float = deg_to_rad(cfg.get("spread_angle", 30.0))
	var directions: Array[Vector2] = [
		player.aim_direction,
		player.aim_direction.rotated(-spread_rad),
		player.aim_direction.rotated(spread_rad),
	]
	var first_rocket: Area2D = null
	for dir in directions:
		var rocket: Area2D = _rocket_scene.instantiate()
		rocket.setup_from_config(
			player.player_id, dir, player.player_color, cfg)
		rocket.owner_ref = player
		rocket.homing = player.homing_strength
		rocket.phase = player.phase_shot
		rocket.global_position = player.global_position \
			+ dir * (player.get_player_radius() + 10.0)
		get_tree().current_scene.add_child(rocket)
		if first_rocket == null:
			first_rocket = rocket
	_track_entity(first_rocket, AbilityRegistry.ROCKET_LAUNCHER)
	# Burst fire — extra rocket salvos
	if player.burst_count > 0:
		_burst_rockets(cfg, player.burst_count)


func _ab_grab_throw() -> bool:
	_try_grab_nearby()
	return true  # always "succeeds" — cooldown managed by _release_grab


func _try_grab_nearby() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.GRAB_THROW)
	var grab_r: float = cfg["grab_radius"]
	var best: CharacterBody2D = null
	var best_dist: float = 9999.0
	for p in get_tree().get_nodes_in_group("players"):
		if p == player or not p.is_alive or p.is_grabbed:
			continue
		# Account for both players' radii when checking grab range
		var dist: float = player.global_position.distance_to(p.global_position)
		var effective_range: float = grab_r \
			+ player.get_player_radius() + p.get_player_radius()
		if dist < effective_range and dist < best_dist:
			best_dist = dist
			best = p
	if best == null:
		return  # keep scanning next frame

	SoundManager.play_whip()
	# Start grab hook animation
	player.grab_hook_timer = 0.35
	player.grab_hook_target = best.global_position
	best.grab_stun_timer = player.GRAB_MAX_HOLD + 0.5
	best.is_grabbed = true
	best.velocity = Vector2.ZERO
	# Cut victim's grapple so they actually get pulled to the grabber
	if best.is_grappling or best.grapple_shooting:
		best._release_grapple()
	# Disable collision so grabbed player doesn't block grabber
	var col: CollisionShape2D = best.get_node_or_null("CollisionShape2D")
	if col != null:
		col.set_deferred("disabled", true)
	player.grabbed_player = best
	player.grab_hold_timer = 0.0


func _release_grab() -> void:
	if player.grabbed_player == null:
		player.grab_slot = -1
		return
	var cfg := AbilityRegistry.get_data(AbilityRegistry.GRAB_THROW)
	if is_instance_valid(player.grabbed_player) \
		and player.grabbed_player.is_alive:
		var throw_dir: Vector2 = player.aim_direction
		var spd: float = cfg["throw_speed"]
		player.grabbed_player.velocity = throw_dir * spd
		player.grabbed_player.take_damage(
			cfg["throw_damage"] * player.damage_multiplier, player)
		player.grabbed_player.grab_stun_timer = 0.0
		player.grabbed_player.is_grabbed = false
		# Re-enable collision
		var col: CollisionShape2D = player.grabbed_player.get_node_or_null(
			"CollisionShape2D")
		if col != null:
			col.set_deferred("disabled", false)
		SoundManager.play_toss()
		player.vibrate(0.4, 0.6, 0.15)
		player._add_vfx("muzzle_flash", 0.2,
			{"dir": throw_dir, "color": player.player_color})
	player.grabbed_player = null
	player.ability_cds[player.grab_slot] = cfg["cooldown"] \
		* player.cd_multiplier
	player.grab_slot = -1
	player.grab_hold_timer = 0.0


func _ab_black_hole() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.BLACK_HOLE)
	if not _can_spawn_ability(AbilityRegistry.BLACK_HOLE):
		return
	SoundManager.play_explosion()
	player._add_sprite_vfx("cartoon_10", 0.6,
		player.global_position, 0.5, 0.0)
	var hole: Node2D = _black_hole_scene.instantiate()
	hole.setup_from_config(player.player_id, cfg)
	hole.owner_ref = player
	hole.max_radius *= player.radius_multiplier
	hole.global_position = player.global_position
	get_tree().current_scene.add_child(hole)
	_track_entity(hole, AbilityRegistry.BLACK_HOLE)


func _ab_portal_gate() -> bool:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.PORTAL_GATE)
	var portal_r: float = cfg.get("portal_radius", 100.0) * player.radius_multiplier

	if not player.has_portal_gate:
		# First press — place portal A
		player.portal_gate_pos = player.global_position
		player.has_portal_gate = true
		SoundManager.play_blink()
		player._add_vfx("shield_flash", 0.2)
		return false  # no cooldown yet

	# Second press — swap everything in both radii
	var pos_a: Vector2 = player.portal_gate_pos
	var pos_b: Vector2 = player.global_position
	SoundManager.play_blink()

	# Collect entities near portal A and near player (B)
	var at_a: Array = []
	var at_b: Array = []
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive:
			continue
		if p.global_position.distance_to(pos_a) < portal_r:
			at_a.append(p)
		elif p.global_position.distance_to(pos_b) < portal_r:
			at_b.append(p)

	# Teleport: A→B, B→A (preserve velocity)
	var offset := pos_b - pos_a
	for p in at_a:
		p.global_position += offset
		p._spawn_hit_burst("electric", 5)
	for p in at_b:
		p.global_position -= offset
		p._spawn_hit_burst("electric", 5)

	# Also move projectiles
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if not is_instance_valid(proj):
			continue
		if proj.global_position.distance_to(pos_a) < portal_r:
			proj.global_position += offset
		elif proj.global_position.distance_to(pos_b) < portal_r:
			proj.global_position -= offset

	# Portal-open burst at both portal endpoints (world-anchored, not
	# attached to any player — so both sides of the swap see the flash).
	var swap_fx: GDScript = load("res://scripts/effects/swap_effect.gd")
	swap_fx.spawn(get_tree().current_scene, pos_a)
	swap_fx.spawn(get_tree().current_scene, pos_b)
	player.has_portal_gate = false
	player.portal_gate_pos = Vector2.ZERO
	return true


func _ab_heavens_wrath() -> void:
	var cfg := AbilityRegistry.get_data(AbilityRegistry.HEAVENS_WRATH)
	if not _can_spawn_ability(AbilityRegistry.HEAVENS_WRATH):
		return
	SoundManager.play_explosion()
	player._add_sprite_vfx("slash3", 0.5,
		player.global_position, 0.5, 0.0,
		Color(1.0, 0.95, 0.6))
	var wrath: Node2D = _heavens_wrath_scene.instantiate()
	wrath.setup_from_config(
		player.player_id, player.aim_direction, player.player_color, cfg)
	wrath.owner_ref = player
	wrath.start_pos = player.global_position
	wrath.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(wrath)
	_track_entity(wrath, AbilityRegistry.HEAVENS_WRATH)


func _burst_parry(count: int) -> void:
	for _i in range(count):
		await get_tree().create_timer(0.15).timeout
		if not is_instance_valid(player) or not player.is_alive:
			return
		if player.parry_cooldown > 0.0:
			player.parry_cooldown = 0.0
		player.parry_timer = player.PARRY_WINDOW
		player.parry_visual = 0.3
		SoundManager.play_shield()
		player._add_vfx("shield_flash", 0.2)
		player._add_sprite_vfx("cartoon_7", 0.4,
			player.global_position, 0.3, 0.0)
		player._parry_detach_grapples()
		if player.shockwave_radius_mult > 0.0:
			player._do_shockwave()
		if player.spirit_burst_count > 0:
			_spawn_spirit_burst()


func _spawn_spirit_burst() -> void:
	## Spawn 5 × stacks homing soul essences, max 15 on map.
	var count: int = 5 * player.spirit_burst_count
	var dmg: float = player.spirit_burst_damage * player.damage_multiplier
	# Limit: max 15 essences per player on map
	var existing := 0
	for e in get_tree().get_nodes_in_group("soul_essences"):
		if is_instance_valid(e) and e.owner_id == player.player_id:
			existing += 1
	count = mini(count, 15 - existing)
	if count <= 0:
		return
	for i in range(count):
		var angle := float(i) * TAU / count
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) \
			* (player.get_player_radius() + 15.0)
		var ess: Node2D = _soul_essence_scene.instantiate()
		ess.setup(player.player_id, player.player_color,
			Vector2(cos(angle), sin(angle)), dmg)
		ess.owner_ref = player
		ess.global_position = player.global_position + offset
		ess.delay = 0.2 + i * 0.04  # staggered launch
		get_tree().current_scene.add_child(ess)
