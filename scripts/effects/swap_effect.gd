extends Node2D
## Standalone swap / portal burst VFX — sits at a fixed world position
## in the scene, plays the 5-frame swap sprite animation, then despawns.
## Spawn via `SwapEffect.spawn(parent, world_pos, duration)`.

const ProjectileSprites := preload("res://scripts/characters/projectile_sprites.gd")

const DURATION := 0.45
const FRAMES := 5
const SIZE := 160.0

var time_alive: float = 0.0


static func spawn(parent: Node, world_pos: Vector2,
	duration: float = DURATION) -> Node2D:
	var node: Node2D = Node2D.new()
	var script: GDScript = load("res://scripts/effects/swap_effect.gd")
	node.set_script(script)
	node.set("time_alive", 0.0)
	node.global_position = world_pos
	node.z_index = 50
	parent.add_child(node)
	return node


func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = clampf(time_alive / DURATION, 0.0, 1.0)
	# Frame progresses bright-star (0) → opening portal (2) → fading ring (4)
	var frame: int = clampi(int(k * FRAMES), 0, FRAMES - 1)
	var fade: float = 1.0 - pow(k, 1.5)
	var tex_name: String = "swap_%d.png" % frame
	ProjectileSprites.draw_single(self, tex_name, SIZE, 0.0,
		Color(1.0, 1.0, 1.0, fade))
