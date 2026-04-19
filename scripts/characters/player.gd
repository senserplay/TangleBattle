extends CharacterBody2D

signal died(player_id: int)

const SPEED := 300.0
const JUMP_SPEED := -550.0
const GRAVITY := 980.0
const MAX_FALL_SPEED := 600.0
var MAX_HP: float = 100.0
const BOUND_MARGIN := 60.0
const DANGER_ZONE_TIME := 2.0  # seconds in danger zone before death

# Physics polish
const COYOTE_TIME := 0.1
const AIR_ACCEL := 600.0  # air control force (px/s^2)
const WALL_SLIDE_SPEED := 120.0
const GROUND_FRICTION := 12.0
const AIR_FRICTION := 1.5
const AIR_DRAG := 0.5  # drag on horizontal velocity in air (per second)

const GRAPPLE_MAX_RANGE := 1200.0
const GRAPPLE_REEL_SPEED := 350.0  # stronger pull
const GRAPPLE_SWING_FORCE := 600.0
const GRAPPLE_MIN_LENGTH := 150.0
const GRAPPLE_HOLD_TIME := 0.15
const GRAPPLE_SHOOT_SPEED := 3500.0
const GRAPPLE_RETRACT_SPEED := 5000.0  # fast retract

const ROPE_COLORS: Array[Color] = [
	Color(0.9, 0.45, 0.4),   # red player — warm red rope
	Color(0.4, 0.55, 0.9),   # blue player — blue rope
	Color(0.4, 0.85, 0.45),  # green player — green rope
	Color(0.95, 0.8, 0.3),   # yellow player — gold rope
]

const PLAYER_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3),
	Color(0.95, 0.85, 0.1),
]

# Crosshair
const CROSSHAIR_DIST := 120.0
const CROSSHAIR_SIZE := 12.0

# Ability icon layout
const ICON_Y := -60.0
const ICON_RADIUS := 18.0
const ICON_SPACING := 42.0

# Player-to-player collision
const PLAYER_BOUNCE := 200.0
const BASE_RADIUS := 24.0  # radius at 100 HP
const MIN_SCALE := 0.7  # scale at very low HP
const MAX_SCALE := 1.8  # scale at very high HP (e.g. 250 HP with Tank)
const BASE_HP_REF := 100.0  # reference HP for scale=1.0

var player_id: int = 1
var player_color: Color = Color.RED
var is_alive: bool = true
var is_invincible: bool = false
var facing_right: bool = true
var hp: float = MAX_HP

var speed_multiplier: float = 1.0
var base_speed_mult: float = 1.0  # from passives
var damage_multiplier: float = 1.0  # from passives
var cd_multiplier: float = 1.0  # from passives
var lifesteal_pct: float = 0.0  # from passives
var poison_pct: float = 0.0  # from passives
var poison_slow: float = 0.0  # from passives (legendary poison)
var extra_lives: int = 0  # from phoenix
var grapple_range_mult: float = 1.0  # from thread master
var grapple_speed_mult: float = 1.0  # from thread master
var radius_multiplier: float = 1.0  # from wide impact
var passives: Array[Dictionary] = []  # [{passive_id, rarity}]
var fire_thread_active: bool = false  # from Fire Thread passive
var fire_burn_damage: float = 0.0
var fire_burn_tick: float = 0.5
var fire_burn_duration: float = 2.0
var ricochet_bounces: int = 0  # from Ricochet passive
var projectile_speed_mult: float = 1.0
var regen_per_sec: float = 0.0  # from Regeneration passive
var damage_reduction: float = 0.0  # from Iron Skin passive (0.0 - 1.0)
var shockwave_radius_mult: float = 0.0  # from Shockwave passive (0 = off)
var lightning_slow_duration: float = 0.0  # from Lightning Strike passive
var collision_force_mult: float = 1.0  # from Heavy Impact passive
var homing_strength: float = 0.0  # from Homing Projectiles passive
var burst_count: int = 0  # from Burst Fire passive
var luck_bonus: float = 0.0  # from Lucky Star passive — shifts rarity weights
var spirit_burst_count: int = 0  # from Spirit Burst passive — stacks
var spirit_burst_damage: float = 0.0
var parry_cd_multiplier: float = 1.0  # from Shield Mastery passive
var parry_burst_count: int = 0  # from Parry Burst passive
var phase_shot: bool = false  # from Phase Shot passive
var cd_flat: float = 0.0  # flat cooldown reduction (seconds)

var danger_timer: float = 0.0
var in_danger: bool = false
var slow_timer: float = 0.0
var stun_timer: float = 0.0
var invincible_timer: float = 0.0

# Two ability slots
var ability_ids: Array[int] = [0, 1]
var ability_cds: Array[float] = [0.0, 0.0]

# Parry
var parry_timer: float = 0.0
var parry_cooldown: float = 0.0
const PARRY_WINDOW := 0.2  # seconds of active parry
const PARRY_CD := 1.0
var parry_visual: float = 0.0  # for sphere animation

# Custom spawn point — set by parry, one per life
var custom_spawn_point: Vector2 = Vector2.ZERO
var has_custom_spawn: bool = false
var spawn_point_used_this_life: bool = false

# Grab/throw
var grabbed_player: CharacterBody2D = null
var grab_slot: int = -1  # which ability slot is holding the grab
var grab_hold_timer: float = 0.0
const GRAB_MAX_HOLD := 2.0
var grab_stun_timer: float = 0.0  # when grabbed BY someone
var is_grabbed: bool = false
var grab_hook_timer: float = 0.0  # hook shoot-out animation
var grab_hook_target: Vector2 = Vector2.ZERO  # where hook is flying to

# Ability-specific state
var whip_visual_timer: float = 0.0
var whip_visual_dir: Vector2 = Vector2.RIGHT
var shield_timer: float = 0.0
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var dash_hit_ids: Dictionary = {}  # player_id → true, prevents multi-hit
var spin_visual_timer: float = 0.0

# Spike armor state
var spike_armor_timer: float = 0.0
var spike_armor_max: float = 2.0
var spike_anim: float = 0.0  # 0=retracted, 1=fully out
var spike_contact_cds: Dictionary = {}  # player_id → cooldown timer

# Visual effects queue: [{type, timer, max_time, data...}]
var vfx: Array[Dictionary] = []

# Grenade charge state
var charge_slot: int = -1  # which slot is charging (-1 = none)
var charge_timer: float = 0.0

# Grapple
var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var grapple_length: float = 0.0
var grapple_target_player: CharacterBody2D = null
var grapple_target_body: Node2D = null  # platform body for moving platforms
var grapple_local_point: Vector2 = Vector2.ZERO  # point relative to target body
var jump_hold_timer: float = 0.0

# Grapple shooting animation
var grapple_shooting: bool = false  # hook is flying out
var grapple_retracting: bool = false  # hook missed, flying back
var grapple_tip: Vector2 = Vector2.ZERO  # current tip position (global)
var grapple_shoot_dir: Vector2 = Vector2.ZERO  # direction of shot
var jump_used: bool = false

var aim_direction: Vector2 = Vector2.RIGHT

# HP-based size
var hp_scale: float = 1.0  # current visual scale based on HP

# Physics state
var coyote_timer: float = 0.0
var is_wall_sliding: bool = false

# ── Animation state ──
var squash_x: float = 1.0  # horizontal scale
var squash_y: float = 1.0  # vertical scale
var was_on_floor: bool = true
var prev_velocity_y: float = 0.0
var hit_flash_timer: float = 0.0
var body_rotation: float = 0.0  # visual rotation in radians
var dust_particles: Array[Dictionary] = []
var spawn_anim_timer: float = 0.0  # >0 during spawn animation
var speed_trail: Array[Vector2] = []  # position trail for fast movement
const TRAIL_MAX_POINTS := 12
const TRAIL_SPEED_THRESHOLD := 400.0  # min speed to show trail
var run_phase: float = 0.0  # animation phase for running

# ── Sprite-based body+face system ──
var body_sprite: Sprite2D = null
var face_sprite: Sprite2D = null
var face_textures: Dictionary = {}      # emotion name -> Texture2D
var current_emotion: String = ""
var roll_rotation: float = 0.0          # accumulated rolling angle from movement
# Event-driven emotion override: when timer > 0, face shows this emotion
# regardless of state; ticked down in _update_timers.
var face_event_timer: float = 0.0
var face_event_emotion: String = ""
const BODY_TEXTURE_SIZE := 512.0        # native px (texture is square 512x512)
const FACE_TEXTURE_PATH := "res://assets/characters/face/face_%s.png"
const BODY_TEXTURE_PATH := "res://assets/characters/body/yarn_ball.png"
const SPRITE_FILL_FACTOR := 1.25        # new ball asset fills ~80% of texture

# Status effect particles
var burn_particles: Array[Dictionary] = []
var poison_particles: Array[Dictionary] = []
var electric_particles: Array[Dictionary] = []
var hit_particles: Array[Dictionary] = []  # burst on any damage
var burn_particle_timer: float = 0.0
var poison_particle_timer: float = 0.0
var electric_particle_timer: float = 0.0

var _death_effect_scene: PackedScene = preload(
	"res://scenes/characters/death_effect.tscn"
)

# Tripwire state
var tripwire_node: Node2D = null
var portal_gate_pos: Vector2 = Vector2.ZERO
var has_portal_gate: bool = false

# Ability entity limit tracking: ability_id → count of active entities on map
var ability_entity_count: Dictionary = {}

# Guided rocket state
var guided_rocket_ref: Node = null  # active guided rocket
var guided_rocket_slot: int = -1  # which ability slot fired it


func setup(id: int) -> void:
	player_id = id
	player_color = GameManager.player_colors[id - 1]
	MAX_HP = GameManager.max_hp
	hp = MAX_HP
	add_to_group("players")
	# Ensure input actions exist for this player
	_ensure_actions()
	if player_id == 1:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	# Setup extracted components
	_grapple = $PlayerGrapple
	_abilities = $PlayerAbilities
	_grapple.setup(self)
	_abilities.setup(self)
	_setup_visual_sprites()


func _setup_visual_sprites() -> void:
	# Body sprite — yarn ball, tinted to player color
	var body_tex: Texture2D = null
	if ResourceLoader.exists(BODY_TEXTURE_PATH):
		body_tex = load(BODY_TEXTURE_PATH)
	else:
		push_error("Player: missing body texture %s" % BODY_TEXTURE_PATH)
	body_sprite = Sprite2D.new()
	body_sprite.texture = body_tex
	# Use absolute z so platforms (z=0) don't occlude the player.
	body_sprite.z_as_relative = false
	body_sprite.z_index = 5
	body_sprite.modulate = player_color
	add_child(body_sprite)

	# Face sprite — emotion overlay (not tinted, stays upright)
	for emo in ["happy", "focus", "pain", "angry", "scared", "dead"]:
		var path: String = FACE_TEXTURE_PATH % emo
		if ResourceLoader.exists(path):
			face_textures[emo] = load(path)
		else:
			push_warning("Player: missing face %s" % path)
	face_sprite = Sprite2D.new()
	face_sprite.texture = face_textures.get("happy", null)
	face_sprite.z_as_relative = false
	face_sprite.z_index = 6  # above body
	add_child(face_sprite)
	current_emotion = "happy"


func _ensure_actions() -> void:
	var prefix := "p%d_" % player_id
	for action in ["left", "right", "jump", "attack1", "attack2", "parry"]:
		var full: String = prefix + action
		if not InputMap.has_action(full):
			InputMap.add_action(full)


func assign_abilities(ids: Array[int]) -> void:
	ability_ids = ids
	ability_cds = [0.0, 0.0]


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_update_timers(delta)
	_update_hp_scale()
	_update_aim()
	_update_grapple_shot(delta)
	_handle_dash(delta)
	_handle_movement(delta)
	_handle_abilities()
	_handle_player_collisions()
	_update_animation(delta)
	_update_particles(delta)
	_check_bounds()
	_update_visual_sprites(delta)
	queue_redraw()


func _update_visual_sprites(delta: float) -> void:
	if body_sprite == null:
		return

	# Sprite scale derived from collision radius + squash/stretch.
	# Squash is suppressed while running on ground — running ball just rotates,
	# squash/stretch is reserved for jump and landing impact (anticipation
	# from _handle_movement) for clearer visual language.
	var radius := get_player_radius()
	var diameter := radius * 2.0
	var base_scale := diameter / BODY_TEXTURE_SIZE * SPRITE_FILL_FACTOR
	var sx := squash_x
	var sy := squash_y
	if is_on_floor() and absf(velocity.x) > 20.0 and is_alive \
			and absf(velocity.y) < 30.0:
		# Running on the ground without vertical motion → no squash, just roll.
		sx = 1.0
		sy = 1.0
	body_sprite.scale = Vector2(base_scale * sx, base_scale * sy)

	# Body color tint — same state-effect math as the old _draw() did
	var color := player_color
	if has_meta("fire_burning"):
		color = color.lerp(Color(1.0, 0.4, 0.1), 0.25)
	if has_meta("poison_active"):
		color = color.lerp(Color(0.3, 0.8, 0.2), 0.25)
	if stun_timer > 0.0:
		color = color.lerp(Color(0.5, 0.8, 1.0), 0.35)
	if slow_timer > 0.0:
		color = color.lerp(Color(0.5, 0.5, 0.7), 0.4)
	if hit_flash_timer > 0.0:
		color = color.lerp(Color.WHITE, 0.7)
	body_sprite.modulate = color

	# Rolling rotation while moving on ground (real ball physics feel)
	if is_on_floor() and absf(velocity.x) > 20.0 and is_alive:
		var circumference: float = TAU * radius
		if circumference > 0.0:
			roll_rotation += velocity.x / circumference * TAU * delta
	# Combine continuous roll with body_rotation (lean from movement)
	body_sprite.rotation = roll_rotation + body_rotation

	# Hide during invincibility flicker (matches old _draw early return)
	var flicker := is_invincible and fmod(invincible_timer, 0.2) < 0.1
	body_sprite.visible = is_alive and not flicker

	# ── Face: stays UPRIGHT (doesn't roll), faces the aim direction ──
	# Bigger face for readability — covers most of the visible ball area.
	var face_scale := base_scale * 0.85
	var fx := face_scale * sx
	if not facing_right:
		fx = -fx  # mirror horizontally for facing direction
	face_sprite.scale = Vector2(fx, face_scale * sy)
	# Slightly above center so eyes look naturally placed on the ball top
	face_sprite.position = Vector2(0.0, -radius * 0.10)
	face_sprite.rotation = 0.0  # never rotate the face — body rolls around it
	face_sprite.visible = body_sprite.visible

	# Emotion state machine
	var new_emotion := _compute_emotion()
	if new_emotion != current_emotion:
		current_emotion = new_emotion
		if face_textures.has(new_emotion):
			face_sprite.texture = face_textures[new_emotion]


func _compute_emotion() -> String:
	# Death always wins
	if not is_alive:
		return "dead"
	# Event-driven emotion has priority over state-driven (e.g. ability use,
	# kill, dash) — see trigger_face_event() for what fires this.
	if face_event_timer > 0.0 and face_event_emotion != "":
		return face_event_emotion
	# Continuous state-driven emotions
	if hit_flash_timer > 0.0:
		return "pain"
	if hp < MAX_HP * 0.3:
		return "scared"
	if charge_slot >= 0 or guided_rocket_slot >= 0 or grab_slot >= 0:
		return "focus"
	if parry_visual > 0.0:
		return "angry"
	return "happy"


## Trigger an event-driven emotion that overrides state-based emotion for
## `duration` seconds. Used when something dramatic happens — ability cast,
## taking damage, getting a kill, dashing, etc.
func trigger_face_event(emotion: String, duration: float) -> void:
	# Don't override longer-lasting events with shorter ones
	if face_event_timer > duration and face_event_emotion == emotion:
		return
	face_event_emotion = emotion
	face_event_timer = duration


# ══════════════════ ANIMATION ══════════════════

func _update_hp_scale() -> void:
	# Scale based on MAX_HP relative to base (100 HP)
	var raw_scale := MAX_HP / BASE_HP_REF
	hp_scale = clampf(raw_scale, MIN_SCALE, MAX_SCALE)
	# Update collision shape radius
	var col_shape: CollisionShape2D = $CollisionShape2D
	if col_shape != null and col_shape.shape is CircleShape2D:
		col_shape.shape.radius = BASE_RADIUS * hp_scale


func get_player_radius() -> float:
	return BASE_RADIUS * hp_scale


func _update_animation(delta: float) -> void:
	# Landing detection
	var just_landed := is_on_floor() and not was_on_floor
	var just_left_floor := not is_on_floor() and was_on_floor

	if just_landed:
		var impact := clampf(absf(prev_velocity_y) / MAX_FALL_SPEED, 0.0, 1.0)
		squash_x = 1.0 + impact * 0.4
		squash_y = 1.0 - impact * 0.35
		_spawn_dust(int(3 + impact * 4))
		if impact > 0.2:
			SoundManager.play_land()
		if impact > 0.5:
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("add_shake"):
				cam.add_shake(impact * 4.0)

	if just_left_floor:
		# Stretch on jump
		squash_x = 0.8
		squash_y = 1.25
		_spawn_dust(2)

	was_on_floor = is_on_floor()
	prev_velocity_y = velocity.y

	# Wall slide visual — stretch vertically, spawn sparks
	if is_wall_sliding:
		squash_x = 0.85
		squash_y = 1.1
		if Engine.get_physics_frames() % 4 == 0:
			var wall_side := 1.0 if velocity.x < 0 else -1.0
			dust_particles.append({
				"pos": global_position + Vector2(wall_side * 20.0, 0),
				"vel": Vector2(wall_side * 30.0, randf_range(-20.0, -50.0)),
				"life": 0.25,
				"max_life": 0.25,
			})

	# Run phase — for legacy yarn-trail visuals (does NOT add squash anymore;
	# rolling motion is shown by sprite rotation in _update_visual_sprites).
	var ground_speed := absf(velocity.x)
	if is_on_floor() and ground_speed > 100.0:
		run_phase += delta * ground_speed * 0.015
	else:
		run_phase += delta * 2.0

	# Smoothly return to normal
	squash_x = move_toward(squash_x, 1.0, delta * 5.0)
	squash_y = move_toward(squash_y, 1.0, delta * 5.0)

	# Speed trail — record positions when moving fast
	var total_speed := velocity.length()
	if total_speed > TRAIL_SPEED_THRESHOLD:
		speed_trail.push_front(global_position)
		if speed_trail.size() > TRAIL_MAX_POINTS:
			speed_trail.resize(TRAIL_MAX_POINTS)
	elif speed_trail.size() > 0:
		# Fade out trail
		speed_trail.pop_back()

	# Spike armor animation
	if spike_armor_timer > 0.0:
		var cfg_sa := AbilityRegistry.get_data(AbilityRegistry.SPIKE_ARMOR)
		var grow_t: float = cfg_sa.get("spike_grow_time", 0.2)
		spike_anim = move_toward(spike_anim, 1.0, delta / grow_t)
	else:
		var cfg_sa := AbilityRegistry.get_data(AbilityRegistry.SPIKE_ARMOR)
		var shrink_t: float = cfg_sa.get("spike_shrink_time", 0.3)
		spike_anim = move_toward(spike_anim, 0.0, delta / shrink_t)

	# Hit flash
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta

	# Body tilt based on horizontal velocity
	var target_rot := clampf(velocity.x / 500.0, -0.3, 0.3)
	body_rotation = move_toward(body_rotation, target_rot, delta * 8.0)

	# In-air tilt from vertical speed
	if not is_on_floor():
		var air_tilt := clampf(velocity.y / 800.0, -0.15, 0.15)
		body_rotation += air_tilt * 0.3


func _spawn_dust(count: int) -> void:
	for i in range(count):
		var spread := randf_range(-1.0, 1.0)
		dust_particles.append({
			"pos": global_position + Vector2(spread * 15.0, get_player_radius() - 4),
			"vel": Vector2(spread * 60.0, randf_range(-40.0, -80.0)),
			"life": 0.4,
			"max_life": 0.4,
		})


func _update_particles(delta: float) -> void:
	var i := dust_particles.size() - 1
	while i >= 0:
		dust_particles[i]["life"] -= delta
		dust_particles[i]["pos"] += dust_particles[i]["vel"] * delta
		dust_particles[i]["vel"] *= 0.92  # drag
		if dust_particles[i]["life"] <= 0.0:
			dust_particles.remove_at(i)
		i -= 1

	# Burn particles — spawn while on fire
	if has_meta("fire_burning"):
		burn_particle_timer -= delta
		if burn_particle_timer <= 0.0:
			burn_particle_timer = 0.06
			var r := get_player_radius()
			burn_particles.append({
				"pos": global_position + Vector2(
					randf_range(-r, r), randf_range(-r * 0.5, 0)),
				"vel": Vector2(randf_range(-20, 20), randf_range(-80, -140)),
				"life": randf_range(0.3, 0.6),
				"max_life": 0.5,
				"size": randf_range(2.5, 5.0),
			})
	i = burn_particles.size() - 1
	while i >= 0:
		burn_particles[i]["life"] -= delta
		burn_particles[i]["pos"] += burn_particles[i]["vel"] * delta
		burn_particles[i]["vel"].x *= 0.95
		burn_particles[i]["size"] *= 0.98
		if burn_particles[i]["life"] <= 0.0:
			burn_particles.remove_at(i)
		i -= 1

	# Poison particles — spawn while poisoned
	if has_meta("poison_active"):
		poison_particle_timer -= delta
		if poison_particle_timer <= 0.0:
			poison_particle_timer = 0.08
			var r := get_player_radius()
			var angle := randf() * TAU
			poison_particles.append({
				"pos": global_position + Vector2(cos(angle), sin(angle)) * r,
				"vel": Vector2(cos(angle) * 15.0, -randf_range(30, 60)),
				"life": randf_range(0.4, 0.7),
				"max_life": 0.6,
				"size": randf_range(2.0, 4.0),
			})
	i = poison_particles.size() - 1
	while i >= 0:
		poison_particles[i]["life"] -= delta
		poison_particles[i]["pos"] += poison_particles[i]["vel"] * delta
		poison_particles[i]["vel"] *= 0.96
		if poison_particles[i]["life"] <= 0.0:
			poison_particles.remove_at(i)
		i -= 1

	# Electric particles — spawn while stunned
	if stun_timer > 0.0:
		electric_particle_timer -= delta
		if electric_particle_timer <= 0.0:
			electric_particle_timer = 0.04
			var r := get_player_radius()
			var angle := randf() * TAU
			var start := Vector2(cos(angle), sin(angle)) * r * randf_range(0.3, 1.0)
			electric_particles.append({
				"pos": global_position + start,
				"end": global_position + start + Vector2(
					randf_range(-25, 25), randf_range(-25, 25)),
				"life": randf_range(0.08, 0.15),
				"max_life": 0.12,
			})
	i = electric_particles.size() - 1
	while i >= 0:
		electric_particles[i]["life"] -= delta
		if electric_particles[i]["life"] <= 0.0:
			electric_particles.remove_at(i)
		i -= 1

	# Hit burst particles — decay
	i = hit_particles.size() - 1
	while i >= 0:
		hit_particles[i]["life"] -= delta
		hit_particles[i]["pos"] += hit_particles[i]["vel"] * delta
		hit_particles[i]["vel"] *= 0.9
		if hit_particles[i]["life"] <= 0.0:
			hit_particles.remove_at(i)
		i -= 1


func _spawn_hit_burst(dmg_type: String, count: int = 8) -> void:
	var r := get_player_radius()
	for _j in range(count):
		var angle := randf() * TAU
		var spd := randf_range(80, 220)
		var col: Color
		match dmg_type:
			"fire":
				col = Color(1.0, randf_range(0.3, 0.7), 0.05)
			"poison":
				col = Color(randf_range(0.1, 0.4), randf_range(0.7, 1.0), 0.15)
			"electric":
				col = Color(0.4, randf_range(0.7, 1.0), 1.0)
			_:
				col = Color(1.0, 1.0, 1.0, 0.9)
		hit_particles.append({
			"pos": global_position + Vector2(cos(angle), sin(angle)) * r * 0.5,
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd - 40.0),
			"life": randf_range(0.2, 0.45),
			"max_life": 0.35,
			"size": randf_range(2.0, 4.5),
			"color": col,
		})


func _handle_player_collisions() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if p == self or not p.is_alive:
			continue
		var diff: Vector2 = global_position - p.global_position
		var dist := diff.length()
		var both_radius: float = get_player_radius() + p.get_player_radius()
		if dist < both_radius and dist > 0.1:
			var push := diff.normalized()
			# Separate
			var overlap := both_radius - dist
			global_position += push * overlap * 0.5
			# Bounce velocity — both players pushed apart
			var rel_vel: Vector2 = velocity - p.velocity
			var impact := rel_vel.length()
			if rel_vel.dot(push) < 0:
				var bounce_force := maxf(PLAYER_BOUNCE, impact * 0.4)
				var my_mult: float = collision_force_mult
				var their_mult: float = p.collision_force_mult
				velocity += push * bounce_force * my_mult * 0.5
				p.velocity -= push * bounce_force * their_mult * 0.5
				# Squash on collision
				squash_x = 0.85
				squash_y = 1.15
				p.squash_x = 0.85
				p.squash_y = 1.15
				if impact > 300.0:
					SoundManager.play_hit()

			# Spike armor contact damage
			if spike_armor_timer > 0.0:
				var pid: int = p.player_id
				if pid not in spike_contact_cds:
					var sa_cfg := AbilityRegistry.get_data(
						AbilityRegistry.SPIKE_ARMOR
					)
					var sa_radius: float = sa_cfg.get("contact_radius", 40.0) + get_player_radius()
					if dist < sa_radius:
						p.take_damage(sa_cfg["contact_damage"] * damage_multiplier, self)
						p.apply_knockback(
							push * -1.0 * sa_cfg["contact_knockback"]
						)
						spike_contact_cds[pid] = sa_cfg["contact_cooldown"]


# ══════════════════ AIM ══════════════════

func _update_aim() -> void:
	if player_id == 1:
		var mouse_pos := get_global_mouse_position()
		facing_right = mouse_pos.x > global_position.x
		var dir := mouse_pos - global_position
		if dir.length() > 1.0:
			aim_direction = dir.normalized()
		else:
			aim_direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	else:
		# Use the actual bound device from InputManager
		var dev: int = InputManager.player_devices[player_id - 1]
		if dev >= 0:
			var rx := Input.get_joy_axis(dev, JOY_AXIS_RIGHT_X)
			var ry := Input.get_joy_axis(dev, JOY_AXIS_RIGHT_Y)
			if Vector2(rx, ry).length() > 0.3:
				aim_direction = Vector2(rx, ry).normalized()
				facing_right = aim_direction.x > 0.0
				return
		var prefix := "p%d_" % player_id
		var h := 0.0
		if Input.is_action_pressed(prefix + "right"):
			h += 1.0
		if Input.is_action_pressed(prefix + "left"):
			h -= 1.0
		if absf(h) > 0.1:
			aim_direction = Vector2(h, 0.0).normalized()
			facing_right = h > 0.0


# ══════════════════ TIMERS ══════════════════

func _update_timers(delta: float) -> void:
	for i in range(ability_cds.size()):
		ability_cds[i] = maxf(ability_cds[i] - delta, 0.0)
	whip_visual_timer = maxf(whip_visual_timer - delta, 0.0)
	spin_visual_timer = maxf(spin_visual_timer - delta, 0.0)
	grab_hook_timer = maxf(grab_hook_timer - delta, 0.0)
	parry_timer = maxf(parry_timer - delta, 0.0)
	parry_cooldown = maxf(parry_cooldown - delta, 0.0)
	parry_visual = maxf(parry_visual - delta, 0.0)
	spawn_anim_timer = maxf(spawn_anim_timer - delta, 0.0)
	face_event_timer = maxf(face_event_timer - delta, 0.0)
	if grab_stun_timer > 0.0:
		grab_stun_timer -= delta
		is_grabbed = true
	else:
		if is_grabbed:
			# Re-enable collision when no longer grabbed
			$CollisionShape2D.set_deferred("disabled", false)
		is_grabbed = false

	# Update VFX timers
	var i := vfx.size() - 1
	while i >= 0:
		vfx[i]["timer"] -= delta
		if vfx[i]["timer"] <= 0.0:
			vfx.remove_at(i)
		i -= 1

	if shield_timer > 0.0:
		shield_timer -= delta
	if spike_armor_timer > 0.0:
		spike_armor_timer -= delta
		# Update spike contact cooldowns
		var keys_to_erase: Array = []
		for pid in spike_contact_cds:
			spike_contact_cds[pid] -= delta
			if spike_contact_cds[pid] <= 0.0:
				keys_to_erase.append(pid)
		for pid in keys_to_erase:
			spike_contact_cds.erase(pid)
	if stun_timer > 0.0:
		stun_timer -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
		speed_multiplier = 0.5
	else:
		speed_multiplier = 1.0
	if invincible_timer > 0.0:
		invincible_timer -= delta
		is_invincible = true
	else:
		is_invincible = false

	# Regeneration passive
	if regen_per_sec > 0.0 and hp < MAX_HP:
		hp = minf(hp + regen_per_sec * delta, MAX_HP)


# ══════════════════ MOVEMENT ══════════════════

func _handle_dash(delta: float) -> void:
	if dash_timer <= 0.0:
		return
	dash_timer -= delta
	var cfg := AbilityRegistry.get_data(AbilityRegistry.NEEDLE_DASH)
	# Velocity is set once in _ab_needle_dash, just move
	move_and_slide()
	# Spawn dash trail sprite each frame
	_add_sprite_vfx("slash5", 0.25,
		global_position, 0.35, dash_dir.angle(),
		Color(1.0, 0.4, 0.3, 0.9))
	# Hit each player at most once per dash
	for p in get_tree().get_nodes_in_group("players"):
		if p == self or not p.is_alive:
			continue
		if p.player_id in dash_hit_ids:
			continue
		var diff: Vector2 = p.global_position - global_position
		var dash_reach: float = cfg["hit_radius"] * radius_multiplier \
			+ get_player_radius()
		if diff.length() < dash_reach:
			p.take_damage(cfg["damage"] * damage_multiplier, self)
			p.apply_knockback(
				dash_dir * cfg["knockback"]
				+ Vector2.UP * cfg["knockback_up"]
			)
			dash_hit_ids[p.player_id] = true


func _handle_movement(delta: float) -> void:
	if dash_timer > 0.0:
		return

	var prefix := "p%d_" % player_id

	if is_grappling:
		if not Input.is_action_pressed(prefix + "jump"):
			_release_grapple()
		else:
			_handle_grapple(delta)
		return

	# Coyote time — allows jumping shortly after leaving edge
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	var can_jump := is_on_floor() or coyote_timer > 0.0

	# Jump / grapple logic
	if Input.is_action_just_pressed(prefix + "jump"):
		jump_hold_timer = 0.0
		jump_used = false
		if can_jump:
			velocity.y = JUMP_SPEED
			jump_used = true
			coyote_timer = 0.0
			SoundManager.play_jump()

	if Input.is_action_pressed(prefix + "jump") and not jump_used:
		jump_hold_timer += delta
		if jump_hold_timer >= GRAPPLE_HOLD_TIME and not is_on_floor():
			_start_grapple()
			if is_grappling:
				return

	if not Input.is_action_pressed(prefix + "jump"):
		jump_hold_timer = 0.0
		# Variable jump height: only cut during a normal jump, not knockback
		if jump_used and velocity.y < JUMP_SPEED * 0.4:
			velocity.y = maxf(velocity.y, JUMP_SPEED * 0.4)

	# Gravity
	is_wall_sliding = false
	if not is_on_floor():
		# Wall slide detection
		if is_on_wall():
			var input_dir := 0.0
			if Input.is_action_pressed(prefix + "left"):
				input_dir -= 1.0
			if Input.is_action_pressed(prefix + "right"):
				input_dir += 1.0
			# Pressing into wall while falling
			if velocity.y > 0.0 and absf(input_dir) > 0.1:
				is_wall_sliding = true
				velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

		var grav_mul: float = _map_gravity_mult()
		if not is_wall_sliding:
			velocity.y += GRAVITY * delta * grav_mul
			velocity.y = minf(velocity.y, MAX_FALL_SPEED)
		else:
			velocity.y += GRAVITY * delta * 0.3 * grav_mul
			velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	# Stunned
	if stun_timer > 0.0:
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * SPEED * delta)
		move_and_slide()
		return

	# Horizontal movement
	var direction := 0.0
	if Input.is_action_pressed(prefix + "left"):
		direction -= 1.0
	if Input.is_action_pressed(prefix + "right"):
		direction += 1.0

	if is_on_floor():
		var target_vx := direction * SPEED * speed_multiplier * base_speed_mult
		var fric_mul: float = _map_floor_friction_mult()
		# Preserve momentum from dash/knockback when player has more speed
		# than walking would give. Active input still steers, but gives a
		# soft pull toward target instead of an abrupt brake.
		var max_walk: float = SPEED * speed_multiplier * base_speed_mult
		if absf(velocity.x) > max_walk and (
			direction == 0.0
			or signf(velocity.x) == signf(direction)
		):
			# Decelerate gently to retain dash carry-over
			velocity.x = move_toward(
				velocity.x, target_vx,
				GROUND_FRICTION * SPEED * delta * 0.30 * fric_mul
			)
		else:
			velocity.x = move_toward(
				velocity.x, target_vx,
				GROUND_FRICTION * SPEED * delta * fric_mul
			)
	else:
		# Air: additive steering, preserves momentum from knockback/rope
		if absf(direction) > 0.1:
			velocity.x += direction * AIR_ACCEL * delta
		else:
			# Gentle drag when not pressing anything
			velocity.x *= (1.0 - AIR_DRAG * delta)

	if player_id != 1 and direction != 0.0:
		facing_right = direction > 0.0

	move_and_slide()


# ══════════════════ GRAPPLE (delegated to PlayerGrapple) ══════════════════

var _grapple: PlayerGrapple
var _abilities: PlayerAbilities


func _start_grapple() -> void:
	_grapple.start_grapple()


func _update_grapple_shot(delta: float) -> void:
	_grapple.update_grapple_shot(delta)


func _handle_grapple(delta: float) -> void:
	_grapple.handle_grapple(delta)


func _release_grapple() -> void:
	_grapple.release_grapple()


func _apply_fire_burn(
	dmg: float, tick: float, duration: float
) -> void:
	# Prevent stacking — only one burn at a time
	if has_meta("fire_burning"):
		return
	set_meta("fire_burning", true)
	var ticks: int = int(duration / tick)
	for _i in range(ticks):
		await get_tree().create_timer(tick).timeout
		if not is_alive:
			break
		hp -= dmg
		hit_flash_timer = 0.05
		_spawn_hit_burst("fire", 6)
		if hp <= 0.0:
			hp = 0.0
			die()
			break
	remove_meta("fire_burning")


# ══════════════════ ABILITIES (delegated to PlayerAbilities) ══════════════════

func _handle_abilities() -> void:
	_abilities.handle_abilities()


# ══════════════════ DAMAGE ══════════════════

func take_damage(amount: float, source: Node = null) -> void:
	if is_invincible:
		return
	if shield_timer > 0.0:
		shield_timer = 0.0
		return
	# Parry — block damage (projectiles are reflected in their own scripts)
	if parry_timer > 0.0:
		parry_timer = 0.0
		SoundManager.play_whip()
		_add_vfx("shield_flash", 0.3)
		vibrate(0.5, 0.8, 0.2)
		_parry_detach_grapples()
		# Shockwave passive — push nearby enemies on parry
		if shockwave_radius_mult > 0.0:
			_do_shockwave()
		return
	# Iron Skin damage reduction
	var actual_amount := amount * (1.0 - damage_reduction)
	hp -= actual_amount
	hit_flash_timer = 0.1
	SoundManager.play_hit()
	squash_x = 1.3
	squash_y = 0.7
	# Pain face for a brief window after taking damage
	trigger_face_event("pain", 0.5)
	# Burst particles on hit
	var burst_count := int(clampf(actual_amount / 5.0, 4, 14))
	_spawn_hit_burst("hit", burst_count)

	# Lifesteal — heal the source
	if source != null and is_instance_valid(source) \
		and source.has_method("heal") and source != self:
		var steal: float = source.lifesteal_pct
		if steal > 0.0:
			source.heal(actual_amount * steal)

	# Spike armor reflect
	if spike_armor_timer > 0.0 and source != null \
		and is_instance_valid(source) and source.has_method("take_damage") \
		and source != self:
		source.take_damage(amount)

	# Poison from source's passive
	if source != null and is_instance_valid(source) and source != self:
		var src_poison: float = source.poison_pct
		if src_poison > 0.0:
			_apply_poison_dot(amount * src_poison, source.poison_slow)

	# Lightning Strike passive — slow on any damage dealt
	if source != null and is_instance_valid(source) and source != self:
		var src_lightning: float = source.lightning_slow_duration
		if src_lightning > 0.0:
			apply_slow(src_lightning)
			_spawn_hit_burst("electric", 4)

	# Vibration on damage
	var dmg_intensity := clampf(actual_amount / 50.0, 0.1, 1.0)
	vibrate(dmg_intensity * 0.3, dmg_intensity * 0.6, 0.15)

	if hp <= 0.0:
		hp = 0.0
		# Killer gets an "angry" face flash on landing the kill
		if source != null and is_instance_valid(source) and source != self \
				and source.has_method("trigger_face_event"):
			source.trigger_face_event("angry", 1.5)
		die()


func is_parrying() -> bool:
	return parry_timer > 0.0


func on_parry_reflect() -> void:
	## Called when a projectile is reflected by parry.
	parry_timer = 0.0
	SoundManager.play_whip()
	_add_vfx("shield_flash", 0.3)
	vibrate(0.5, 0.8, 0.2)
	_parry_detach_grapples()
	if shockwave_radius_mult > 0.0:
		_do_shockwave()


func _parry_detach_grapples() -> void:
	## Detach any grapple hooks that other players have attached to us.
	for p in get_tree().get_nodes_in_group("players"):
		if p == self or not p.is_alive:
			continue
		if p.grapple_target_player == self:
			p._release_grapple()
			p._spawn_hit_burst("electric", 6)


func _do_shockwave() -> void:
	## Push all nearby enemies away without damage.
	var push_radius := get_player_radius() * 2.5 * shockwave_radius_mult
	_add_vfx("bomb_ring", 0.3, {
		"pos": global_position, "radius": push_radius})
	SoundManager.play_explosion()
	for p in get_tree().get_nodes_in_group("players"):
		if p == self or not p.is_alive:
			continue
		var diff: Vector2 = p.global_position - global_position
		if diff.length() < push_radius and diff.length() > 0.1:
			var force := 800.0 * shockwave_radius_mult
			p.apply_knockback(
				diff.normalized() * force + Vector2.UP * 200.0)
			p._spawn_hit_burst("electric", 5)


func vibrate(weak: float, strong: float, duration: float = 0.2) -> void:
	if not GameManager.vibration_enabled:
		return
	var dev: int = InputManager.player_devices[player_id - 1]
	if dev >= 0:
		Input.start_joy_vibration(dev, weak, strong, duration)


func heal(amount: float) -> void:
	if not is_alive:
		return
	hp = minf(hp + amount, MAX_HP)


func _apply_poison_dot(total_damage: float, slow_dur: float) -> void:
	# Apply slow if legendary poison
	if slow_dur > 0.0:
		apply_slow(slow_dur)
	# Tick damage over 2 seconds
	var ticks := 4
	var per_tick := total_damage / ticks
	_run_poison_dot(per_tick, ticks)


func _run_poison_dot(per_tick: float, ticks: int) -> void:
	set_meta("poison_active", true)
	for _i in range(ticks):
		await get_tree().create_timer(0.5).timeout
		if not is_alive:
			remove_meta("poison_active")
			return
		hp -= per_tick
		hit_flash_timer = 0.05
		_spawn_hit_burst("poison", 5)
		if hp <= 0.0:
			hp = 0.0
			remove_meta("poison_active")
			die()
			return
	remove_meta("poison_active")


func apply_knockback(force: Vector2) -> void:
	if is_invincible or shield_timer > 0.0:
		return
	if is_grappling:
		_release_grapple()
	velocity += force


func apply_slow(duration: float) -> void:
	if is_invincible:
		return
	slow_timer = duration


# Read per-map physics tweaks. Falls back to defaults if no map is loaded.
func _map_gravity_mult() -> float:
	var game := get_tree().current_scene
	if game == null or not "current_map" in game or game.current_map == null:
		return 1.0
	var m: Node2D = game.current_map
	if "gravity_multiplier" in m:
		return m.gravity_multiplier
	return 1.0


func _map_floor_friction_mult() -> float:
	var game := get_tree().current_scene
	if game == null or not "current_map" in game or game.current_map == null:
		return 1.0
	var m: Node2D = game.current_map
	if "floor_friction_mult" in m:
		return m.floor_friction_mult
	return 1.0


func apply_stun(duration: float) -> void:
	if is_invincible:
		return
	stun_timer = duration
	_spawn_hit_burst("electric", 10)
	if is_grappling:
		_release_grapple()


func _check_bounds() -> void:
	# Find current map via game scene
	var game := get_tree().current_scene
	if game == null or not "current_map" in game or game.current_map == null:
		return
	var m: Node2D = game.current_map

	# Don't kill invincible players (spawn protection, swap, phoenix)
	if is_invincible:
		danger_timer = 0.0
		in_danger = false
		# But clamp position to prevent flying way off map
		if m.has_method("is_past_kill_zone") \
			and m.is_past_kill_zone(global_position):
			var safe: Rect2 = m.get_safe_rect()
			global_position.x = clampf(global_position.x,
				safe.position.x, safe.end.x)
			global_position.y = clampf(global_position.y,
				safe.position.y, safe.end.y)
			velocity = Vector2.ZERO
		return

	# Instant death if way past kill zone
	if m.has_method("is_past_kill_zone") \
		and m.is_past_kill_zone(global_position):
		die()
		return

	# Danger zone timer
	if m.has_method("is_in_danger_zone") \
		and m.is_in_danger_zone(global_position):
		in_danger = true
		danger_timer += get_physics_process_delta_time()
		if danger_timer >= DANGER_ZONE_TIME:
			die()
	else:
		in_danger = false
		danger_timer = 0.0


func die() -> void:
	if not is_alive:
		return

	# Phoenix: use extra life instead of dying
	if extra_lives > 0:
		extra_lives -= 1
		SoundManager.play_blink()
		vibrate(0.5, 0.7, 0.3)

		# Reset ALL negative effects — full HP
		hp = MAX_HP
		velocity = Vector2.ZERO
		stun_timer = 0.0
		slow_timer = 0.0
		if has_meta("fire_burning"):
			remove_meta("fire_burning")
		if has_meta("poison_active"):
			remove_meta("poison_active")
		burn_particles.clear()
		poison_particles.clear()
		electric_particles.clear()
		hit_particles.clear()
		speed_multiplier = 1.0
		grab_stun_timer = 0.0
		is_grabbed = false
		danger_timer = 0.0
		in_danger = false
		dash_timer = 0.0
		parry_timer = 0.0
		hit_flash_timer = 0.0
		if is_grappling:
			_release_grapple()

		# Invincibility for 2 seconds + wings animation
		invincible_timer = 2.5
		is_invincible = true
		spawn_anim_timer = 2.0  # angel wings for 2 seconds
		danger_timer = 0.0
		in_danger = false

		# Respawn at custom spawn point if set, otherwise default spawn
		if has_custom_spawn:
			global_position = custom_spawn_point
			has_custom_spawn = false
		else:
			# If in danger zone — teleport to default spawn point
			var game := get_tree().current_scene
			if game != null and "current_map" in game \
				and game.current_map != null:
				if game.current_map.is_in_danger_zone(global_position) \
					or game.current_map.is_past_kill_zone(global_position):
					global_position = GameManager.spawn_points[player_id - 1]

		# Allow setting new spawn point if more lives remain
		if extra_lives <= 0:
			spawn_point_used_this_life = true

		_spawn_dust(8)
		return

	is_alive = false
	is_grappling = false
	grapple_shooting = false
	grapple_retracting = false
	grapple_target_player = null
	visible = false
	# Hard-disable all collision so corpse can't be stood on, blocked
	# against, or grappled to. Set both layer/mask AND the shape disabled
	# directly (not deferred) so neighbours stop seeing this body now.
	collision_layer = 0
	collision_mask = 0
	var col_shape: CollisionShape2D = $CollisionShape2D
	col_shape.disabled = true
	# Move the corpse far off-map so nothing can interact with it visually
	# during round end (bullets, raycasts).
	global_position = Vector2(-99999, -99999)
	velocity = Vector2.ZERO
	set_physics_process(false)
	SoundManager.play_death()
	vibrate(0.8, 1.0, 0.4)  # strong vibration on death
	# Screen shake on death
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(8.0)
	var fx: Node2D = _death_effect_scene.instantiate()
	fx.setup(player_color, global_position)
	get_tree().current_scene.add_child(fx)
	# Drop one random ability pickup on death
	var pickup_scn: PackedScene = preload("res://scenes/characters/ability_pickup.tscn")
	var drop_slot: int = randi_range(0, 1)
	var drop: Area2D = pickup_scn.instantiate()
	var drop_vel := Vector2(randf_range(-200, 200), randf_range(-400, -200))
	drop.setup_dropped(ability_ids[drop_slot], global_position, drop_vel)
	drop.add_to_group("pickups")
	get_tree().current_scene.add_child(drop)
	died.emit(player_id)
	GameManager.player_died(player_id)


func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	is_alive = true
	visible = false  # hidden during spawn animation
	is_invincible = true
	# Restore collision (cleared in die())
	collision_layer = 3
	collision_mask = 3
	$CollisionShape2D.disabled = false

	# Reset ALL state
	is_grappling = false
	grapple_shooting = false
	grapple_retracting = false
	grapple_target_player = null
	grapple_target_body = null
	grapple_local_point = Vector2.ZERO
	stun_timer = 0.0
	slow_timer = 0.0
	speed_multiplier = 1.0
	aim_direction = Vector2.RIGHT
	jump_hold_timer = 0.0
	jump_used = false
	coyote_timer = 0.0
	is_wall_sliding = false
	dash_timer = 0.0
	shield_timer = 0.0
	charge_slot = -1
	charge_timer = 0.0
	spike_armor_timer = 0.0
	spike_anim = 0.0
	spike_contact_cds.clear()
	guided_rocket_ref = null
	guided_rocket_slot = -1
	tripwire_node = null
	portal_gate_pos = Vector2.ZERO
	has_portal_gate = false
	ability_entity_count.clear()
	grabbed_player = null
	grab_slot = -1
	grab_hold_timer = 0.0
	grab_hook_timer = 0.0
	grab_stun_timer = 0.0
	is_grabbed = false
	danger_timer = 0.0
	in_danger = false
	parry_timer = 0.0
	parry_cooldown = 0.0
	parry_visual = 0.0
	has_custom_spawn = false
	custom_spawn_point = Vector2.ZERO
	spawn_point_used_this_life = false
	squash_x = 1.0
	squash_y = 1.0
	body_rotation = 0.0
	hit_flash_timer = 0.0
	dust_particles.clear()
	burn_particles.clear()
	poison_particles.clear()
	electric_particles.clear()
	hit_particles.clear()
	speed_trail.clear()
	vfx.clear()
	if has_meta("fire_burning"):
		remove_meta("fire_burning")
	if has_meta("poison_active"):
		remove_meta("poison_active")

	# Apply passives FIRST to set correct MAX_HP
	_apply_passives()
	# Force HP to full MAX_HP
	hp = MAX_HP
	invincible_timer = GameManager.SPAWN_INVINCIBILITY + 2.0

	# No transform-based animation — use VFX spawn effect instead
	scale = Vector2(1.0, 1.0)
	rotation = 0.0
	visible = true
	spawn_anim_timer = 2.0  # 2 second spawn animation
	set_physics_process(true)
	SoundManager.play_blink()


func add_passive(passive_id: int, rarity: int) -> void:
	passives.append({"passive_id": passive_id, "rarity": rarity})
	_apply_passives()


func _apply_passives() -> void:
	## Recalculate all passive modifiers from scratch
	MAX_HP = GameManager.max_hp
	base_speed_mult = 1.0
	damage_multiplier = 1.0
	cd_multiplier = 1.0
	lifesteal_pct = 0.0
	poison_pct = 0.0
	poison_slow = 0.0
	extra_lives = 0
	grapple_range_mult = 1.0
	grapple_speed_mult = 1.0
	radius_multiplier = 1.0
	fire_thread_active = false
	fire_burn_damage = 0.0
	ricochet_bounces = 0
	projectile_speed_mult = 1.0
	regen_per_sec = 0.0
	damage_reduction = 0.0
	shockwave_radius_mult = 0.0
	lightning_slow_duration = 0.0
	collision_force_mult = 1.0
	homing_strength = 0.0
	burst_count = 0
	luck_bonus = 0.0
	spirit_burst_count = 0
	spirit_burst_damage = 0.0
	parry_cd_multiplier = 1.0
	parry_burst_count = 0
	phase_shot = false
	cd_flat = 0.0

	for p in passives:
		var pid: int = p["passive_id"]
		var rar: int = p["rarity"]
		var pdata: Dictionary = PassiveRegistry.get_data(pid)
		var rdata: Dictionary = pdata["rarities"][rar]

		# Universal modifiers that any passive can have
		if rdata.has("hp_multiplier"):
			MAX_HP *= rdata["hp_multiplier"]
		if rdata.has("speed_multiplier"):
			base_speed_mult *= rdata["speed_multiplier"]
		if rdata.has("damage_multiplier"):
			damage_multiplier *= rdata["damage_multiplier"]
		if rdata.has("cd_multiplier"):
			cd_multiplier *= rdata["cd_multiplier"]

		# Flat additions (applied after multipliers)
		if rdata.has("hp_flat"):
			MAX_HP += rdata["hp_flat"]
		if rdata.has("damage_flat"):
			damage_multiplier += rdata["damage_flat"]
		if rdata.has("speed_flat"):
			base_speed_mult += rdata["speed_flat"]

		# Passive-specific modifiers
		match pid:
			PassiveRegistry.PassiveId.POISON_PROJECTILE:
				poison_pct += rdata.get("poison_pct", 0.0)
				poison_slow = maxf(poison_slow, rdata.get("slow_duration", 0.0))

			PassiveRegistry.PassiveId.PHOENIX:
				extra_lives += rdata.get("extra_lives", 0)
				var penalty: float = rdata.get("hp_penalty", 0.0)
				MAX_HP *= (1.0 - penalty)

			PassiveRegistry.PassiveId.LIFESTEAL:
				lifesteal_pct += rdata.get("lifesteal_pct", 0.0)

			PassiveRegistry.PassiveId.THREAD_MASTER:
				grapple_range_mult *= rdata.get("grapple_range_mult", 1.0)
				grapple_speed_mult *= rdata.get("grapple_speed_mult", 1.0)

			PassiveRegistry.PassiveId.WIDE_IMPACT:
				radius_multiplier *= rdata.get("radius_multiplier", 1.0)

			PassiveRegistry.PassiveId.QUICK_HANDS:
				pass  # cd_multiplier already handled above

			PassiveRegistry.PassiveId.FIRE_THREAD:
				fire_thread_active = true
				fire_burn_damage = rdata.get("burn_damage", 12.0)
				fire_burn_tick = rdata.get("burn_tick", 0.5)
				fire_burn_duration = rdata.get("burn_duration", 2.0)

			PassiveRegistry.PassiveId.RICOCHET:
				ricochet_bounces += rdata.get("bounce_count", 0)
				projectile_speed_mult *= rdata.get("projectile_speed_mult", 1.0)

			PassiveRegistry.PassiveId.REGENERATION:
				regen_per_sec += rdata.get("regen_per_sec", 0.0)

			PassiveRegistry.PassiveId.EXPLOSIVE_POWER:
				pass  # radius + damage handled by universal modifiers

			PassiveRegistry.PassiveId.SWIFT_FEET:
				pass  # speed + grapple handled by universal modifiers

			PassiveRegistry.PassiveId.PROJECTILE_MASTER:
				if rdata.has("projectile_speed_mult"):
					projectile_speed_mult *= rdata["projectile_speed_mult"]

			PassiveRegistry.PassiveId.GLASS_CANNON:
				pass  # damage + hp handled by universal modifiers

			PassiveRegistry.PassiveId.IRON_SKIN:
				damage_reduction = clampf(
					damage_reduction + rdata.get("damage_reduction", 0.0),
					0.0, 0.8  # cap at 80%
				)

			PassiveRegistry.PassiveId.SHOCKWAVE:
				shockwave_radius_mult = maxf(shockwave_radius_mult,
					rdata.get("radius_mult", 1.0))

			PassiveRegistry.PassiveId.LIGHTNING_STRIKE:
				lightning_slow_duration = maxf(lightning_slow_duration,
					rdata.get("slow_duration", 0.3))

			PassiveRegistry.PassiveId.HEAVY_IMPACT:
				collision_force_mult *= rdata.get("collision_mult", 1.5)

			PassiveRegistry.PassiveId.HOMING_PROJECTILES:
				homing_strength = maxf(homing_strength,
					rdata.get("homing_strength", 0.0))

			PassiveRegistry.PassiveId.BURST_FIRE:
				burst_count += rdata.get("burst_count", 0)

			PassiveRegistry.PassiveId.LUCKY_STAR:
				luck_bonus = minf(luck_bonus + rdata.get("luck_bonus", 0.0), 50.0)

			PassiveRegistry.PassiveId.SPIRIT_BURST:
				spirit_burst_count += 1
				spirit_burst_damage += rdata.get("essence_damage", 18.0)

			PassiveRegistry.PassiveId.SHIELD_MASTERY:
				parry_cd_multiplier *= rdata.get("parry_cd_mult", 1.0)

			PassiveRegistry.PassiveId.PARRY_BURST:
				parry_burst_count += rdata.get("burst_count", 0)

			PassiveRegistry.PassiveId.PHASE_SHOT:
				phase_shot = true

	hp = minf(hp, MAX_HP)


# ══════════════════ DRAWING ══════════════════

func _draw() -> void:
	if not is_alive:
		return
	if is_invincible and fmod(invincible_timer, 0.2) < 0.1:
		return

	# Dust particles (drawn in world space, offset from player)
	for particle in dust_particles:
		var p_pos: Vector2 = particle["pos"] - global_position
		var life_ratio: float = particle["life"] / particle["max_life"]
		var alpha := life_ratio * 0.6
		var size := 3.0 + (1.0 - life_ratio) * 2.0
		draw_circle(p_pos, size, Color(0.7, 0.65, 0.5, alpha))

	# Burn particles — fire rising from body
	for particle in burn_particles:
		var bp: Vector2 = particle["pos"] - global_position
		var blife: float = particle["life"] / particle["max_life"]
		var bsize: float = particle["size"] * blife
		# Orange → yellow → white gradient based on life
		var fire_col := Color(1.0, 0.3 + blife * 0.3, 0.05, blife * 0.8)
		if blife < 0.4:
			fire_col = Color(0.9, 0.7, 0.1, blife * 0.6)
		draw_circle(bp, bsize, fire_col)

	# Poison particles — green bubbles
	for particle in poison_particles:
		var pp: Vector2 = particle["pos"] - global_position
		var plife: float = particle["life"] / particle["max_life"]
		var psize: float = particle["size"] * (0.5 + plife * 0.5)
		draw_circle(pp, psize, Color(0.2, 0.9, 0.15, plife * 0.7))
		draw_circle(pp, psize * 0.5, Color(0.4, 1.0, 0.3, plife * 0.4))

	# Electric particles — lightning bolts while stunned
	for particle in electric_particles:
		var ep0: Vector2 = particle["pos"] - global_position
		var ep1: Vector2 = particle["end"] - global_position
		var elife: float = particle["life"] / particle["max_life"]
		var ecol := Color(0.4, 0.85, 1.0, elife)
		# Draw zigzag bolt with 3 segments
		var mid1 := ep0.lerp(ep1, 0.33) + Vector2(
			randf_range(-8, 8), randf_range(-8, 8))
		var mid2 := ep0.lerp(ep1, 0.66) + Vector2(
			randf_range(-8, 8), randf_range(-8, 8))
		draw_line(ep0, mid1, ecol, 2.0)
		draw_line(mid1, mid2, ecol, 1.5)
		draw_line(mid2, ep1, ecol, 1.0)
		# Glow dot at start
		draw_circle(ep0, 2.5 * elife, Color(0.7, 0.95, 1.0, elife * 0.6))

	# Hit burst particles — colored sparks on damage
	for particle in hit_particles:
		var hp_pos: Vector2 = particle["pos"] - global_position
		var hlife: float = particle["life"] / particle["max_life"]
		var hsize: float = particle["size"] * hlife
		var hcol: Color = particle["color"]
		hcol.a = hlife * 0.9
		draw_circle(hp_pos, hsize, hcol)

	var base_color := player_color
	if has_meta("fire_burning"):
		base_color = base_color.lerp(Color(1.0, 0.4, 0.1), 0.25)
	if has_meta("poison_active"):
		base_color = base_color.lerp(Color(0.3, 0.8, 0.2), 0.25)
	if stun_timer > 0.0:
		base_color = base_color.lerp(Color(0.5, 0.8, 1.0), 0.35)
	if slow_timer > 0.0:
		base_color = base_color.lerp(Color(0.5, 0.5, 0.7), 0.4)
	if stun_timer > 0.0:
		base_color = base_color.lerp(Color.WHITE, 0.5)
	if hit_flash_timer > 0.0:
		base_color = base_color.lerp(Color.WHITE, 0.7)

	# Spawn animation — angel wings + glow
	if spawn_anim_timer > 0.0:
		var spawn_r := get_player_radius()
		var st := spawn_anim_timer
		var sa := 2.0 - st  # 0 → 2 progress
		var wing_alpha := clampf(st / 1.0, 0.0, 0.8)
		var wing_size := 30.0 + sa * 15.0
		var wing_flap := sin(sa * 8.0) * 0.3 + 0.7

		# Glow circle
		draw_circle(Vector2.ZERO, spawn_r * 1.5 * wing_alpha,
			Color(1, 1, 0.8, wing_alpha * 0.1))

		# Left wing
		var lw_pts := PackedVector2Array([
			Vector2(-spawn_r * 0.5, -spawn_r * 0.2),
			Vector2(-spawn_r - wing_size * wing_flap, -spawn_r * 0.8 - wing_size * 0.5),
			Vector2(-spawn_r - wing_size * 0.6, -spawn_r * 0.1),
			Vector2(-spawn_r * 0.7, spawn_r * 0.3),
		])
		draw_colored_polygon(lw_pts, Color(1, 1, 1, wing_alpha * 0.35))
		for fi in range(3):
			var ft := float(fi) / 3.0
			var f_start := Vector2(-spawn_r * 0.5, -spawn_r * 0.2).lerp(
				Vector2(-spawn_r - wing_size * wing_flap, -spawn_r * 0.8 - wing_size * 0.5), ft
			)
			draw_line(f_start, f_start + Vector2(-5, 10), Color(1, 1, 1, wing_alpha * 0.2), 1.0)

		# Right wing (mirror)
		var rw_pts := PackedVector2Array([
			Vector2(spawn_r * 0.5, -spawn_r * 0.2),
			Vector2(spawn_r + wing_size * wing_flap, -spawn_r * 0.8 - wing_size * 0.5),
			Vector2(spawn_r + wing_size * 0.6, -spawn_r * 0.1),
			Vector2(spawn_r * 0.7, spawn_r * 0.3),
		])
		draw_colored_polygon(rw_pts, Color(1, 1, 1, wing_alpha * 0.35))
		for fi in range(3):
			var ft := float(fi) / 3.0
			var f_start := Vector2(spawn_r * 0.5, -spawn_r * 0.2).lerp(
				Vector2(spawn_r + wing_size * wing_flap, -spawn_r * 0.8 - wing_size * 0.5), ft
			)
			draw_line(f_start, f_start + Vector2(5, 10), Color(1, 1, 1, wing_alpha * 0.2), 1.0)

		# Halo above head
		var halo_y := -spawn_r - 12.0
		draw_arc(Vector2(0, halo_y), 10.0, 0.0, TAU, 12,
			Color(1, 0.95, 0.6, wing_alpha * 0.4), 2.0)

		# Sparkles
		for si in range(6):
			var spark_angle := sa * 3.0 + si * TAU / 6.0
			var spark_r := spawn_r * 1.8 * wing_alpha
			var spark_pos := Vector2(cos(spark_angle) * spark_r,
				sin(spark_angle) * spark_r)
			draw_circle(spark_pos, 2.5 * wing_alpha,
				Color(1, 1, 0.7, wing_alpha * 0.5))

	# Speed trail (afterimages)
	if speed_trail.size() > 1:
		for ti in range(speed_trail.size()):
			var trail_pos: Vector2 = speed_trail[ti] - global_position
			var t := 1.0 - float(ti) / TRAIL_MAX_POINTS
			var trail_r := get_player_radius() * t * 0.7
			var trail_alpha := t * 0.2
			draw_circle(trail_pos, trail_r,
				Color(base_color.r, base_color.g, base_color.b, trail_alpha))

	# Grapple rope / shooting hook (per-player color)
	var rope_col := player_color.lerp(Color(0.7, 0.55, 0.35), 0.3)
	var rope_active := false
	var rope_end := Vector2.ZERO
	if is_grappling:
		rope_end = grapple_point - global_position
		draw_line(Vector2.ZERO, rope_end, rope_col, 2.5)
		draw_circle(rope_end, 5.0, rope_col)
		draw_circle(rope_end, 3.0, rope_col.lightened(0.3))
		rope_active = true
	elif grapple_shooting or grapple_retracting:
		rope_end = grapple_tip - global_position
		draw_line(Vector2.ZERO, rope_end, rope_col, 2.0)
		draw_circle(rope_end, 5.0, rope_col)
		draw_circle(rope_end, 3.0, rope_col.lightened(0.3))
		rope_active = true

	# Fire Thread glow on rope
	if rope_active and fire_thread_active:
		var seg_count := 8
		var t_phase := float(Engine.get_physics_frames()) * 0.1
		for si in range(seg_count):
			var t0 := float(si) / seg_count
			var t1 := float(si + 1) / seg_count
			var p0 := rope_end * t0
			var p1 := rope_end * t1
			var glow := 0.4 + 0.3 * sin(t_phase + si * 1.2)
			draw_line(p0, p1, Color(1.0, 0.5, 0.05, glow), 4.0)
			# Small flame at midpoint
			var mid := (p0 + p1) * 0.5
			var flicker := sin(t_phase * 3.0 + si * 2.0) * 4.0
			draw_circle(mid + Vector2(0, flicker - 3.0),
				2.5 + glow, Color(1.0, 0.7, 0.1, glow * 0.5))

	# Parry sphere
	if parry_visual > 0.0:
		var pv := parry_visual / 0.3
		var parry_r := get_player_radius() + 12.0 * pv
		draw_arc(Vector2.ZERO, parry_r, 0.0, TAU, 20,
			Color(1, 1, 1, pv * 0.5), 3.0 * pv)
		draw_circle(Vector2.ZERO, parry_r,
			Color(1, 1, 1, pv * 0.1))

	# Shield
	if shield_timer > 0.0:
		var sa := 0.2 + 0.15 * sin(shield_timer * 10.0)
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 32, Color(0.9, 0.9, 0.4, sa), 3.0)
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 32, Color(1.0, 1.0, 0.6, sa * 0.5), 1.5)

	# Spike armor visual — animated spikes
	if spike_anim > 0.01:
		var sa_cfg := AbilityRegistry.get_data(AbilityRegistry.SPIKE_ARMOR)
		var spike_n: int = sa_cfg.get("spike_count", 8)
		var spike_len := 18.0 * spike_anim
		var spike_w := 4.0 * spike_anim
		var time := float(Engine.get_physics_frames()) * 0.02
		var rot_offset := time * 1.5 if spike_armor_timer > 0.0 else 0.0
		var spike_col := Color(0.85, 0.85, 0.85)
		if spike_armor_timer <= 0.0:
			spike_col.a = spike_anim  # fade out
		for si in range(spike_n):
			var angle := float(si) * TAU / spike_n + rot_offset
			var base := Vector2(cos(angle), sin(angle)) * (get_player_radius() - 2)
			var tip := Vector2(cos(angle), sin(angle)) * (get_player_radius() + spike_len)
			var perp := Vector2(-sin(angle), cos(angle))
			var p1 := base + perp * spike_w
			var p2 := base - perp * spike_w
			draw_colored_polygon(
				PackedVector2Array([p1, tip, p2]),
				spike_col
			)
			# Spike edge
			draw_line(p1, tip, spike_col.darkened(0.3), 1.0)
			draw_line(p2, tip, spike_col.darkened(0.3), 1.0)

	# Spin visual
	if spin_visual_timer > 0.0:
		var t := 1.0 - spin_visual_timer / 0.2
		var spin_col := Color(1.0, 0.8, 0.2, 0.5 * (1.0 - t))
		draw_arc(Vector2.ZERO, 30.0 + t * 30.0, 0.0, TAU, 24, spin_col, 4.0)

	# Crosshair (gamepad only)
	if player_id != 1:
		_draw_crosshair()

	# Body and eyes are drawn by Sprite2D nodes via _update_visual_sprites().
	# Below variables are still needed by trailing draws (whip, grab hook, etc.).
	var r := get_player_radius()
	var s := hp_scale
	var dark := base_color.darkened(0.3)
	# Trailing yarn threads when moving fast — keep this decorative bit
	if velocity.length() > 200.0:
		var move_dir := -velocity.normalized()
		for ti in range(3):
			var ta := run_phase * 2.0 + ti * 2.0
			var thread_end := move_dir * (15.0 + ti * 8.0) * s
			thread_end += Vector2(sin(ta) * 4.0, cos(ta * 1.3) * 4.0)
			draw_line(
				move_dir * r * 0.5,
				thread_end,
				Color(dark.r, dark.g, dark.b, 0.4), 1.5 * s
			)

	# Whip visual — sweeping arc
	if whip_visual_timer > 0.0:
		var wt := whip_visual_timer / 0.15
		var base_angle := whip_visual_dir.angle()
		var sweep := (1.0 - wt) * 0.8  # arc sweeps over time
		for wi in range(5):
			var wa := base_angle - 0.4 + sweep + wi * 0.15
			var w_start := Vector2(cos(wa), sin(wa)) * r
			var w_end := Vector2(cos(wa), sin(wa)) * 90.0
			var w_alpha := wt * (1.0 - float(wi) * 0.15)
			draw_line(w_start, w_end, Color(dark.r, dark.g, dark.b, w_alpha), 3.0 - wi * 0.4)

	# Grab hook animation — big hook swings from top to bottom
	if grab_hook_timer > 0.0:
		var grab_dur := 0.35
		var ght := grab_hook_timer / grab_dur
		var hook_alpha := minf(ght * 2.0, 1.0)
		var hook_col := Color(player_color.r, player_color.g,
			player_color.b, hook_alpha)
		var dark_col := Color(dark.r, dark.g, dark.b, hook_alpha)
		# Hook size = 2.5x player radius — big and visible
		var hook_size := r * 2.5
		var side := 1.0 if facing_right else -1.0
		var swing_t := 1.0 - ght  # 0→1 over animation
		var swing_angle := lerpf(-PI * 0.6, PI * 0.5, swing_t) * side
		# Pivot in front of player
		var pivot := Vector2(side * r * 0.4, -r * 0.3)
		# Handle
		var handle_len := hook_size * 0.5
		var handle_dir := Vector2(cos(swing_angle), sin(swing_angle))
		var handle_end := pivot + handle_dir * handle_len
		draw_line(pivot, handle_end, hook_col, 5.0)
		# Thick curved claw
		var claw_len := hook_size * 0.6
		var claw_perp := Vector2(-handle_dir.y, handle_dir.x) * side
		var claw_p1 := handle_end + handle_dir * claw_len * 0.25 \
			+ claw_perp * claw_len * 0.5
		var claw_p2 := handle_end + handle_dir * claw_len * 0.5 \
			+ claw_perp * claw_len * 0.35
		var claw_p3 := handle_end + handle_dir * claw_len * 0.45 \
			+ claw_perp * claw_len * 0.05
		draw_line(handle_end, claw_p1, dark_col, 6.0)
		draw_line(claw_p1, claw_p2, dark_col, 5.0)
		draw_line(claw_p2, claw_p3, dark_col, 4.0)
		# Sharp tip
		draw_line(claw_p3, claw_p3 + handle_dir * 4.0, dark_col, 2.5)
		# Inner barb
		var barb := handle_end + handle_dir * claw_len * 0.12 \
			+ claw_perp * claw_len * 0.22
		draw_line(handle_end + handle_dir * claw_len * 0.08,
			barb, dark_col, 3.5)
		# Metallic shine
		draw_circle(handle_end, 4.0,
			Color(0.95, 0.95, 0.95, hook_alpha * 0.7))
		draw_circle(claw_p1, 2.5,
			Color(0.9, 0.9, 0.9, hook_alpha * 0.4))

	# Grab hold visual — thread connecting grabber to grabbed player
	if grabbed_player != null and is_instance_valid(grabbed_player) \
		and grabbed_player.is_alive:
		var grab_to: Vector2 = grabbed_player.global_position - global_position
		var time_val := float(Engine.get_physics_frames()) * 0.15
		var gc := player_color.darkened(0.2)
		# Wavy thread with 4 segments
		var prev_pt := Vector2.ZERO
		for gi in range(5):
			var gt := float(gi) / 4.0
			var pt := grab_to * gt
			if gi > 0 and gi < 4:
				var wave := sin(time_val + gi * 2.0) * 6.0
				var perp := Vector2(-grab_to.y, grab_to.x).normalized()
				pt += perp * wave
			draw_line(prev_pt, pt, gc, 2.5)
			prev_pt = pt
		# Grab indicator ring around grabbed player
		var pulse := 0.4 + 0.2 * sin(time_val * 3.0)
		var gr_r: float = grabbed_player.get_player_radius() + 4.0
		draw_arc(grab_to, gr_r, 0.0, TAU, 16,
			Color(gc.r, gc.g, gc.b, pulse), 2.0)

	# Portal Gate marker (drawn in world space)
	if has_portal_gate:
		var pg: Vector2 = portal_gate_pos - global_position
		var pg_time := float(Engine.get_physics_frames()) * 0.03
		var pg_pulse := 0.5 + 0.2 * sin(pg_time * 4.0)
		var pg_col := Color(0.5, 0.2, 0.9, pg_pulse)
		# Outer ring
		draw_arc(pg, 100.0, 0.0, TAU, 20, pg_col, 2.5)
		# Inner rotating arcs
		for pi in range(3):
			var arc_s := pg_time * 2.0 + pi * TAU / 3.0
			draw_arc(pg, 60.0, arc_s, arc_s + 1.0, 8,
				Color(0.6, 0.3, 1.0, pg_pulse * 0.6), 2.0)
		# Center dot
		draw_circle(pg, 8.0, Color(0.5, 0.2, 0.9, pg_pulse * 0.4))
		# Sparkles
		for pi in range(6):
			var sa := pg_time * 1.5 + pi * TAU / 6.0
			var sd := 70.0 + sin(pg_time + pi) * 20.0
			draw_circle(pg + Vector2(cos(sa) * sd, sin(sa) * sd),
				2.5, Color(0.7, 0.4, 1.0, pg_pulse * 0.5))

	# Custom spawn point marker (drawn in world space)
	if has_custom_spawn:
		var sp: Vector2 = custom_spawn_point - global_position
		var sp_time := float(Engine.get_physics_frames()) * 0.04
		var sp_pulse := 0.4 + 0.2 * sin(sp_time * 3.0)
		var sp_col := Color(player_color.r, player_color.g,
			player_color.b, sp_pulse)
		# Pulsing ring
		draw_arc(sp, 18.0, 0.0, TAU, 16, sp_col, 2.0)
		draw_arc(sp, 10.0, 0.0, TAU, 12,
			Color(1, 1, 1, sp_pulse * 0.5), 1.5)
		# Cross
		draw_line(sp + Vector2(-7, 0), sp + Vector2(7, 0), sp_col, 2.0)
		draw_line(sp + Vector2(0, -7), sp + Vector2(0, 7), sp_col, 2.0)
		# Rising spark
		var spark_y := fmod(sp_time * 20.0, 30.0)
		draw_circle(sp + Vector2(0, -spark_y),
			2.0, Color(1, 1, 1, (1.0 - spark_y / 30.0) * 0.5))

	# VFX effects
	_draw_vfx()

	# Shadow under player when airborne
	if not is_on_floor():
		var shadow_y := 30.0  # relative to player, approximate
		var shadow_alpha := clampf(1.0 - velocity.y / 300.0, 0.1, 0.3)
		draw_ellipse_simple(
			Vector2(0, shadow_y), r * 0.6, 4.0,
			Color(0, 0, 0, shadow_alpha)
		)

	# Danger zone warning
	if in_danger:
		var danger_ratio := clampf(danger_timer / DANGER_ZONE_TIME, 0.0, 1.0)
		var time := float(Engine.get_physics_frames()) * 0.016
		var pulse := sin(time * (8.0 + danger_ratio * 12.0)) * 0.3 + 0.5
		var warn_col := Color(1, 0.1, 0.05, pulse * danger_ratio)
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 16, warn_col, 3.0)
		# Countdown text
		var remaining := DANGER_ZONE_TIME - danger_timer
		if remaining < 1.5:
			var font := ThemeDB.fallback_font
			var txt := "%.1f" % remaining
			var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			draw_string(
				font,
				Vector2(-ts.x / 2.0, -45),
				txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(1, 0.2, 0.1, 0.9)
			)

	# Grenade charge indicator
	if charge_slot >= 0:
		var cfg := AbilityRegistry.get_data(AbilityRegistry.GRENADE)
		var charge_time: float = cfg.get("charge_time", 1.0)
		var overcharge: float = cfg.get("overcharge_time", 2.5)
		var ratio := clampf(charge_timer / charge_time, 0.0, 1.0)
		var danger := clampf(
			(charge_timer - charge_time) / (overcharge - charge_time), 0.0, 1.0
		)
		# Growing ring
		var ring_r := 30.0 + ratio * 15.0
		var ring_col := Color(0.8, 0.6, 0.1, 0.5).lerp(
			Color(1.0, 0.1, 0.05, 0.8), danger
		)
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU * ratio, 24, ring_col, 3.0)
		# Danger pulsing when overcharging
		if charge_timer > charge_time:
			var pulse := sin(charge_timer * 15.0) * 0.3 + 0.3
			draw_arc(
				Vector2.ZERO, ring_r + 5.0, 0.0, TAU,
				16, Color(1, 0.1, 0.05, pulse), 2.0
			)

	_draw_hp_bar()
	_draw_ability_icons()


func _draw_ellipse(
	center: Vector2, rx: float, ry: float, color: Color,
	rot: float = 0.0
) -> void:
	var pts: PackedVector2Array = []
	var segs := 24
	for i in range(segs):
		var a := i * TAU / segs + rot * 0.5
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func draw_ellipse_simple(
	center: Vector2, rx: float, ry: float, color: Color
) -> void:
	var pts: PackedVector2Array = []
	var segs := 16
	for i in range(segs):
		var a := i * TAU / segs
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_crosshair() -> void:
	var ch_pos := aim_direction * CROSSHAIR_DIST
	var s := CROSSHAIR_SIZE
	var col := player_color.lightened(0.3)
	col.a = 0.85
	var outline := Color(0, 0, 0, 0.7)
	# Outline layer (black, thicker)
	draw_arc(ch_pos, s, 0.0, TAU, 20, outline, 4.0)
	draw_line(ch_pos + Vector2(-s * 1.6, 0), ch_pos + Vector2(-s * 0.4, 0), outline, 4.0)
	draw_line(ch_pos + Vector2(s * 0.4, 0), ch_pos + Vector2(s * 1.6, 0), outline, 4.0)
	draw_line(ch_pos + Vector2(0, -s * 1.6), ch_pos + Vector2(0, -s * 0.4), outline, 4.0)
	draw_line(ch_pos + Vector2(0, s * 0.4), ch_pos + Vector2(0, s * 1.6), outline, 4.0)
	draw_circle(ch_pos, 4.0, outline)
	# Color layer on top
	draw_arc(ch_pos, s, 0.0, TAU, 20, col, 2.0)
	draw_line(ch_pos + Vector2(-s * 1.6, 0), ch_pos + Vector2(-s * 0.4, 0), col, 2.0)
	draw_line(ch_pos + Vector2(s * 0.4, 0), ch_pos + Vector2(s * 1.6, 0), col, 2.0)
	draw_line(ch_pos + Vector2(0, -s * 1.6), ch_pos + Vector2(0, -s * 0.4), col, 2.0)
	draw_line(ch_pos + Vector2(0, s * 0.4), ch_pos + Vector2(0, s * 1.6), col, 2.0)
	draw_circle(ch_pos, 2.5, col)


func _draw_hp_bar() -> void:
	var w := 40.0 * hp_scale
	var h := 5.0
	var y := -(get_player_radius() + 14.0) * squash_y
	var bg := Rect2(-w / 2.0, y, w, h)
	draw_rect(bg, Color(0.2, 0.2, 0.2, 0.8))
	var ratio := hp / MAX_HP
	var hc := Color(0.2, 0.8, 0.2)
	if ratio < 0.3:
		hc = Color(0.9, 0.2, 0.2)
	elif ratio < 0.6:
		hc = Color(0.9, 0.7, 0.1)
	draw_rect(Rect2(-w / 2.0, y, w * ratio, h), hc)
	draw_rect(bg, Color(0.5, 0.5, 0.5, 0.6), false, 1.0)


func _draw_ability_icons() -> void:
	var icon_y := -(get_player_radius() + 40.0) * squash_y
	for i in range(2):
		var x: float = (i * 2 - 1) * (ICON_SPACING / 2.0)
		var center := Vector2(x, icon_y)
		var ab_id: int = ability_ids[i]
		var data: Dictionary = AbilityRegistry.get_data(ab_id)
		var max_cd: float = data["cooldown"]
		var cd_ratio: float = ability_cds[i] / max_cd if max_cd > 0 else 0.0
		var ab_color: Color = data["color"]

		draw_circle(center, ICON_RADIUS, Color(0.15, 0.15, 0.15, 0.7))
		_draw_emblem(ab_id, center, cd_ratio, ab_color)
		if cd_ratio > 0.0:
			_draw_cd_pie(center, ICON_RADIUS, cd_ratio)
		var bc := ab_color if cd_ratio <= 0.0 else Color(0.4, 0.4, 0.4, 0.6)
		draw_arc(center, ICON_RADIUS, 0.0, TAU, 24, bc, 1.5)


func _draw_emblem(
	ab_id: int, c: Vector2, cd_ratio: float, ab_color: Color
) -> void:
	var col := ab_color if cd_ratio <= 0.0 else ab_color.darkened(0.5)
	match ab_id:
		0:  # Yarn Toss
			draw_circle(c + Vector2(2, 0), 4.0, col)
			draw_line(c + Vector2(-6, 2), c + Vector2(-2, 0), col, 1.5)
		1:  # Needle Dash
			draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), col, 2.0)
			draw_line(c + Vector2(3, -4), c + Vector2(6, 0), col, 2.0)
			draw_line(c + Vector2(3, 4), c + Vector2(6, 0), col, 2.0)
		2:  # Yarn Bomb
			draw_circle(c, 4.0, col)
			for j in range(4):
				var a := j * TAU / 4.0 + 0.4
				draw_line(c + Vector2(cos(a), sin(a)) * 4.0,
					c + Vector2(cos(a), sin(a)) * 8.0, col, 1.5)
		3:  # Thread Pull
			draw_line(c + Vector2(-7, 0), c + Vector2(-2, 0), col, 1.5)
			draw_line(c + Vector2(7, 0), c + Vector2(2, 0), col, 1.5)
			draw_circle(c, 2.0, col)
		4:  # Spin Attack
			draw_arc(c, 6.0, 0.0, TAU * 0.75, 12, col, 2.0)
			var tip := c + Vector2(cos(TAU * 0.75), sin(TAU * 0.75)) * 6.0
			draw_circle(tip, 2.0, col)
		5:  # Grenade
			draw_circle(c + Vector2(0, 1), 5.0, col)
			draw_line(c + Vector2(0, -4), c + Vector2(3, -8), col, 2.0)
			draw_circle(c + Vector2(3, -8), 2.0, col.lightened(0.4))
		6:  # Rocket Launcher
			draw_line(c + Vector2(0, 3), c + Vector2(0, -6), col, 2.0)
			draw_line(c + Vector2(0, -6), c + Vector2(-2, -3), col, 1.5)
			draw_line(c + Vector2(0, -6), c + Vector2(2, -3), col, 1.5)
			draw_line(c + Vector2(-5, 3), c + Vector2(-7, -4), col, 1.5)
			draw_line(c + Vector2(5, 3), c + Vector2(7, -4), col, 1.5)
		7:  # Stink Cloud
			draw_circle(c, 5.0, col.darkened(0.2))
			draw_circle(c + Vector2(-4, -3), 3.0, col)
			draw_circle(c + Vector2(4, -2), 3.5, col)
			draw_circle(c + Vector2(0, 3), 3.0, col.darkened(0.1))
		8:  # Spike Armor
			draw_circle(c, 4.0, col.darkened(0.2))
			for si in range(6):
				var sa := si * TAU / 6.0 - PI / 6.0
				draw_line(c + Vector2(cos(sa), sin(sa)) * 4.0,
					c + Vector2(cos(sa), sin(sa)) * 9.0, col, 2.0)
		9:  # Swap
			draw_line(c + Vector2(-6, -4), c + Vector2(6, 4), col, 2.0)
			draw_line(c + Vector2(6, 4), c + Vector2(3, 2), col, 1.5)
			draw_line(c + Vector2(6, 4), c + Vector2(4, 7), col, 1.5)
			draw_line(c + Vector2(6, -4), c + Vector2(-6, 4), col, 2.0)
			draw_line(c + Vector2(-6, 4), c + Vector2(-3, 2), col, 1.5)
			draw_line(c + Vector2(-6, 4), c + Vector2(-4, 7), col, 1.5)
		10:  # Boomerang
			for bi in range(4):
				var ba := bi * PI / 2.0 + 0.3
				draw_line(c, c + Vector2(cos(ba), sin(ba)) * 8.0, col, 2.0)
		11:  # Guided Rocket
			draw_line(c + Vector2(-6, 4), c + Vector2(0, -6), col, 2.0)
			draw_line(c + Vector2(0, -6), c + Vector2(6, 0), col, 2.0)
			draw_circle(c + Vector2(6, 0), 2.5, col)
		12:  # Tripwire
			draw_circle(c + Vector2(-6, 0), 3.0, col)
			draw_circle(c + Vector2(6, 0), 3.0, col)
			draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), col, 1.5)
			draw_line(c + Vector2(-2, -2), c + Vector2(2, 2), col, 1.0)
		13:  # Grab/Throw — hand grabbing
			draw_arc(c, 6.0, -0.5, PI + 0.5, 8, col, 2.0)
			draw_line(c + Vector2(5, -3), c + Vector2(8, -6), col, 2.0)
			draw_line(c + Vector2(5, 3), c + Vector2(8, 6), col, 2.0)
		14:  # Black Hole — spiral vortex
			draw_circle(c, 5.0, col.darkened(0.5))
			draw_arc(c, 7.0, 0.0, TAU * 0.7, 10, col, 2.0)
			draw_arc(c, 4.0, PI, PI + TAU * 0.6, 8, col, 1.5)
		15:  # Portal Gate — two linked circles
			draw_arc(c + Vector2(-4, 0), 4.0, 0.0, TAU, 8, col, 1.5)
			draw_arc(c + Vector2(4, 0), 4.0, 0.0, TAU, 8, col, 1.5)
			draw_line(c + Vector2(-1, -3), c + Vector2(1, 3), col, 1.5)
			draw_line(c + Vector2(1, -3), c + Vector2(-1, 3), col, 1.5)
		16:  # Heaven's Wrath — light pillars
			draw_line(c + Vector2(-5, -8), c + Vector2(-5, 6), col, 2.5)
			draw_line(c + Vector2(0, -6), c + Vector2(0, 8), col, 2.0)
			draw_line(c + Vector2(5, -8), c + Vector2(5, 6), col, 1.5)
			draw_circle(c + Vector2(-5, -8), 2.0, col)
			draw_circle(c + Vector2(5, -8), 1.5, col)


func _draw_cd_pie(center: Vector2, radius: float, ratio: float) -> void:
	var segs := 24
	var span := ratio * TAU
	var start := -PI / 2.0
	var pts: PackedVector2Array = [center]
	for s in range(segs + 1):
		var a := start + (float(s) / segs) * span
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	if pts.size() >= 3:
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))


# ══════════════════ VFX SYSTEM ══════════════════

func _add_vfx(type: String, duration: float, data: Dictionary = {}) -> void:
	data["type"] = type
	data["timer"] = duration
	data["max_time"] = duration
	vfx.append(data)


static var _sprite_effect_scene: PackedScene = preload(
	"res://scenes/effects/sprite_effect.tscn")


func _add_sprite_vfx(
	effect: String, duration: float, pos: Vector2,
	scale_mult: float = 1.0, rotation: float = 0.0,
	modulate: Color = Color.WHITE,
	spin: float = 0.0
) -> void:
	## Spawn a standalone animated sprite VFX node in world space.
	var fx: Node2D = _sprite_effect_scene.instantiate()
	fx.global_position = pos
	get_tree().current_scene.add_child(fx)
	fx.setup(effect, duration, scale_mult, rotation, modulate, spin)


func _draw_vfx() -> void:
	for fx in vfx:
		var t: float = fx["timer"] / fx["max_time"]  # 1→0 over lifetime
		var type: String = fx["type"]
		match type:
			"muzzle_flash":
				_vfx_muzzle_flash(fx, t)
			"bomb_ring":
				_vfx_bomb_ring(fx, t)
			"pull_thread":
				_vfx_pull_thread(fx, t)
			"wall_build":
				_vfx_wall_build(fx, t)
			"blink_ghost":
				_vfx_blink_ghost(fx, t)
			"dash_trail":
				_vfx_dash_trail(fx, t)
			"shield_flash":
				_vfx_shield_flash(fx, t)
			"trap_drop":
				_vfx_trap_drop(fx, t)
			"stink_puff":
				_vfx_stink_puff(fx, t)
			"spin_lines":
				_vfx_spin_lines(fx, t)
			"swap_line":
				_vfx_swap_line(fx, t)


func _vfx_muzzle_flash(fx: Dictionary, t: float) -> void:
	var dir: Vector2 = fx["dir"]
	var col: Color = fx.get("color", player_color)
	var flash_r := 15.0 * t
	draw_circle(dir * 30.0, flash_r, Color(col.r, col.g, col.b, 0.5 * t))
	draw_circle(dir * 30.0, flash_r * 0.5, Color(1, 1, 0.8, 0.6 * t))


func _vfx_bomb_ring(fx: Dictionary, t: float) -> void:
	var offset_pos: Vector2 = fx["pos"] - global_position
	var max_r: float = fx.get("radius", 150.0)
	var expand := (1.0 - t)
	var ring_r := max_r * expand
	var alpha := t * 0.6
	draw_arc(offset_pos, ring_r, 0.0, TAU, 24, Color(1, 0.5, 0.1, alpha), 4.0)
	draw_arc(offset_pos, ring_r * 0.6, 0.0, TAU, 16, Color(1, 0.8, 0.3, alpha * 0.5), 2.0)


func _vfx_pull_thread(fx: Dictionary, t: float) -> void:
	var target_pos: Vector2 = fx["target"] - global_position
	var alpha := t
	var col := Color(player_color.r, player_color.g, player_color.b, alpha)
	# Thread with wave
	var segs := 8
	var prev := Vector2.ZERO
	for s in range(segs + 1):
		var st := float(s) / segs
		var pt := prev.lerp(target_pos, st / float(segs)) if s == 0 \
			else Vector2.ZERO.lerp(target_pos, st)
		# Add wave perpendicular
		var perp := (target_pos.normalized()).rotated(PI / 2.0)
		pt += perp * sin(st * PI * 3.0 + (1.0 - t) * 10.0) * 8.0 * t
		if s > 0:
			draw_line(prev, pt, col, 2.0)
		prev = pt
	# Hook at end
	draw_circle(target_pos, 4.0 * t, col)


func _vfx_wall_build(fx: Dictionary, t: float) -> void:
	var wall_pos: Vector2 = fx["pos"] - global_position
	var w: float = fx.get("w", 20.0)
	var h: float = fx.get("h", 80.0)
	# Rising construction effect
	var build_h := h * (1.0 - t)
	var alpha := t * 0.5
	var col := Color(player_color.r, player_color.g, player_color.b, alpha)
	# Sparkles rising
	for i in range(4):
		var spark_y := wall_pos.y - build_h * float(i) / 4.0
		var spark_x := wall_pos.x + sin(float(i) * 2.0 + (1.0 - t) * 8.0) * w
		draw_circle(Vector2(spark_x, spark_y), 3.0 * t, col)


func _vfx_blink_ghost(fx: Dictionary, t: float) -> void:
	var start_pos: Vector2 = fx["start"] - global_position
	var col := Color(player_color.r, player_color.g, player_color.b, t * 0.4)
	# Ghost afterimage at original position
	draw_circle(start_pos, 24.0 * t, col)
	# Dashed line from start to current
	var segs := 6
	for s in range(segs):
		var st := float(s) / segs
		if s % 2 == 0:
			var p1 := start_pos.lerp(Vector2.ZERO, st)
			var p2 := start_pos.lerp(Vector2.ZERO, st + 1.0 / segs)
			draw_line(p1, p2, col, 2.0)


func _vfx_dash_trail(fx: Dictionary, t: float) -> void:
	var dir: Vector2 = fx["dir"]
	var col := Color(player_color.r, player_color.g, player_color.b, t * 0.3)
	# Series of afterimages behind
	for i in range(4):
		var offset := -dir * float(i + 1) * 25.0 * (1.0 - t)
		var ghost_alpha := t * (1.0 - float(i) * 0.25)
		draw_circle(offset, 20.0 * ghost_alpha,
			Color(col.r, col.g, col.b, ghost_alpha * 0.3))


func _vfx_shield_flash(_fx: Dictionary, t: float) -> void:
	# Bright flash when shield activates
	var alpha := t * 0.6
	draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 20,
		Color(0.9, 0.9, 0.4, alpha), 5.0 * t)
	draw_circle(Vector2.ZERO, 30.0 * t,
		Color(1, 1, 0.8, alpha * 0.3))


func _vfx_trap_drop(fx: Dictionary, t: float) -> void:
	var trap_pos: Vector2 = fx["pos"] - global_position
	var col := Color(0.6, 0.3, 0.7, t * 0.5)
	# Falling web lines
	for i in range(3):
		var lx := trap_pos.x + float(i - 1) * 10.0
		var ly_start := trap_pos.y - 30.0 * t
		draw_line(Vector2(lx, ly_start), Vector2(lx, trap_pos.y),
			col, 1.5)
	# Landing puff
	if t < 0.5:
		var puff := (0.5 - t) / 0.5
		draw_circle(trap_pos, 15.0 * puff, Color(col.r, col.g, col.b, puff * 0.3))


func _vfx_stink_puff(_fx: Dictionary, t: float) -> void:
	# Green gas burst from player
	var col := Color(0.3, 0.8, 0.15, t * 0.4)
	for i in range(6):
		var angle := float(i) * TAU / 6.0 + (1.0 - t) * 2.0
		var dist := 30.0 + (1.0 - t) * 40.0
		draw_circle(
			Vector2(cos(angle) * dist, sin(angle) * dist),
			8.0 * t, col
		)


func _vfx_swap_line(fx: Dictionary, t: float) -> void:
	var target_pos: Vector2 = fx["target"] - global_position
	var col := Color(0.9, 0.3, 0.9, t)
	# Zigzag lightning between positions
	var segs := 10
	var prev := Vector2.ZERO
	for s in range(segs + 1):
		var st := float(s) / segs
		var pt: Vector2 = Vector2.ZERO.lerp(target_pos, st)
		if s > 0 and s < segs:
			var perp := (target_pos.normalized()).rotated(PI / 2.0)
			pt += perp * sin(st * PI * 4.0 + (1.0 - t) * 15.0) * 12.0 * t
		if s > 0:
			draw_line(prev, pt, col, 2.5 * t)
		prev = pt
	# Flash circles at both ends
	draw_circle(Vector2.ZERO, 15.0 * t, Color(0.9, 0.3, 0.9, t * 0.4))
	draw_circle(target_pos, 15.0 * t, Color(0.9, 0.3, 0.9, t * 0.4))


func _vfx_spin_lines(fx: Dictionary, t: float) -> void:
	var col := Color(player_color.r, player_color.g, player_color.b, t * 0.5)
	var radius: float = fx.get("radius", 120.0)
	# Rotating slash lines
	var rot := (1.0 - t) * TAU * 2.0
	for i in range(6):
		var a := rot + float(i) * TAU / 6.0
		var r_inner := radius * 0.3
		var r_outer := radius * (0.5 + t * 0.5)
		draw_line(
			Vector2(cos(a) * r_inner, sin(a) * r_inner),
			Vector2(cos(a) * r_outer, sin(a) * r_outer),
			col, 3.0 * t
		)
