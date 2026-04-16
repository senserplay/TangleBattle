extends Node
## Procedural sound effects using sine wave synthesis.

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS := 8
const SAMPLE_RATE := 44100


func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var ap := AudioStreamPlayer.new()
		ap.bus = "Master"
		add_child(ap)
		_players.append(ap)


func _get_free_player() -> AudioStreamPlayer:
	for ap in _players:
		if not ap.playing:
			return ap
	return _players[0]


func play_jump() -> void:
	_play_sweep_sine(500.0, 900.0, 0.07, -14.0)


func play_land() -> void:
	_play_thud(120.0, 0.08, -12.0)


func play_hit() -> void:
	_play_impact(0.08, -8.0)


func play_whip() -> void:
	_play_sweep_sine(700.0, 200.0, 0.1, -10.0)


func play_toss() -> void:
	_play_sweep_sine(300.0, 500.0, 0.08, -12.0)


func play_explosion() -> void:
	_play_boom(0.2, -6.0)


func play_dash() -> void:
	_play_sweep_sine(250.0, 700.0, 0.1, -11.0)


func play_shield() -> void:
	_play_chime(700.0, 0.15, -14.0)


func play_blink() -> void:
	_play_sweep_sine(300.0, 1400.0, 0.06, -13.0)


func play_grapple() -> void:
	_play_sweep_sine(350.0, 700.0, 0.08, -12.0)


func play_death() -> void:
	_play_sweep_sine(600.0, 80.0, 0.35, -8.0)


func play_round_end() -> void:
	_play_chime(523.0, 0.12, -10.0)
	await get_tree().create_timer(0.14).timeout
	_play_chime(659.0, 0.12, -10.0)
	await get_tree().create_timer(0.14).timeout
	_play_chime(784.0, 0.2, -10.0)


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
