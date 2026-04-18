extends Node
## Sound effects using WAV files in assets/sounds/.
## Falls back to procedural synthesis if WAV missing.

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS := 12
const SAMPLE_RATE := 44100

# Pre-loaded WAV streams
var _streams: Dictionary = {}
const SOUND_FILES := {
	"jump": "res://assets/sounds/jump.wav",
	"land": "res://assets/sounds/land.wav",
	"hit": "res://assets/sounds/hit.wav",
	"whip": "res://assets/sounds/whip.wav",
	"toss": "res://assets/sounds/toss.wav",
	"explosion": "res://assets/sounds/explosion.wav",
	"dash": "res://assets/sounds/dash.wav",
	"shield": "res://assets/sounds/shield.wav",
	"blink": "res://assets/sounds/blink.wav",
	"grapple": "res://assets/sounds/grapple.wav",
	"death": "res://assets/sounds/death.wav",
	"round_end": "res://assets/sounds/round_end.wav",
}
const VOLUMES := {
	"jump": -10.0, "land": -12.0, "hit": -8.0,
	"whip": -10.0, "toss": -12.0, "explosion": -6.0,
	"dash": -10.0, "shield": -10.0, "blink": -12.0,
	"grapple": -12.0, "death": -8.0, "round_end": -8.0,
}


func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var ap := AudioStreamPlayer.new()
		ap.bus = "Master"
		add_child(ap)
		_players.append(ap)
	for key in SOUND_FILES:
		var path: String = SOUND_FILES[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)


func _get_free_player() -> AudioStreamPlayer:
	for ap in _players:
		if not ap.playing:
			return ap
	return _players[0]


func _play(key: String) -> void:
	if not _streams.has(key):
		return
	var ap := _get_free_player()
	ap.stream = _streams[key]
	ap.volume_db = VOLUMES.get(key, -10.0)
	ap.play()


func play_jump() -> void: _play("jump")
func play_land() -> void: _play("land")
func play_hit() -> void: _play("hit")
func play_whip() -> void: _play("whip")
func play_toss() -> void: _play("toss")
func play_explosion() -> void: _play("explosion")
func play_dash() -> void: _play("dash")
func play_shield() -> void: _play("shield")
func play_blink() -> void: _play("blink")
func play_grapple() -> void: _play("grapple")
func play_death() -> void: _play("death")
func play_round_end() -> void: _play("round_end")


## Pure sine tone with smooth envelope
func _play_chime(freq: float, duration: float, vol_db: float) -> void:
	var ap := _get_free_player()
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var env := _smooth_env(float(i) / samples, 0.02, 0.3)
		var val := sin(t * freq * TAU) * 0.4 * env
		# Add soft overtone
		val += sin(t * freq * 2.0 * TAU) * 0.1 * env
		var sample := int(clampf(val, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data

	ap.stream = stream
	ap.volume_db = vol_db
	ap.play()


## Frequency sweep (sine)
func _play_sweep_sine(
	f_start: float, f_end: float, duration: float, vol_db: float
) -> void:
	var ap := _get_free_player()
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in range(samples):
		var t := float(i) / samples
		var freq := lerpf(f_start, f_end, t)
		phase += freq / SAMPLE_RATE
		var env := _smooth_env(t, 0.01, 0.4)
		var val := sin(phase * TAU) * 0.35 * env
		var sample := int(clampf(val, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data

	ap.stream = stream
	ap.volume_db = vol_db
	ap.play()


## Low thud — sine with fast decay
func _play_thud(freq: float, duration: float, vol_db: float) -> void:
	var ap := _get_free_player()
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-float(i) / samples * 6.0)
		# Frequency drops as it decays
		var f := freq * (1.0 - float(i) / samples * 0.5)
		var val := sin(t * f * TAU) * 0.5 * env
		var sample := int(clampf(val, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data

	ap.stream = stream
	ap.volume_db = vol_db
	ap.play()


## Short impact — filtered noise burst
func _play_impact(duration: float, vol_db: float) -> void:
	var ap := _get_free_player()
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(samples * 2)
	var prev := 0.0
	for i in range(samples):
		var env := exp(-float(i) / samples * 8.0)
		var noise := randf_range(-1.0, 1.0)
		# Simple low-pass filter
		prev = prev * 0.7 + noise * 0.3
		var val := prev * 0.5 * env
		var sample := int(clampf(val, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data

	ap.stream = stream
	ap.volume_db = vol_db
	ap.play()


## Boom — low sine + filtered noise
func _play_boom(duration: float, vol_db: float) -> void:
	var ap := _get_free_player()
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(samples * 2)
	var prev := 0.0
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-float(i) / samples * 4.0)
		# Low rumble
		var bass := sin(t * 60.0 * TAU) * 0.4
		# Filtered noise crackle
		var noise := randf_range(-1.0, 1.0)
		prev = prev * 0.6 + noise * 0.4
		var val := (bass + prev * 0.3) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data

	ap.stream = stream
	ap.volume_db = vol_db
	ap.play()


## Smooth attack-decay envelope
func _smooth_env(t: float, attack: float, decay_start: float) -> float:
	if t < attack:
		return t / attack
	if t > decay_start:
		return 1.0 - (t - decay_start) / (1.0 - decay_start)
	return 1.0
