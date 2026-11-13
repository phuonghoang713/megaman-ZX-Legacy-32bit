extends Node
# Chiptune sound effects and a looping stage track, synthesized at startup so
# the project needs no audio files. Replace with real assets later by putting
# AudioStreams into `sounds` / `music_stream`.

const RATE := 22050
const MUSIC_RATE := 16000

var sounds := {}
var music_stream: AudioStreamSample
var _players := []
var _music: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	_rng.seed = 7
	sounds["shot"] = _sweep(1300.0, 900.0, 0.05, "square", 0.22)
	sounds["shot_mid"] = _sweep(700.0, 300.0, 0.12, "square", 0.28)
	sounds["shot_big"] = _sweep(520.0, 110.0, 0.25, "square", 0.32)
	sounds["jump"] = _sweep(280.0, 620.0, 0.07, "square", 0.12)
	sounds["dash"] = _sweep(2400.0, 600.0, 0.16, "noise", 0.18)
	sounds["slash"] = _sweep(5000.0, 1200.0, 0.10, "noise", 0.22)
	sounds["hit"] = _sweep(420.0, 160.0, 0.06, "square", 0.22)
	sounds["hurt"] = _sweep(650.0, 90.0, 0.25, "square", 0.28)
	sounds["explode"] = _sweep(900.0, 80.0, 0.45, "noise", 0.35)
	sounds["select"] = _sweep(990.0, 990.0, 0.035, "square", 0.12)
	sounds["pickup"] = _arpeggio([523.0, 659.0, 784.0, 1047.0], 0.055, 0.2)
	sounds["core"] = _arpeggio([392.0, 523.0, 659.0, 784.0, 1047.0, 1319.0], 0.05, 0.2)
	for i in range(10):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)


func play(name: String) -> void:
	if not sounds.has(name):
		return
	for player in _players:
		if not player.playing:
			player.stream = sounds[name]
			player.play()
			return
	_players[0].stream = sounds[name]
	_players[0].play()


func play_music() -> void:
	if music_stream == null:
		music_stream = _compose()
	if not _music.playing:
		_music.stream = music_stream
		_music.play()


func stop_music() -> void:
	_music.stop()


func _sample(data: PoolByteArray, rate: int, loop: bool) -> AudioStreamSample:
	var stream := AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamSample.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size()
	return stream


func _byte(v: float) -> int:
	return int(round(clamp(v, -1.0, 1.0) * 127.0)) & 0xFF


# A tone or noise burst whose pitch slides from f0 to f1 and fades out.
func _sweep(f0: float, f1: float, duration: float, wave: String, volume: float) -> AudioStreamSample:
	var n := int(RATE * duration)
	var data := PoolByteArray()
	data.resize(n)
	var phase := 0.0
	var noise := 0.0
	for i in range(n):
		var t := float(i) / n
		var f: float = lerp(f0, f1, t)
		var before := phase
		phase += f / RATE
		var v := 0.0
		if wave == "square":
			v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		else:
			if int(phase) != int(before):
				noise = _rng.randf_range(-1.0, 1.0)
			v = noise
		data[i] = _byte(v * volume * (1.0 - t))
	return _sample(data, RATE, false)


func _arpeggio(freqs: Array, step: float, volume: float) -> AudioStreamSample:
	var per := int(RATE * step)
	var data := PoolByteArray()
	data.resize(per * freqs.size())
	var phase := 0.0
	for k in range(freqs.size()):
		for i in range(per):
			phase += freqs[k] / RATE
			var fade := 1.0 - float(k * per + i) / data.size() * 0.7
			data[k * per + i] = _byte((1.0 if fmod(phase, 1.0) < 0.5 else -1.0) * volume * fade)
	return _sample(data, RATE, false)


# Original 4-bar loop in A minor (Am - F - C - G): pulse bass, triangle
# arpeggio, kick and hi-hat.
func _compose() -> AudioStreamSample:
	var step_len := 60.0 / 140.0 / 4.0
	var steps := 64
	var per := int(MUSIC_RATE * step_len)
	var data := PoolByteArray()
	data.resize(per * steps)
	var roots := [0, -4, 3, -2]
	var thirds := [3, 4, 4, 4]
	var bass_hits := [0, 2, 3, 6, 8, 10, 11, 14]
	var bass_phase := 0.0
	var lead_phase := 0.0
	var kick_phase := 0.0
	for s in range(steps):
		var bar := s / 16
		var st := s % 16
		var root: int = roots[bar]
		var bass_on := st in bass_hits
		var bass_note := root + (12 if st == 3 or st == 11 else 0)
		var bass_f := 110.0 * pow(2.0, bass_note / 12.0)
		var tones := [0, thirds[bar], 7, 12]
		var lead_f := 440.0 * pow(2.0, (root + tones[st % 4]) / 12.0)
		kick_phase = 0.0
		for j in range(per):
			var t := float(j) / per
			var v := 0.0
			if bass_on:
				bass_phase += bass_f / MUSIC_RATE
				v += (0.5 if fmod(bass_phase, 1.0) < 0.25 else -0.5) * 0.4 * (1.0 - t * 0.6)
			lead_phase += lead_f / MUSIC_RATE
			var tri: float = abs(fmod(lead_phase, 1.0) * 4.0 - 2.0) - 1.0
			v += tri * 0.16 * (1.0 - t * 0.8)
			if st % 4 == 2 and t < 0.25:
				v += _rng.randf_range(-1.0, 1.0) * 0.1 * (1.0 - t * 4.0)
			if st % 8 == 0:
				kick_phase += lerp(150.0, 45.0, t) / MUSIC_RATE
				v += sin(kick_phase * TAU) * 0.45 * (1.0 - t)
			data[s * per + j] = _byte(v)
	return _sample(data, MUSIC_RATE, true)
