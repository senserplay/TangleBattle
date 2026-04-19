extends Node2D

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")
var pickup_scene: PackedScene = preload("res://scenes/characters/ability_pickup.tscn")

const MAP_SCENES: Array[String] = [
	"res://scenes/maps/forest_glade.tscn",
	"res://scenes/maps/sunset_spires.tscn",
	"res://scenes/maps/sky_citadel.tscn",
	"res://scenes/maps/volcano_crater.tscn",
	"res://scenes/maps/frozen_lake.tscn",
	"res://scenes/maps/deep_space.tscn",
	"res://scenes/maps/ancient_ruins.tscn",
	"res://scenes/maps/mystic_hollow.tscn",
]

@onready var map_container: Node2D = $MapContainer
@onready var players_node: Node2D = $Players
@onready var hud: CanvasLayer = $HUD
@onready var game_camera: Camera2D = $GameCamera

var current_map: Node2D = null

# Pause
var is_paused: bool = false
var pause_selection: int = 0
var blink_timer: float = 0.0
var is_stats_open: bool = false  # Tab stats overlay

# Passive selection state
var is_selecting_passive: bool = false
var passive_chooser_queue: Array[int] = []  # player_ids waiting to choose
var current_chooser_id: int = -1
var passive_choices: Array = []  # [{passive_id, rarity}] x3
var passive_cursor: int = 0
var passive_timer: float = 0.0
var passive_anim_timer: float = 0.0
var passive_drop_card: int = -1  # card index being dropped (-1 = none)
var passive_drop_timer: float = 0.0
var passive_waiting_drop: bool = false  # waiting for drop anim to finish
var passive_stick_cd: float = 0.0
const PASSIVE_CHOOSE_TIME := 15.0
const PASSIVE_ANIM_DURATION := 0.6  # cards slide in over this time

# Ability pickup spawner
var pickup_spawn_timer: float = 0.0
const PICKUP_INTERVAL := 15.0
const MAX_PICKUPS := 3
var last_round_winner: int = -1

# Victory screen
var is_victory: bool = false
var victory_winner: int = -1
var victory_timer: float = 0.0
const VICTORY_DURATION := 5.0

# Debug passive selection
var is_debug_selecting: bool = false
var debug_chooser_id: int = -1
var debug_passive_list: Array = []  # all (pid, rar) combos
var debug_cursor: int = 0
var debug_scroll: int = 0  # scroll offset for long list
var debug_picks_left: int = 20
const DEBUG_CARDS_VISIBLE := 8  # how many cards visible at once

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
const PLAYER_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 0.9),
	Color(0.2, 0.8, 0.3), Color(0.95, 0.85, 0.1),
]


func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.game_won.connect(_on_game_won)
	_load_random_map()
	_spawn_players()
	if GameManager.game_mode == GameManager.GameMode.DEBUG:
		_start_debug_passive_select()
	else:
		GameManager.start_round()


func _process(delta: float) -> void:
	blink_timer += delta
	# Passive selection timer
	if is_victory:
		victory_timer += delta

	if passive_drop_timer > 0.0:
		passive_drop_timer -= delta
		if passive_drop_timer <= 0.0 and passive_waiting_drop:
			passive_waiting_drop = false
			passive_drop_card = -1
			_next_chooser()

	if is_selecting_passive and current_chooser_id > 0 and not passive_waiting_drop:
		passive_timer -= delta
		passive_anim_timer += delta
		passive_stick_cd = maxf(passive_stick_cd - delta, 0.0)

		# Poll stick for passive navigation
		var dev: int = InputManager.player_devices[current_chooser_id - 1]
		if dev >= 0 and passive_stick_cd <= 0.0:
			var lx := Input.get_joy_axis(dev, JOY_AXIS_LEFT_X)
			if absf(lx) > 0.5:
				var dir := 1 if lx > 0 else -1
				var nc: int = passive_choices.size()
				passive_cursor = (passive_cursor + dir + nc) % nc
				passive_stick_cd = 0.2

		if passive_timer <= 0.0:
			_select_passive()

	# Ability pickup spawner
	if not is_paused and not is_selecting_passive \
		and GameManager.state == GameManager.State.PLAYING:
		pickup_spawn_timer += delta
		if pickup_spawn_timer >= PICKUP_INTERVAL:
			pickup_spawn_timer = 0.0
			_spawn_pickup()


func _unhandled_input(event: InputEvent) -> void:
	# Debug passive selection input
	if is_debug_selecting:
		_handle_debug_input(event)
		return
	# Passive selection input
	if is_selecting_passive:
		_handle_passive_input(event)
		return

	# Pause
	var pause_pressed := false
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE:
			pause_pressed = true
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B:
			pause_pressed = true

	# Tab — stats overlay (hold to view)
	if event is InputEventKey:
		if event.physical_keycode == KEY_TAB:
			is_stats_open = event.pressed
			return

	if pause_pressed:
		if is_paused:
			_resume()
		else:
			_pause()
		return

	if is_paused:
		if event is InputEventKey and event.pressed:
			match event.physical_keycode:
				KEY_W, KEY_UP:
					pause_selection = 0
				KEY_S, KEY_DOWN:
					pause_selection = 1
				KEY_ENTER, KEY_SPACE:
					_pause_select()
		if event is InputEventJoypadButton and event.pressed:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					pause_selection = 0
				JOY_BUTTON_DPAD_DOWN:
					pause_selection = 1
				JOY_BUTTON_A:
					_pause_select()


# ══════════════════ PASSIVE SELECTION ══════════════════

func _handle_passive_input(event: InputEvent) -> void:
	if current_chooser_id <= 0 or passive_waiting_drop:
		return

	var device: int = InputManager.player_devices[current_chooser_id - 1]
	var is_kb := device == -2

	if is_kb and event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_A, KEY_LEFT:
				passive_cursor = (passive_cursor - 1 + passive_choices.size()) % passive_choices.size()
			KEY_D, KEY_RIGHT:
				passive_cursor = (passive_cursor + 1) % passive_choices.size()
			KEY_ENTER, KEY_SPACE:
				_select_passive()

	if not is_kb and event is InputEventJoypadButton and event.pressed:
		if event.device != device:
			return
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				passive_cursor = (passive_cursor - 1 + passive_choices.size()) % passive_choices.size()
			JOY_BUTTON_DPAD_RIGHT:
				passive_cursor = (passive_cursor + 1) % passive_choices.size()
			JOY_BUTTON_A:
				_select_passive()


func _start_passive_selection(winner_id: int) -> void:
	# Build queue of losers — each loser appears passive_pick_count times
	passive_chooser_queue.clear()
	for child in players_node.get_children():
		if child.player_id != winner_id:
			for _p in range(GameManager.passive_pick_count):
				passive_chooser_queue.append(child.player_id)

	if passive_chooser_queue.is_empty():
		_finish_passive_selection()
		return

	is_selecting_passive = true
	get_tree().paused = true
	_next_chooser()


func _next_chooser() -> void:
	if passive_chooser_queue.is_empty():
		_finish_passive_selection()
		return

	current_chooser_id = passive_chooser_queue.pop_front()
	# Get player's luck bonus for rarity roll
	var chooser_luck := 0.0
	for child in players_node.get_children():
		if child.player_id == current_chooser_id:
			chooser_luck = child.luck_bonus
			break
	passive_choices = PassiveRegistry.roll_choices(GameManager.passive_card_count, chooser_luck + GameManager.base_luck)
	passive_cursor = GameManager.passive_card_count / 2  # middle card
	passive_anim_timer = 0.0
	passive_timer = PASSIVE_CHOOSE_TIME


func _select_passive() -> void:
	if passive_waiting_drop:
		return
	if passive_cursor < 0 or passive_cursor >= passive_choices.size():
		return

	var choice: Dictionary = passive_choices[passive_cursor]
	for child in players_node.get_children():
		if child.player_id == current_chooser_id:
			child.add_passive(choice["passive_id"], choice["rarity"])
			break

	SoundManager.play_shield()
	passive_drop_card = passive_cursor
	passive_drop_timer = 0.7
	passive_waiting_drop = true


func _finish_passive_selection() -> void:
	is_selecting_passive = false
	current_chooser_id = -1
	get_tree().paused = false
	_load_random_map()
	_respawn_all()
	GameManager.start_round()


# ══════════════════ DEBUG PASSIVE SELECT ══════════════════

func _start_debug_passive_select() -> void:
	# Build full list of all (passive × rarity) combos
	debug_passive_list.clear()
	for pid in range(PassiveRegistry.PASSIVE_COUNT):
		var pdata: Dictionary = PassiveRegistry.get_data(pid)
		var available: Array = pdata["available_rarities"]
		for rar in available:
			debug_passive_list.append({"passive_id": pid, "rarity": rar})
	# Start with player 1
	is_debug_selecting = true
	debug_chooser_id = 1
	debug_cursor = 0
	debug_scroll = 0
	debug_picks_left = 20
	get_tree().paused = true


func _debug_select_passive() -> void:
	if debug_cursor < 0 or debug_cursor >= debug_passive_list.size():
		return
	var choice: Dictionary = debug_passive_list[debug_cursor]
	for child in players_node.get_children():
		if child.player_id == debug_chooser_id:
			child.add_passive(choice["passive_id"], choice["rarity"])
			break
	debug_picks_left -= 1
	SoundManager.play_shield()


func _debug_skip_player() -> void:
	# Move to next player or finish
	debug_chooser_id += 1
	if debug_chooser_id > GameManager.player_count:
		_finish_debug_select()
		return
	debug_cursor = 0
	debug_scroll = 0
	debug_picks_left = 20


func _finish_debug_select() -> void:
	is_debug_selecting = false
	debug_chooser_id = -1
	get_tree().paused = false
	GameManager.start_round()


func _handle_debug_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_W, KEY_UP:
				debug_cursor = maxi(debug_cursor - 1, 0)
				if debug_cursor < debug_scroll:
					debug_scroll = debug_cursor
			KEY_S, KEY_DOWN:
				debug_cursor = mini(debug_cursor + 1,
					debug_passive_list.size() - 1)
				if debug_cursor >= debug_scroll + DEBUG_CARDS_VISIBLE:
					debug_scroll = debug_cursor - DEBUG_CARDS_VISIBLE + 1
			KEY_ENTER, KEY_SPACE:
				if debug_picks_left > 0:
					_debug_select_passive()
				if debug_picks_left <= 0:
					_debug_skip_player()
			KEY_TAB, KEY_D:
				_debug_skip_player()


# ══════════════════ PAUSE ══════════════════

func _pause() -> void:
	is_paused = true
	pause_selection = 0
	get_tree().paused = true


func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	queue_redraw()


func _pause_select() -> void:
	match pause_selection:
		0:
			_resume()
		1:
			get_tree().paused = false
			GameManager.go_to_menu()


# ══════════════════ PICKUPS ══════════════════

func _spawn_pickup() -> void:
	# Don't exceed max pickups on map
	var current_pickups := get_tree().get_nodes_in_group("pickups")
	if current_pickups.size() >= MAX_PICKUPS:
		return
	if current_map == null:
		return

	# Pick random platform to spawn on
	if current_map.platforms.is_empty():
		return
	var plat: Array = current_map.platforms[randi_range(0, current_map.platforms.size() - 1)]
	var px: float = plat[0] + randf_range(-plat[2] * 0.3, plat[2] * 0.3)
	var py: float = plat[1] - plat[3] / 2.0 - 30.0  # above the platform

	var ab_id: int = randi_range(0, AbilityRegistry.ABILITY_COUNT - 1)

	var pickup: Area2D = pickup_scene.instantiate()
	pickup.setup(ab_id, Vector2(px, py))
	pickup.add_to_group("pickups")
	add_child(pickup)


# ══════════════════ MAP & PLAYERS ══════════════════

func _load_random_map() -> void:
	for child in map_container.get_children():
		child.queue_free()
	# Wipe all transient round-state objects that live outside map_container:
	# in-flight projectiles (rockets, grenades, boomerangs, yarn shots,
	# black holes, stink clouds, tripwires, heaven's wrath), dropped pickups
	# from death, and lingering soul essences.
	for grp in ["ability_entities", "pickups", "soul_essences"]:
		for node in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(node):
				node.queue_free()
	var idx: int = randi_range(0, MAP_SCENES.size() - 1)
	var scene: PackedScene = load(MAP_SCENES[idx])
	current_map = scene.instantiate()
	map_container.add_child(current_map)
	if current_map != null and "spawn_points" in current_map:
		GameManager.spawn_points = current_map.spawn_points
	game_camera.map_ref = current_map
	# Play map-specific music
	if current_map != null and "map_name" in current_map:
		MusicManager.play_map_theme(current_map.map_name)


func _spawn_players() -> void:
	for i in range(GameManager.player_count):
		var player: CharacterBody2D = player_scene.instantiate()
		player.setup(i + 1)
		player.position = GameManager.spawn_points[i]
		players_node.add_child(player)


func _on_round_started() -> void:
	pass


func _on_round_ended(winner_id: int) -> void:
	last_round_winner = winner_id
	await get_tree().create_timer(GameManager.ROUND_END_DELAY).timeout
	# Show passive selection for losers
	_start_passive_selection(winner_id)


func _on_game_won(winner_id: int) -> void:
	is_victory = true
	victory_winner = winner_id
	victory_timer = 0.0
	get_tree().paused = true
	await get_tree().create_timer(VICTORY_DURATION).timeout
	is_victory = false
	get_tree().paused = false
	GameManager.go_to_menu()


func _respawn_all() -> void:
	for child in players_node.get_children():
		if child.has_method("respawn"):
			child.respawn(GameManager.spawn_points[child.player_id - 1])
	for group in ["projectiles", "traps", "walls", "pickups"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	pickup_spawn_timer = 0.0
