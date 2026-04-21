extends Node2D

const ProjectileSprites := preload("res://scripts/characters/projectile_sprites.gd")
## Stationary poison cloud. Poisons enemies who enter.

var owner_id: int = -1
var cloud_radius: float = 200.0
var cloud_duration: float = 3.0
var tick_damage: float = 8.0
var tick_interval: float = 0.5
var poison_duration: float = 2.0
var lifetime: float = 3.0
var time_alive: float = 0.0

# Track poison tick timers per player_id to avoid double-poisoning
var poison_applied: Dictionary = {}


func setup_from_config(id: int, cfg: Dictionary) -> void:
	owner_id = id
	cloud_radius = cfg.get("cloud_radius", 200.0)
	cloud_duration = cfg.get("cloud_duration", 3.0)
	lifetime = cloud_duration
	tick_damage = cfg.get("tick_damage", 8.0)
	tick_interval = cfg.get("tick_interval", 0.5)
	poison_duration = cfg.get("poison_duration", 2.0)


func _ready() -> void:
	add_to_group("ability_entities")


func _exit_tree() -> void:
	var owner_p: Node = get_meta("owner_player", null)
	var ab_id: int = get_meta("ability_id", -1)
	if owner_p != null and is_instance_valid(owner_p) and ab_id >= 0:
		var count: int = owner_p.ability_entity_count.get(ab_id, 0)
		owner_p.ability_entity_count[ab_id] = maxi(count - 1, 0)


var _puff_timer: float = 0.0


func _physics_process(delta: float) -> void:
	time_alive += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Periodic green puff sprite at random offset
	_puff_timer -= delta
	if _puff_timer <= 0.0:
		_puff_timer = 0.3
		var SpriteEffect := load("res://scripts/effects/sprite_effect.gd")
		var off := Vector2(
			randf_range(-cloud_radius * 0.6, cloud_radius * 0.6),
			randf_range(-cloud_radius * 0.6, cloud_radius * 0.6))
		SpriteEffect.spawn(get_tree().current_scene, "cartoon_8",
			global_position + off, 0.5, 0.3, randf() * TAU,
			Color(0.5, 1.0, 0.4, 0.7))

	# Check players inside cloud
	for p in get_tree().get_nodes_in_group("players"):
		if not p.is_alive or p.player_id == owner_id:
			continue
		var dist := global_position.distance_to(p.global_position)
		if dist < cloud_radius:
			_apply_poison(p)

	queue_redraw()


func _apply_poison(player: CharacterBody2D) -> void:
	var pid: int = player.player_id
	if pid in poison_applied:
		return  # already poisoned by this cloud recently
	poison_applied[pid] = true
	# Start poison coroutine
	_run_poison(player, pid)


func _run_poison(player: CharacterBody2D, pid: int) -> void:
	var ticks: int = int(poison_duration / tick_interval)
	for i in range(ticks):
		await get_tree().create_timer(tick_interval).timeout
		if not is_instance_valid(player) or not player.is_alive:
			break
		player.take_damage(tick_damage)
	# Allow re-poisoning after duration ends
	if pid in poison_applied:
		poison_applied.erase(pid)


func _draw() -> void:
	# 3-phase cloud animation (same pattern as black hole):
	#   grow   [0..grow_time):         frame 0..5, size 0..1 (ease-in²)
	#   hold   [grow_time..shrink):    frame 5, size 1
	#   shrink [shrink_start..end):    frame 5..0, size 1..0 (ease-out²)
	# Sized so grow + hold + shrink fit inside cloud_duration. For short
	# durations the grow/shrink shrink proportionally so hold >= 0.
	var grow_time: float = minf(0.6, cloud_duration * 0.3)
	var shrink_time: float = minf(0.6, cloud_duration * 0.3)
	var shrink_start: float = cloud_duration - shrink_time

	var size_k: float = 1.0
	var frame: int = 5
	if time_alive < grow_time:
		var t: float = time_alive / grow_time
		size_k = t * t
		frame = clampi(int(t * 6.0), 0, 5)
	elif time_alive >= shrink_start:
		var t: float = (time_alive - shrink_start) / shrink_time
		var k: float = 1.0 - t
		size_k = k * k
		frame = clampi(5 - int(t * 6.0), 0, 5)

	var pulse: float = sin(time_alive * 4.0) * 0.04 + 1.0
	var display_w: float = cloud_radius * 2.1 * size_k * pulse
	var tex_name: String = "stink_cloud_%d.png" % frame
	ProjectileSprites.draw_single(self, tex_name,
		display_w, 0.0, Color.WHITE)

	# Floating toxin motes on top for motion juice.
	var r: float = cloud_radius * pulse * size_k
	for i in range(10):
		var angle := time_alive * (0.5 + i * 0.15) + i * TAU / 10.0
		var dist := r * (0.35 + fmod(i * 0.17, 0.45))
		var px := cos(angle) * dist
		var py := sin(angle) * dist
		var ps := (3.0 + sin(time_alive * 2.0 + i) * 1.5) * size_k
		draw_circle(
			Vector2(px, py), maxf(ps, 0.5),
			Color(0.4, 0.95, 0.25, 0.28 * size_k)
		)
