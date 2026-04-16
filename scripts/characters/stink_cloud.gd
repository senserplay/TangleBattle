extends Node2D
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


func _physics_process(delta: float) -> void:
	time_alive += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

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
	var fade := clampf(lifetime / 0.5, 0.0, 1.0)  # fade out last 0.5s
	var pulse := sin(time_alive * 4.0) * 0.03 + 1.0

	# Outer cloud
	var r := cloud_radius * pulse
	var col := Color(0.2, 0.7, 0.1, 0.08 * fade)
	draw_circle(Vector2.ZERO, r, col)

	# Middle layer
	draw_circle(Vector2.ZERO, r * 0.7, Color(0.25, 0.75, 0.1, 0.1 * fade))

	# Inner core
	draw_circle(Vector2.ZERO, r * 0.35, Color(0.3, 0.8, 0.15, 0.12 * fade))

	# Edge ring
	draw_arc(
		Vector2.ZERO, r, 0.0, TAU, 32,
		Color(0.3, 0.8, 0.1, 0.15 * fade), 2.0
	)

	# Floating particles
	for i in range(12):
		var angle := time_alive * (0.5 + i * 0.15) + i * TAU / 12.0
		var dist := r * (0.3 + fmod(i * 0.17, 0.5))
		var px := cos(angle) * dist
		var py := sin(angle) * dist
		var ps := 3.0 + sin(time_alive * 2.0 + i) * 1.5
		draw_circle(
			Vector2(px, py), ps,
			Color(0.3, 0.85, 0.15, 0.2 * fade)
		)
