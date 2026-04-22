extends Control
## Map editor — create, load, edit, delete, and test-play custom maps.
## Saves to user://custom_maps/<name>.json.
##
## Tools:
##   - Select/Move: click object to select, drag to move, resize via corners.
##   - Platform:    drag rectangle to place a new platform.
##   - Spike:       drag rectangle to place a spike hazard.
##   - Teleport:    click twice — first point is portal A, second is portal B.
##   - Spawn:       click to place/move the next spawn point (up to 4).
##
## Top toolbar: New, Load, Save, Save As, Delete, Test Play, Back.

const BgPresets := preload("res://scripts/maps/bg_presets.gd")

const MAPS_DIR := "user://custom_maps/"
const GRID_SIZE := 40.0
const MIN_RECT := 20.0

# Built-in maps — selectable via the Import dropdown so the player can
# start from an existing map and edit it as a custom one.
const BUILTIN_MAPS: Array[Dictionary] = [
	{"name": "Forest Glade",   "scene": "res://scenes/maps/forest_glade.tscn"},
	{"name": "Desert Dunes",   "scene": "res://scenes/maps/desert_dunes.tscn"},
	{"name": "Iceberg Bay",    "scene": "res://scenes/maps/iceberg_bay.tscn"},
	{"name": "Ocean Shore",    "scene": "res://scenes/maps/ocean_shore.tscn"},
	{"name": "Winter Night",   "scene": "res://scenes/maps/winter_night.tscn"},
	{"name": "Haunted Castle", "scene": "res://scenes/maps/haunted_castle.tscn"},
]

# UI refs
@onready var tb_new: Button         = %NewBtn
@onready var tb_load: OptionButton  = %LoadMenu
@onready var tb_import: OptionButton = %ImportMenu
@onready var tb_save: Button        = %SaveBtn
@onready var tb_save_as: Button     = %SaveAsBtn
@onready var tb_delete: Button      = %DeleteBtn
@onready var tb_test: Button        = %TestBtn
@onready var tb_back: Button        = %BackBtn

@onready var tool_select: Button     = %ToolSelect
@onready var tool_platform: Button   = %ToolPlatform
@onready var tool_spike: Button      = %ToolSpike
@onready var tool_teleport: Button   = %ToolTeleport
@onready var tool_spawn: Button      = %ToolSpawn

@onready var prop_name: LineEdit      = %PropName
@onready var prop_bg: OptionButton    = %PropBg
@onready var prop_palette: OptionButton = %PropPalette
@onready var prop_map_w: SpinBox      = %PropMapW
@onready var prop_map_h: SpinBox      = %PropMapH
@onready var prop_danger_l: SpinBox   = %PropDangerL
@onready var prop_danger_r: SpinBox   = %PropDangerR
@onready var prop_danger_b: SpinBox   = %PropDangerB
@onready var prop_gravity: SpinBox    = %PropGravity
@onready var prop_friction: SpinBox   = %PropFriction
@onready var prop_event: OptionButton = %PropEvent

const EVENT_IDS: Array[String] = [
	"none", "all", "wind", "meteor", "lightning", "tsunami",
]
const EVENT_LABELS: Array[String] = [
	"None", "Random (all)", "Wind gust", "Meteor", "Lightning",
	"Tsunami",
]

@onready var sel_panel: VBoxContainer = %SelectedPanel
@onready var sel_label: Label         = %SelLabel
@onready var sel_x: SpinBox           = %SelX
@onready var sel_y: SpinBox           = %SelY
@onready var sel_w: SpinBox           = %SelW
@onready var sel_h: SpinBox           = %SelH
@onready var sel_del_btn: Button      = %SelDeleteBtn
@onready var sel_oneway: CheckBox     = %SelOneWay

@onready var canvas: Control          = %Canvas
@onready var status_label: Label      = %StatusLabel
@onready var name_dialog: AcceptDialog = %NameDialog
@onready var name_input: LineEdit     = %NameInput
@onready var confirm_dialog: ConfirmationDialog = %ConfirmDialog

# State
var map_data: Dictionary = _default_map()
var current_file: String = ""
var current_tool: String = "select"
# Selection: {"type": "platform"/"spike"/"teleport_a"/"teleport_b"/"spawn", "idx": int}
var selected: Dictionary = {}
var name_dialog_purpose: String = ""  # "save_as" or "new"

# Canvas view
var cam_offset: Vector2 = Vector2(-200, -200)
var cam_zoom: float = 0.22

# Drag state
var is_panning: bool = false
var pan_start_mouse: Vector2
var pan_start_offset: Vector2
var is_placing: bool = false
var place_start_world: Vector2
var place_current_world: Vector2
var is_moving_selected: bool = false
var move_start_world: Vector2
var move_start_obj: Dictionary  # snapshot of object at drag start
var teleport_pending_a: Vector2 = Vector2.INF  # INF = no pending

# Block property-change loops (setting field from data shouldn't fire re-set)
var _updating_props: bool = false


func _ready() -> void:
	_ensure_dir()
	_populate_bg_dropdown()
	_populate_palette_dropdown()
	_populate_event_dropdown()
	_populate_import_menu()
	_refresh_load_menu()
	_connect_signals()
	_load_props_from_data()
	_set_tool("select")
	_center_view()


func _populate_import_menu() -> void:
	tb_import.clear()
	tb_import.add_item("Import built-in...", 0)
	for i in range(BUILTIN_MAPS.size()):
		tb_import.add_item(BUILTIN_MAPS[i]["name"], i + 1)


func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(MAPS_DIR):
		DirAccess.make_dir_recursive_absolute(MAPS_DIR)


func _populate_bg_dropdown() -> void:
	prop_bg.clear()
	for t in BgPresets.THEMES:
		prop_bg.add_item(t)


func _populate_palette_dropdown() -> void:
	prop_palette.clear()
	for p in BgPresets.PALETTES:
		prop_palette.add_item(p)


func _populate_event_dropdown() -> void:
	prop_event.clear()
	for label in EVENT_LABELS:
		prop_event.add_item(label)


func _refresh_load_menu() -> void:
	tb_load.clear()
	tb_load.add_item("Load...", 0)
	var dir := DirAccess.open(MAPS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	var idx := 1
	while f != "":
		if f.ends_with(".json"):
			tb_load.add_item(f.trim_suffix(".json"), idx)
			idx += 1
		f = dir.get_next()
	dir.list_dir_end()


func _connect_signals() -> void:
	tb_new.pressed.connect(_on_new)
	tb_load.item_selected.connect(_on_load_selected)
	tb_import.item_selected.connect(_on_import_selected)
	tb_save.pressed.connect(_on_save)
	tb_save_as.pressed.connect(_on_save_as)
	tb_delete.pressed.connect(_on_delete)
	tb_test.pressed.connect(_on_test_play)
	tb_back.pressed.connect(_on_back)

	tool_select.pressed.connect(func(): _set_tool("select"))
	tool_platform.pressed.connect(func(): _set_tool("platform"))
	tool_spike.pressed.connect(func(): _set_tool("spike"))
	tool_teleport.pressed.connect(func(): _set_tool("teleport"))
	tool_spawn.pressed.connect(func(): _set_tool("spawn"))

	prop_name.text_changed.connect(_on_prop_changed.unbind(1))
	prop_bg.item_selected.connect(_on_prop_changed.unbind(1))
	prop_palette.item_selected.connect(_on_prop_changed.unbind(1))
	prop_map_w.value_changed.connect(_on_prop_changed.unbind(1))
	prop_map_h.value_changed.connect(_on_prop_changed.unbind(1))
	prop_danger_l.value_changed.connect(_on_prop_changed.unbind(1))
	prop_danger_r.value_changed.connect(_on_prop_changed.unbind(1))
	prop_danger_b.value_changed.connect(_on_prop_changed.unbind(1))
	prop_gravity.value_changed.connect(_on_prop_changed.unbind(1))
	prop_friction.value_changed.connect(_on_prop_changed.unbind(1))
	prop_event.item_selected.connect(_on_prop_changed.unbind(1))

	sel_x.value_changed.connect(_on_sel_changed.unbind(1))
	sel_y.value_changed.connect(_on_sel_changed.unbind(1))
	sel_w.value_changed.connect(_on_sel_changed.unbind(1))
	sel_h.value_changed.connect(_on_sel_changed.unbind(1))
	sel_oneway.toggled.connect(_on_sel_changed.unbind(1))
	sel_del_btn.pressed.connect(_delete_selected)

	canvas.gui_input.connect(_on_canvas_input)
	canvas.draw.connect(_on_canvas_draw)

	name_dialog.confirmed.connect(_on_name_dialog_ok)
	confirm_dialog.confirmed.connect(_on_confirm_delete)


func _set_tool(t: String) -> void:
	current_tool = t
	teleport_pending_a = Vector2.INF
	_update_tool_buttons()
	_set_status("Tool: " + t.capitalize() + _tool_hint(t))
	canvas.queue_redraw()


func _tool_hint(t: String) -> String:
	match t:
		"select":   return "  —  click to select, drag to move, Del to remove."
		"platform": return "  —  drag rectangle to place a platform."
		"spike":    return "  —  drag rectangle to place a spike hazard."
		"teleport": return "  —  click point A, then click point B."
		"spawn":    return "  —  click to place spawn point (up to 4, reuses oldest)."
	return ""


func _update_tool_buttons() -> void:
	tool_select.button_pressed = current_tool == "select"
	tool_platform.button_pressed = current_tool == "platform"
	tool_spike.button_pressed = current_tool == "spike"
	tool_teleport.button_pressed = current_tool == "teleport"
	tool_spawn.button_pressed = current_tool == "spawn"


# ──────────── Map data helpers ────────────

func _default_map() -> Dictionary:
	return {
		"name": "New Map",
		"bg_theme": "forest_blue",
		"platform_palette": "stone",
		"map_rect": [0, 0, 4500, 2800],
		"danger_left": 280,
		"danger_right": 280,
		"danger_bottom": 420,
		"danger_top": 0,
		"gravity_multiplier": 1.0,
		"floor_friction_mult": 1.0,
		"event_type": "all",
		"events_enabled": true,
		"platforms": [
			{"x": 2250, "y": 2300, "w": 2800, "h": 60, "one_way": false},
			{"x": 900, "y": 1900, "w": 520, "h": 32, "one_way": true},
			{"x": 3600, "y": 1900, "w": 520, "h": 32, "one_way": true},
		],
		"hazards": [],
		"teleports": [],
		"spawn_points": [[1200, 2235], [3300, 2235], [900, 1835], [3600, 1835]],
		"item_spawns": [],
	}


func _load_props_from_data() -> void:
	_updating_props = true
	prop_name.text = map_data["name"]
	var bg_idx: int = BgPresets.THEMES.find(map_data["bg_theme"])
	if bg_idx >= 0:
		prop_bg.selected = bg_idx
	var pal_idx: int = BgPresets.PALETTES.find(map_data["platform_palette"])
	if pal_idx >= 0:
		prop_palette.selected = pal_idx
	var r: Array = map_data["map_rect"]
	prop_map_w.value = r[2]
	prop_map_h.value = r[3]
	prop_danger_l.value = map_data["danger_left"]
	prop_danger_r.value = map_data["danger_right"]
	prop_danger_b.value = map_data["danger_bottom"]
	prop_gravity.value = map_data["gravity_multiplier"]
	prop_friction.value = map_data.get("floor_friction_mult", 1.0)
	var ev_id: String = String(map_data.get("event_type", "none"))
	# Back-compat: if only legacy events_enabled=true is present, map to "all"
	if ev_id == "none" and map_data.get("events_enabled", false):
		ev_id = "all"
	var ev_idx: int = EVENT_IDS.find(ev_id)
	prop_event.selected = ev_idx if ev_idx >= 0 else 0
	_updating_props = false
	_load_sel_from_data()
	canvas.queue_redraw()


func _on_prop_changed() -> void:
	if _updating_props:
		return
	map_data["name"] = prop_name.text
	map_data["bg_theme"] = BgPresets.THEMES[prop_bg.selected]
	map_data["platform_palette"] = BgPresets.PALETTES[prop_palette.selected]
	map_data["map_rect"] = [0, 0, prop_map_w.value, prop_map_h.value]
	map_data["danger_left"] = prop_danger_l.value
	map_data["danger_right"] = prop_danger_r.value
	map_data["danger_bottom"] = prop_danger_b.value
	map_data["gravity_multiplier"] = prop_gravity.value
	map_data["floor_friction_mult"] = prop_friction.value
	var ev_id: String = EVENT_IDS[prop_event.selected] if prop_event.selected >= 0 else "none"
	map_data["event_type"] = ev_id
	map_data["events_enabled"] = ev_id != "none"
	canvas.queue_redraw()


func _load_sel_from_data() -> void:
	_updating_props = true
	if selected.is_empty():
		sel_panel.visible = false
	else:
		sel_panel.visible = true
		var t: String = selected.type
		var idx: int = selected.idx
		match t:
			"platform":
				var p: Dictionary = map_data["platforms"][idx]
				sel_label.text = "Platform #%d" % idx
				sel_x.value = p.x; sel_y.value = p.y
				sel_w.value = p.w; sel_h.value = p.h
				sel_oneway.visible = true
				sel_oneway.button_pressed = p.get("one_way", true)
				sel_w.editable = true; sel_h.editable = true
			"spike":
				var p: Dictionary = map_data["hazards"][idx]
				sel_label.text = "Spike #%d" % idx
				sel_x.value = p.x; sel_y.value = p.y
				sel_w.value = p.w; sel_h.value = p.h
				sel_oneway.visible = false
				sel_w.editable = true; sel_h.editable = true
			"teleport_a", "teleport_b":
				var p: Dictionary = map_data["teleports"][idx]
				sel_label.text = "Teleport #%d (%s)" % [idx, "A" if t == "teleport_a" else "B"]
				var kx: String = "x1" if t == "teleport_a" else "x2"
				var ky: String = "y1" if t == "teleport_a" else "y2"
				sel_x.value = p[kx]; sel_y.value = p[ky]
				sel_w.value = 0; sel_h.value = 0
				sel_oneway.visible = false
				sel_w.editable = false; sel_h.editable = false
			"spawn":
				var sp: Array = map_data["spawn_points"][idx]
				sel_label.text = "Spawn Point #%d" % idx
				sel_x.value = sp[0]; sel_y.value = sp[1]
				sel_w.value = 0; sel_h.value = 0
				sel_oneway.visible = false
				sel_w.editable = false; sel_h.editable = false
	_updating_props = false


func _on_sel_changed() -> void:
	if _updating_props or selected.is_empty():
		return
	var t: String = selected.type
	var idx: int = selected.idx
	match t:
		"platform":
			var p: Dictionary = map_data["platforms"][idx]
			p.x = sel_x.value; p.y = sel_y.value
			p.w = sel_w.value; p.h = sel_h.value
			p.one_way = sel_oneway.button_pressed
		"spike":
			var p: Dictionary = map_data["hazards"][idx]
			p.x = sel_x.value; p.y = sel_y.value
			p.w = sel_w.value; p.h = sel_h.value
		"teleport_a":
			var p: Dictionary = map_data["teleports"][idx]
			p.x1 = sel_x.value; p.y1 = sel_y.value
		"teleport_b":
			var p: Dictionary = map_data["teleports"][idx]
			p.x2 = sel_x.value; p.y2 = sel_y.value
		"spawn":
			map_data["spawn_points"][idx] = [sel_x.value, sel_y.value]
	canvas.queue_redraw()


func _delete_selected() -> void:
	if selected.is_empty():
		return
	var t: String = selected.type
	var idx: int = selected.idx
	match t:
		"platform":
			map_data["platforms"].remove_at(idx)
		"spike":
			map_data["hazards"].remove_at(idx)
		"teleport_a", "teleport_b":
			map_data["teleports"].remove_at(idx)
		"spawn":
			if map_data["spawn_points"].size() > 1:
				map_data["spawn_points"].remove_at(idx)
	selected = {}
	_load_sel_from_data()
	canvas.queue_redraw()


# ──────────── Toolbar actions ────────────

func _on_new() -> void:
	map_data = _default_map()
	current_file = ""
	selected = {}
	_load_props_from_data()
	_set_status("New map")


func _on_load_selected(idx: int) -> void:
	if idx == 0:
		return  # "Load..." placeholder
	var fname: String = tb_load.get_item_text(idx) + ".json"
	_load_from_file(fname)
	tb_load.selected = 0


func _on_import_selected(idx: int) -> void:
	if idx == 0:
		return
	var info: Dictionary = BUILTIN_MAPS[idx - 1]
	var scn_path: String = info["scene"]
	var packed: PackedScene = load(scn_path)
	if packed == null:
		_set_status("Can't load: " + scn_path)
		return
	# Instantiate WITHOUT adding to the tree — we want to read field
	# values set by the map script's _init(), not spawn physics bodies.
	var node: Node2D = packed.instantiate()
	map_data = _builtin_to_dict(node)
	node.queue_free()
	current_file = ""  # imported → becomes a new map; "Save As" to persist
	selected = {}
	_load_props_from_data()
	_set_status("Imported: " + info["name"] + " — Save As to keep it.")
	tb_import.selected = 0


# Serialize an in-memory map_base node into the editor Dictionary format.
func _builtin_to_dict(m: Node2D) -> Dictionary:
	var bg_theme: String = "forest_blue"
	if m.bg_layers.size() > 0:
		var p: String = m.bg_layers[0].get("path", "")
		for t in BgPresets.THEMES:
			if p.contains("/" + t + "/"):
				bg_theme = t
				break
	var plats: Array = []
	for p in m.platforms:
		var one_way: bool = (p.size() > 4 and p[4] is bool and p[4])
		plats.append({
			"x": float(p[0]), "y": float(p[1]),
			"w": float(p[2]), "h": float(p[3]),
			"one_way": one_way,
		})
	var hazs: Array = []
	for h in m.hazards:
		if h[0] == "spikes":
			hazs.append({
				"type": "spikes",
				"x": float(h[1]), "y": float(h[2]),
				"w": float(h[3]), "h": float(h[4]),
			})
	var tps: Array = []
	for t in m.teleports:
		# v2 format: [x1, y1, h1, a1, x2, y2, h2, a2] — flatten to simple pair
		if t.size() >= 8:
			tps.append({"x1": float(t[0]), "y1": float(t[1]),
				"x2": float(t[4]), "y2": float(t[5])})
		else:
			tps.append({"x1": float(t[0]), "y1": float(t[1]),
				"x2": float(t[2]), "y2": float(t[3])})
	var sps: Array = []
	for sp in m.spawn_points:
		sps.append([sp.x, sp.y])
	var isps: Array = []
	for sp in m.item_spawns:
		isps.append([float(sp[0]), float(sp[1])])
	return {
		"name": m.map_name + " (copy)",
		"bg_theme": bg_theme,
		"platform_palette": m.platform_palette if m.platform_palette != "" else "stone",
		"map_rect": [m.map_rect.position.x, m.map_rect.position.y,
			m.map_rect.size.x, m.map_rect.size.y],
		"danger_left": m.danger_left,
		"danger_right": m.danger_right,
		"danger_bottom": m.danger_bottom,
		"danger_top": m.danger_top,
		"gravity_multiplier": m.gravity_multiplier,
		"floor_friction_mult": m.floor_friction_mult,
		"events_enabled": m.events_enabled,
		"platforms": plats,
		"hazards": hazs,
		"teleports": tps,
		"spawn_points": sps,
		"item_spawns": isps,
	}


func _load_from_file(fname: String) -> void:
	var path: String = MAPS_DIR + fname
	if not FileAccess.file_exists(path):
		_set_status("File not found: " + fname)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if parsed == null:
		_set_status("Invalid JSON: " + fname)
		return
	map_data = parsed
	# Ensure required fields exist
	for k in _default_map().keys():
		if not map_data.has(k):
			map_data[k] = _default_map()[k]
	current_file = fname
	selected = {}
	_load_props_from_data()
	_set_status("Loaded: " + fname)


func _on_save() -> void:
	if current_file == "":
		_on_save_as()
		return
	_save_to_file(current_file)


func _on_save_as() -> void:
	name_dialog_purpose = "save_as"
	name_input.text = map_data["name"]
	name_dialog.popup_centered()


func _save_to_file(fname: String) -> void:
	var path: String = MAPS_DIR + fname
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_set_status("Cannot write: " + fname)
		return
	f.store_string(JSON.stringify(map_data, "\t"))
	f.close()
	current_file = fname
	_refresh_load_menu()
	_set_status("Saved: " + fname)


func _on_delete() -> void:
	if current_file == "":
		_set_status("Nothing to delete (unsaved map)")
		return
	confirm_dialog.dialog_text = "Delete map: " + current_file + " ?"
	confirm_dialog.popup_centered()


func _on_confirm_delete() -> void:
	var path: String = MAPS_DIR + current_file
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_set_status("Deleted: " + current_file)
	current_file = ""
	_refresh_load_menu()
	_on_new()


func _on_name_dialog_ok() -> void:
	var nm := name_input.text.strip_edges()
	if nm == "":
		return
	# Sanitize filename
	nm = nm.replace("/", "_").replace("\\", "_").replace(":", "_")
	if name_dialog_purpose == "save_as":
		map_data["name"] = nm
		prop_name.text = nm
		_save_to_file(nm + ".json")


func _on_test_play() -> void:
	# Push the current in-memory data to GameManager so game.gd can load it
	# as a custom map instead of the random rotation.
	GameManager.pending_custom_map = map_data.duplicate(true)
	GameManager.returning_to_editor = true
	get_tree().change_scene_to_file("res://scenes/main/lobby.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main/title_menu.tscn")


# ──────────── Canvas: draw + input ────────────

func _world_to_canvas(w: Vector2) -> Vector2:
	return (w + cam_offset) * cam_zoom


func _canvas_to_world(c: Vector2) -> Vector2:
	return c / cam_zoom - cam_offset


func _center_view() -> void:
	# Fit the map into the canvas area, with some margin
	await get_tree().process_frame
	var sz := canvas.size
	var mw: float = map_data["map_rect"][2]
	var mh: float = map_data["map_rect"][3]
	if mw < 1 or mh < 1:
		return
	cam_zoom = minf(sz.x / (mw + 400.0), sz.y / (mh + 400.0))
	cam_offset = Vector2(
		(sz.x / cam_zoom - mw) * 0.5,
		(sz.y / cam_zoom - mh) * 0.5
	)
	canvas.queue_redraw()


func _on_canvas_draw() -> void:
	var sz := canvas.size
	# Canvas bg
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.08, 0.08, 0.10))

	var r: Array = map_data["map_rect"]
	var mr_pos := _world_to_canvas(Vector2(r[0], r[1]))
	var mr_size := Vector2(r[2], r[3]) * cam_zoom
	# Map body
	canvas.draw_rect(Rect2(mr_pos, mr_size),
		BgPresets.get_bg_color(map_data["bg_theme"]))
	# Safe area outline
	var safe_pos := _world_to_canvas(Vector2(
		r[0] + map_data["danger_left"], r[1] + map_data["danger_top"]))
	var safe_size := Vector2(
		r[2] - map_data["danger_left"] - map_data["danger_right"],
		r[3] - map_data["danger_top"] - map_data["danger_bottom"]
	) * cam_zoom
	canvas.draw_rect(Rect2(safe_pos, safe_size),
		Color(0.15, 0.35, 0.25, 0.25))
	# Water band
	var water_pos := _world_to_canvas(Vector2(
		r[0], r[1] + r[3] - map_data["danger_bottom"]))
	var water_size := Vector2(r[2], map_data["danger_bottom"]) * cam_zoom
	canvas.draw_rect(Rect2(water_pos, water_size),
		Color(0.10, 0.30, 0.50, 0.55))

	# Grid
	_draw_grid(r)

	# Map border
	canvas.draw_rect(Rect2(mr_pos, mr_size), Color(0.6, 0.6, 0.7), false, 1.5)

	# Platforms
	for i in range(map_data["platforms"].size()):
		var p: Dictionary = map_data["platforms"][i]
		var is_sel: bool = selected.get("type", "") == "platform" and selected.get("idx", -1) == i
		_draw_obj_rect(Vector2(p.x - p.w * 0.5, p.y - p.h * 0.5),
			Vector2(p.w, p.h),
			Color(0.55, 0.55, 0.60, 0.85),
			Color(0.85, 0.85, 0.95) if is_sel else Color(0.70, 0.70, 0.80),
			is_sel, int(minf(p.h * 0.45, 26))
		)

	# Spikes
	for i in range(map_data["hazards"].size()):
		var h: Dictionary = map_data["hazards"][i]
		if h.get("type", "") != "spikes":
			continue
		var is_sel: bool = selected.get("type", "") == "spike" and selected.get("idx", -1) == i
		_draw_obj_rect(Vector2(h.x - h.w * 0.5, h.y - h.h * 0.5),
			Vector2(h.w, h.h),
			Color(0.80, 0.15, 0.10, 0.75),
			Color(1.0, 0.4, 0.25) if is_sel else Color(0.95, 0.35, 0.15),
			is_sel, 4)
		# Little spike hats
		_draw_spike_hats(h.x, h.y, h.w, h.h)

	# Teleports
	for i in range(map_data["teleports"].size()):
		var tp: Dictionary = map_data["teleports"][i]
		var pa := _world_to_canvas(Vector2(tp.x1, tp.y1))
		var pb := _world_to_canvas(Vector2(tp.x2, tp.y2))
		canvas.draw_line(pa, pb, Color(0.6, 0.3, 1.0, 0.4), 1.0)
		var a_sel: bool = selected.get("type", "") == "teleport_a" and selected.get("idx", -1) == i
		var b_sel: bool = selected.get("type", "") == "teleport_b" and selected.get("idx", -1) == i
		canvas.draw_circle(pa, 14.0 * maxf(cam_zoom, 0.3), Color(0.5, 0.25, 0.85))
		canvas.draw_arc(pa, 14.0 * maxf(cam_zoom, 0.3), 0, TAU, 16,
			Color(1, 0.8, 1.0) if a_sel else Color(0.8, 0.5, 1.0), 2.0)
		canvas.draw_circle(pb, 14.0 * maxf(cam_zoom, 0.3), Color(0.25, 0.5, 0.85))
		canvas.draw_arc(pb, 14.0 * maxf(cam_zoom, 0.3), 0, TAU, 16,
			Color(0.8, 1.0, 1.0) if b_sel else Color(0.5, 0.8, 1.0), 2.0)
		var font := ThemeDB.fallback_font
		canvas.draw_string(font, pa + Vector2(-4, 5),
			"A", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		canvas.draw_string(font, pb + Vector2(-4, 5),
			"B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	# Spawn points
	for i in range(map_data["spawn_points"].size()):
		var sp: Array = map_data["spawn_points"][i]
		var cp := _world_to_canvas(Vector2(sp[0], sp[1]))
		var is_sel: bool = selected.get("type", "") == "spawn" and selected.get("idx", -1) == i
		var col: Color = [
			Color(0.9, 0.25, 0.25), Color(0.25, 0.45, 0.95),
			Color(0.25, 0.8, 0.30), Color(0.95, 0.85, 0.15)
		][i % 4]
		canvas.draw_circle(cp, 16.0 * maxf(cam_zoom, 0.3), col)
		if is_sel:
			canvas.draw_arc(cp, 20.0 * maxf(cam_zoom, 0.3), 0, TAU, 20,
				Color.WHITE, 2.0)
		var font := ThemeDB.fallback_font
		canvas.draw_string(font, cp - Vector2(5, -5),
			"P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Ghost-rect while placing
	if is_placing and current_tool in ["platform", "spike"]:
		var a := Vector2(
			minf(place_start_world.x, place_current_world.x),
			minf(place_start_world.y, place_current_world.y)
		)
		var b := Vector2(
			maxf(place_start_world.x, place_current_world.x),
			maxf(place_start_world.y, place_current_world.y)
		)
		var ca := _world_to_canvas(a)
		var cb := _world_to_canvas(b)
		var col := Color(0.5, 0.9, 1.0, 0.4) if current_tool == "platform" \
			else Color(1.0, 0.3, 0.2, 0.4)
		canvas.draw_rect(Rect2(ca, cb - ca), col)
		canvas.draw_rect(Rect2(ca, cb - ca), col.lightened(0.3), false, 1.5)

	# Teleport first-click indicator
	if current_tool == "teleport" and teleport_pending_a != Vector2.INF:
		var cp := _world_to_canvas(teleport_pending_a)
		canvas.draw_circle(cp, 10.0, Color(0.6, 0.3, 1.0))
		canvas.draw_arc(cp, 10.0, 0, TAU, 16, Color.WHITE, 2.0)


func _draw_grid(r: Array) -> void:
	var start_x: float = r[0]
	var start_y: float = r[1]
	var end_x: float = r[0] + r[2]
	var end_y: float = r[1] + r[3]
	var x := start_x
	while x <= end_x:
		var p1 := _world_to_canvas(Vector2(x, start_y))
		var p2 := _world_to_canvas(Vector2(x, end_y))
		canvas.draw_line(p1, p2, Color(1, 1, 1, 0.04), 1.0)
		x += GRID_SIZE * 5.0
	var y := start_y
	while y <= end_y:
		var p1 := _world_to_canvas(Vector2(start_x, y))
		var p2 := _world_to_canvas(Vector2(end_x, y))
		canvas.draw_line(p1, p2, Color(1, 1, 1, 0.04), 1.0)
		y += GRID_SIZE * 5.0


func _draw_obj_rect(world_pos: Vector2, world_size: Vector2,
	fill: Color, edge: Color, selected_: bool, _corner_r: int
) -> void:
	var cp := _world_to_canvas(world_pos)
	var cs := world_size * cam_zoom
	canvas.draw_rect(Rect2(cp, cs), fill)
	canvas.draw_rect(Rect2(cp, cs), edge, false, 2.0 if selected_ else 1.0)


func _draw_spike_hats(cx: float, cy: float, w: float, h: float) -> void:
	var n: int = int(w / 30.0) + 1
	var step := w / n
	var y_top := cy - h * 0.5
	for i in range(n):
		var sx := cx - w * 0.5 + step * (i + 0.5)
		var pts := PackedVector2Array([
			_world_to_canvas(Vector2(sx - step * 0.4, y_top + 8)),
			_world_to_canvas(Vector2(sx, y_top - 4)),
			_world_to_canvas(Vector2(sx + step * 0.4, y_top + 8)),
		])
		canvas.draw_colored_polygon(pts, Color(1, 0.5, 0.25, 0.7))


# ──────────── Canvas input ────────────

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(e: InputEventMouseButton) -> void:
	var world := _canvas_to_world(e.position)
	if e.button_index == MOUSE_BUTTON_MIDDLE:
		if e.pressed:
			is_panning = true
			pan_start_mouse = e.position
			pan_start_offset = cam_offset
		else:
			is_panning = false
	elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
		_zoom_at(e.position, 1.15)
	elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
		_zoom_at(e.position, 1.0 / 1.15)
	elif e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_handle_left_down(world, e.position)
		else:
			_handle_left_up(world)


func _handle_mouse_motion(e: InputEventMouseMotion) -> void:
	if is_panning:
		var d := e.position - pan_start_mouse
		cam_offset = pan_start_offset + d / cam_zoom
		canvas.queue_redraw()
	elif is_placing:
		place_current_world = _canvas_to_world(e.position)
		canvas.queue_redraw()
	elif is_moving_selected:
		var world := _canvas_to_world(e.position)
		_apply_move_delta(world - move_start_world)
		canvas.queue_redraw()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var world_before := _canvas_to_world(screen_pos)
	cam_zoom = clampf(cam_zoom * factor, 0.05, 2.0)
	var world_after := _canvas_to_world(screen_pos)
	cam_offset += world_after - world_before
	canvas.queue_redraw()


func _handle_left_down(world: Vector2, _screen: Vector2) -> void:
	match current_tool:
		"select":
			var hit: Dictionary = _pick_at(world)
			selected = hit
			if not hit.is_empty():
				is_moving_selected = true
				move_start_world = world
				move_start_obj = _snapshot_selected()
			_load_sel_from_data()
			canvas.queue_redraw()
		"platform", "spike":
			is_placing = true
			place_start_world = _snap(world)
			place_current_world = place_start_world
		"teleport":
			if teleport_pending_a == Vector2.INF:
				teleport_pending_a = _snap(world)
			else:
				map_data["teleports"].append({
					"x1": teleport_pending_a.x, "y1": teleport_pending_a.y,
					"x2": _snap(world).x, "y2": _snap(world).y,
				})
				teleport_pending_a = Vector2.INF
			canvas.queue_redraw()
		"spawn":
			var sp: Array = map_data["spawn_points"]
			if sp.size() < 4:
				sp.append([_snap(world).x, _snap(world).y])
			else:
				# Replace the spawn point closest to this click
				var best_i := 0
				var best_d := INF
				for i in range(sp.size()):
					var d := (Vector2(sp[i][0], sp[i][1]) - world).length()
					if d < best_d:
						best_d = d
						best_i = i
				sp[best_i] = [_snap(world).x, _snap(world).y]
			canvas.queue_redraw()


func _handle_left_up(world: Vector2) -> void:
	if is_placing:
		var a := Vector2(
			minf(place_start_world.x, world.x),
			minf(place_start_world.y, world.y)
		)
		var b := Vector2(
			maxf(place_start_world.x, world.x),
			maxf(place_start_world.y, world.y)
		)
		var rect_size := b - a
		if rect_size.x >= MIN_RECT and rect_size.y >= MIN_RECT:
			var cx := (a.x + b.x) * 0.5
			var cy := (a.y + b.y) * 0.5
			match current_tool:
				"platform":
					# Default every new platform to one-way so the user can
					# always jump up through from below. Uncheck "One-Way"
					# in the properties panel if you need a solid wall.
					map_data["platforms"].append({
						"x": cx, "y": cy, "w": rect_size.x, "h": rect_size.y,
						"one_way": true,
					})
					selected = {"type": "platform", "idx": map_data["platforms"].size() - 1}
				"spike":
					map_data["hazards"].append({
						"type": "spikes",
						"x": cx, "y": cy, "w": rect_size.x, "h": rect_size.y,
					})
					selected = {"type": "spike", "idx": map_data["hazards"].size() - 1}
		is_placing = false
		_load_sel_from_data()
		canvas.queue_redraw()
	is_moving_selected = false


func _snap(v: Vector2) -> Vector2:
	return Vector2(
		round(v.x / GRID_SIZE) * GRID_SIZE,
		round(v.y / GRID_SIZE) * GRID_SIZE
	)


func _pick_at(world: Vector2) -> Dictionary:
	# Check spawn points first (top layer)
	for i in range(map_data["spawn_points"].size()):
		var sp: Array = map_data["spawn_points"][i]
		if Vector2(sp[0], sp[1]).distance_to(world) < 40.0:
			return {"type": "spawn", "idx": i}
	# Teleports
	for i in range(map_data["teleports"].size()):
		var tp: Dictionary = map_data["teleports"][i]
		if Vector2(tp.x1, tp.y1).distance_to(world) < 40.0:
			return {"type": "teleport_a", "idx": i}
		if Vector2(tp.x2, tp.y2).distance_to(world) < 40.0:
			return {"type": "teleport_b", "idx": i}
	# Spikes (front of platforms)
	for i in range(map_data["hazards"].size() - 1, -1, -1):
		var h: Dictionary = map_data["hazards"][i]
		if h.get("type", "") == "spikes":
			if _rect_contains(h, world):
				return {"type": "spike", "idx": i}
	# Platforms
	for i in range(map_data["platforms"].size() - 1, -1, -1):
		var p: Dictionary = map_data["platforms"][i]
		if _rect_contains(p, world):
			return {"type": "platform", "idx": i}
	return {}


func _rect_contains(r: Dictionary, p: Vector2) -> bool:
	return absf(p.x - r.x) <= r.w * 0.5 and absf(p.y - r.y) <= r.h * 0.5


func _snapshot_selected() -> Dictionary:
	if selected.is_empty():
		return {}
	var t: String = selected.type
	var idx: int = selected.idx
	match t:
		"platform":
			return map_data["platforms"][idx].duplicate()
		"spike":
			return map_data["hazards"][idx].duplicate()
		"teleport_a", "teleport_b":
			return map_data["teleports"][idx].duplicate()
		"spawn":
			var sp: Array = map_data["spawn_points"][idx]
			return {"x": sp[0], "y": sp[1]}
	return {}


func _apply_move_delta(delta: Vector2) -> void:
	if selected.is_empty():
		return
	var t: String = selected.type
	var idx: int = selected.idx
	match t:
		"platform", "spike":
			var arr: Array = map_data["platforms"] if t == "platform" \
				else map_data["hazards"]
			var o: Dictionary = arr[idx]
			o.x = move_start_obj.x + delta.x
			o.y = move_start_obj.y + delta.y
		"teleport_a":
			var o: Dictionary = map_data["teleports"][idx]
			o.x1 = move_start_obj.x1 + delta.x
			o.y1 = move_start_obj.y1 + delta.y
		"teleport_b":
			var o: Dictionary = map_data["teleports"][idx]
			o.x2 = move_start_obj.x2 + delta.x
			o.y2 = move_start_obj.y2 + delta.y
		"spawn":
			var base_x: float = move_start_obj.x
			var base_y: float = move_start_obj.y
			map_data["spawn_points"][idx] = [base_x + delta.x, base_y + delta.y]
	_load_sel_from_data()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DELETE, KEY_BACKSPACE:
				_delete_selected()
			KEY_ESCAPE:
				selected = {}
				teleport_pending_a = Vector2.INF
				_load_sel_from_data()
				canvas.queue_redraw()
			KEY_S:
				if event.ctrl_pressed:
					_on_save()


func _set_status(s: String) -> void:
	status_label.text = s
