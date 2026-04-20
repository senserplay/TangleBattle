extends Area2D
## Ability pickup — falls with gravity, lands on platforms, rotates ability.

var ability_id: int = 0
var bob_timer: float = 0.0
var velocity_y: float = 0.0
var landed: bool = false
var change_timer: float = 10.0

const BOB_SPEED := 3.0
const BOB_AMP := 4.0
const PICKUP_RADIUS := 22.0
const GRAVITY := 600.0
const CHANGE_INTERVAL := 10.0

var ability_color: Color = Color.WHITE
var ability_name: String = ""


func setup(ab_id: int, pos: Vector2) -> void:
	ability_id = ab_id
	global_position = pos
	_update_ability_data()
	bob_timer = randf() * TAU


func setup_dropped(ab_id: int, pos: Vector2, vel: Vector2) -> void:
	ability_id = ab_id
	global_position = pos
	velocity_y = vel.y
	global_position.x += vel.x * 0.1
	_update_ability_data()
	bob_timer = randf() * TAU


func _update_ability_data() -> void:
	var data: Dictionary = AbilityRegistry.get_data(ability_id)
	ability_color = data["color"]
	ability_name = data["name"]


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 2


func _physics_process(delta: float) -> void:
	bob_timer += delta * BOB_SPEED

	if not landed:
		# Fall with gravity
		velocity_y += GRAVITY * delta
		global_position.y += velocity_y * delta
		# Simple platform landing check via raycast
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(
			global_position, global_position + Vector2(0, 10), 1)
		var result := space.intersect_ray(query)
		if not result.is_empty() and velocity_y > 0:
			global_position.y = result.position.y - 5
			velocity_y = 0.0
			landed = true
	else:
		# Small bob when landed
		global_position.y += sin(bob_timer) * BOB_AMP * delta

	# Rotate ability every 10 seconds
	change_timer -= delta
	if change_timer <= 0.0:
		change_timer = CHANGE_INTERVAL
		ability_id = randi_range(0, AbilityRegistry.ABILITY_COUNT - 1)
		_update_ability_data()

	# Bounds check
	if absf(global_position.x) > 8000 or global_position.y > 8000:
		queue_free()
		return

	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	if not body.has_method("assign_abilities"):
		return
	if not body.is_alive:
		return
	var slot: int = randi_range(0, 1)
	body.ability_ids[slot] = ability_id
	body.ability_cds[slot] = 0.0
	SoundManager.play_shield()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, PICKUP_RADIUS + 8,
		Color(ability_color.r, ability_color.g, ability_color.b, 0.08))
	# Textured ability icon (replaces procedural emblem)
	AbilityIcon.draw_at(self, Vector2.ZERO, PICKUP_RADIUS, ability_id)
	draw_arc(Vector2.ZERO, PICKUP_RADIUS, 0.0, TAU, 20, ability_color, 3.0)
	# Change timer indicator — shrinking arc
	var change_ratio := change_timer / CHANGE_INTERVAL
	draw_arc(Vector2.ZERO, PICKUP_RADIUS + 3, 0.0, TAU * change_ratio, 12,
		Color(1, 1, 1, 0.2), 1.5)
	# Sparkle
	var sparkle_a := fmod(bob_timer * 2.0, TAU)
	draw_circle(Vector2(cos(sparkle_a) * 15, sin(sparkle_a) * 15),
		2.5, Color(1, 1, 1, 0.4))


func _draw_emblem() -> void:
	var c := Vector2.ZERO
	var col := ability_color
	match ability_id:
		0: draw_circle(c + Vector2(2, 0), 5.0, col)
		1:
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 2.5)
			draw_line(c + Vector2(5, -4), c + Vector2(8, 0), col, 2.0)
			draw_line(c + Vector2(5, 4), c + Vector2(8, 0), col, 2.0)
		2: draw_circle(c, 5.0, col)
		3:
			draw_line(c + Vector2(-8, 0), c + Vector2(-2, 0), col, 2.0)
			draw_line(c + Vector2(8, 0), c + Vector2(2, 0), col, 2.0)
		4: draw_arc(c, 7.0, 0.0, TAU * 0.75, 10, col, 2.5)
		5:
			draw_circle(c, 6.0, col)
			draw_line(c + Vector2(0, -6), c + Vector2(3, -10), col, 2.0)
		6:
			draw_line(c + Vector2(0, 5), c + Vector2(0, -7), col, 2.5)
			draw_line(c + Vector2(-5, 4), c + Vector2(-7, -4), col, 1.5)
			draw_line(c + Vector2(5, 4), c + Vector2(7, -4), col, 1.5)
		7:
			draw_circle(c, 5.0, col.darkened(0.2))
			draw_circle(c + Vector2(-4, -3), 3.0, col)
			draw_circle(c + Vector2(4, -2), 3.0, col)
		8:
			draw_circle(c, 4.0, col.darkened(0.2))
			for si in range(5):
				var sa := si * TAU / 5.0
				draw_line(c + Vector2(cos(sa), sin(sa)) * 4.0,
					c + Vector2(cos(sa), sin(sa)) * 9.0, col, 1.5)
		9:
			draw_line(c + Vector2(-7, -4), c + Vector2(7, 4), col, 2.0)
			draw_line(c + Vector2(7, -4), c + Vector2(-7, 4), col, 2.0)
		10:
			for bi in range(4):
				var ba := bi * PI / 2.0 + 0.3
				draw_line(c, c + Vector2(cos(ba), sin(ba)) * 7.0, col, 2.0)
		11:
			draw_line(c + Vector2(-5, 4), c + Vector2(0, -5), col, 2.0)
			draw_line(c + Vector2(0, -5), c + Vector2(5, 0), col, 2.0)
			draw_circle(c + Vector2(5, 0), 2.0, col)
		12:
			draw_circle(c + Vector2(-5, 0), 3.0, col)
			draw_circle(c + Vector2(5, 0), 3.0, col)
			draw_line(c + Vector2(-3, 0), c + Vector2(3, 0), col, 1.5)
		13:
			draw_arc(c, 6.0, -0.5, PI + 0.5, 8, col, 2.0)
			draw_line(c + Vector2(5, -3), c + Vector2(7, -5), col, 1.5)
		14:
			draw_circle(c, 5.0, col.darkened(0.5))
			draw_arc(c, 7.0, 0.0, TAU * 0.7, 8, col, 2.0)
		15:
			draw_arc(c + Vector2(-4, 0), 4.0, 0.0, TAU, 6, col, 1.5)
			draw_arc(c + Vector2(4, 0), 4.0, 0.0, TAU, 6, col, 1.5)
		16:
			draw_line(c + Vector2(-5, -8), c + Vector2(-5, 6), col, 2.0)
			draw_line(c + Vector2(0, -6), c + Vector2(0, 8), col, 1.5)
			draw_line(c + Vector2(5, -8), c + Vector2(5, 6), col, 1.5)
		_: draw_circle(c, 6.0, col)
