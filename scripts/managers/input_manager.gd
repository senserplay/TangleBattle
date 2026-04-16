extends Node

var gamepad_devices: Array[int] = []
# Player slot → device_id mapping (-1 = unbound, -2 = keyboard)
var player_devices: Array[int] = [-2, -1, -1, -1]  # P1 = keyboard by default


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_detect_gamepads()
	_setup_keyboard_player()


func _detect_gamepads() -> void:
	gamepad_devices.clear()
	for device_id in Input.get_connected_joypads():
		gamepad_devices.append(device_id)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected and device not in gamepad_devices:
		gamepad_devices.append(device)
	elif not connected:
		gamepad_devices.erase(device)
		# Unbind disconnected device
		for i in range(player_devices.size()):
			if player_devices[i] == device:
				player_devices[i] = -1
				_clear_player_actions(i + 1)


func bind_device_to_player(device_id: int, player_id: int) -> void:
	# device_id: -2 = keyboard, >= 0 = gamepad
	player_devices[player_id - 1] = device_id
	if device_id == -2:
		_setup_keyboard_player()
	else:
		_setup_gamepad_for_player(player_id, device_id)


func unbind_player(player_id: int) -> void:
	player_devices[player_id - 1] = -1
	_clear_player_actions(player_id)


func is_device_bound(device_id: int) -> bool:
	return device_id in player_devices


func get_device_name(device_id: int) -> String:
	if device_id == -2:
		return "Keyboard + Mouse"
	if device_id == -1:
		return ""
	var joy_name := Input.get_joy_name(device_id)
	if joy_name.length() > 20:
		joy_name = joy_name.substr(0, 18) + ".."
	return joy_name


func setup_all_bound_players() -> void:
	# Called before game starts to ensure all bindings are active
	_setup_keyboard_player()
	for i in range(4):
		var dev: int = player_devices[i]
		if dev >= 0:
			_setup_gamepad_for_player(i + 1, dev)


func _clear_player_actions(player_id: int) -> void:
	var actions: Array[String] = [
		"left", "right", "jump", "attack1", "attack2", "parry"
	]
	var prefix: String = "p%d_" % player_id
	for action in actions:
		var full_name: String = prefix + action
		if InputMap.has_action(full_name):
			InputMap.erase_action(full_name)


func _setup_keyboard_player() -> void:
	_add_key_action("p1_left", KEY_A)
	_add_key_action("p1_right", KEY_D)
	_add_key_action("p1_jump", KEY_SPACE)
	_add_mouse_action("p1_attack1", MOUSE_BUTTON_LEFT)
	_add_mouse_action("p1_attack2", MOUSE_BUTTON_RIGHT)
	_add_mouse_action("p1_parry", MOUSE_BUTTON_MIDDLE)


func _setup_gamepad_for_player(player_id: int, device: int) -> void:
	var prefix := "p%d_" % player_id

	_add_joy_axis_action(prefix + "left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_joy_button_action(prefix + "left", device, JOY_BUTTON_DPAD_LEFT)

	_add_joy_axis_action(prefix + "right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button_action(prefix + "right", device, JOY_BUTTON_DPAD_RIGHT)

	_add_joy_button_action(
		prefix + "jump", device, JOY_BUTTON_LEFT_SHOULDER
	)
	_add_joy_button_action(
		prefix + "jump", device, JOY_BUTTON_RIGHT_SHOULDER
	)
	_add_joy_button_action(
		prefix + "parry", device, JOY_BUTTON_LEFT_STICK
	)

	_add_joy_axis_action(
		prefix + "attack1", device, JOY_AXIS_TRIGGER_LEFT, 0.5
	)
	_add_joy_axis_action(
		prefix + "attack2", device, JOY_AXIS_TRIGGER_RIGHT, 0.5
	)


func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _add_joy_button_action(
	action_name: String, device: int, button: JoyButton
) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	InputMap.action_add_event(action_name, event)


func _add_joy_axis_action(
	action_name: String, device: int, axis: JoyAxis, value: float
) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action_name, event)


func _add_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)
