extends Node

const RATE := 11025
var bgm := AudioStreamPlayer.new()
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var next_player := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm)
	bgm.volume_db = -17.0
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.volume_db = -7.0
		add_child(player)
		players.append(player)
	sounds = {
		"ui": _sequence([[620.0, 0.045]], "soft", 0.32),
		"cash": _sequence([[880.0, 0.07], [1320.0, 0.20]], "bell", 0.50),
		"sell": _sequence([[660.0, 0.05], [880.0, 0.05], [1100.0, 0.06], [1480.0, 0.18]], "bell", 0.54),
		"merge": _sequence([[523.0, 0.07], [659.0, 0.07], [784.0, 0.09], [1047.0, 0.24]], "bell", 0.48),
		"swap": _sequence([[420.0, 0.06], [310.0, 0.06], [520.0, 0.09]], "soft", 0.38),
		"milk": _sequence([[300.0, 0.06], [420.0, 0.08], [560.0, 0.13]], "bubble", 0.38),
		"upgrade": _sequence([[392.0, 0.08], [523.0, 0.08], [659.0, 0.10], [784.0, 0.12], [1047.0, 0.30]], "bell", 0.52),
		"lottery": _sequence([[440.0, 0.05], [554.0, 0.05], [659.0, 0.05], [880.0, 0.05], [1109.0, 0.08], [1320.0, 0.24]], "arcade", 0.45),
		"equip": _sequence([[180.0, 0.04], [260.0, 0.07]], "click", 0.35),
		"shot": _shot_sound(),
		"poof": _poof_sound()
	}
	bgm.stream = _make_bgm()
	bgm.play()

func play_sfx(id: String) -> void:
	if not sounds.has(id):
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = sounds[id]
	player.play()

func _sequence(notes: Array, wave: String, gain: float) -> AudioStreamWAV:
	var total := 0
	for note in notes:
		total += int(note[1] * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var cursor := 0
	for note in notes:
		var frequency: float = note[0]
		var count := int(note[1] * RATE)
		for i in count:
			var t := float(i) / RATE
			var phase := TAU * frequency * t
			var value := sin(phase)
			if wave == "bell":
				value = sin(phase) + 0.38 * sin(phase * 2.01) + 0.18 * sin(phase * 3.99)
			elif wave == "arcade":
				value = 0.72 * signf(sin(phase)) + 0.28 * sin(phase * 2.0)
			elif wave == "bubble":
				value = sin(phase * (1.0 + t * 1.8)) + 0.2 * sin(phase * 2.0)
			elif wave == "click":
				value = signf(sin(phase)) * (1.0 - t / maxf(0.001, note[1]))
			var attack := minf(1.0, t / 0.008)
			var release := pow(maxf(0.0, 1.0 - float(i) / count), 1.7)
			var sample := clampi(roundi(value * attack * release * gain * 32767.0), -32768, 32767)
			data.encode_s16((cursor + i) * 2, sample)
		cursor += count
	return _wav(data)

func _shot_sound() -> AudioStreamWAV:
	var count := int(0.24 * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var noise := _noise(i) * exp(-t * 18.0)
		var boom := sin(TAU * (92.0 - t * 170.0) * t) * exp(-t * 11.0)
		var sample := clampi(roundi((noise * 0.68 + boom * 0.62) * 25000.0), -32768, 32767)
		data.encode_s16(i * 2, sample)
	return _wav(data)

func _poof_sound() -> AudioStreamWAV:
	var count := int(0.30 * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var puff := _noise(i * 3 + 17) * exp(-t * 10.0)
		var tone := sin(TAU * (240.0 + t * 500.0) * t) * exp(-t * 7.0)
		data.encode_s16(i * 2, clampi(roundi((puff * 0.35 + tone * 0.28) * 24000.0), -32768, 32767))
	return _wav(data)

func _noise(index: int) -> float:
	return fmod(abs(sin(float(index) * 12.9898) * 43758.5453), 1.0) * 2.0 - 1.0

func _make_bgm() -> AudioStreamWAV:
	var melody := [523.25, 659.25, 783.99, 659.25, 440.0, 523.25, 659.25, 523.25,
		349.23, 440.0, 523.25, 440.0, 392.0, 493.88, 587.33, 493.88,
		523.25, 659.25, 880.0, 783.99, 440.0, 523.25, 698.46, 659.25,
		349.23, 440.0, 587.33, 523.25, 392.0, 493.88, 659.25, 523.25]
	var bass := [130.81, 110.0, 87.31, 98.0]
	var step_duration := 0.34
	var step_samples := int(step_duration * RATE)
	var total := melody.size() * step_samples
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var step := i / step_samples
		var local := float(i % step_samples) / RATE
		var envelope := minf(1.0, local / 0.025) * (0.72 + 0.28 * cos(PI * local / step_duration))
		var lead := sin(TAU * melody[step] * local) + 0.22 * sin(TAU * melody[step] * 2.0 * local)
		var root: float = bass[(step / 8) % bass.size()]
		var low := sin(TAU * root * (float(i) / RATE)) * 0.75
		var breeze := sin(TAU * 0.18 * (float(i) / RATE)) * 0.08
		var sample := clampi(roundi((lead * envelope * 0.16 + low * 0.13 + breeze) * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample)
	var stream := _wav(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	return stream

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
