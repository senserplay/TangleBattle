extends Control

@onready var player_count_label: Label = $VBoxContainer/PlayerCountLabel
@onready var start_button: Button = $VBoxContainer/StartButton

var selected_count: int = 2


func _ready() -> void:
	_update_label()
	$VBoxContainer/HBoxButtons/AddButton.pressed.connect(_on_add)
	$VBoxContainer/HBoxButtons/RemoveButton.pressed.connect(_on_remove)
	start_button.pressed.connect(_on_start)


func _on_add() -> void:
	selected_count = mini(selected_count + 1, 4)
	_update_label()


func _on_remove() -> void:
	selected_count = maxi(selected_count - 1, 2)
	_update_label()


func _update_label() -> void:
	player_count_label.text = "Players: %d" % selected_count


func _on_start() -> void:
	GameManager.start_game(selected_count)
