extends Node
## Registry for passive abilities. Data loaded from data/passives.json.

enum PassiveId {
	POISON_PROJECTILE,  # 0
	PHOENIX,            # 1
	TANK,               # 2
	LIFESTEAL,          # 3
	THREAD_MASTER,      # 4
	WIDE_IMPACT,        # 5
	QUICK_HANDS,        # 6
	FIRE_THREAD,        # 7
	RICOCHET,           # 8
	REGENERATION,       # 9
	EXPLOSIVE_POWER,    # 10
	SWIFT_FEET,         # 11
	PROJECTILE_MASTER,  # 12
	GLASS_CANNON,       # 13
	IRON_SKIN,          # 14
	SHOCKWAVE,          # 15
	LIGHTNING_STRIKE,   # 16
	HEAVY_IMPACT,       # 17
	HOMING_PROJECTILES, # 18
	BURST_FIRE,         # 19
	LUCKY_STAR,         # 20
	SPIRIT_BURST,       # 21
	SHIELD_MASTERY,     # 22
	PARRY_BURST,        # 23
	PHASE_SHOT,         # 24
}

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY, MYTHIC }

const PASSIVE_COUNT := 25

const RARITY_NAMES: Array[String] = [
	"Common", "Uncommon", "Rare", "Legendary", "Mythic"
]
const RARITY_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),     # Common — grey
	Color(0.3, 0.8, 0.3),     # Uncommon — green
	Color(0.3, 0.5, 1.0),     # Rare — blue
	Color(1.0, 0.8, 0.2),     # Legendary — gold
	Color(0.95, 0.2, 0.5),    # Mythic — pink-red
]

# Drop weights for each rarity
const RARITY_WEIGHTS: Array[float] = [45.0, 30.0, 18.0, 3.0, 1.0]

var DATA: Array[Dictionary] = []


func _ready() -> void:
	var file := FileAccess.open("res://data/passives.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	for entry: Variant in parsed["passives"]:
		var d: Dictionary = entry
		# Convert string rarity keys ("0","1",...) to int keys
		var str_rarities: Dictionary = d["rarities"]
		var int_rarities: Dictionary = {}
		for key: Variant in str_rarities:
			int_rarities[int(str(key))] = str_rarities[key]
		d["rarities"] = int_rarities
		DATA.append(d)
	assert(DATA.size() == PASSIVE_COUNT,
		"passives.json has %d entries, expected %d" % [DATA.size(), PASSIVE_COUNT])


func get_data(passive_id: int) -> Dictionary:
	return DATA[passive_id]


const MAX_LUCK := 50.0
# Target weights at max luck: C=0%, U=10%, R=20%, L=30%, M=40%
const LUCK_TARGET_WEIGHTS: Array[float] = [0.0, 10.0, 20.0, 30.0, 40.0]


func _get_rarity_weight(rar: int, luck: float) -> float:
	## Linearly interpolate from base weights to target weights by luck/50.
	var base: float = RARITY_WEIGHTS[rar]
	if luck <= 0.0:
		return base
	var t: float = clampf(luck / MAX_LUCK, 0.0, 1.0)
	return lerpf(base, LUCK_TARGET_WEIGHTS[rar], t)


func roll_choices(count: int, luck: float = 0.0) -> Array:
	## Flat pool system: every (passive × rarity) is a separate slot.
	## Each slot has weight = rarity_weight modified by luck.
	## Same passive can appear at different rarities on different cards.
	## Luck increases rare/legendary/mythic weights for ALL passives equally,
	## so even Mythic-only passives get a fair chance with high luck.
	var choices: Array = []
	# Track which passive IDs are already picked (no duplicate passives)
	var used_ids: Dictionary = {}

	for _i in range(count):
		# Build flat pool: all (pid, rar) combos not yet used
		var pool: Array[Dictionary] = []
		var pool_weights: Array[float] = []
		for pid in range(PASSIVE_COUNT):
			if pid in used_ids:
				continue
			var pdata: Dictionary = DATA[pid]
			var available: Array = pdata["available_rarities"]
			for rar in available:
				var w: float = _get_rarity_weight(rar, luck)
				pool.append({"passive_id": pid, "rarity": rar})
				pool_weights.append(w)

		if pool.is_empty():
			break

		# Weighted random pick from flat pool
		var total := 0.0
		for w in pool_weights:
			total += w
		var roll := randf() * total
		var acc := 0.0
		var picked_idx: int = 0
		for idx in range(pool.size()):
			acc += pool_weights[idx]
			if roll <= acc:
				picked_idx = idx
				break

		choices.append(pool[picked_idx])
		used_ids[pool[picked_idx]["passive_id"]] = true

	return choices
