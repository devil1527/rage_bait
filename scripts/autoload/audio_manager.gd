extends Node

## AudioManager provides retro synth sound effects without external copyright assets.
## Respects user SFX setting in SaveManager.

var _sfx_players: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Create pool of audio players for concurrent sound effects
	for i: int in range(6):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	_generate_retro_sounds()

func _generate_retro_sounds() -> void:
	_sounds["click"] = _synth_tone(0.06, 520.0, 380.0, 0.4, "square")
	_sounds["jump"] = _synth_tone(0.14, 260.0, 580.0, 0.35, "square")
	_sounds["land"] = _synth_tone(0.08, 140.0, 90.0, 0.3, "triangle")
	_sounds["coin"] = _synth_coin()
	_sounds["death"] = _synth_death()
	_sounds["unlock"] = _synth_arpeggio([440.0, 554.37, 659.25, 880.0], 0.08)
	_sounds["complete"] = _synth_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.12)
	_sounds["warning"] = _synth_tone(0.12, 220.0, 180.0, 0.4, "saw")

func play_sfx(sound_name: String) -> void:
	if not SaveManager.sfx_enabled:
		return
	if not _sounds.has(sound_name):
		return

	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			player.stream = _sounds[sound_name]
			player.play()
			return

	# If all busy, use the first one
	_sfx_players[0].stream = _sounds[sound_name]
	_sfx_players[0].play()

func _synth_tone(duration: float, start_freq: float, end_freq: float, volume: float = 0.5, wave: String = "square") -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples)

	var phase: float = 0.0
	for i: int in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU

		var val: float = 0.0
		match wave:
			"square":
				val = 1.0 if phase < PI else -1.0
			"triangle":
				val = (phase / PI) - 1.0 if phase < PI else 1.0 - ((phase - PI) / PI)
			"saw":
				val = (phase / PI) - 1.0
			_:
				val = sin(phase)

		# Decay envelope
		var env: float = (1.0 - t) * volume
		var sample_8bit: int = int(clampf((val * env * 120.0) + 128.0, 0.0, 255.0))
		data[i] = sample_8bit

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_coin() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(0.22 * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples)

	var phase: float = 0.0
	for i: int in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = 987.77 if t < 0.35 else 1318.51 # B5 then E6
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU

		var val: float = 1.0 if phase < PI else -1.0
		var env: float = (1.0 - t) * 0.4
		var sample_8bit: int = int(clampf((val * env * 120.0) + 128.0, 0.0, 255.0))
		data[i] = sample_8bit

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_death() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(0.45 * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples)

	var phase: float = 0.0
	for i: int in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(320.0, 60.0, t * t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU

		# Mixed noise and harsh square
		var noise: float = randf_range(-0.4, 0.4)
		var val: float = (1.0 if phase < PI else -1.0) * 0.6 + noise
		var env: float = (1.0 - t) * 0.45
		var sample_8bit: int = int(clampf((val * env * 120.0) + 128.0, 0.0, 255.0))
		data[i] = sample_8bit

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_arpeggio(notes: Array[float], note_duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var samples_per_note: int = int(note_duration * float(sample_rate))
	var total_samples: int = samples_per_note * notes.size()
	var data := PackedByteArray()
	data.resize(total_samples)

	for note_idx: int in range(notes.size()):
		var freq: float = notes[note_idx]
		var phase: float = 0.0
		for i: int in range(samples_per_note):
			var global_i: int = (note_idx * samples_per_note) + i
			var t: float = float(i) / float(samples_per_note)
			phase += (freq * TAU) / float(sample_rate)
			if phase > TAU:
				phase -= TAU

			var val: float = 1.0 if phase < PI else -1.0
			var env: float = (1.0 - (t * 0.7)) * 0.35
			var sample_8bit: int = int(clampf((val * env * 120.0) + 128.0, 0.0, 255.0))
			data[global_i] = sample_8bit

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
