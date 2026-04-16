extends Node
## Procedural music & ambient system.
## Generates unique themes per map + menu ambient + UI sounds.
## Dynamic intensity: music gets more intense with fewer alive players.

const SAMPLE_RATE := 22050
const BPM := 120.0
const BEAT := 60.0 / BPM  # seconds per beat

var music_player: AudioStreamPlayer = null
var ambient_player: AudioStreamPlayer = null
var ui_player: AudioStreamPlayer = null

var current_theme: String = ""
var intensity: float = 0.5  # 0=calm, 1=intense
var target_intensity: float = 0.5


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -12.0
	add_child(music_player)

	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Master"
	ambient_player.volume_db = -18.0
	add_child(ambient_player)

	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master"
	ui_player.volume_db = -8.0
	add_child(ui_player)


func _process(delta: float) -> void:
	intensity = move_toward(intensity, target_intensity, delta * 0.5)
	if music_player.playing:
		# Adjust volume based on intensity
		music_player.volume_db = lerpf(-18.0, -8.0, intensity)


## ══════ PUBLIC API ══════

func play_map_theme(map_name: String) -> void:
	if current_theme == map_name and music_player.playing:
		return
	current_theme = map_name
	var stream := _generate_map_music(map_name)
	if stream != null:
		music_player.stream = stream
		music_player.play()
	var amb := _generate_ambient(map_name)
	if amb != null:
		ambient_player.stream = amb
		ambient_player.play()


func play_menu_music() -> void:
	if current_theme == "menu" and music_player.playing:
		return
	current_theme = "menu"
	var stream := _generate_menu_music()
	music_player.stream = stream
	music_player.play()
	ambient_player.stop()


func stop_music() -> void:
	music_player.stop()
	ambient_player.stop()
	current_theme = ""


func set_intensity(alive_count: int, total_count: int) -> void:
	if total_count <= 1:
		target_intensity = 1.0
		return
	# More intense with fewer players alive
	target_intensity = 1.0 - float(alive_count - 1) / float(total_count - 1)


func play_ui_click() -> void:
	_play_ui_tone(800.0, 0.05, -10.0)


func play_ui_switch() -> void:
	_play_ui_tone(600.0, 0.04, -12.0)


func play_ui_error() -> void:
	_play_ui_tone(200.0, 0.1, -8.0)


func play_ui_confirm() -> void:
	_play_ui_sweep(400.0, 800.0, 0.08, -10.0)


## ══════ MUSIC GENERATION ══════

func _generate_menu_music() -> AudioStreamWAV:
	# Calm ambient pad — C major chord drone
	var duration := 8.0
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# Soft pad — C E G chord
		var val := sin(t * 261.63 * TAU) * 0.15  # C4
		val += sin(t * 329.63 * TAU) * 0.1  # E4
		val += sin(t * 392.0 * TAU) * 0.08  # G4
		# Slow LFO modulation
		val *= 0.6 + sin(t * 0.3) * 0.2
		# Gentle envelope
		var env := clampf(t / 1.0, 0.0, 1.0) * clampf((duration - t) / 1.0, 0.0, 1.0)
		val *= env
		var sample := int(clampf(val, -1.0, 1.0) * 30000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data
	return stream


func _generate_map_music(map_name: String) -> AudioStreamWAV:
	# Each map gets unique notes/tempo
	var notes: Array[float] = []
	var tempo_mult := 1.0

	match map_name:
		"Workshop":
			notes = [261.63, 293.66, 329.63, 392.0, 440.0, 329.63, 293.66, 261.63]
			tempo_mult = 0.8
		"Sky Garden":
			notes = [392.0, 440.0, 493.88, 523.25, 493.88, 440.0, 392.0, 349.23]
			tempo_mult = 0.7
		"Volcano":
			notes = [196.0, 233.08, 261.63, 196.0, 220.0, 261.63, 233.08, 196.0]
			tempo_mult = 1.2
		"Ice Cave":
			notes = [523.25, 493.88, 440.0, 392.0, 349.23, 392.0, 440.0, 493.88]
			tempo_mult = 0.6
		"Tower":
			notes = [329.63, 349.23, 392.0, 440.0, 493.88, 523.25, 493.88, 440.0]
			tempo_mult = 0.9
		"Factory":
			notes = [196.0, 220.0, 196.0, 246.94, 196.0, 220.0, 261.63, 196.0]
			tempo_mult = 1.3
		"Jungle":
			notes = [293.66, 329.63, 349.23, 392.0, 349.23, 329.63, 293.66, 261.63]
			tempo_mult = 0.85
		"Space":
			notes = [220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63]
			tempo_mult = 0.5
		"Dungeon":
			notes = [196.0, 207.65, 220.0, 196.0, 185.0, 196.0, 220.0, 207.65]
			tempo_mult = 0.7
		"Cloud Kingdom":
			notes = [440.0, 493.88, 523.25, 587.33, 523.25, 493.88, 440.0, 392.0]
			tempo_mult = 0.6
		"Underwater":
			notes = [261.63, 293.66, 261.63, 246.94, 261.63, 293.66, 329.63, 293.66]
			tempo_mult = 0.5
		"Clockwork":
			notes = [329.63, 329.63, 392.0, 329.63, 293.66, 293.66, 349.23, 293.66]
			tempo_mult = 1.0
		"Arena":
			notes = [196.0, 246.94, 293.66, 349.23, 392.0, 349.23, 293.66, 246.94]
			tempo_mult = 1.4
		"Mirror":
			notes = [392.0, 349.23, 329.63, 293.66, 329.63, 349.23, 392.0, 440.0]
			tempo_mult = 0.75
		_:
			notes = [261.63, 293.66, 329.63, 349.23, 392.0, 349.23, 329.63, 293.66]

	var beat_dur := BEAT / tempo_mult
	var duration := notes.size() * beat_dur
	var samples := int(SAMPLE_RATE * duration)

	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var note_idx := int(t / beat_dur) % notes.size()
		var freq: float = notes[note_idx]
		var note_t := fmod(t, beat_dur)

		# Envelope per note
		var env := 1.0
		if note_t < 0.02:
			env = note_t / 0.02
		elif note_t > beat_dur - 0.05:
			env = (beat_dur - note_t) / 0.05

		# Sine + soft harmonics
		var val := sin(t * freq * TAU) * 0.2
		val += sin(t * freq * 2.0 * TAU) * 0.06
		val += sin(t * freq * 0.5 * TAU) * 0.08  # sub bass
		val *= env * 0.7

		var sample := int(clampf(val, -1.0, 1.0) * 28000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	stream.data = data
	return stream


func _generate_ambient(map_name: String) -> AudioStreamWAV:
	var duration := 6.0
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var val := 0.0

		match map_name:
			"Volcano":
				# Rumbling lava
				val = sin(t * 40.0 * TAU) * 0.05
				val += sin(t * 25.0 * TAU + sin(t * 0.5) * 3.0) * 0.04
			"Underwater":
				# Bubbling water
				val = sin(t * 80.0 * TAU + sin(t * 2.0) * 5.0) * 0.03
				val += sin(t * 120.0 * TAU + sin(t * 3.5) * 4.0) * 0.02
			"Factory", "Clockwork":
				# Mechanical hum
				val = sin(t * 60.0 * TAU) * 0.03
				val += sin(t * 120.0 * TAU) * 0.02
				# Clicking
				val += sin(t * 200.0 * TAU) * 0.01 * (1.0 if fmod(t, 0.5) < 0.05 else 0.0)
			"Sky Garden", "Cloud Kingdom":
				# Wind whoosh
				var wind := sin(t * 0.3) * 0.5 + 0.5
				val = _noise_at(i) * 0.03 * wind
			"Space":
				# Deep space drone
				val = sin(t * 30.0 * TAU) * 0.02
				val += sin(t * 45.0 * TAU + sin(t * 0.2) * 2.0) * 0.015
			"Dungeon":
				# Eerie drip echoes
				val = sin(t * 50.0 * TAU) * 0.01
				if fmod(t, 2.0) < 0.02:
					val += sin(t * 800.0 * TAU) * 0.04
			"Jungle":
				# Crickets/insects
				var chirp := sin(t * 4000.0 * TAU) * 0.015
				chirp *= 1.0 if fmod(t, 0.8) < 0.1 else 0.0
				val = chirp
				val += sin(t * 60.0 * TAU + sin(t * 0.7) * 2.0) * 0.01
			"Arena":
				# Crowd murmur (noise)
				val = _noise_at(i) * 0.02
			_:
				val = sin(t * 40.0 * TAU) * 0.01

		var sample := int(clampf(val, -1.0, 1.0) * 30000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	stream.data = data
	return stream


func _noise_at(i: int) -> float:
	# Simple deterministic noise
	var x := i * 1103515245 + 12345
	return float(x % 65536) / 32768.0 - 1.0


## ══════ UI SOUNDS ══════

func _play_ui_tone(freq: float, duration: float, vol_db: float) -> void:
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS

	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - float(i) / samples
		var val := sin(t * freq * TAU) * 0.3 * env
		var sample := int(clampf(val, -1.0, 1.0) * 30000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data
	ui_player.stream = stream
	ui_player.volume_db = vol_db
	ui_player.play()


func _play_ui_sweep(f_start: float, f_end: float, duration: float, vol_db: float) -> void:
	var samples := int(SAMPLE_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS

	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in range(samples):
		var t := float(i) / samples
		var freq := lerpf(f_start, f_end, t)
		phase += freq / SAMPLE_RATE
		var env := 1.0 - t
		var val := sin(phase * TAU) * 0.3 * env
		var sample := int(clampf(val, -1.0, 1.0) * 30000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data
	ui_player.stream = stream
	ui_player.volume_db = vol_db
	ui_player.play()
