extends Control
## Screen-space overlay for pause menu and passive selection.

var game: Node = null

func _process(_delta: float) -> void:
	if game == null:
		game = get_parent().get_parent()
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	if game.is_victory:
		_draw_victory_screen()
	elif game.is_debug_selecting:
		_draw_debug_passive_select()
	elif game.is_selecting_passive:
		_draw_passive_selection()
	elif game.is_paused:
		_draw_pause_menu()
	elif game.is_stats_open:
		_draw_stats_overlay()


func _draw_victory_screen() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var cx := vp.x / 2.0
	var cy := vp.y / 2.0
	var t: float = game.victory_timer
	var winner: int = game.victory_winner

	# Fade in background
	var fade := clampf(t / 0.5, 0.0, 0.7)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, fade))

	if winner <= 0 or winner > 4:
		return
	var pc: Color = GameManager.player_colors[winner - 1]

	# Confetti particles
	for i in range(40):
		var confetti_t := t * 2.0 + i * 0.7
		var cx2 := fmod(i * 137.5 + sin(confetti_t) * 50.0, vp.x)
		var cy2 := fmod(confetti_t * 80.0 + i * 30.0, vp.y + 200) - 100
		var csize := 4.0 + fmod(i * 3.7, 6.0)
		var confetti_colors: Array[Color] = [
			Color(1, 0.3, 0.3, 0.6), Color(0.3, 0.5, 1, 0.6),
			Color(0.3, 0.9, 0.3, 0.6), Color(1, 0.85, 0.2, 0.6),
			Color(0.9, 0.3, 0.9, 0.6),
		]
		var confetti_col: Color = confetti_colors[i % 5]
		var _rot := confetti_t * (2.0 + fmod(i * 0.3, 3.0))
		draw_rect(
			Rect2(cx2 - csize / 2.0, cy2 - csize / 2.0, csize, csize * 0.5),
			confetti_col
		)

	# Firework bursts
	for fi in range(6):
		var ft := t - fi * 0.4 - 0.5
		if ft > 0.0 and ft < 1.5:
			var fx := fmod(fi * 373.0 + 200, vp.x - 200) + 100
			var fy := fmod(fi * 217.0 + 100, vp.y * 0.4) + 100
			var burst_t := clampf(ft / 0.8, 0.0, 1.0)
			var burst_alpha := 1.0 - clampf((ft - 0.5) / 1.0, 0.0, 1.0)
			for si in range(8):
				var sa := si * TAU / 8.0
				var sr := burst_t * 60.0
				var _sc: Array[Color] = [Color(1, 0.8, 0.2), Color(1, 0.4, 0.1), Color(0.3, 0.8, 1)]
				var spark_col: Color = _sc[fi % 3]
				spark_col.a = burst_alpha * 0.7
				draw_circle(
					Vector2(fx + cos(sa) * sr, fy + sin(sa) * sr),
					3.0 * (1.0 - burst_t * 0.5), spark_col
				)

	# Big winner yarn ball
	var ball_y := cy - 60.0
	var ball_scale := clampf(t / 0.8, 0.0, 1.0)
	ball_scale = 1.0 - (1.0 - ball_scale) * (1.0 - ball_scale)  # ease out
	var ball_r := 70.0 * ball_scale

	# Glow
	draw_circle(Vector2(cx, ball_y), ball_r + 30, Color(pc.r, pc.g, pc.b, 0.06))
	draw_circle(Vector2(cx, ball_y), ball_r + 15, Color(pc.r, pc.g, pc.b, 0.08))
	# Body
	draw_circle(Vector2(cx, ball_y), ball_r, pc)
	# Yarn lines
	var dark := pc.darkened(0.3)
	for i in range(7):
		var angle := i * TAU / 7.0 + t * 0.3
		var from := Vector2(cx + cos(angle) * ball_r * 0.4,
			ball_y + sin(angle) * ball_r * 0.4)
		var to := Vector2(cx + cos(angle + 1.0) * ball_r * 0.85,
			ball_y + sin(angle + 1.0) * ball_r * 0.85)
		draw_line(from, to, dark, 3.0)
	# Eyes
	var er := ball_r * 0.15
	draw_circle(Vector2(cx - ball_r * 0.2, ball_y - ball_r * 0.15), er, Color.WHITE)
	draw_circle(Vector2(cx + ball_r * 0.2, ball_y - ball_r * 0.15), er, Color.WHITE)
	draw_circle(Vector2(cx - ball_r * 0.12, ball_y - ball_r * 0.15), er * 0.5, Color.BLACK)
	draw_circle(Vector2(cx + ball_r * 0.28, ball_y - ball_r * 0.15), er * 0.5, Color.BLACK)
	# Crown
	var crown_y := ball_y - ball_r - 10.0
	var crown_pts := PackedVector2Array([
		Vector2(cx - 25, crown_y),
		Vector2(cx - 15, crown_y - 20),
		Vector2(cx, crown_y - 8),
		Vector2(cx + 15, crown_y - 20),
		Vector2(cx + 25, crown_y),
	])
	draw_colored_polygon(crown_pts, Color(1, 0.85, 0.2))

	# Text
	var text_y := ball_y + ball_r + 50.0
	_txt(font, Vector2(cx, text_y), "PLAYER %d WINS!" % winner, 48.0, pc)
	_txt(font, Vector2(cx, text_y + 45),
		"THE CHAMPION", 24.0, Color(1, 0.85, 0.2, 0.8))


func _draw_pause_menu() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var cx := vp.x / 2.0
	var cy := vp.y / 2.0

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6))

	var panel := Rect2(cx - 250, cy - 150, 500, 300)
	draw_rect(panel, Color(0.12, 0.1, 0.18, 0.95))
	draw_rect(panel, Color(0.4, 0.3, 0.6, 0.6), false, 3.0)

	_txt(font, Vector2(cx, cy - 90), "PAUSED", 40.0, Color(0.9, 0.85, 1.0))

	var items: Array[String] = ["RESUME", "QUIT TO MENU"]
	for i in range(items.size()):
		var iy := cy + i * 70.0
		var focused: bool = (game.pause_selection == i)
		if focused:
			var pulse := 0.7 + sin(game.blink_timer * 5.0) * 0.3
			draw_rect(Rect2(cx - 160, iy - 25, 320, 50), Color(0.3, 0.2, 0.5, 0.3 * pulse))
			draw_rect(Rect2(cx - 160, iy - 25, 320, 50), Color(0.6, 0.4, 0.9, 0.5 * pulse), false, 2.0)
		var col := Color(0.95, 0.9, 1.0) if focused else Color(0.5, 0.45, 0.6)
		_txt(font, Vector2(cx, iy), items[i], 28.0, col)

	_txt(font, Vector2(cx, cy + 120), "ESC/B: Back    Enter/A: Select", 14.0, Color(0.4, 0.35, 0.5))


func _draw_stats_overlay() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.65))

	var cx := vp.x / 2.0
	_txt(font, Vector2(cx, 40), "PLAYER STATS", 32.0, Color(0.9, 0.85, 1.0))
	_txt(font, Vector2(cx, 65), "[TAB]", 14.0, Color(0.5, 0.45, 0.6))

	var players := get_tree().get_nodes_in_group("players")
	var col_w := minf(350.0, (vp.x - 80.0) / maxf(players.size(), 1))
	var total_w := col_w * players.size()
	var start_x := (vp.x - total_w) / 2.0

	for i in range(players.size()):
		var p: CharacterBody2D = players[i]
		var pc: Color = GameManager.player_colors[p.player_id - 1]
		var bx := start_x + i * col_w
		var by := 90.0
		var bw := col_w - 10.0

		# Panel background
		draw_rect(Rect2(bx, by, bw, 420), Color(0.1, 0.08, 0.14, 0.9))
		draw_rect(Rect2(bx, by, bw, 420), pc.darkened(0.3), false, 2.0)

		# Header
		draw_rect(Rect2(bx, by, bw, 40), pc.darkened(0.5))
		_txt(font, Vector2(bx + bw / 2.0, by + 22),
			"PLAYER %d" % p.player_id, 22.0, pc)

		# Yarn ball icon
		var ball_x := bx + bw / 2.0
		var ball_y := by + 80.0
		draw_circle(Vector2(ball_x, ball_y), 25.0, pc)
		draw_circle(Vector2(ball_x - 5, ball_y - 6), 5.0, Color.WHITE)
		draw_circle(Vector2(ball_x + 5, ball_y - 6), 5.0, Color.WHITE)
		draw_circle(Vector2(ball_x - 3, ball_y - 6), 2.5, Color.BLACK)
		draw_circle(Vector2(ball_x + 7, ball_y - 6), 2.5, Color.BLACK)

		# Stats list
		var sy := by + 120.0
		var gap := 32.0
		var label_x := bx + 15.0
		var value_x := bx + bw - 15.0

		# HP
		var hp_text := "%d / %d" % [int(p.hp), int(p.MAX_HP)]
		_txt(font, Vector2(label_x + 20, sy), "HP", 16.0,
			Color(0.6, 0.55, 0.7))
		_txt(font, Vector2(value_x - 30, sy), hp_text, 16.0,
			Color(0.2, 0.9, 0.3))
		sy += gap

		# HP bar
		var bar_w := bw - 30.0
		var hp_ratio: float = p.hp / maxf(p.MAX_HP, 1.0)
		draw_rect(Rect2(label_x, sy - 10, bar_w, 10),
			Color(0.2, 0.15, 0.25))
		draw_rect(Rect2(label_x, sy - 10, bar_w * hp_ratio, 10),
			Color(0.2, 0.8, 0.3))
		sy += gap * 0.7

		# Damage multiplier
		_txt(font, Vector2(label_x + 20, sy), "DMG", 16.0,
			Color(0.6, 0.55, 0.7))
		_txt(font, Vector2(value_x - 30, sy),
			"x%.1f" % p.damage_multiplier, 16.0,
			Color(1.0, 0.5, 0.3))
		sy += gap

		# Extra lives
		_txt(font, Vector2(label_x + 20, sy), "LIVES", 16.0,
			Color(0.6, 0.55, 0.7))
		var lives_col := Color(1.0, 0.85, 0.2) if p.extra_lives > 0 \
			else Color(0.4, 0.35, 0.45)
		_txt(font, Vector2(value_x - 30, sy),
			str(p.extra_lives + 1), 16.0, lives_col)
		sy += gap

		# Luck
		_txt(font, Vector2(label_x + 20, sy), "LUCK", 16.0,
			Color(0.6, 0.55, 0.7))
		var luck_col := Color(0.9, 0.7, 0.2) if p.luck_bonus > 0 \
			else Color(0.4, 0.35, 0.45)
		_txt(font, Vector2(value_x - 30, sy),
			"+%.0f" % p.luck_bonus if p.luck_bonus > 0 else "0", 16.0,
			luck_col)
		sy += gap

		# Regen
		_txt(font, Vector2(label_x + 20, sy), "REGEN", 16.0,
			Color(0.6, 0.55, 0.7))
		var regen_col := Color(0.3, 0.9, 0.5) if p.regen_per_sec > 0 \
			else Color(0.4, 0.35, 0.45)
		_txt(font, Vector2(value_x - 30, sy),
			"%.1f/s" % p.regen_per_sec if p.regen_per_sec > 0 \
			else "0", 16.0, regen_col)
		sy += gap

		# Speed
		_txt(font, Vector2(label_x + 20, sy), "SPEED", 16.0,
			Color(0.6, 0.55, 0.7))
		_txt(font, Vector2(value_x - 30, sy),
			"x%.1f" % p.base_speed_mult, 16.0,
			Color(0.3, 0.7, 1.0))
		sy += gap

		# Cooldown
		_txt(font, Vector2(label_x + 20, sy), "CD", 16.0,
			Color(0.6, 0.55, 0.7))
		_txt(font, Vector2(value_x - 30, sy),
			"x%.1f" % p.cd_multiplier, 16.0,
			Color(0.7, 0.5, 1.0))
		sy += gap

		# Score
		_txt(font, Vector2(label_x + 20, sy), "SCORE", 16.0,
			Color(0.6, 0.55, 0.7))
		_txt(font, Vector2(value_x - 30, sy),
			str(GameManager.scores[p.player_id - 1]), 18.0,
			Color(1.0, 0.95, 0.6))


func _draw_debug_passive_select() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var cx := vp.x / 2.0

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.85))

	var pid: int = game.debug_chooser_id
	var pc: Color = GameManager.player_colors[pid - 1] if pid > 0 \
		else Color.WHITE

	# Header
	_txt(font, Vector2(cx, 35), "DEBUG — SELECT PASSIVES", 28.0,
		Color(0.9, 0.85, 1.0))
	_txt(font, Vector2(cx, 60),
		"Player %d — %d picks left" % [pid, game.debug_picks_left],
		20.0, pc)
	_txt(font, Vector2(cx, 82),
		"W/S: Navigate    Enter: Pick    Tab/D: Next Player",
		14.0, Color(0.5, 0.45, 0.6))

	# List
	var list: Array = game.debug_passive_list
	var scroll: int = game.debug_scroll
	var cursor: int = game.debug_cursor
	var row_h := 50.0
	var list_y := 100.0
	var list_w := vp.x - 100.0
	var list_x := 50.0
	var visible: int = game.DEBUG_CARDS_VISIBLE

	for i in range(visible):
		var idx: int = scroll + i
		if idx >= list.size():
			break
		var entry: Dictionary = list[idx]
		var p_id: int = entry["passive_id"]
		var rar: int = entry["rarity"]
		var pdata: Dictionary = PassiveRegistry.get_data(p_id)
		var rdata: Dictionary = pdata["rarities"][rar]
		var rc: Color = game.RARITY_COLORS[rar]
		var focused: bool = (idx == cursor)

		var ry := list_y + i * row_h
		# Background
		var bg := Color(0.15, 0.12, 0.2, 0.9)
		if focused:
			bg = bg.lightened(0.1)
		draw_rect(Rect2(list_x, ry, list_w, row_h - 4), bg)

		# Rarity bar on left
		draw_rect(Rect2(list_x, ry, 6, row_h - 4), rc)

		# Focus border
		if focused:
			var glow := 0.6 + sin(game.blink_timer * 5.0) * 0.2
			draw_rect(Rect2(list_x, ry, list_w, row_h - 4),
				Color(rc.r, rc.g, rc.b, glow), false, 2.0)

		# Icon
		var icon_c := Vector2(list_x + 35, ry + (row_h - 4) / 2.0)
		draw_circle(icon_c, 14.0, Color(0.1, 0.08, 0.14))
		draw_arc(icon_c, 14.0, 0.0, TAU, 10, rc, 1.5)
		_draw_passive_icon(pdata["icon"], icon_c, rc)

		# Name + rarity
		var name_x := list_x + 60.0
		_txt(font, Vector2(name_x + 80, ry + 16),
			pdata["name"], 16.0, Color(0.95, 0.9, 1.0))
		_txt(font, Vector2(name_x + 80, ry + 34),
			game.RARITY_NAMES[rar], 12.0, rc)

		# Positive effect
		var pos_text: String = rdata.get("positive", "")
		if pos_text.length() > 0:
			_txt(font, Vector2(list_x + list_w - 150, ry + 22),
				pos_text, 13.0, Color(0.3, 0.9, 0.3))

	# Scrollbar
	if list.size() > visible:
		var sb_x := list_x + list_w + 5
		var sb_h := visible * row_h
		var ratio: float = float(visible) / list.size()
		var thumb_h := maxf(sb_h * ratio, 20.0)
		var thumb_y: float = list_y + (float(scroll) / (list.size() - visible)) \
			* (sb_h - thumb_h)
		draw_rect(Rect2(sb_x, list_y, 6, sb_h),
			Color(0.2, 0.18, 0.25))
		draw_rect(Rect2(sb_x, thumb_y, 6, thumb_h),
			Color(0.5, 0.4, 0.7))


func _draw_passive_selection() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var cx := vp.x / 2.0
	var bt: float = game.blink_timer

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.75))

	var pid: int = game.current_chooser_id
	if pid <= 0:
		return
	var pc: Color = GameManager.player_colors[pid - 1]

	# Compact header: ball + title + timer on one row
	var header_y := 55.0
	# Ball
	draw_circle(Vector2(cx, header_y), 40.0, pc)
	var dark := pc.darkened(0.3)
	for i in range(5):
		var angle := i * TAU / 5.0 + bt * 0.5
		var from := Vector2(cx + cos(angle) * 14, header_y + sin(angle) * 14)
		var to := Vector2(cx + cos(angle + 1.0) * 35, header_y + sin(angle + 1.0) * 35)
		draw_line(from, to, dark, 2.0)
	# Eyes
	draw_circle(Vector2(cx - 8, header_y - 8), 6.0, Color.WHITE)
	draw_circle(Vector2(cx + 8, header_y - 8), 6.0, Color.WHITE)
	draw_circle(Vector2(cx - 5, header_y - 8), 3.0, Color.BLACK)
	draw_circle(Vector2(cx + 11, header_y - 8), 3.0, Color.BLACK)

	# Title below ball
	_txt(font, Vector2(cx, header_y + 58),
		"PLAYER %d" % pid, 28.0, pc)

	# Timer — right side
	var remaining: float = game.passive_timer
	var timer_col := Color(0.9, 0.9, 0.9) if remaining > 3.0 \
		else Color(1, 0.3, 0.2)
	_txt(font, Vector2(vp.x - 80, header_y),
		"%.0f" % ceilf(remaining), 40.0, timer_col)

	# "CHOOSE A PASSIVE" subtitle
	_txt(font, Vector2(cx, header_y + 85),
		"CHOOSE A PASSIVE", 18.0, Color(0.6, 0.55, 0.7))

	# Cards — dynamic layout (1-10 cards)
	var num_cards: int = game.passive_choices.size()
	var gap := 12.0
	var card_w := minf(240.0, (vp.x - 80.0 - gap * (num_cards - 1)) / num_cards)
	var card_h := 320.0
	var total_w := card_w * num_cards + gap * (num_cards - 1)
	var start_x := (vp.x - total_w) / 2.0
	var card_top := (vp.y - card_h) / 2.0 + 30.0  # centered vertically with slight offset

	# Animation progress
	var anim_t: float = game.passive_anim_timer
	var anim_dur: float = game.PASSIVE_ANIM_DURATION

	for i in range(num_cards):
		var choice: Dictionary = game.passive_choices[i]
		var passive_id: int = choice["passive_id"]
		var rar: int = choice["rarity"]
		var pdata: Dictionary = PassiveRegistry.get_data(passive_id)
		var rdata: Dictionary = pdata["rarities"][rar]
		var rc: Color = game.RARITY_COLORS[rar]

		# Staggered slide-in from bottom — adapt to card count
		var stagger_per: float = minf(0.08, (anim_dur * 0.6) / maxf(num_cards, 1))
		var stagger: float = i * stagger_per
		var card_anim := clampf((anim_t - stagger) / maxf(anim_dur - stagger, 0.1), 0.0, 1.0)
		# Ease out
		card_anim = 1.0 - (1.0 - card_anim) * (1.0 - card_anim)

		var card_x := start_x + i * (card_w + gap)
		var slide_offset := (1.0 - card_anim) * (vp.y - card_top + 50.0)
		var card := Rect2(card_x, card_top + slide_offset, card_w, card_h)
		var focused: bool = (game.passive_cursor == i)
		var _card_alpha := card_anim

		# Drop animation — selected card falls, others fade out
		if game.passive_waiting_drop and game.passive_drop_timer > 0.0:
			var drop_t: float = 1.0 - (game.passive_drop_timer / 0.7)
			if game.passive_drop_card == i:
				# Selected card drops down with rotation feel
				card.position.y += drop_t * drop_t * vp.y * 0.9
				_card_alpha *= maxf(1.0 - drop_t * 1.3, 0.0)
			else:
				# Non-selected cards fade out
				_card_alpha *= maxf(1.0 - drop_t * 2.0, 0.0)

		if focused and not game.passive_waiting_drop:
			card.position.y -= 12.0

		# Background
		var bg := Color(0.15, 0.12, 0.2, 0.95 * _card_alpha)
		if focused:
			bg = bg.lightened(0.08)
		draw_rect(card, bg)

		# Border
		var bw := 3.0 if not focused else 4.0
		var ba := (0.5 if not focused else (0.7 + sin(bt * 5.0) * 0.3)) * _card_alpha
		draw_rect(card, Color(rc.r, rc.g, rc.b, ba), false, bw)

		var icon_cx := card.position.x + card_w / 2.0

		# Rarity header — compact
		var header_h := 28.0
		draw_rect(Rect2(card.position.x, card.position.y, card_w, header_h), rc.darkened(0.5))
		_txt(font, Vector2(icon_cx, card.position.y + 16),
			game.RARITY_NAMES[rar], 14.0, rc)

		# Icon — centered in card
		var icon_y := card.position.y + header_h + 42.0
		draw_circle(Vector2(icon_cx, icon_y), 28.0, Color(0.1, 0.08, 0.14))
		draw_arc(Vector2(icon_cx, icon_y), 28.0, 0.0, TAU, 16, rc, 2.0)
		_draw_passive_icon(pdata["icon"], Vector2(icon_cx, icon_y), rc)

		# Name
		var name_y := icon_y + 42.0
		_txt_clipped(font, Vector2(icon_cx, name_y),
			pdata["name"], 16.0, Color(0.95, 0.9, 1.0), card_w - 14.0)

		# Description
		var desc_y := name_y + 20.0
		_txt_clipped(font, Vector2(icon_cx, desc_y),
			pdata["description"], 11.0, Color(0.55, 0.5, 0.65), card_w - 12.0)

		# Separator
		var sep_y := desc_y + 14.0
		draw_line(
			Vector2(card.position.x + 10, sep_y),
			Vector2(card.position.x + card_w - 10, sep_y),
			Color(0.3, 0.25, 0.35, 0.5), 1.0
		)

		# Positive effect
		var pos_text: String = rdata.get("positive", "")
		if pos_text.length() > 0:
			_txt_clipped(font, Vector2(icon_cx, sep_y + 18.0),
				pos_text, 13.0, Color(0.3, 0.9, 0.3), card_w - 12.0)

		# Negative effect
		var neg_text: String = rdata.get("negative", "")
		if neg_text.length() > 0:
			_txt_clipped(font, Vector2(icon_cx, sep_y + 38.0),
				neg_text, 12.0, Color(0.9, 0.3, 0.3), card_w - 12.0)

	# Controls hint
	_txt(font, Vector2(cx, vp.y - 25),
		"A/D: Choose    Enter/X: Select", 15.0, Color(0.4, 0.35, 0.5))


func _draw_passive_icon(icon_name: String, c: Vector2, col: Color) -> void:
	match icon_name:
		"poison":
			draw_circle(c, 16.0, col.darkened(0.2))
			draw_circle(c + Vector2(-6, -4), 4.0, Color(0, 0, 0, 0.7))
			draw_circle(c + Vector2(6, -4), 4.0, Color(0, 0, 0, 0.7))
			draw_line(c + Vector2(-5, 7), c + Vector2(5, 7), Color(0, 0, 0, 0.5), 2.0)
		"phoenix":
			draw_line(c + Vector2(0, 15), c + Vector2(0, -15), col, 3.0)
			draw_line(c + Vector2(0, -15), c + Vector2(-10, -5), col, 2.5)
			draw_line(c + Vector2(0, -15), c + Vector2(10, -5), col, 2.5)
			draw_line(c + Vector2(-8, 5), c + Vector2(-15, -8), col, 2.0)
			draw_line(c + Vector2(8, 5), c + Vector2(15, -8), col, 2.0)
		"tank":
			draw_circle(c, 18.0, col.darkened(0.3))
			draw_arc(c, 18.0, 0.0, TAU, 16, col, 3.0)
			_txt(ThemeDB.fallback_font, c, "+", 24.0, col)
		"lifesteal":
			draw_circle(c + Vector2(-7, -5), 9.0, col)
			draw_circle(c + Vector2(7, -5), 9.0, col)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-15, -2), c + Vector2(0, 15), c + Vector2(15, -2),
			]), col)
		"thread":
			draw_line(c + Vector2(-12, 8), c + Vector2(12, -8), col, 2.5)
			draw_circle(c + Vector2(12, -8), 5.0, col)
			draw_circle(c + Vector2(-12, 8), 3.0, col.darkened(0.3))
		"radius":
			draw_arc(c, 14.0, 0.0, TAU, 16, col, 2.0)
			draw_arc(c, 8.0, 0.0, TAU, 12, col, 1.5)
			draw_circle(c, 3.0, col)
		"clock":
			draw_arc(c, 14.0, 0.0, TAU, 16, col, 2.0)
			draw_line(c, c + Vector2(0, -10), col, 2.5)
			draw_line(c, c + Vector2(7, 0), col, 2.0)
			draw_circle(c, 2.0, col)
		"fire_thread":
			draw_line(c + Vector2(-12, 8), c + Vector2(12, -8), Color(1, 0.5, 0.1), 3.0)
			draw_circle(c + Vector2(-6, 4), 5.0, Color(1, 0.3, 0.05))
			draw_circle(c + Vector2(6, -4), 5.0, Color(1, 0.4, 0.1))
		"ricochet":
			draw_line(c + Vector2(-10, 6), c + Vector2(0, -6), col, 2.5)
			draw_line(c + Vector2(0, -6), c + Vector2(10, 6), col, 2.5)
			draw_circle(c + Vector2(10, 6), 4.0, col)
			draw_circle(c + Vector2(-10, 6), 3.0, col.darkened(0.3))
		"regen":
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 3.0)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 8), col, 3.0)
			draw_arc(c, 12.0, 0.0, TAU, 12, col.darkened(0.2), 1.5)
		"explosive":
			draw_circle(c, 8.0, col)
			for ei in range(5):
				var ea := ei * TAU / 5.0 + 0.3
				draw_line(c + Vector2(cos(ea), sin(ea)) * 8.0,
					c + Vector2(cos(ea), sin(ea)) * 15.0, col, 2.0)
		"swift":
			draw_line(c + Vector2(-10, 4), c + Vector2(10, 4), col, 2.5)
			draw_line(c + Vector2(-6, -2), c + Vector2(10, -2), col, 2.0)
			draw_line(c + Vector2(6, 4), c + Vector2(10, 0), col, 2.0)
			draw_line(c + Vector2(6, -2), c + Vector2(10, 0), col, 2.0)
		"proj_master":
			draw_circle(c + Vector2(5, 0), 8.0, col)
			draw_line(c + Vector2(-10, 0), c + Vector2(-2, 0), col, 2.5)
			draw_circle(c + Vector2(-10, 0), 4.0, col.darkened(0.3))
		"glass_cannon":
			draw_line(c + Vector2(0, 12), c + Vector2(0, -8), col, 3.0)
			draw_line(c + Vector2(-8, -8), c + Vector2(8, -8), col, 2.5)
			draw_circle(c + Vector2(0, -8), 4.0, col)
			draw_circle(c + Vector2(0, 12), 3.0, col.darkened(0.3))
		"iron_skin":
			draw_arc(c, 12.0, -PI * 0.7, PI * 0.7, 12, col, 3.0)
			draw_line(c + Vector2(-8, 6), c + Vector2(8, 6), col, 2.5)
			draw_circle(c, 4.0, col.darkened(0.2))
		"shockwave":
			# Expanding rings
			draw_arc(c, 8.0, 0.0, TAU, 12, col, 2.0)
			draw_arc(c, 14.0, 0.0, TAU, 12, col.darkened(0.3), 1.5)
			draw_circle(c, 4.0, col)
		"lightning":
			# Lightning bolt zigzag
			draw_line(c + Vector2(-3, -12), c + Vector2(3, -4), col, 2.5)
			draw_line(c + Vector2(3, -4), c + Vector2(-2, 0), col, 2.5)
			draw_line(c + Vector2(-2, 0), c + Vector2(4, 12), col, 2.5)
			draw_circle(c + Vector2(4, 12), 2.0, col)
		"heavy":
			# Heavy weight / anvil
			draw_rect(Rect2(c.x - 8, c.y - 4, 16, 10), col)
			draw_rect(Rect2(c.x - 5, c.y - 10, 10, 6), col.darkened(0.2))
			draw_line(c + Vector2(-10, 6), c + Vector2(10, 6), col, 2.0)
		"homing":
			# Crosshair/target circle with arrow
			draw_arc(c, 10.0, 0.0, TAU, 12, col, 2.0)
			draw_line(c + Vector2(0, -14), c + Vector2(0, -6), col, 2.0)
			draw_line(c + Vector2(0, 14), c + Vector2(0, 6), col, 2.0)
			draw_line(c + Vector2(-14, 0), c + Vector2(-6, 0), col, 2.0)
			draw_line(c + Vector2(14, 0), c + Vector2(6, 0), col, 2.0)
			draw_circle(c, 3.0, col)
		"burst":
			# Three projectiles in a fan
			for bi in range(3):
				var ba := -0.3 + bi * 0.3
				var tip := c + Vector2(cos(ba - PI / 2.0), sin(ba - PI / 2.0)) * 12.0
				draw_line(c + Vector2(0, 4), tip, col, 2.0)
				draw_circle(tip, 2.5, col)
		"lucky":
			# Four-point star
			draw_line(c + Vector2(0, -12), c + Vector2(0, 12), col, 2.0)
			draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), col, 2.0)
			draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), col, 1.5)
			draw_line(c + Vector2(7, -7), c + Vector2(-7, 7), col, 1.5)
			draw_circle(c, 3.0, col)
		"spirit":
			# 5 small orbs around a center ring
			draw_arc(c, 8.0, 0.0, TAU, 12, col, 1.5)
			for si in range(5):
				var sa := si * TAU / 5.0 - PI / 2.0
				draw_circle(c + Vector2(cos(sa), sin(sa)) * 13.0,
					3.5, col)
			draw_circle(c, 3.0, Color(1, 1, 1, 0.7))
		"shield_cd":
			draw_arc(c, 10.0, -PI * 0.7, PI * 0.7, 10, col, 2.5)
			draw_line(c + Vector2(-6, 5), c + Vector2(6, 5), col, 2.0)
			draw_line(c + Vector2(0, -2), c + Vector2(0, 4), col, 2.0)
			draw_line(c + Vector2(0, -2), c + Vector2(4, 1), col, 1.5)
		"parry_burst":
			draw_arc(c, 8.0, -PI * 0.7, PI * 0.7, 10, col, 2.0)
			draw_arc(c, 12.0, -PI * 0.5, PI * 0.5, 8, col.darkened(0.3), 1.5)
			draw_circle(c, 3.0, col)
		"phase":
			draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), col, 2.0)
			draw_line(c + Vector2(-4, -6), c + Vector2(-4, 6), col.darkened(0.3), 1.5)
			draw_line(c + Vector2(4, -6), c + Vector2(4, 6), col.darkened(0.3), 1.5)
			draw_circle(c + Vector2(8, 0), 3.0, col)


# ══════════════════ TEXT HELPERS ══════════════════

func _txt(
	font: Font, pos: Vector2, text: String, fs: float, col: Color
) -> void:
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	draw_string(
		font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col
	)


func _txt_clipped(
	font: Font, pos: Vector2, text: String, fs: float, col: Color,
	max_width: float
) -> void:
	## Draw text centered, but clipped to max_width (truncate with ..)
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	var display_text := text
	if ts.x > max_width:
		# Truncate
		while display_text.length() > 3:
			display_text = display_text.substr(0, display_text.length() - 1)
			ts = font.get_string_size(display_text + "..", HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
			if ts.x <= max_width:
				break
		display_text += ".."
		ts = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	draw_string(
		font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0),
		display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col
	)
