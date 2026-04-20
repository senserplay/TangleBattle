extends Node

var _screenshot_counter: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_F12:
			var img := get_viewport().get_texture().get_image()
			var path := "user://screenshot_%d.png" % _screenshot_counter
			img.save_png(path)
			_screenshot_counter += 1
			print("Screenshot saved: ", path)

signal round_started
signal round_ended(winner_id: int)
signal game_won(winner_id: int)
signal scores_updated

enum State { MENU, PLAYING, ROUND_END, GAME_OVER }
enum GameMode { CLASSIC, ENDLESS, CHAOS, DEBUG }

const ROUND_END_DELAY := 2.0
const SPAWN_INVINCIBILITY := 1.0

const MODE_NAMES: Array[String] = ["Classic", "Endless", "Chaos", "Debug"]

# Configurable from lobby
# Map editor integration — when non-empty, game.gd loads this custom map
# instead of the random rotation. `returning_to_editor` = go back to the
# editor after the match ends (or the player exits).
var pending_custom_map: Dictionary = {}
var returning_to_editor: bool = false

var game_mode: GameMode = GameMode.CLASSIC
var base_luck: float = 0.0  # extra luck for all players
var passive_card_count: int = 5  # cards shown per passive selection
var passive_pick_count: int = 1  # picks per player per round
var max_hp: float = 100.0
var win_score: int = 7
var vibration_enabled: bool = true
var screen_shake_enabled: bool = true
var player_colors: Array[Color] = [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3), Color(0.95, 0.85, 0.1),
]

var state: State = State.MENU
var player_count: int = 2
var scores: Array[int] = [0, 0, 0, 0]
var alive_count: int = 0
var last_alive_id: int = -1

# Ability choices per player: [ab1_id, ab2_id], -1 means random
var player_ability_choices: Array = [
	[-1, -1], [-1, -1], [-1, -1], [-1, -1]
]

var spawn_points: Array[Vector2] = [
	Vector2(300, 960),
	Vector2(1620, 960),
	Vector2(860, 680),
	Vector2(1060, 680),
]

var debug_passives: Array = [[], [], [], []]  # per-player passive arrays for debug mode


func start_game(num_players: int) -> void:
	if game_mode == GameMode.DEBUG:
		player_count = clampi(num_players, 1, 4)
	else:
		player_count = clampi(num_players, 2, 4)
	scores = [0, 0, 0, 0]
	state = State.PLAYING
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")


func start_round() -> void:
	state = State.PLAYING
	alive_count = player_count
	last_alive_id = -1
	MusicManager.set_intensity(alive_count, player_count)
	_assign_abilities()
	round_started.emit()


func _assign_abilities() -> void:
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		var pid: int = player.player_id - 1
		var choice: Array = player_ability_choices[pid]
		var ab1: int = choice[0]
		var ab2: int = choice[1]
		if ab1 < 0:
			ab1 = randi_range(0, AbilityRegistry.ABILITY_COUNT - 1)
		if ab2 < 0:
			ab2 = randi_range(0, AbilityRegistry.ABILITY_COUNT - 1)
		player.assign_abilities([ab1, ab2] as Array[int])


func player_died(_player_id: int) -> void:
	if state != State.PLAYING:
		return
	alive_count -= 1
	MusicManager.set_intensity(alive_count, player_count)
	if alive_count <= 1:
		_find_last_alive()
		_end_round()


func _find_last_alive() -> void:
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if player.is_alive:
			last_alive_id = player.player_id
			return


func _end_round() -> void:
	state = State.ROUND_END
	if last_alive_id > 0:
		scores[last_alive_id - 1] += 1
		scores_updated.emit()

	# Endless mode — never end, always next round
	if game_mode == GameMode.ENDLESS:
		round_ended.emit(last_alive_id)
		return

	# Classic / Chaos — check win condition
	if last_alive_id > 0 and scores[last_alive_id - 1] >= win_score:
		state = State.GAME_OVER
		game_won.emit(last_alive_id)
	else:
		round_ended.emit(last_alive_id)


func go_to_menu() -> void:
	state = State.MENU
	scores = [0, 0, 0, 0]
	MusicManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/main/title_menu.tscn")
