extends "res://scripts/maps/map_base.gd"
## Arena — small map, danger zones shrink over time (battle royale).

var shrink_timer: float = 0.0
const SHRINK_DELAY := 10.0  # seconds before shrinking starts
const SHRINK_SPEED := 15.0  # pixels per second
const MIN_SAFE_SIZE := 800.0  # minimum safe area width

var initial_danger_left: float = 200.0
var initial_danger_right: float = 200.0
var initial_danger_bottom: float = 200.0
var initial_danger_top: float = 200.0

func _init() -> void:
	map_name = "Arena"
	platform_palette = "stone"
	bg_color = Color(0.15, 0.08, 0.08)
	bg_theme = "dawn"
	bg_tint = Color(1.0, 0.65, 0.55)
	death_zone_style = "spikes"
	platform_color = Color(0.45, 0.25, 0.2)
	platform_edge_color = Color(0.7, 0.4, 0.3)
	floor_color = Color(0.35, 0.2, 0.15)
	floor_edge_color = Color(0.55, 0.35, 0.25)

	map_rect = Rect2(0, 0, 3200, 2800)  # smaller map
	danger_left = 200.0
	danger_right = 200.0
	danger_bottom = 400.0
	danger_top = 200.0

	initial_danger_left = danger_left
	initial_danger_right = danger_right
	initial_danger_bottom = danger_bottom
	initial_danger_top = danger_top

	platforms = [
		# Central arena
		[1600, 2100, 1400, 50, false],
		# Elevated
		[800, 1700, 400, 28, true],
		[2400, 1700, 400, 28, true],
		[1600, 1350, 500, 28, true],
		[600, 1050, 350, 28, true],
		[2600, 1050, 350, 28, true],
		[1600, 750, 400, 28, true],
		[1100, 450, 300, 28, true],
		[2100, 450, 300, 28, true],
	]

	objects = [
		["ball", 1600, 1100, 50],
	]

	item_spawns = [
		[1600, 1250], [800, 1600], [2400, 1600],
	]

	spawn_points = [
		Vector2(1200, 2030), Vector2(2000, 2030),
		Vector2(800, 1630), Vector2(2400, 1630),
	]


func _process(delta: float) -> void:
	super._process(delta)
	shrink_timer += delta

	# After delay, start shrinking danger zones
	if shrink_timer > SHRINK_DELAY:
		var safe_w := map_rect.size.x - danger_left - danger_right
		var safe_h := map_rect.size.y - danger_top - danger_bottom
		if safe_w > MIN_SAFE_SIZE:
			danger_left += SHRINK_SPEED * delta * 0.5
			danger_right += SHRINK_SPEED * delta * 0.5
		if safe_h > MIN_SAFE_SIZE:
			danger_top += SHRINK_SPEED * delta * 0.3
			danger_bottom += SHRINK_SPEED * delta * 0.3


func _draw_decorations() -> void:
	# Warning text when shrinking
	if shrink_timer > SHRINK_DELAY - 3.0 and shrink_timer < SHRINK_DELAY:
		var alpha := sin(shrink_timer * 5.0) * 0.3 + 0.5
		var font := ThemeDB.fallback_font
		var ts := font.get_string_size("ZONE SHRINKING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		draw_string(font,
			Vector2(map_rect.size.x / 2.0 - ts.x / 2.0, map_rect.size.y / 2.0),
			"ZONE SHRINKING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			Color(1, 0.2, 0.1, alpha))

	# Arena chains on walls
	for cy in range(5):
		var y := 400.0 + cy * 400.0
		draw_circle(Vector2(danger_left + 15, y), 4.0, Color(0.4, 0.3, 0.2, 0.2))
		draw_circle(Vector2(map_rect.size.x - danger_right - 15, y), 4.0,
			Color(0.4, 0.3, 0.2, 0.2))

	# Blood splatter decoration
	for bi in range(8):
		var bx := fmod(bi * 433.0 + 200, map_rect.size.x - 400) + 200
		var by := fmod(bi * 277.0 + 300, map_rect.size.y - 600) + 300
		draw_circle(Vector2(bx, by), 5.0 + fmod(bi * 3.0, 8.0),
			Color(0.5, 0.1, 0.05, 0.05))
