extends Node
## Central registry for all abilities. Data loaded from data/abilities.json.

enum {
	YARN_TOSS,        # 0
	NEEDLE_DASH,      # 1
	YARN_BOMB,        # 2
	THREAD_PULL,      # 3
	SPIN_ATTACK,      # 4
	GRENADE,          # 5
	ROCKET_LAUNCHER,  # 6
	STINK_CLOUD,      # 7
	SPIKE_ARMOR,      # 8
	SWAP,             # 9
	BOOMERANG,        # 10
	GUIDED_ROCKET,    # 11
	TRIPWIRE,         # 12
	GRAB_THROW,       # 13
	BLACK_HOLE,       # 14
	PORTAL_GATE,      # 15
	HEAVENS_WRATH,    # 16
}

const ABILITY_COUNT := 17

var DATA: Array[Dictionary] = []


func _ready() -> void:
	var file := FileAccess.open("res://data/abilities.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	for entry: Variant in parsed["abilities"]:
		var d: Dictionary = entry
		# Convert color array [r, g, b] to Color object
		var c: Array = d["color"]
		d["color"] = Color(c[0], c[1], c[2])
		DATA.append(d)
	assert(DATA.size() == ABILITY_COUNT,
		"abilities.json has %d entries, expected %d" % [DATA.size(), ABILITY_COUNT])


func get_random_pair() -> Array[int]:
	var a: int = randi_range(0, ABILITY_COUNT - 1)
	var b: int = randi_range(0, ABILITY_COUNT - 1)
	return [a, b]


func get_data(ability_id: int) -> Dictionary:
	return DATA[ability_id]


func get_val(ability_id: int, key: String, default_val: Variant) -> Variant:
	var d := DATA[ability_id]
	if d.has(key):
		return d[key]
	return default_val
