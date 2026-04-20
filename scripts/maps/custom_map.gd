extends "res://scripts/maps/map_base.gd"
## Custom map loaded at runtime from a user-authored Dictionary.
## Used both by the map editor (live preview) and the game (Test Play /
## custom map match). All fields are optional; sensible defaults kick in.

const BgPresets := preload("res://scripts/maps/bg_presets.gd")


func load_from_dict(d: Dictionary) -> void:
	map_name = d.get("name", "Custom Map")
	platform_palette = d.get("platform_palette", "stone")
	var theme: String = d.get("bg_theme", "forest_blue")
	bg_layers = BgPresets.get_layers(theme)
	bg_color = BgPresets.get_bg_color(theme)
	bg_tint = Color.WHITE

	var rect_arr: Array = d.get("map_rect", [0, 0, 4500, 2800])
	map_rect = Rect2(rect_arr[0], rect_arr[1], rect_arr[2], rect_arr[3])
	danger_left   = float(d.get("danger_left",   280))
	danger_right  = float(d.get("danger_right",  280))
	danger_bottom = float(d.get("danger_bottom", 420))
	danger_top    = float(d.get("danger_top",    0))
	gravity_multiplier = float(d.get("gravity_multiplier", 1.0))
	floor_friction_mult = float(d.get("floor_friction_mult", 1.0))
	events_enabled = bool(d.get("events_enabled", false))

	# Colors — picked from palette defaults, can be overridden by the dict
	match platform_palette:
		"stone":
			platform_color = Color(0.38, 0.38, 0.40)
			platform_edge_color = Color(0.60, 0.62, 0.65)
		"wood":
			platform_color = Color(0.45, 0.30, 0.18)
			platform_edge_color = Color(0.70, 0.48, 0.28)
		"sand":
			platform_color = Color(0.80, 0.65, 0.40)
			platform_edge_color = Color(0.95, 0.80, 0.55)
		"water":
			platform_color = Color(0.30, 0.55, 0.75)
			platform_edge_color = Color(0.50, 0.80, 0.95)
		"lava_ice":
			platform_color = Color(0.78, 0.88, 0.95)
			platform_edge_color = Color(0.95, 0.98, 1.00)
	floor_color = platform_color.darkened(0.1)
	floor_edge_color = platform_edge_color.darkened(0.15)

	# Platforms: array of [x, y, w, h, one_way]
	platforms.clear()
	for p in d.get("platforms", []):
		platforms.append([
			float(p.get("x", 0)), float(p.get("y", 0)),
			float(p.get("w", 200)), float(p.get("h", 32)),
			bool(p.get("one_way", true)),
		])

	# Hazards: spikes only for MVP
	hazards.clear()
	for h in d.get("hazards", []):
		if h.get("type", "") == "spikes":
			hazards.append([
				"spikes",
				float(h.get("x", 0)), float(h.get("y", 0)),
				float(h.get("w", 100)), float(h.get("h", 30)),
			])

	# Teleports: pairs
	teleports.clear()
	for t in d.get("teleports", []):
		teleports.append([
			float(t.get("x1", 0)), float(t.get("y1", 0)),
			float(t.get("x2", 0)), float(t.get("y2", 0)),
		])

	# Spawn points
	spawn_points.clear()
	for sp in d.get("spawn_points", []):
		spawn_points.append(Vector2(float(sp[0]), float(sp[1])))
	# Fallback if none: four corners of the safe area
	if spawn_points.is_empty():
		var safe_y: float = map_rect.end.y - danger_bottom - 80.0
		var sx1: float = map_rect.position.x + danger_left + 200.0
		var sx2: float = map_rect.end.x - danger_right - 200.0
		spawn_points = [
			Vector2(sx1, safe_y),
			Vector2(sx2, safe_y),
			Vector2((sx1 + sx2) * 0.5 - 300, safe_y - 400),
			Vector2((sx1 + sx2) * 0.5 + 300, safe_y - 400),
		]

	# Item spawns
	item_spawns.clear()
	for sp in d.get("item_spawns", []):
		item_spawns.append([float(sp[0]), float(sp[1])])


# Convert current map data back to a Dictionary (for save).
func to_dict() -> Dictionary:
	var plats: Array = []
	for p in platforms:
		plats.append({
			"x": p[0], "y": p[1], "w": p[2], "h": p[3],
			"one_way": (p.size() > 4 and p[4] is bool and p[4]),
		})
	var hazs: Array = []
	for h in hazards:
		if h[0] == "spikes":
			hazs.append({"type": "spikes", "x": h[1], "y": h[2], "w": h[3], "h": h[4]})
	var tps: Array = []
	for t in teleports:
		tps.append({"x1": t[0], "y1": t[1], "x2": t[2], "y2": t[3]})
	var sps: Array = []
	for sp in spawn_points:
		sps.append([sp.x, sp.y])
	var isps: Array = []
	for sp in item_spawns:
		isps.append([sp[0], sp[1]])
	return {
		"name": map_name,
		"bg_theme": _guess_theme(),
		"platform_palette": platform_palette,
		"map_rect": [map_rect.position.x, map_rect.position.y,
			map_rect.size.x, map_rect.size.y],
		"danger_left": danger_left,
		"danger_right": danger_right,
		"danger_bottom": danger_bottom,
		"danger_top": danger_top,
		"gravity_multiplier": gravity_multiplier,
		"floor_friction_mult": floor_friction_mult,
		"events_enabled": events_enabled,
		"platforms": plats,
		"hazards": hazs,
		"teleports": tps,
		"spawn_points": sps,
		"item_spawns": isps,
	}


func _guess_theme() -> String:
	# Heuristic: the first layer's path reveals the theme folder name.
	if bg_layers.is_empty():
		return "forest_blue"
	var p: String = bg_layers[0].get("path", "")
	for t in BgPresets.THEMES:
		if p.contains("/" + t + "/"):
			return t
	return "forest_blue"
