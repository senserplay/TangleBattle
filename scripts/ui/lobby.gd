extends Control
## Lobby screen with cursor-based navigation.
## Keyboard: W/S to move focus, A/D to change value, Enter to start
## Gamepad: Left stick to navigate and change, A to start, B to leave

const DEFAULT_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3),
	Color(0.95, 0.85, 0.1),
]

const COLOR_PALETTE: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.4, 0.9),   # Blue
	Color(0.2, 0.8, 0.3),   # Green
	Color(0.95, 0.85, 0.1), # Yellow
	Color(0.9, 0.4, 0.1),   # Orange
	Color(0.7, 0.2, 0.9),   # Purple
	Color(0.1, 0.8, 0.8),   # Cyan
	Color(0.9, 0.3, 0.6),   # Pink
	Color(0.5, 0.5, 0.5),   # Grey
	Color(0.95, 0.95, 0.95), # White
]

var PLAYER_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3),
	Color(0.95, 0.85, 0.1),
]
var player_color_idx: Array[int] = [0, 1, 2, 3]

const HP_OPTIONS: Array[int] = [50, 75, 100, 150]
const ROUND_OPTIONS: Array[int] = [3, 5, 7, 10]
const LUCK_OPTIONS: Array[int] = [0, 5, 10, 15, 20, 25, 30, 40, 50]
const CARD_OPTIONS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const PICK_OPTIONS: Array[int] = [1, 2, 3, 4, 5]

# Slot state: -1 = empty, -2 = keyboard, >= 0 = gamepad device id
var slot_device: Array[int] = [-2, -1, -1, -1]
var slot_abilities: Array = [[-1, -1], [-1, -1], [-1, -1], [-1, -1]]

var hp_index: int = 2
var rounds_index: int = 2
var mode_index: int = 0  # 0=Classic, 1=Endless, 2=Chaos
var joined_count: int = 1
var luck_index: int = 0
var card_index: int = 4  # default 5 cards
var pick_index: int = 0  # default 1 pick

# Focus system: which row is selected per slot
# 0 = ability1, 1 = ability2
var slot_focus: Array[int] = [0, 0, 0, 0]
# Keyboard extra focus: 0=ab1, 1=ab2, 2=hp, 3=rounds
var kb_focus: int = 0

# Stick repeat prevention
var stick_cooldown: Array[float] = [0.0, 0.0, 0.0, 0.0]
const STICK_REPEAT := 0.2

var blink_timer: float = 0.0


func _ready() -> void:
	# Control roots default to MOUSE_FILTER_STOP, which absorbs mouse
	# clicks inside the gui system before `_unhandled_input` fires.
	# Ignore so script-level click handling receives the events.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_device[0] = -2
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	blink_timer += delta
	# Handle joystick stick input (analog, needs per-frame polling)
	_poll_joystick_sticks(delta)
	queue_redraw()


func _poll_joystick_sticks(delta: float) -> void:
	for i in range(4):
		stick_cooldown[i] = maxf(stick_cooldown[i] - delta, 0.0)

	for i in range(4):
		var dev: int = slot_device[i]
		if dev < 0:
			continue  # keyboard or empty
		if stick_cooldown[i] > 0.0:
			continue

		var lx := Input.get_joy_axis(dev, JOY_AXIS_LEFT_X)
		var ly := Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y)

		if absf(ly) > 0.5:
			# Up/down — switch focus between ability slots
			var dir := 1 if ly > 0 else -1
			slot_focus[i] = clampi(slot_focus[i] + dir, 0, 2)
			stick_cooldown[i] = STICK_REPEAT

		if absf(lx) > 0.5:
			var dir := 1 if lx > 0 else -1
			if slot_focus[i] == 0:
				_cycle_color(i, dir)
			else:
				_cycle_ability(i, slot_focus[i] - 1, dir)
			stick_cooldown[i] = STICK_REPEAT


func _unhandled_input(event: InputEvent) -> void:
	# Gamepad button press
	if event is InputEventJoypadButton and event.pressed:
		var dev: int = event.device
		if not _is_device_joined(dev):
			# X (Cross) to join
			if event.button_index == JOY_BUTTON_A:
				_join_device(dev)
		else:
			var slot := _get_slot_for_device(dev)
			if slot >= 0:
				_handle_joy_button(slot, event)

	# Keyboard
	if event is InputEventKey and event.pressed:
		_handle_keyboard(event)

	# Mouse click
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_mouse_click(event.position)


func _is_device_joined(device_id: int) -> bool:
	return device_id in slot_device


func _get_slot_for_device(device_id: int) -> int:
	for i in range(4):
		if slot_device[i] == device_id:
			return i
	return -1


func _join_device(device_id: int) -> void:
	for i in range(4):
		if slot_device[i] == -1:
			slot_device[i] = device_id
			joined_count += 1
			return


func _leave_slot(slot: int) -> void:
	if slot_device[slot] == -1:
		return  # already empty
	slot_device[slot] = -1
	slot_abilities[slot] = [-1, -1]
	joined_count -= 1


func _handle_joy_button(slot: int, event: InputEventJoypadButton) -> void:
	match event.button_index:
		JOY_BUTTON_B:
			# Circle/B — leave slot, or go to title if already empty
			if slot_device[slot] != -1:
				_leave_slot(slot)
			else:
				get_tree().change_scene_to_file(
					"res://scenes/main/title_menu.tscn"
				)
		JOY_BUTTON_A:
			# Cross/X — start game
			if joined_count >= 2 or (mode_index == 3 and joined_count >= 1):
				_start_game()
		JOY_BUTTON_DPAD_LEFT:
			if slot_focus[slot] == 0:
				_cycle_color(slot, -1)
			else:
				_cycle_ability(slot, slot_focus[slot] - 1, -1)
		JOY_BUTTON_DPAD_RIGHT:
			if slot_focus[slot] == 0:
				_cycle_color(slot, 1)
			else:
				_cycle_ability(slot, slot_focus[slot] - 1, 1)
		JOY_BUTTON_DPAD_UP:
			slot_focus[slot] = clampi(slot_focus[slot] - 1, 0, 2)
		JOY_BUTTON_DPAD_DOWN:
			slot_focus[slot] = clampi(slot_focus[slot] + 1, 0, 2)


func _handle_keyboard(event: InputEventKey) -> void:
	# If keyboard not connected, any key except ESC re-joins
	if slot_device[0] != -2:
		if event.physical_keycode == KEY_ESCAPE:
			# Go back to title if nobody is on keyboard
			get_tree().change_scene_to_file(
				"res://scenes/main/title_menu.tscn"
			)
			return
		# Rejoin keyboard to slot 0
		slot_device[0] = -2
		joined_count += 1
		return

	match event.physical_keycode:
		KEY_W, KEY_UP:
			kb_focus = clampi(kb_focus - 1, 0, 8)
		KEY_S, KEY_DOWN:
			kb_focus = clampi(kb_focus + 1, 0, 8)
		# Change value: A/D or Left/Right
		KEY_A, KEY_LEFT:
			_apply_kb_change(-1)
		KEY_D, KEY_RIGHT:
			_apply_kb_change(1)
		KEY_ENTER, KEY_SPACE:
			if joined_count >= 2 or (mode_index == 3 and joined_count >= 1):
				_start_game()
		KEY_ESCAPE:
			# If keyboard player is connected, disconnect them
			if slot_device[0] == -2:
				_leave_slot(0)
			else:
				# No keyboard player connected — go back to title
				get_tree().change_scene_to_file(
					"res://scenes/main/title_menu.tscn"
				)


func _apply_kb_change(dir: int) -> void:
	match kb_focus:
		0:
			_cycle_color(0, dir)
		1:
			_cycle_ability(0, 0, dir)
		2:
			_cycle_ability(0, 1, dir)
		3:
			hp_index = clampi(hp_index + dir, 0, HP_OPTIONS.size() - 1)
		4:
			rounds_index = clampi(rounds_index + dir, 0, ROUND_OPTIONS.size() - 1)
		5:
			mode_index = clampi(mode_index + dir, 0, 3)
		6:
			luck_index = clampi(luck_index + dir, 0, LUCK_OPTIONS.size() - 1)
		7:
			card_index = clampi(card_index + dir, 0, CARD_OPTIONS.size() - 1)
		8:
			pick_index = clampi(pick_index + dir, 0, PICK_OPTIONS.size() - 1)


func _cycle_color(slot: int, dir: int) -> void:
	player_color_idx[slot] = (player_color_idx[slot] + dir + COLOR_PALETTE.size()) % COLOR_PALETTE.size()
	PLAYER_COLORS[slot] = COLOR_PALETTE[player_color_idx[slot]]


func _handle_mouse_click(pos: Vector2) -> void:
	# Check if clicking on ability selector arrows for P1
	var vp := get_viewport_rect().size
	var slot_w := 380.0
	var gap := 30.0
	var total_w := slot_w * 4 + gap * 3
	var start_x := (vp.x - total_w) / 2.0
	var slot_x := start_x
	var cx := slot_x + slot_w / 2.0

	# Ability 1 area: y ~ 240
	# Ability 2 area: y ~ 340
	var top := 130.0
	for ab_slot in range(2):
		var ay := top + 240.0 + ab_slot * 100.0
		if pos.y > ay - 30 and pos.y < ay + 40:
			if pos.x > slot_x and pos.x < slot_x + slot_w:
				kb_focus = ab_slot
				if pos.x < cx:
					_cycle_ability(0, ab_slot, -1)
				else:
					_cycle_ability(0, ab_slot, 1)
				return

	# Settings panel — layout mirrors _draw_settings exactly. Each
	# control is a 100-px wide value block with ±48-px arrow zones on
	# either side. Click left arrow = −1, right arrow = +1, middle =
	# focus only. Kept as a table so the click map can't drift from
	# the draw code without also editing this list.
	var bar_y := vp.y - 130.0
	var bar_y2 := bar_y + 55.0
	var s_cx := vp.x / 2.0
	# Each row: [focus_id, center_x, center_y, kb_focus value]. kb_focus
	# mapping from _apply_kb_change: 3=HP, 4=Rounds, 5=Mode, 6=Luck,
	# 7=Cards, 8=Picks.
	var settings_map: Array = [
		[3, s_cx - 250.0, bar_y + 42.0],   # HP
		[4, s_cx -  50.0, bar_y + 42.0],   # Rounds (disabled in Endless)
		[5, s_cx + 250.0, bar_y + 42.0],   # Mode
		[6, s_cx - 250.0, bar_y2 + 22.0],  # Luck
		[7, s_cx -  50.0, bar_y2 + 22.0],  # Cards
		[8, s_cx + 150.0, bar_y2 + 22.0],  # Picks
	]
	for s in settings_map:
		var sid: int = s[0]
		var scx: float = s[1]
		var scy: float = s[2]
		# Click box matches the drawn focus rect (−50..+50 × −14..+14)
		# plus an extra 12 px around each arrow.
		if absf(pos.x - scx) <= 60.0 and absf(pos.y - scy) <= 18.0:
			kb_focus = sid
			# Rounds value is frozen in Endless mode (mode_index == 1)
			# — match the keyboard path exactly.
			if sid == 4 and mode_index == 1:
				return
			var dir: int = -1 if pos.x < scx else 1
			_apply_kb_change(dir)
			return

	# Start button
	var btn_y := vp.y - 15.0
	var can_start := joined_count >= 2 or (mode_index == 3 and joined_count >= 1)
	if pos.y > btn_y - 30 and pos.y < btn_y + 30 and can_start:
		if absf(pos.x - vp.x / 2.0) < 150:
			_start_game()


func _cycle_ability(slot: int, ab_slot: int, dir: int) -> void:
	var current: int = slot_abilities[slot][ab_slot]
	current += dir
	if current < -1:
		current = AbilityRegistry.ABILITY_COUNT - 1
	elif current >= AbilityRegistry.ABILITY_COUNT:
		current = -1
	slot_abilities[slot][ab_slot] = current


func _start_game() -> void:
	MusicManager.play_ui_confirm()
	GameManager.max_hp = float(HP_OPTIONS[hp_index])
	GameManager.win_score = ROUND_OPTIONS[rounds_index]
	GameManager.game_mode = mode_index as GameManager.GameMode
	GameManager.base_luck = float(LUCK_OPTIONS[luck_index])
	GameManager.passive_card_count = CARD_OPTIONS[card_index]
	GameManager.passive_pick_count = PICK_OPTIONS[pick_index]
	if mode_index == 3:
		# Debug mode — give each player some test passives
		GameManager.game_mode = GameManager.GameMode.DEBUG

	var count := 0
	for i in range(4):
		if slot_device[i] != -1:
			count += 1
			GameManager.player_ability_choices[i] = slot_abilities[i]
			InputManager.bind_device_to_player(slot_device[i], i + 1)
		else:
			InputManager.unbind_player(i + 1)
			GameManager.player_ability_choices[i] = [-1, -1]

	GameManager.player_colors = PLAYER_COLORS.duplicate()
	InputManager.setup_all_bound_players()
	GameManager.start_game(count)


# ══════════════════ DRAWING ══════════════════

func _draw() -> void:
	var vp := get_viewport_rect().size

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.1, 0.08, 0.14))

	# Background pattern
	for i in range(15):
		for j in range(10):
			var cx := i * 140.0 + 30.0
			var cy := j * 120.0 + 30.0
			draw_circle(Vector2(cx, cy), 35.0, Color(0.15, 0.12, 0.2, 0.3))

	_draw_title(vp)
	_draw_player_slots(vp)
	_draw_settings(vp)
	_draw_start_button(vp)


func _draw_title(vp: Vector2) -> void:
	draw_rect(Rect2(0, 20, vp.x, 80), Color(0.15, 0.1, 0.2, 0.8))
	_draw_text_centered(
		Vector2(vp.x / 2.0, 65), "TANGLE BATTLE", 42.0, Color(0.9, 0.85, 1.0)
	)
	for i in range(5):
		var x := 100.0 + i * 430.0
		var col := PLAYER_COLORS[i % 4].lerp(Color.WHITE, 0.2)
		col.a = 0.3
		draw_circle(Vector2(x, 60), 12.0, col)


func _draw_player_slots(vp: Vector2) -> void:
	var slot_w := 380.0
	var slot_h := 500.0
	var gap := 30.0
	var total_w := slot_w * 4 + gap * 3
	var start_x := (vp.x - total_w) / 2.0
	var start_y := 130.0

	for i in range(4):
		var x := start_x + i * (slot_w + gap)
		var rect := Rect2(x, start_y, slot_w, slot_h)
		var is_joined := slot_device[i] != -1

		var bg := Color(0.12, 0.1, 0.16, 0.9) if not is_joined \
			else PLAYER_COLORS[i].darkened(0.75)
		draw_rect(rect, bg)

		var border_col := Color(0.3, 0.25, 0.35) if not is_joined \
			else PLAYER_COLORS[i].darkened(0.2)
		draw_rect(rect, border_col, false, 3.0)

		for corner in [rect.position, Vector2(rect.end.x, rect.position.y),
			Vector2(rect.position.x, rect.end.y), rect.end]:
			draw_circle(corner, 8.0, border_col)

		if is_joined:
			_draw_joined_slot(i, rect)
		else:
			_draw_empty_slot(i, rect)


func _draw_empty_slot(slot: int, rect: Rect2) -> void:
	var cx := rect.position.x + rect.size.x / 2.0
	var cy := rect.position.y + rect.size.y / 2.0

	var alpha := 0.5 + sin(blink_timer * 3.0) * 0.3
	var col := Color(0.6, 0.55, 0.7, alpha)

	_draw_text_centered(Vector2(cx, cy - 30), "?", 60.0, col)
	_draw_text_centered(Vector2(cx, cy + 40), "PRESS X", 22.0, col)
	_draw_text_centered(Vector2(cx, cy + 65), "TO JOIN", 22.0, col)
	_draw_text_centered(
		Vector2(cx, rect.position.y + 30), "P%d" % (slot + 1),
		24.0, Color(0.4, 0.35, 0.5)
	)


func _draw_joined_slot(slot: int, rect: Rect2) -> void:
	var cx := rect.position.x + rect.size.x / 2.0
	var top := rect.position.y
	var pc := PLAYER_COLORS[slot]

	# Header
	draw_rect(Rect2(rect.position.x, top, rect.size.x, 50), pc.darkened(0.5))
	_draw_text_centered(
		Vector2(cx, top + 28), "PLAYER %d" % (slot + 1), 24.0, pc
	)

	# Yarn ball icon (texture asset, tinted to player color)
	var ball_y := top + 120.0
	YarnBallIcon.draw_at(self, Vector2(cx, ball_y), 40.0, pc)

	# Device name — inside header bar to avoid overlap with selectors
	var dev_name := InputManager.get_device_name(slot_device[slot])
	_draw_text_centered(
		Vector2(cx, top + 45), dev_name, 11.0, Color(0.6, 0.6, 0.7)
	)

	# Determine focus: 0=color, 1=ab1, 2=ab2
	var focus: int
	if slot == 0:
		focus = kb_focus  # 0=color, 1=ab1, 2=ab2, 3=hp, 4=rounds
	else:
		focus = slot_focus[slot]  # 0=color, 1=ab1, 2=ab2

	# Color selector
	_draw_color_selector(slot, cx, top + 210, focus == 0)

	# Ability selectors
	_draw_ability_selector(slot, 0, cx, top + 300, focus == 1)
	_draw_ability_selector(slot, 1, cx, top + 400, focus == 2)

	# Controls hint
	if slot_device[slot] == -2:  # keyboard
		_draw_text_centered(
			Vector2(cx, rect.end.y - 40),
			"W/S + A/D: select", 12.0, Color(0.45, 0.4, 0.5)
		)
		_draw_text_centered(
			Vector2(cx, rect.end.y - 22),
			"ESC: leave", 12.0, Color(0.45, 0.4, 0.5)
		)
	else:
		_draw_text_centered(
			Vector2(cx, rect.end.y - 40),
			"Stick: select", 12.0, Color(0.45, 0.4, 0.5)
		)
		_draw_text_centered(
			Vector2(cx, rect.end.y - 22),
			"O: leave  X: start", 12.0, Color(0.45, 0.4, 0.5)
		)


func _draw_color_selector(
	slot: int, cx: float, cy: float, focused: bool
) -> void:
	var pc := PLAYER_COLORS[slot]
	_draw_text_centered(
		Vector2(cx, cy - 18), "Color", 14.0, Color(0.6, 0.55, 0.7)
	)
	# Color preview circle
	var box_w := 200.0
	var box_h := 40.0
	var box := Rect2(cx - box_w / 2.0, cy - box_h / 2.0 + 8, box_w, box_h)
	draw_rect(box, Color(0.15, 0.13, 0.2))
	if focused:
		var glow := sin(blink_timer * 5.0) * 0.15 + 0.85
		draw_rect(box.grow(3), Color(pc.r, pc.g, pc.b, glow * 0.4), false, 3.0)
	else:
		draw_rect(box, Color(0.3, 0.25, 0.35), false, 2.0)
	# Color circle
	draw_circle(Vector2(cx, cy + 8), 14.0, pc)
	draw_arc(Vector2(cx, cy + 8), 14.0, 0.0, TAU, 12, pc.lightened(0.3), 2.0)
	# Arrows
	var arrow_col := pc if focused else Color(0.4, 0.35, 0.5)
	draw_line(Vector2(box.position.x - 15, cy + 8), Vector2(box.position.x - 5, cy), arrow_col, 2.5)
	draw_line(Vector2(box.position.x - 15, cy + 8), Vector2(box.position.x - 5, cy + 16), arrow_col, 2.5)
	draw_line(Vector2(box.end.x + 15, cy + 8), Vector2(box.end.x + 5, cy), arrow_col, 2.5)
	draw_line(Vector2(box.end.x + 15, cy + 8), Vector2(box.end.x + 5, cy + 16), arrow_col, 2.5)


func _draw_ability_selector(
	slot: int, ab_slot: int, cx: float, cy: float, focused: bool
) -> void:
	var ab_id: int = slot_abilities[slot][ab_slot]
	var pc := PLAYER_COLORS[slot]

	# Label
	var slot_label := "Ability %d" % (ab_slot + 1)
	_draw_text_centered(
		Vector2(cx, cy - 20), slot_label, 14.0, Color(0.6, 0.55, 0.7)
	)

	var box_w := 300.0
	var box_h := 55.0
	var box := Rect2(cx - box_w / 2.0, cy - box_h / 2.0 + 10, box_w, box_h)

	# Focus highlight
	if focused:
		var glow := sin(blink_timer * 5.0) * 0.15 + 0.85
		var focus_col := pc.lerp(Color.WHITE, 0.3)
		focus_col.a = glow * 0.4
		draw_rect(box.grow(4), focus_col, false, 3.0)

	if ab_id == -1:
		draw_rect(box, Color(0.2, 0.18, 0.25))
		draw_rect(box, pc.darkened(0.3), false, 2.0)
		_draw_text_centered(
			Vector2(cx, cy + 13), "RANDOM", 20.0, Color(0.8, 0.7, 0.9)
		)
		draw_circle(Vector2(cx - 70, cy + 10), 10.0, Color(0.3, 0.25, 0.35))
		_draw_text_centered(
			Vector2(cx - 70, cy + 14), "?", 16.0, Color(0.6, 0.5, 0.7)
		)
	else:
		var data: Dictionary = AbilityRegistry.get_data(ab_id)
		var ab_color: Color = data["color"]
		var ab_name: String = data["name"]

		draw_rect(box, Color(0.15, 0.13, 0.2))
		draw_rect(box, ab_color.darkened(0.3), false, 2.0)

		var icon_x := cx - box_w / 2.0 + 30.0
		# Textured ability icon (assets/textures/abilities/<name>.png)
		AbilityIcon.draw_at(self, Vector2(icon_x, cy + 10), 18.0, ab_id)
		draw_arc(
			Vector2(icon_x, cy + 10), 18.0, 0.0, TAU, 16, ab_color, 2.0
		)
		_draw_text_centered(
			Vector2(cx + 20, cy + 13), ab_name, 18.0, ab_color
		)

	# Arrows (brighter when focused)
	var arrow_col := pc if focused else Color(0.4, 0.35, 0.5)
	# Left
	draw_line(
		Vector2(box.position.x - 18, cy + 10),
		Vector2(box.position.x - 8, cy + 2), arrow_col, 2.5
	)
	draw_line(
		Vector2(box.position.x - 18, cy + 10),
		Vector2(box.position.x - 8, cy + 18), arrow_col, 2.5
	)
	# Right
	draw_line(
		Vector2(box.end.x + 18, cy + 10),
		Vector2(box.end.x + 8, cy + 2), arrow_col, 2.5
	)
	draw_line(
		Vector2(box.end.x + 18, cy + 10),
		Vector2(box.end.x + 8, cy + 18), arrow_col, 2.5
	)


func _draw_settings(vp: Vector2) -> void:
	var bar_y := vp.y - 130.0
	draw_rect(Rect2(0, bar_y, vp.x, 100), Color(0.12, 0.1, 0.16, 0.9))
	draw_line(
		Vector2(0, bar_y), Vector2(vp.x, bar_y),
		Color(0.3, 0.25, 0.35), 2.0
	)

	var cx := vp.x / 2.0

	# HP
	var hp_focused := kb_focus == 3
	_draw_text_centered(
		Vector2(cx - 250, bar_y + 18), "HP", 16.0, Color(0.6, 0.55, 0.7)
	)
	var hp_col := Color(0.2, 1.0, 0.3) if hp_focused else Color(0.2, 0.8, 0.2)
	_draw_setting_value(
		cx - 250, bar_y + 42, str(HP_OPTIONS[hp_index]), hp_col, hp_focused
	)

	# Rounds (dimmed in Endless mode)
	var rounds_focused := kb_focus == 4
	var rounds_dim := 0.3 if mode_index == 1 else 1.0
	_draw_text_centered(
		Vector2(cx - 50, bar_y + 18), "ROUNDS TO WIN", 16.0,
		Color(0.6, 0.55, 0.7, rounds_dim)
	)
	var r_col := Color(1.0, 0.85, 0.2) if rounds_focused else Color(0.9, 0.7, 0.1)
	r_col.a = rounds_dim
	if mode_index == 1:
		_draw_setting_value(
			cx - 50, bar_y + 42, "INF", r_col, false)
	else:
		_draw_setting_value(
			cx - 50, bar_y + 42, str(ROUND_OPTIONS[rounds_index]),
			r_col, rounds_focused)

	# Game Mode
	var mode_focused := kb_focus == 5
	_draw_text_centered(
		Vector2(cx + 250, bar_y + 18), "MODE", 16.0, Color(0.6, 0.55, 0.7)
	)
	var m_col := Color(0.8, 0.4, 1.0) if mode_focused else Color(0.6, 0.3, 0.8)
	_draw_setting_value(
		cx + 250, bar_y + 42, GameManager.MODE_NAMES[mode_index],
		m_col, mode_focused
	)

	# Second row
	var bar_y2 := bar_y + 55

	# Luck Boost
	var luck_focused := kb_focus == 6
	_draw_text_centered(Vector2(cx - 250, bar_y2 + 5), "LUCK", 14.0, Color(0.6, 0.55, 0.7))
	var lk_col := Color(0.9, 0.7, 0.2) if luck_focused else Color(0.7, 0.55, 0.15)
	_draw_setting_value(cx - 250, bar_y2 + 22, str(LUCK_OPTIONS[luck_index]), lk_col, luck_focused)

	# Cards
	var cards_focused := kb_focus == 7
	_draw_text_centered(Vector2(cx - 50, bar_y2 + 5), "CARDS", 14.0, Color(0.6, 0.55, 0.7))
	var cc_col := Color(0.4, 0.7, 1.0) if cards_focused else Color(0.3, 0.5, 0.8)
	_draw_setting_value(cx - 50, bar_y2 + 22, str(CARD_OPTIONS[card_index]), cc_col, cards_focused)

	# Picks
	var picks_focused := kb_focus == 8
	_draw_text_centered(Vector2(cx + 150, bar_y2 + 5), "PICKS", 14.0, Color(0.6, 0.55, 0.7))
	var pk_col := Color(0.7, 0.4, 1.0) if picks_focused else Color(0.5, 0.3, 0.8)
	_draw_setting_value(cx + 150, bar_y2 + 22, str(PICK_OPTIONS[pick_index]), pk_col, picks_focused)

	# Hint
	_draw_text_centered(
		Vector2(cx + 500, bar_y + 30),
		"P1: W/S + A/D", 13.0, Color(0.4, 0.35, 0.5)
	)


func _draw_setting_value(
	cx: float, cy: float, text: String, col: Color, focused: bool
) -> void:
	# Focus box
	if focused:
		var glow := sin(blink_timer * 5.0) * 0.1 + 0.9
		draw_rect(
			Rect2(cx - 50, cy - 14, 100, 28),
			Color(col.r, col.g, col.b, 0.15 * glow)
		)

	# Left arrow
	var ac := col if focused else col.darkened(0.3)
	draw_line(Vector2(cx - 48, cy), Vector2(cx - 38, cy - 8), ac, 2.5)
	draw_line(Vector2(cx - 48, cy), Vector2(cx - 38, cy + 8), ac, 2.5)
	# Value
	_draw_text_centered(Vector2(cx, cy), text, 24.0, col)
	# Right arrow
	draw_line(Vector2(cx + 48, cy), Vector2(cx + 38, cy - 8), ac, 2.5)
	draw_line(Vector2(cx + 48, cy), Vector2(cx + 38, cy + 8), ac, 2.5)


func _draw_start_button(vp: Vector2) -> void:
	var btn_w := 300.0
	var btn_h := 55.0
	var cx := vp.x / 2.0
	var cy := vp.y - 15.0
	var btn_rect := Rect2(cx - btn_w / 2.0, cy - btn_h / 2.0, btn_w, btn_h)

	var can_start_draw := joined_count >= 2 or (mode_index == 3 and joined_count >= 1)
	if can_start_draw:
		var pulse := 0.8 + sin(blink_timer * 4.0) * 0.2
		var btn_col := Color(0.2, 0.7, 0.3, pulse)
		draw_rect(btn_rect, btn_col.darkened(0.5))
		draw_rect(btn_rect, btn_col, false, 3.0)
		_draw_text_centered(
			Vector2(cx, cy + 3), "START [ENTER / A]", 24.0, btn_col
		)
	else:
		draw_rect(btn_rect, Color(0.15, 0.13, 0.18))
		draw_rect(btn_rect, Color(0.3, 0.25, 0.3), false, 2.0)
		_draw_text_centered(
			Vector2(cx, cy + 3), "NEED 2+ PLAYERS", 20.0, Color(0.4, 0.35, 0.45)
		)


# ══════════════════ TEXT HELPER ══════════════════

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


# ══════════════════ ABILITY EMBLEMS ══════════════════

func _draw_ability_emblem_lobby(
	ab_id: int, c: Vector2, col: Color
) -> void:
	match ab_id:
		0:  # Yarn Toss
			draw_circle(c + Vector2(2, 0), 6.0, col)
			draw_line(c + Vector2(-8, 3), c + Vector2(-3, 0), col, 2.0)
		1:  # Needle Dash
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 2.5)
			draw_line(c + Vector2(4, -5), c + Vector2(8, 0), col, 2.5)
			draw_line(c + Vector2(4, 5), c + Vector2(8, 0), col, 2.5)
		2:  # Yarn Bomb
			draw_circle(c, 6.0, col)
			for j in range(4):
				var a := j * TAU / 4.0 + 0.4
				draw_line(c + Vector2(cos(a), sin(a)) * 6.0,
					c + Vector2(cos(a), sin(a)) * 11.0, col, 2.0)
		3:  # Thread Pull
			draw_line(c + Vector2(-10, 0), c + Vector2(-3, 0), col, 2.0)
			draw_line(c + Vector2(10, 0), c + Vector2(3, 0), col, 2.0)
			draw_circle(c, 3.0, col)
		4:  # Spin Attack
			draw_arc(c, 8.0, 0.0, TAU * 0.75, 14, col, 2.5)
			var tip := c + Vector2(cos(TAU * 0.75), sin(TAU * 0.75)) * 8.0
			draw_circle(tip, 3.0, col)
		5:  # Grenade
			draw_circle(c + Vector2(0, 2), 7.0, col)
			draw_line(c + Vector2(0, -5), c + Vector2(4, -11), col, 2.5)
			draw_circle(c + Vector2(4, -11), 3.0, col.lightened(0.4))
		6:  # Rocket Launcher
			draw_line(c + Vector2(0, 4), c + Vector2(0, -8), col, 2.5)
			draw_line(c + Vector2(0, -8), c + Vector2(-3, -4), col, 2.0)
			draw_line(c + Vector2(0, -8), c + Vector2(3, -4), col, 2.0)
			draw_line(c + Vector2(-6, 4), c + Vector2(-9, -5), col, 2.0)
			draw_line(c + Vector2(6, 4), c + Vector2(9, -5), col, 2.0)
		7:  # Stink Cloud
			draw_circle(c, 7.0, col.darkened(0.2))
			draw_circle(c + Vector2(-5, -4), 4.0, col)
			draw_circle(c + Vector2(5, -3), 4.5, col)
			draw_circle(c + Vector2(0, 4), 4.0, col.darkened(0.1))
		8:  # Spike Armor
			draw_circle(c, 5.0, col.darkened(0.2))
			for si in range(6):
				var sa := si * TAU / 6.0 - PI / 6.0
				draw_line(c + Vector2(cos(sa), sin(sa)) * 5.0,
					c + Vector2(cos(sa), sin(sa)) * 11.0, col, 2.5)
		9:  # Swap
			draw_line(c + Vector2(-8, -5), c + Vector2(8, 5), col, 2.5)
			draw_line(c + Vector2(8, 5), c + Vector2(4, 2), col, 2.0)
			draw_line(c + Vector2(8, 5), c + Vector2(5, 9), col, 2.0)
			draw_line(c + Vector2(8, -5), c + Vector2(-8, 5), col, 2.5)
			draw_line(c + Vector2(-8, 5), c + Vector2(-4, 2), col, 2.0)
			draw_line(c + Vector2(-8, 5), c + Vector2(-5, 9), col, 2.0)
		10:  # Boomerang
			for bi in range(4):
				var ba := bi * PI / 2.0 + 0.3
				draw_line(c, c + Vector2(cos(ba), sin(ba)) * 10.0, col, 2.5)
		11:  # Guided Rocket
			draw_line(c + Vector2(-8, 5), c + Vector2(0, -8), col, 2.5)
			draw_line(c + Vector2(0, -8), c + Vector2(8, 0), col, 2.5)
			draw_circle(c + Vector2(8, 0), 3.0, col)
		12:  # Tripwire
			draw_circle(c + Vector2(-8, 0), 4.0, col)
			draw_circle(c + Vector2(8, 0), 4.0, col)
			draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), col, 2.0)
			draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), col, 1.5)
		13:  # Grab/Throw
			draw_arc(c, 8.0, -0.5, PI + 0.5, 10, col, 2.5)
			draw_line(c + Vector2(7, -4), c + Vector2(10, -8), col, 2.0)
			draw_line(c + Vector2(7, 4), c + Vector2(10, 8), col, 2.0)
		14:  # Black Hole
			draw_circle(c, 7.0, col.darkened(0.5))
			draw_arc(c, 10.0, 0.0, TAU * 0.7, 12, col, 2.5)
			draw_arc(c, 6.0, PI, PI + TAU * 0.6, 10, col, 2.0)
		15:  # Portal Gate
			draw_arc(c + Vector2(-5, 0), 6.0, 0.0, TAU, 10, col, 2.0)
			draw_arc(c + Vector2(5, 0), 6.0, 0.0, TAU, 10, col, 2.0)
			draw_line(c + Vector2(-1, -4), c + Vector2(1, 4), col, 2.0)
			draw_line(c + Vector2(1, -4), c + Vector2(-1, 4), col, 2.0)
		16:  # Heaven's Wrath — light pillars
			draw_line(c + Vector2(-7, -10), c + Vector2(-7, 8), col, 3.0)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 10), col, 2.5)
			draw_line(c + Vector2(7, -10), c + Vector2(7, 8), col, 2.0)
			draw_circle(c + Vector2(-7, -10), 3.0, col)
			draw_circle(c + Vector2(7, -10), 2.0, col)
