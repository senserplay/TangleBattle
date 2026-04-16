extends CanvasLayer

@onready var draw_node: Control = $Root

var round_label_text: String = ""
var round_label_color: Color = Color.WHITE
var round_label_visible: bool = false

# Hover state for passive tooltip
var hovered_passive: Dictionary = {}  # {passive_id, rarity, player_id}
var mouse_pos: Vector2 = Vector2.ZERO

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

const DOT_RADIUS := 8.0
const DOT_GAP := 6.0
const PASSIVE_ICON_SIZE := 28.0
const PASSIVE_GAP := 6.0


func _ready() -> void:
	GameManager.scores_updated.connect(_on_scores_updated)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.game_won.connect(_on_game_won)
	GameManager.round_started.connect(_on_round_started)


func _process(_delta: float) -> void:
	mouse_pos = draw_node.get_global_mouse_position()
	_check_passive_hover()
	draw_node.queue_redraw()


func _on_scores_updated() -> void:
	pass  # redraw handles it


func _on_round_ended(winner_id: int) -> void:
	if winner_id > 0:
		round_label_text = "Player %d wins the round!" % winner_id
		round_label_color = GameManager.player_colors[winner_id - 1]
		round_label_visible = true


func _on_game_won(winner_id: int) -> void:
	round_label_text = "PLAYER %d WINS THE GAME!" % winner_id
	round_label_color = GameManager.player_colors[winner_id - 1]
	round_label_visible = true


func _on_round_started() -> void:
	round_label_visible = false


func _check_passive_hover() -> void:
	hovered_passive = {}
	var vp := draw_node.get_viewport_rect().size
	# Passive icons are drawn top-right
	var players := get_tree().get_nodes_in_group("players")
	var y := 15.0
	for p in players:
		if not "passives" in p:
			continue
		var passives_arr: Array = p.passives
		for pi in range(passives_arr.size()):
			var ix := vp.x - 15.0 - (pi + 1) * (PASSIVE_ICON_SIZE + PASSIVE_GAP)
			var iy := y
			var icon_rect := Rect2(ix, iy, PASSIVE_ICON_SIZE, PASSIVE_ICON_SIZE)
			if icon_rect.has_point(mouse_pos):
				hovered_passive = passives_arr[pi].duplicate()
				hovered_passive["player_id"] = p.player_id
				return
		y += PASSIVE_ICON_SIZE + 12.0
