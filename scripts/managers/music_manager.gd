extends Node
## Music & UI sound system.
## Plays a continuous lo-fi playlist with smooth crossfade between tracks.
## Music does NOT depend on the current map — same playlist runs in menu and game.
## Intensity (more dead players = more intense) only modulates volume slightly.

const CROSSFADE_DUR := 4.0    # seconds for end-of-track crossfade
const FADE_IN_DUR := 2.0      # seconds for very first track or after stop
const FADE_OUT_DUR := 1.0     # seconds for stop_music
const SILENCE_DB := -60.0     # effectively muted

# Volume range modulated by intensity (0..1):
# calm play -> QUIET_DB, last-man-standing -> LOUD_DB
const QUIET_DB := -16.0
const LOUD_DB := -8.0

const SAMPLE_RATE := 22050    # for procedural UI sounds

# Track files in assets/music/
const TRACK_PATHS: Array[String] = [
	"res://assets/music/adventure_chill.mp3",
	"res://assets/music/empty_mind.mp3",
	"res://assets/music/sentimental_jazz.mp3",
	"res://assets/music/easter.mp3",
	"res://assets/music/goodnight_cozy.mp3",
]

var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var ui_player: AudioStreamPlayer

var tracks: Array[AudioStream] = []
var current_track_idx: int = -1
var active_player: AudioStreamPlayer = null    # the one playing or fading-in
var fade_tween: Tween = null

var intensity: float = 0.5
var target_intensity: float = 0.5
var paused: bool = true


func _ready() -> void:
	music_a = _make_player()
	music_b = _make_player()
	ui_player = _make_player()
	ui_player.volume_db = -8.0

	# Load all tracks once. MP3 streams default to looping; we disable that
	# so we can control transitions via crossfade.
	for path: String in TRACK_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("MusicManager: missing track %s" % path)
			continue
		var stream: AudioStream = load(path)
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = false
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = false
		tracks.append(stream)
	tracks.shuffle()
	active_player = music_a


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Master"
	p.volume_db = SILENCE_DB
	add_child(p)
	return p


func _process(delta: float) -> void:
	# Smooth intensity tracking
	intensity = move_toward(intensity, target_intensity, delta * 0.5)

	if paused or active_player == null or not active_player.playing:
		return

	# When no fade is happening, hard-set the active volume to follow intensity.
	# (Inactive player stays at SILENCE_DB; fade tweens manage their own values.)
	if fade_tween == null or not fade_tween.is_running():
		active_player.volume_db = _target_vol()

	# End-of-track detection -> schedule crossfade
	if active_player.stream != null \
		and (fade_tween == null or not fade_tween.is_running()):
		var len_s: float = active_player.stream.get_length()
		var pos: float = active_player.get_playback_position()
		if len_s > 0.0 and pos >= len_s - CROSSFADE_DUR:
			_crossfade_to_next()


func _target_vol() -> float:
	return lerpf(QUIET_DB, LOUD_DB, clampf(intensity, 0.0, 1.0))


func _crossfade_to_next() -> void:
	if tracks.is_empty():
		return
	var next_player: AudioStreamPlayer = (
		music_b if active_player == music_a else music_a
	)
	current_track_idx = (current_track_idx + 1) % tracks.size()
	next_player.stream = tracks[current_track_idx]
	next_player.volume_db = SILENCE_DB
	next_player.play()

	var old_player: AudioStreamPlayer = active_player
	active_player = next_player

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(
		next_player, "volume_db", _target_vol(), CROSSFADE_DUR
	)
	fade_tween.tween_property(
		old_player, "volume_db", SILENCE_DB, CROSSFADE_DUR
	)
	# After cross-fade, stop the old player to free the slot.
	fade_tween.chain().tween_callback(func() -> void:
		old_player.stop()
	)


# ══════════════════ PUBLIC API ══════════════════

func play_menu_music() -> void:
	_ensure_playing()


func play_map_theme(_map_name: String = "") -> void:
	# Map name ignored on purpose — music is continuous and map-independent.
	_ensure_playing()


func _ensure_playing() -> void:
	paused = false
	if active_player == null or tracks.is_empty():
		return
	if active_player.playing:
		return
	# Start (or resume) the playlist by picking the next track and fading in.
	current_track_idx = (
		(current_track_idx + 1) % tracks.size() if current_track_idx >= 0 else 0
	)
	active_player.stream = tracks[current_track_idx]
	active_player.volume_db = SILENCE_DB
	active_player.play()
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(
		active_player, "volume_db", _target_vol(), FADE_IN_DUR
	)


func stop_music() -> void:
	paused = true
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	if music_a.playing:
		fade_tween.tween_property(music_a, "volume_db", SILENCE_DB, FADE_OUT_DUR)
	if music_b.playing:
		fade_tween.tween_property(music_b, "volume_db", SILENCE_DB, FADE_OUT_DUR)
	fade_tween.chain().tween_callback(func() -> void:
		music_a.stop()
		music_b.stop()
	)


func set_intensity(alive_count: int, total_count: int) -> void:
	if total_count <= 1:
		target_intensity = 1.0
		return
	# More intense with fewer players alive.
	target_intensity = 1.0 - float(alive_count - 1) / float(total_count - 1)


# ══════════════════ UI SOUNDS (procedural — short tones) ══════════════════

func play_ui_click() -> void:
	_play_ui_tone(800.0, 0.05, -10.0)


func play_ui_switch() -> void:
	_play_ui_tone(600.0, 0.04, -12.0)


func play_ui_error() -> void:
	_play_ui_tone(200.0, 0.1, -8.0)


func play_ui_confirm() -> void:
	_play_ui_sweep(400.0, 800.0, 0.08, -10.0)


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


func _play_ui_sweep(
	f_start: float, f_end: float, duration: float, vol_db: float
) -> void:
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
