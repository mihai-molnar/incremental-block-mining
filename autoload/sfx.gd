extends Node
## Small procedural sound bank so the prototype has audio without asset files.
## To use real sounds later, replace entries in `_streams` with loaded AudioStreams.

const MIX_RATE := 22050
const VOICES := 16

@export var volume_db := -6.0

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_streams = {
		&"hit": _make_hit(),
		&"break": _make_break(),
		&"coin": _make_coin(),
		&"explode": _make_explode(),
		&"blast": _make_blast(),
		&"buy": _make_buy(),
		&"land": _make_land(),
		&"pickup": _make_pickup(),
		&"drop": _make_drop(),
		&"click": _make_click(),
		&"convert": _make_convert(),
		&"crit": _make_crit(),
		&"clear": _make_clear(),
		&"lucky": _make_lucky(),
		&"frenzy": _make_frenzy(),
		&"zap": _make_zap(),
	}


func play(sound: StringName, pitch_variance := 0.08, volume_offset_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Unknown sound: %s" % sound)
		return
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.pitch_scale = pitch * (1.0 + randf_range(-pitch_variance, pitch_variance))
	player.volume_db = volume_db + volume_offset_db
	player.play()


# --- Synthesis -------------------------------------------------------------

func _make_hit() -> AudioStreamWAV:
	var noise := _held_noise(2)
	return _render(0.07, func(t: float, _p: float) -> float:
		var tone := _square(t * 620.0) * 0.35
		return (tone + noise.call() * 0.5) * exp(-t * 55.0))


func _make_break() -> AudioStreamWAV:
	var noise := _held_noise(3)
	return _render(0.18, func(t: float, _p: float) -> float:
		var tone := _square(_sweep(t, 420.0, 90.0, 0.18)) * 0.3 * exp(-t * 22.0)
		return tone + noise.call() * 0.55 * exp(-t * 20.0))


func _make_coin() -> AudioStreamWAV:
	return _render(0.16, func(t: float, _p: float) -> float:
		var freq := 988.0 if t < 0.05 else 1319.0
		return _pulse(t * freq, 0.25) * 0.22 * exp(-maxf(t - 0.05, 0.0) * 18.0))


func _make_explode() -> AudioStreamWAV:
	var noise := _held_noise(6)
	return _render(0.55, func(t: float, _p: float) -> float:
		var thump := sin(TAU * _sweep(t, 150.0, 35.0, 0.55)) * 0.75 * exp(-t * 6.0)
		return thump + noise.call() * 0.5 * exp(-t * 7.0))


## An explosive square: a sharper crack on top of a quick low boom.
func _make_blast() -> AudioStreamWAV:
	var noise := _held_noise(3)
	var rumble := _held_noise(9)
	return _render(0.42, func(t: float, _p: float) -> float:
		var boom := sin(TAU * _sweep(t, 120.0, 28.0, 0.42)) * 0.8 * exp(-t * 8.0)
		return boom + noise.call() * 0.55 * exp(-t * 30.0) + rumble.call() * 0.35 * exp(-t * 9.0))


func _make_buy() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	return _render(0.26, func(t: float, _p: float) -> float:
		var i := mini(int(t / 0.055), notes.size() - 1)
		var local_t := t - i * 0.055
		return _pulse(t * notes[i], 0.5) * 0.2 * exp(-local_t * 12.0))


func _make_land() -> AudioStreamWAV:
	var noise := _held_noise(4)
	return _render(0.14, func(t: float, _p: float) -> float:
		var thud := sin(TAU * _sweep(t, 130.0, 55.0, 0.14)) * 0.7
		return (thud + noise.call() * 0.25) * exp(-t * 28.0))


func _make_pickup() -> AudioStreamWAV:
	return _render(0.07, func(t: float, _p: float) -> float:
		return _square(_sweep(t, 380.0, 760.0, 0.07)) * 0.16 * exp(-t * 30.0))


func _make_drop() -> AudioStreamWAV:
	var noise := _held_noise(4)
	return _render(0.1, func(t: float, _p: float) -> float:
		var tone := _square(_sweep(t, 520.0, 220.0, 0.1)) * 0.14
		return (tone + noise.call() * 0.2) * exp(-t * 35.0))


func _make_convert() -> AudioStreamWAV:
	var notes := [1318.5, 1568.0, 2093.0]
	return _render(0.2, func(t: float, _p: float) -> float:
		var i := mini(int(t / 0.04), notes.size() - 1)
		return _pulse(t * notes[i], 0.25) * 0.12 * exp(-t * 10.0))


## A critical hit: a bright two-note ping over a sharp crack.
func _make_crit() -> AudioStreamWAV:
	var noise := _held_noise(2)
	return _render(0.24, func(t: float, _p: float) -> float:
		var freq := 1760.0 if t < 0.04 else 2637.0
		var ping := _pulse(t * freq, 0.25) * 0.2 * exp(-maxf(t - 0.04, 0.0) * 14.0)
		return ping + noise.call() * 0.45 * exp(-t * 70.0))


## A cube cleared for a bonus: a quick rising fanfare that rings out on the last note.
func _make_clear() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	return _render(0.55, func(t: float, _p: float) -> float:
		var i := mini(int(t / 0.06), notes.size() - 1)
		var local_t := t - i * 0.06
		var decay := 6.0 if i == notes.size() - 1 else 14.0
		var tone := _pulse(t * notes[i], 0.5) * 0.16 + _pulse(t * notes[i] * 2.0, 0.25) * 0.05
		return tone * exp(-local_t * decay))


## A Lucky Cube appearing: a soft, high twinkle that rises and falls.
func _make_lucky() -> AudioStreamWAV:
	var notes := [2093.0, 2637.0, 3136.0, 3951.0, 3136.0, 2637.0]
	return _render(0.5, func(t: float, _p: float) -> float:
		var i := mini(int(t / 0.07), notes.size() - 1)
		var local_t := t - i * 0.07
		return _pulse(t * notes[i], 0.25) * 0.09 * exp(-local_t * 18.0))


## Catching a Lucky Cube: a fast run up into a held, shimmering chord.
func _make_frenzy() -> AudioStreamWAV:
	var run := [523.25, 659.25, 783.99, 1046.5]
	var chord := [1046.5, 1318.5, 1568.0]
	return _render(0.9, func(t: float, _p: float) -> float:
		if t < 0.2:
			var i := mini(int(t / 0.05), run.size() - 1)
			return _pulse(t * run[i], 0.5) * 0.18 * exp(-(t - i * 0.05) * 10.0)
		# Each note doubled a hair sharp, so the pair beats and shimmers.
		var sum := 0.0
		for note: float in chord:
			sum += (_pulse(t * note, 0.5) + _pulse(t * note * 1.006, 0.5)) * 0.04
		return sum * exp(-(t - 0.2) * 3.5))


## A lightning square: a buzzing tone that sweeps down under a stuttering crackle.
func _make_zap() -> AudioStreamWAV:
	var noise := _held_noise(1)
	return _render(0.32, func(t: float, _p: float) -> float:
		var buzz := _square(_sweep(t, 1600.0, 180.0, 0.32)) * 0.22 * exp(-t * 8.0)
		var stutter := 1.0 if fmod(t * 45.0, 1.0) < 0.5 else 0.35
		return buzz + noise.call() * 0.45 * stutter * exp(-t * 12.0))


func _make_click() -> AudioStreamWAV:
	return _render(0.035, func(t: float, _p: float) -> float:
		return _square(t * 1200.0) * 0.15 * exp(-t * 90.0))


## Renders `generator(time, progress)` into a 16-bit mono wav.
func _render(duration: float, generator: Callable) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var sample: float = generator.call(t, float(i) / count)
		# Short fade-out avoids a click at the end of the sample.
		sample *= clampf((count - i) / 64.0, 0.0, 1.0)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


## Phase (in cycles) of a linear frequency sweep at time t.
static func _sweep(t: float, from_hz: float, to_hz: float, duration: float) -> float:
	return from_hz * t + (to_hz - from_hz) * t * t / (2.0 * duration)


static func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


static func _pulse(phase: float, duty: float) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0


## Noise that holds each value for `hold` samples, which sounds crunchier than white noise.
static func _held_noise(hold: int) -> Callable:
	var state := {"value": 0.0, "count": 0}
	return func() -> float:
		if state.count % hold == 0:
			state.value = randf_range(-1.0, 1.0)
		state.count += 1
		return state.value
