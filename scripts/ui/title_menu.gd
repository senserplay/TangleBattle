extends Control
## Main title screen — Play, Settings, Quit

enum Screen { TITLE, SETTINGS }

const PLAYER_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3),
	Color(0.95, 0.85, 0.1),
]

var current_screen: Screen = Screen.TITLE
var title_focus: int = 0  # 0=Play, 1=Settings, 2=Quit
var settings_focus: int = 0

# Settings data
var master_volume: float = 1.0  # 0.0 - 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var vsync: bool = true
var show_fps: bool = false
var screen_shake: bool = true

const TITLE_ITEMS: Array[String] = ["PLAY", "MAP EDITOR", "SETTINGS", "QUIT"]

const SETTINGS_ITEMS: Array[String] = [
	"Master Volume",
	"SFX Volume",
	"Fullscreen",
	"VSync",
	"Show FPS",
	"Screen Shake",
	"Vibration",
	"Back",
]

var vibration_enabled: bool = true

var blink_timer: float = 0.0
var yarn_anim: float = 0.0


func _ready() -> void:
	# Root Control defaults to MOUSE_FILTER_STOP, which consumes mouse
	# clicks inside the gui system and prevents them from ever reaching
	# `_unhandled_input`. Force IGNORE so the script-level click
	# handler actually sees the events (whole screen is drawn via
	# `_draw`, there are no native Button children to intercept).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_settings()
	MusicManager.play_menu_music()


func _process(delta: float) -> void:
	blink_timer += delta
	yarn_anim += delta
	if show_fps:
		pass  # FPS shown in _draw
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_key(event)
	if event is InputEventJoypadButton and event.pressed:
		_handle_joy(event)
	# Mouse click
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)


func _handle_key(event: InputEventKey) -> void:
	match current_screen:
		Screen.TITLE:
			match event.physical_keycode:
				KEY_W, KEY_UP:
					title_focus = (title_focus - 1 + TITLE_ITEMS.size()) % TITLE_ITEMS.size()
				KEY_S, KEY_DOWN:
					title_focus = (title_focus + 1) % TITLE_ITEMS.size()
				KEY_ENTER, KEY_SPACE:
					_select_title()
				KEY_ESCAPE:
					pass
		Screen.SETTINGS:
			match event.physical_keycode:
				KEY_W, KEY_UP:
					settings_focus = (settings_focus - 1 + SETTINGS_ITEMS.size()) % SETTINGS_ITEMS.size()
				KEY_S, KEY_DOWN:
					settings_focus = (settings_focus + 1) % SETTINGS_ITEMS.size()
				KEY_A, KEY_LEFT:
					_change_setting(-1)
				KEY_D, KEY_RIGHT:
					_change_setting(1)
				KEY_ENTER, KEY_SPACE:
					_select_setting()
				KEY_ESCAPE:
					current_screen = Screen.TITLE


func _handle_joy(event: InputEventJoypadButton) -> void:
	match current_screen:
		Screen.TITLE:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					title_focus = (title_focus - 1 + TITLE_ITEMS.size()) % TITLE_ITEMS.size()
				JOY_BUTTON_DPAD_DOWN:
					title_focus = (title_focus + 1) % TITLE_ITEMS.size()
				JOY_BUTTON_A:
					_select_title()
				JOY_BUTTON_B:
					pass
		Screen.SETTINGS:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					settings_focus = (settings_focus - 1 + SETTINGS_ITEMS.size()) % SETTINGS_ITEMS.size()
				JOY_BUTTON_DPAD_DOWN:
					settings_focus = (settings_focus + 1) % SETTINGS_ITEMS.size()
				JOY_BUTTON_DPAD_LEFT:
					_change_setting(-1)
				JOY_BUTTON_DPAD_RIGHT:
					_change_setting(1)
				JOY_BUTTON_A:
					_select_setting()
				JOY_BUTTON_B:
					current_screen = Screen.TITLE


func _handle_click(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var cx := vp.x / 2.0

	match current_screen:
		Screen.TITLE:
			for i in range(TITLE_ITEMS.size()):
				var iy := 500.0 + i * 80.0
				if pos.y > iy - 25 and pos.y < iy + 25 and absf(pos.x - cx) < 150:
					title_focus = i
					_select_title()
					return
		Screen.SETTINGS:
			for i in range(SETTINGS_ITEMS.size()):
				var iy := 250.0 + i * 65.0
				if pos.y > iy - 20 and pos.y < iy + 20:
					settings_focus = i
					if i < 2:  # volume sliders
						if pos.x < cx:
							_change_setting(-1)
						else:
							_change_setting(1)
					else:
						_select_setting()
					return


func _select_title() -> void:
	MusicManager.play_ui_confirm()
	match title_focus:
		0:  # Play
			GameManager.vibration_enabled = vibration_enabled
			GameManager.screen_shake_enabled = screen_shake
			# Normal play uses the random map rotation — clear any
			# editor-test-play custom map left over from a previous session.
			GameManager.pending_custom_map = {}
			GameManager.returning_to_editor = false
			get_tree().change_scene_to_file("res://scenes/main/lobby.tscn")
		1:  # Map Editor
			get_tree().change_scene_to_file("res://scenes/main/map_editor.tscn")
		2:  # Settings
			current_screen = Screen.SETTINGS
			settings_focus = 0
		3:  # Quit
			get_tree().quit()


func _select_setting() -> void:
	match settings_focus:
		2:  # Fullscreen
			fullscreen = not fullscreen
			_apply_settings()
		3:  # VSync
			vsync = not vsync
			_apply_settings()
		4:  # Show FPS
			show_fps = not show_fps
		5:  # Screen Shake
			screen_shake = not screen_shake
		6:  # Vibration
			vibration_enabled = not vibration_enabled
		7:  # Back
			current_screen = Screen.TITLE


func _change_setting(dir: int) -> void:
	match settings_focus:
		0:  # Master Volume
			master_volume = clampf(master_volume + dir * 0.1, 0.0, 1.0)
			_apply_settings()
		1:  # SFX Volume
			sfx_volume = clampf(sfx_volume + dir * 0.1, 0.0, 1.0)
			_apply_settings()
		2:  # Fullscreen
			fullscreen = not fullscreen
			_apply_settings()
		3:  # VSync
			vsync = not vsync
			_apply_settings()
		4:
			show_fps = not show_fps
		5:
			screen_shake = not screen_shake
		6:
			vibration_enabled = not vibration_enabled


func _apply_settings() -> void:
	# Audio
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(
			master_bus,
			linear_to_db(master_volume)
		)

	# Fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# VSync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# ══════════════════ DRAWING ══════════════════

func _draw() -> void:
	var vp := get_viewport_rect().size

	# Background
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.08, 0.06, 0.12))

	# Animated background yarn balls
	_draw_bg_decorations(vp)

	match current_screen:
		Screen.TITLE:
			_draw_title_screen(vp)
		Screen.SETTINGS:
			_draw_settings_screen(vp)

	# FPS counter
	if show_fps:
		_draw_text(
			Vector2(vp.x - 100, 30),
			"FPS: %d" % Engine.get_frames_per_second(),
			16.0, Color(0.7, 0.9, 0.3)
		)


func _draw_bg_decorations(vp: Vector2) -> void:
	# Floating yarn balls in background
	var colors: Array[Color] = [
		Color(0.9, 0.2, 0.2, 0.08),
		Color(0.2, 0.4, 0.9, 0.08),
		Color(0.2, 0.8, 0.3, 0.08),
		Color(0.95, 0.85, 0.1, 0.08),
	]
	for i in range(20):
		var bx := fmod(i * 173.0 + yarn_anim * (10.0 + i * 2.0), vp.x + 100) - 50.0
		var by := fmod(i * 97.0 + yarn_anim * (5.0 + i * 1.5), vp.y + 100) - 50.0
		var radius := 20.0 + fmod(i * 13.0, 30.0)
		draw_circle(Vector2(bx, by), radius, colors[i % 4])

	# Subtle grid pattern
	for i in range(20):
		for j in range(12):
			var cx := i * 100.0 + 50.0
			var cy := j * 100.0 + 50.0
			draw_circle(Vector2(cx, cy), 2.0, Color(0.15, 0.12, 0.2, 0.2))


func _draw_title_screen(vp: Vector2) -> void:
	var cx := vp.x / 2.0

	# Title glow
	draw_circle(Vector2(cx, 280), 200.0, Color(0.3, 0.15, 0.5, 0.08))
	draw_circle(Vector2(cx, 280), 120.0, Color(0.4, 0.2, 0.6, 0.06))

	# Title text
	_draw_text_centered(Vector2(cx, 230), "TANGLE", 80.0, Color(0.95, 0.9, 1.0))
	_draw_text_centered(Vector2(cx, 320), "BATTLE", 80.0, Color(0.8, 0.6, 1.0))

	# Subtitle
	_draw_text_centered(
		Vector2(cx, 380), "Local Multiplayer Brawl",
		18.0, Color(0.5, 0.45, 0.6)
	)

	# Decorative orbiting yarn balls in title — texture asset, semi-transparent
	var title_ball_y := 280.0
	for pi in range(4):
		var angle := yarn_anim * 0.5 + pi * TAU / 4.0
		var ox := cos(angle) * 200.0
		var oy := sin(angle) * 30.0
		var pc := PLAYER_COLORS[pi]
		pc.a = 0.5
		YarnBallIcon.draw_at(self,
			Vector2(cx + ox, title_ball_y + oy), 22.0, pc, false)

	# Menu items
	for i in range(TITLE_ITEMS.size()):
		var iy := 500.0 + i * 80.0
		var focused := title_focus == i

		if focused:
			# Selection box
			var pulse := 0.7 + sin(blink_timer * 5.0) * 0.3
			var box := Rect2(cx - 160, iy - 28, 320, 56)
			draw_rect(box, Color(0.3, 0.2, 0.5, 0.3 * pulse))
			draw_rect(box, Color(0.6, 0.4, 0.9, 0.6 * pulse), false, 2.0)

			# Arrow indicator
			draw_line(
				Vector2(cx - 175, iy), Vector2(cx - 165, iy - 8),
				Color(0.8, 0.6, 1.0, pulse), 3.0
			)
			draw_line(
				Vector2(cx - 175, iy), Vector2(cx - 165, iy + 8),
				Color(0.8, 0.6, 1.0, pulse), 3.0
			)

		var col := Color(0.95, 0.9, 1.0) if focused \
			else Color(0.5, 0.45, 0.6)
		var fs := 36.0 if focused else 30.0
		_draw_text_centered(Vector2(cx, iy), TITLE_ITEMS[i], fs, col)

	# Controls hint
	_draw_text_centered(
		Vector2(cx, vp.y - 50),
		"W/S or D-Pad: Navigate    Enter/A: Select",
		14.0, Color(0.35, 0.3, 0.45)
	)
	_draw_text_centered(
		Vector2(cx, vp.y - 28),
		"Supports 1-4 players, keyboard + gamepads",
		13.0, Color(0.3, 0.25, 0.4)
	)


func _draw_settings_screen(vp: Vector2) -> void:
	var cx := vp.x / 2.0

	# Header
	draw_rect(Rect2(0, 30, vp.x, 70), Color(0.12, 0.1, 0.18, 0.9))
	_draw_text_centered(Vector2(cx, 70), "SETTINGS", 40.0, Color(0.9, 0.85, 1.0))

	# Panel background
	var panel := Rect2(cx - 400, 140, 800, SETTINGS_ITEMS.size() * 65.0 + 40)
	draw_rect(panel, Color(0.1, 0.08, 0.14, 0.95))
	draw_rect(panel, Color(0.3, 0.25, 0.4, 0.5), false, 2.0)

	for i in range(SETTINGS_ITEMS.size()):
		var iy := 250.0 + i * 65.0
		var focused := settings_focus == i

		# Focus highlight
		if focused:
			var pulse := 0.7 + sin(blink_timer * 5.0) * 0.3
			draw_rect(
				Rect2(cx - 380, iy - 22, 760, 44),
				Color(0.3, 0.2, 0.5, 0.2 * pulse)
			)

		var label_col := Color(0.9, 0.85, 1.0) if focused \
			else Color(0.55, 0.5, 0.65)

		match i:
			0:  # Master Volume
				_draw_text(
					Vector2(cx - 350, iy), "Master Volume", 20.0, label_col
				)
				_draw_slider(cx + 100, iy, master_volume, focused)
			1:  # SFX Volume
				_draw_text(
					Vector2(cx - 350, iy), "SFX Volume", 20.0, label_col
				)
				_draw_slider(cx + 100, iy, sfx_volume, focused)
			2:  # Fullscreen
				_draw_text(
					Vector2(cx - 350, iy), "Fullscreen", 20.0, label_col
				)
				_draw_toggle(cx + 200, iy, fullscreen, focused)
			3:  # VSync
				_draw_text(
					Vector2(cx - 350, iy), "VSync", 20.0, label_col
				)
				_draw_toggle(cx + 200, iy, vsync, focused)
			4:  # Show FPS
				_draw_text(
					Vector2(cx - 350, iy), "Show FPS", 20.0, label_col
				)
				_draw_toggle(cx + 200, iy, show_fps, focused)
			5:  # Screen Shake
				_draw_text(
					Vector2(cx - 350, iy), "Screen Shake", 20.0, label_col
				)
				_draw_toggle(cx + 200, iy, screen_shake, focused)
			6:  # Vibration
				_draw_text(
					Vector2(cx - 350, iy), "Vibration", 20.0, label_col
				)
				_draw_toggle(cx + 200, iy, vibration_enabled, focused)
			7:  # Back
				_draw_text_centered(
					Vector2(cx, iy), "< BACK >", 24.0, label_col
				)

	# Controls hint
	_draw_text_centered(
		Vector2(cx, vp.y - 40),
		"W/S: Navigate    A/D: Change    Enter: Select    ESC/B: Back",
		14.0, Color(0.35, 0.3, 0.45)
	)


func _draw_slider(cx: float, cy: float, value: float, focused: bool) -> void:
	var bar_w := 200.0
	var bar_h := 6.0
	var x0 := cx - bar_w / 2.0

	# Track
	draw_rect(
		Rect2(x0, cy - bar_h / 2.0, bar_w, bar_h),
		Color(0.2, 0.18, 0.25)
	)

	# Fill
	var fill_col := Color(0.5, 0.3, 0.8) if focused \
		else Color(0.35, 0.25, 0.5)
	draw_rect(
		Rect2(x0, cy - bar_h / 2.0, bar_w * value, bar_h),
		fill_col
	)

	# Handle
	var handle_x := x0 + bar_w * value
	var handle_col := Color(0.8, 0.6, 1.0) if focused \
		else Color(0.5, 0.4, 0.65)
	draw_circle(Vector2(handle_x, cy), 10.0, handle_col)

	# Percentage text
	var pct := "%d%%" % int(value * 100)
	_draw_text(Vector2(cx + bar_w / 2.0 + 20, cy), pct, 16.0, handle_col)

	# Arrows
	if focused:
		var ac := Color(0.7, 0.5, 0.9)
		draw_line(Vector2(x0 - 20, cy), Vector2(x0 - 10, cy - 6), ac, 2.0)
		draw_line(Vector2(x0 - 20, cy), Vector2(x0 - 10, cy + 6), ac, 2.0)
		var xe := x0 + bar_w
		draw_line(Vector2(xe + 55, cy), Vector2(xe + 45, cy - 6), ac, 2.0)
		draw_line(Vector2(xe + 55, cy), Vector2(xe + 45, cy + 6), ac, 2.0)


func _draw_toggle(cx: float, cy: float, enabled: bool, focused: bool) -> void:
	var box_w := 60.0
	var box_h := 28.0
	var box := Rect2(cx - box_w / 2.0, cy - box_h / 2.0, box_w, box_h)

	if enabled:
		draw_rect(box, Color(0.2, 0.6, 0.3, 0.8))
		# Knob right
		draw_circle(Vector2(cx + 16, cy), 10.0, Color(0.3, 0.9, 0.4))
		_draw_text(Vector2(cx + 40, cy), "ON", 16.0, Color(0.3, 0.9, 0.4))
	else:
		draw_rect(box, Color(0.25, 0.2, 0.3, 0.8))
		# Knob left
		draw_circle(Vector2(cx - 16, cy), 10.0, Color(0.5, 0.4, 0.55))
		_draw_text(Vector2(cx + 40, cy), "OFF", 16.0, Color(0.5, 0.4, 0.55))

	if focused:
		draw_rect(box, Color(0.7, 0.5, 0.9, 0.4), false, 2.0)


# ══════════════════ TEXT HELPERS ══════════════════

func _draw_text_centered(
	pos: Vector2, text: String, font_size: float, color: Color
) -> void:
	var font := ThemeDB.fallback_font
	var ts := font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size)
	)
	draw_string(
		font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size), color
	)


func _draw_text(
	pos: Vector2, text: String, font_size: float, color: Color
) -> void:
	var font := ThemeDB.fallback_font
	var ts := font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size)
	)
	draw_string(
		font, Vector2(pos.x, pos.y + ts.y / 4.0),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size), color
	)
