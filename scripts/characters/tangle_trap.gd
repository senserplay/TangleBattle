extends Area2D

var owner_id: int = -1
var color: Color = Color.WHITE
var lifetime: float = 15.0
var damage: float = 15.0
var slow_duration: float = 2.0


func setup(id: int, col: Color) -> void:
	owner_id = id
	color = col.lerp(Color.WHITE, 0.3)


func setup_from_config(id: int, col: Color, cfg: Dictionary) -> void:
	owner_id = id
	color = col.lerp(Color.WHITE, 0.3)
	damage = cfg.get("damage", 15.0)
	slow_duration = cfg.get("slow_duration", 2.0)
	lifetime = cfg.get("lifetime", 15.0)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	if not body.has_method("apply_slow"):
		return
	if body.player_id == owner_id:
		return
	body.take_damage(damage)
	body.apply_slow(slow_duration)
	queue_free()


func _draw() -> void:
	var trap_color := Color(color.r, color.g, color.b, 0.5)
	draw_circle(Vector2.ZERO, 16.0, trap_color)
	var dark := color.darkened(0.2)
	dark.a = 0.6
	for i in range(4):
		var a := i * TAU / 4.0
		var from := Vector2(cos(a), sin(a)) * 5.0
		var to := Vector2(cos(a + 1.5), sin(a + 1.5)) * 13.0
		draw_line(from, to, dark, 1.5)
