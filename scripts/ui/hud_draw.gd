extends Control
## Draws HUD elements: score dots (bottom-left), passive icons (top-right),
## round label (center), passive hover tooltip.
##
## Win-score rows live at the bottom so passive icons stacking from the
## top-right can never reach down and cover them — even when a player
## has every passive slot filled.

var hud: CanvasLayer = null

const PLAYER_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3),
	Color(0.95, 0.85, 0.1),
]
const RARITY_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),
	Color(0.3, 0.8, 0.3),
	Color(0.3, 0.5, 1.0),
	Color(1.0, 0.8, 0.2),
	Color(0.95, 0.2, 0.5),
]
const RARITY_NAMES: Array[String] = [
	"Common", "Uncommon", "Rare", "Legendary", "Mythic"
]

const DOT_R := 7.0
const DOT_GAP := 5.0
const ROW_GAP := 22.0
const PASSIVE_SIZE := 30.0
const PASSIVE_GAP := 5.0


func _ready() -> void:
	hud = get_parent()


func _draw() -> void:
	if hud == null:
		return
	_draw_score_dots()
	_draw_passive_icons()
	_draw_round_label()
	_draw_passive_tooltip()


# ══════════════════ SCORE DOTS ══════════════════

func _draw_score_dots() -> void:
	var win: int = GameManager.win_score
	# Endless mode: show max_score + 1 dots (always one empty ahead)
	if GameManager.game_mode == GameManager.GameMode.ENDLESS:
		var max_score: int = 0
		for i in range(GameManager.player_count):
			if GameManager.scores[i] > max_score:
				max_score = GameManager.scores[i]
		win = max_score + 1

	# Anchor to the bottom-left of the viewport. Rows stack UPWARD so
	# P1 is the topmost row of the block and P4 sits flush with the
	# bottom margin — mirrors the top-right passive column visually.
	var vp := get_viewport_rect().size
	var bottom_margin := 18.0
	var start_x := 20.0
	var block_h: float = GameManager.player_count * ROW_GAP
	var start_y: float = vp.y - block_h - bottom_margin

	for p_idx in range(GameManager.player_count):
		var pc := GameManager.player_colors[p_idx]
		var score: int = GameManager.scores[p_idx]
		var y := start_y + p_idx * ROW_GAP

		for d in range(win):
			var x := start_x + d * (DOT_R * 2.0 + DOT_GAP)
			var center := Vector2(x + DOT_R, y + DOT_R)

			if d < score:
				# Filled dot
				draw_circle(center, DOT_R, pc)
			else:
				# Empty dot
				draw_circle(center, DOT_R, Color(0.2, 0.18, 0.25, 0.6))
				draw_arc(center, DOT_R, 0.0, TAU, 12,
					pc.darkened(0.4), 1.5)


# ══════════════════ PASSIVE ICONS ══════════════════

func _draw_passive_icons() -> void:
	var vp := get_viewport_rect().size
	var players := get_tree().get_nodes_in_group("players")
	var y := 15.0

	for p in players:
		if not "passives" in p:
			continue
		var _pc: Color = PLAYER_COLORS[p.player_id - 1]
		var passives_arr: Array = p.passives

		if passives_arr.is_empty():
			y += PASSIVE_SIZE + 12.0
			continue

		for pi in range(passives_arr.size()):
			var passive_data: Dictionary = passives_arr[pi]
			var pid: int = passive_data["passive_id"]
			var rar: int = passive_data["rarity"]
			var pdata: Dictionary = PassiveRegistry.get_data(pid)
			var rc: Color = RARITY_COLORS[rar]

			var ix := vp.x - 15.0 - (pi + 1) * (PASSIVE_SIZE + PASSIVE_GAP)
			var center := Vector2(ix + PASSIVE_SIZE / 2.0, y + PASSIVE_SIZE / 2.0)

			# Background
			draw_rect(
				Rect2(ix, y, PASSIVE_SIZE, PASSIVE_SIZE),
				Color(0.1, 0.08, 0.14, 0.8)
			)
			# Border — rarity color
			draw_rect(
				Rect2(ix, y, PASSIVE_SIZE, PASSIVE_SIZE),
				rc, false, 2.0
			)
			# Icon
			_draw_passive_mini_icon(pdata["icon"], center, rc)

		y += PASSIVE_SIZE + 12.0


func _draw_passive_mini_icon(icon: String, c: Vector2, col: Color) -> void:
	match icon:
		"poison":
			draw_circle(c, 7.0, col.darkened(0.2))
			draw_circle(c + Vector2(-3, -2), 2.0, Color(0, 0, 0, 0.6))
			draw_circle(c + Vector2(3, -2), 2.0, Color(0, 0, 0, 0.6))
		"phoenix":
			draw_line(c + Vector2(0, 6), c + Vector2(0, -6), col, 2.0)
			draw_line(c + Vector2(0, -6), c + Vector2(-4, -1), col, 1.5)
			draw_line(c + Vector2(0, -6), c + Vector2(4, -1), col, 1.5)
		"tank":
			draw_circle(c, 7.0, col.darkened(0.3))
			draw_arc(c, 7.0, 0.0, TAU, 10, col, 1.5)
		"lifesteal":
			draw_circle(c + Vector2(-3, -2), 4.0, col)
			draw_circle(c + Vector2(3, -2), 4.0, col)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-6, -1), c + Vector2(0, 7), c + Vector2(6, -1)
			]), col)
		"thread":
			draw_line(c + Vector2(-6, 4), c + Vector2(6, -4), col, 2.0)
			draw_circle(c + Vector2(6, -4), 3.0, col)
		"radius":
			draw_arc(c, 6.0, 0.0, TAU, 10, col, 1.5)
			draw_arc(c, 3.0, 0.0, TAU, 8, col, 1.0)
		"clock":
			draw_arc(c, 6.0, 0.0, TAU, 10, col, 1.5)
			draw_line(c, c + Vector2(0, -5), col, 1.5)
			draw_line(c, c + Vector2(4, 0), col, 1.5)
		"fire_thread":
			draw_line(c + Vector2(-5, 4), c + Vector2(5, -4), Color(1, 0.5, 0.1), 2.0)
			draw_circle(c, 3.0, Color(1, 0.3, 0.05))
		"ricochet":
			draw_line(c + Vector2(-5, 3), c + Vector2(0, -3), col, 1.5)
			draw_line(c + Vector2(0, -3), c + Vector2(5, 3), col, 1.5)
			draw_circle(c + Vector2(5, 3), 2.0, col)
		"regen":
			draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), col, 2.0)
			draw_line(c + Vector2(0, -4), c + Vector2(0, 4), col, 2.0)
		"explosive":
			draw_circle(c, 4.0, col)
			for ei in range(4):
				var ea := ei * TAU / 4.0 + 0.3
				draw_line(c + Vector2(cos(ea), sin(ea)) * 4.0,
					c + Vector2(cos(ea), sin(ea)) * 7.0, col, 1.5)
		"swift":
			draw_line(c + Vector2(-5, 2), c + Vector2(5, 2), col, 1.5)
			draw_line(c + Vector2(-3, -2), c + Vector2(5, -2), col, 1.5)
			draw_line(c + Vector2(3, 2), c + Vector2(5, 0), col, 1.5)
		"proj_master":
			draw_circle(c + Vector2(3, 0), 4.0, col)
			draw_line(c + Vector2(-5, 0), c + Vector2(0, 0), col, 1.5)
			draw_circle(c + Vector2(-5, 0), 2.0, col.darkened(0.3))
		"glass_cannon":
			draw_line(c + Vector2(0, 5), c + Vector2(0, -5), col, 2.0)
			draw_line(c + Vector2(-4, -5), c + Vector2(4, -5), col, 1.5)
			draw_circle(c + Vector2(0, -5), 2.0, col)
		"iron_skin":
			draw_arc(c, 6.0, -PI * 0.7, PI * 0.7, 8, col, 2.0)
			draw_line(c + Vector2(-4, 3), c + Vector2(4, 3), col, 1.5)
		"shockwave":
			draw_arc(c, 4.0, 0.0, TAU, 8, col, 1.5)
			draw_arc(c, 7.0, 0.0, TAU, 8, col.darkened(0.3), 1.0)
			draw_circle(c, 2.0, col)
		"lightning":
			draw_line(c + Vector2(-1, -6), c + Vector2(2, -1), col, 1.5)
			draw_line(c + Vector2(2, -1), c + Vector2(-1, 1), col, 1.5)
			draw_line(c + Vector2(-1, 1), c + Vector2(2, 6), col, 1.5)
		"heavy":
			draw_rect(Rect2(c.x - 4, c.y - 2, 8, 5), col)
			draw_rect(Rect2(c.x - 3, c.y - 5, 6, 3), col.darkened(0.2))
		"homing":
			draw_arc(c, 5.0, 0.0, TAU, 8, col, 1.5)
			draw_circle(c, 1.5, col)
			draw_line(c + Vector2(0, -7), c + Vector2(0, -3), col, 1.0)
			draw_line(c + Vector2(0, 7), c + Vector2(0, 3), col, 1.0)
		"burst":
			for bi in range(3):
				var ba := -0.25 + bi * 0.25
				var tip := c + Vector2(cos(ba - PI / 2.0), sin(ba - PI / 2.0)) * 6.0
				draw_line(c, tip, col, 1.5)
		"lucky":
			draw_line(c + Vector2(0, -6), c + Vector2(0, 6), col, 1.5)
			draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), col, 1.5)
			draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), col, 1.0)
			draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), col, 1.0)
			draw_circle(c, 1.5, col)
		"spirit":
			draw_arc(c, 4.0, 0.0, TAU, 8, col, 1.0)
			for si in range(5):
				var sa := si * TAU / 5.0 - PI / 2.0
				draw_circle(c + Vector2(cos(sa), sin(sa)) * 6.5,
					1.5, col)
		"shield_cd":
			draw_arc(c, 5.0, -PI * 0.7, PI * 0.7, 8, col, 1.5)
			draw_line(c + Vector2(-3, 3), c + Vector2(3, 3), col, 1.0)
		"parry_burst":
			draw_arc(c, 4.0, -PI * 0.7, PI * 0.7, 6, col, 1.5)
			draw_arc(c, 6.0, -PI * 0.5, PI * 0.5, 5, col.darkened(0.3), 1.0)
		"phase":
			draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), col, 1.5)
			draw_line(c + Vector2(-2, -3), c + Vector2(-2, 3), col.darkened(0.3), 1.0)
			draw_line(c + Vector2(2, -3), c + Vector2(2, 3), col.darkened(0.3), 1.0)


# ══════════════════ ROUND LABEL ══════════════════

func _draw_round_label() -> void:
	if not hud.round_label_visible:
		return
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	_txt(font, Vector2(vp.x / 2.0, vp.y / 2.0),
		hud.round_label_text, 36.0, hud.round_label_color)


# ══════════════════ PASSIVE TOOLTIP ══════════════════

func _draw_passive_tooltip() -> void:
	if hud.hovered_passive.is_empty():
		return

	var pid: int = hud.hovered_passive["passive_id"]
	var rar: int = hud.hovered_passive["rarity"]
	var pdata: Dictionary = PassiveRegistry.get_data(pid)
	var rdata: Dictionary = pdata["rarities"][rar]
	var rc: Color = RARITY_COLORS[rar]
	var font := ThemeDB.fallback_font

	# Card position near mouse
	var card_w := 280.0
	var card_h := 220.0
	var vp := get_viewport_rect().size
	var mx: float = hud.mouse_pos.x
	var my: float = hud.mouse_pos.y

	# Position card near mouse, keep on screen
	var cx := mx - card_w - 10.0
	if cx < 10.0:
		cx = mx + 10.0
	if cx + card_w > vp.x - 10.0:
		cx = vp.x - card_w - 10.0
	var cy := clampf(my, 10.0, vp.y - card_h - 10.0)

	# Card bg
	draw_rect(Rect2(cx, cy, card_w, card_h), Color(0.12, 0.1, 0.18, 0.95))
	draw_rect(Rect2(cx, cy, card_w, card_h), rc, false, 3.0)

	# Rarity header
	draw_rect(Rect2(cx, cy, card_w, 30), rc.darkened(0.5))
	_txt(font, Vector2(cx + card_w / 2.0, cy + 17), RARITY_NAMES[rar], 16.0, rc)

	# Icon
	var icon_center := Vector2(cx + card_w / 2.0, cy + 70.0)
	draw_circle(icon_center, 25.0, Color(0.08, 0.06, 0.12))
	draw_arc(icon_center, 25.0, 0.0, TAU, 16, rc, 2.0)
	_draw_passive_mini_icon(pdata["icon"], icon_center, rc)

	# Name
	var tcx := cx + card_w / 2.0
	_txt_clip(font, Vector2(tcx, cy + 110.0),
		pdata["name"], 18.0, Color(0.95, 0.9, 1.0), card_w - 16.0)

	# Description
	_txt_clip(font, Vector2(tcx, cy + 132.0),
		pdata["description"], 12.0, Color(0.55, 0.5, 0.65), card_w - 12.0)

	# Positive
	var pos_text: String = rdata.get("positive", "")
	if pos_text.length() > 0:
		_txt_clip(font, Vector2(tcx, cy + 162.0),
			pos_text, 14.0, Color(0.3, 0.9, 0.3), card_w - 12.0)

	# Negative
	var neg_text: String = rdata.get("negative", "")
	if neg_text.length() > 0:
		_txt_clip(font, Vector2(tcx, cy + 185.0),
			neg_text, 13.0, Color(0.9, 0.3, 0.3), card_w - 12.0)


func _txt(font: Font, pos: Vector2, text: String, fs: float, col: Color) -> void:
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	draw_string(
		font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col
	)


func _txt_clip(
	font: Font, pos: Vector2, text: String, fs: float, col: Color,
	max_w: float
) -> void:
	var display := text
	var ts := font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	if ts.x > max_w:
		while display.length() > 3:
			display = display.substr(0, display.length() - 1)
			ts = font.get_string_size(display + "..", HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
			if ts.x <= max_w:
				break
		display += ".."
		ts = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
	draw_string(
		font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0),
		display, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col
	)
