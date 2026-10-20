extends Node

## WindfallSound — procedural audio for WINDFALL.
## Every sound is synthesised once (16-bit), cached, and replayed through a
## small voice pool with slight pitch variation so repeats never sound robotic.
## Also runs the ambient bed: birdsong and breeze by day, crickets by night.

const SR := 22050
var _cache: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _amb_player: AudioStreamPlayer
var _amb_night: bool = false
var _chirp_timer: float = 2.0
var _ambience_on: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_voices.append(p)
	_amb_player = AudioStreamPlayer.new()
	_amb_player.bus = &"Music"
	_amb_player.volume_db = -14.0
	add_child(_amb_player)


# ── synthesis core ──────────────────────────────────────────────────────────

func _render(key: String, duration: float, fn: Callable, loop: bool = false) -> AudioStreamWAV:
	if _cache.has(key):
		return _cache[key]
	var n := int(duration * SR)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var lp := 0.0
	for i in n:
		var t := float(i) / SR
		var v: float = fn.call(t, rng)
		# gentle soft-clip keeps everything warm, never harsh
		v = tanh(v * 1.2) * 0.85
		# fade the last 6ms so nothing clicks
		var tail := float(n - i) / SR
		if tail < 0.006 and not loop:
			v *= tail / 0.006
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = n
	_cache[key] = wav
	return wav


func _play(stream: AudioStream, db: float = 0.0, pitch_var: float = 0.06, bus: StringName = &"SFX") -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


static func _env(t: float, a: float, d: float) -> float:
	if t < a:
		return t / a
	return exp(-(t - a) / d)


static func _noise(rng: RandomNumberGenerator) -> float:
	return rng.randf() * 2.0 - 1.0


const FAM_ROOT := [392.0, 293.66, 523.25, 261.63, 329.63, 440.0, 220.0, 587.33]


# ── gameplay sounds ─────────────────────────────────────────────────────────

func play_bite(family: int = WindfallTypes.Family.STORM) -> void:
	var root: float = FAM_ROOT[clampi(family, 0, 7)]
	var s := _render("bite_%d" % family, 0.55, func(t: float, rng: RandomNumberGenerator) -> float:
		var v := 0.0
		# crunch: filtered noise bursts (3 quick cracks)
		for k in 3:
			var ct := t - k * 0.028
			if ct > 0.0 and ct < 0.05:
				v += _noise(rng) * exp(-ct * 70.0) * (0.9 - k * 0.2)
		# juicy squelch: falling sine
		if t > 0.03 and t < 0.25:
			var jt := t - 0.03
			v += sin(TAU * (260.0 * jt - 500.0 * jt * jt)) * sin(PI * jt / 0.22) * 0.45
		# elemental bloom: major arpeggio in the family's key
		if t > 0.1:
			var bt := t - 0.1
			for i in 3:
				var nt := bt - i * 0.05
				if nt > 0.0:
					var f: float = root * [1.0, 1.25, 1.5][i]
					v += (sin(TAU * f * nt) + sin(TAU * f * 2.0 * nt) * 0.3) * exp(-nt * 7.0) * 0.22
		return v)
	_play(s, 0.0, 0.04)


func play_spell(family: int = WindfallTypes.Family.STORM) -> void:
	var s := _render("spell_%d" % family, 0.45, func(t: float, rng: RandomNumberGenerator) -> float: return _spell_sample(family, t, rng))
	_play(s, -4.0)


func _spell_sample(family: int, t: float, rng: RandomNumberGenerator) -> float:
	var e := _env(t, 0.01, 0.12)
	match family:
		WindfallTypes.Family.STORM:
			var f := 900.0 + sin(t * 140.0) * 500.0
			return (signf(sin(TAU * f * t)) * 0.25 + _noise(rng) * 0.4 * (1.0 if fmod(t, 0.03) < 0.012 else 0.2)) * e
		WindfallTypes.Family.EMBER:
			return (sin(TAU * maxf(160.0 - t * 200.0, 50.0) * t) * 0.6 + _noise(rng) * 0.45 * _env(t, 0.04, 0.15)) * e
		WindfallTypes.Family.FROST:
			return (sin(TAU * 1568.0 * t) * 0.35 + sin(TAU * 2093.0 * t) * 0.25 + sin(TAU * 2637.0 * t) * 0.15) * _env(t, 0.002, 0.18)
		WindfallTypes.Family.TIDE:
			return (sin(TAU * (300.0 + sin(t * 30.0) * 120.0) * t) * 0.4 + _noise(rng) * 0.35) * e
		WindfallTypes.Family.GALE:
			return _noise(rng) * sin(PI * t / 0.45) * 0.5
		WindfallTypes.Family.LUMEN:
			return (sin(TAU * 784.0 * t) * 0.4 + sin(TAU * 1176.0 * t) * 0.3 + sin(TAU * 1568.0 * t) * 0.2) * _env(t, 0.02, 0.2)
		WindfallTypes.Family.UMBRA:
			return (sin(TAU * 110.0 * t) * 0.5 + sin(TAU * 116.0 * t) * 0.5) * e
		_:
			return (sin(TAU * (220.0 + t * 300.0) * t) * 0.5 + _noise(rng) * 0.15) * e


func play_swing() -> void:
	var s := _render("swing", 0.16, func(t: float, rng: RandomNumberGenerator) -> float:
		return _noise(rng) * sin(PI * t / 0.16) * 0.5 * (0.6 + 0.4 * sin(TAU * (900.0 - t * 4000.0) * t)))
	_play(s, -8.0, 0.12)


func play_hit() -> void:
	var s := _render("hit", 0.18, func(t: float, rng: RandomNumberGenerator) -> float:
		return (sin(TAU * maxf(180.0 - t * 600.0, 50.0) * t) * 0.8 + _noise(rng) * 0.6 * exp(-t * 60.0)) * exp(-t * 18.0))
	_play(s, -3.0, 0.1)


func play_hurt() -> void:
	var s := _render("hurt", 0.25, func(t: float, rng: RandomNumberGenerator) -> float:
		return (sin(TAU * (330.0 - t * 500.0) * t) * 0.5 + _noise(rng) * 0.3 * exp(-t * 30.0)) * exp(-t * 10.0))
	_play(s, -2.0)


func play_roll() -> void:
	var s := _render("roll", 0.2, func(t: float, rng: RandomNumberGenerator) -> float:
		return _noise(rng) * sin(PI * t / 0.2) * 0.35)
	_play(s, -10.0, 0.1)


func play_poof() -> void:
	var s := _render("poof", 0.35, func(t: float, rng: RandomNumberGenerator) -> float:
		return (_noise(rng) * 0.6 + sin(TAU * 90.0 * t) * 0.4) * _env(t, 0.01, 0.08))
	_play(s, -4.0)


func play_harvest() -> void:
	var s := _render("harvest", 0.3, func(t: float, _rng: RandomNumberGenerator) -> float:
		var v := sin(TAU * 659.25 * t) * _env(t, 0.003, 0.09) * 0.5
		if t > 0.07:
			v += sin(TAU * 987.77 * (t - 0.07)) * _env(t - 0.07, 0.003, 0.12) * 0.45
		return v)
	_play(s, -4.0, 0.02, &"UI")


func play_prime_timing() -> void:
	var s := _render("prime", 0.8, func(t: float, _rng: RandomNumberGenerator) -> float:
		var v := 0.0
		var notes := [523.25, 659.25, 783.99, 1046.5]
		for i in notes.size():
			var nt := t - i * 0.07
			if nt > 0.0:
				var f: float = notes[i]
				v += (sin(TAU * f * nt) + sin(TAU * f * 3.0 * nt) * 0.15) * _env(nt, 0.004, 0.25) * 0.3
		return v)
	_play(s, -1.0, 0.0, &"UI")


func play_plant() -> void:
	var s := _render("plant", 0.22, func(t: float, rng: RandomNumberGenerator) -> float:
		return (sin(TAU * 140.0 * t) * 0.5 + _noise(rng) * 0.4) * exp(-t * 20.0))
	_play(s, -5.0, 0.1)


func play_raid_horn() -> void:
	var s := _render("horn", 1.4, func(t: float, _rng: RandomNumberGenerator) -> float:
		var e := minf(t * 5.0, 1.0) * (1.0 - smoothstep(0.9, 1.4, t))
		var f := 110.0 + (8.0 if t > 0.5 else 0.0)
		var v := 0.0
		for h in [1.0, 2.0, 3.0, 4.0, 5.0]:
			v += sin(TAU * f * h * t + sin(t * 5.0) * 0.3) / h
		return v * e * 0.35)
	_play(s, -2.0, 0.0)


## Raid-start sting: low drum hits under a minor stab, layered on the horn.
func play_raid_sting() -> void:
	var s := _render("sting", 1.6, func(t: float, rng: RandomNumberGenerator) -> float:
		var v := 0.0
		for k in [0.0, 0.18, 0.36]:
			var dt: float = t - k
			if dt > 0.0:
				v += sin(TAU * maxf(70.0 - dt * 60.0, 35.0) * dt) * exp(-dt * 9.0) * 0.9
				v += _noise(rng) * exp(-dt * 40.0) * 0.3
		if t > 0.36:
			var st := t - 0.36
			for f in [220.0, 261.63, 311.13, 440.0]:
				v += (fmod(f * st, 1.0) * 2.0 - 1.0) * _env(st, 0.01, 0.5) * 0.12
		return v)
	_play(s, 0.0, 0.0)


func play_ui_move() -> void:
	var s := _render("ui_move", 0.06, func(t: float, _rng: RandomNumberGenerator) -> float:
		return signf(sin(TAU * 880.0 * t)) * 0.15 * exp(-t * 60.0))
	_play(s, -10.0, 0.0, &"UI")


func play_ui_confirm() -> void:
	var s := _render("ui_ok", 0.12, func(t: float, _rng: RandomNumberGenerator) -> float:
		var f := 660.0 if t < 0.05 else 990.0
		return signf(sin(TAU * f * t)) * 0.14 * exp(-fmod(t, 0.05) * 40.0))
	_play(s, -8.0, 0.0, &"UI")


func play_ui_back() -> void:
	var s := _render("ui_back", 0.1, func(t: float, _rng: RandomNumberGenerator) -> float:
		return signf(sin(TAU * (600.0 - t * 2000.0) * t)) * 0.12 * exp(-t * 30.0))
	_play(s, -8.0, 0.0, &"UI")


# ── ambience ────────────────────────────────────────────────────────────────

func start_ambience() -> void:
	_ambience_on = true
	_apply_ambience()


func stop_ambience() -> void:
	_ambience_on = false
	_amb_player.stop()


func set_ambience_night(night: bool) -> void:
	if night == _amb_night and _amb_player.playing:
		return
	_amb_night = night
	_apply_ambience()


func _apply_ambience() -> void:
	if not _ambience_on:
		return
	var bed: AudioStreamWAV
	if _amb_night:
		bed = _render("amb_night", 4.0, func(t: float, rng: RandomNumberGenerator) -> float:
			# crickets: rapid amplitude-gated high tones in two voices
			var c1 := sin(TAU * 4200.0 * t) * (1.0 if fmod(t * 34.0, 1.0) < 0.5 else 0.0) * (1.0 if fmod(t, 1.0) < 0.42 else 0.0)
			var c2 := sin(TAU * 4700.0 * t) * (1.0 if fmod(t * 29.0, 1.0) < 0.5 else 0.0) * (1.0 if fmod(t + 0.5, 1.33) < 0.5 else 0.0)
			return c1 * 0.05 + c2 * 0.035 + _noise(rng) * 0.02, true)
	else:
		bed = _render("amb_day", 4.0, func(t: float, rng: RandomNumberGenerator) -> float:
			# soft breeze: slowly swelling noise
			return _noise(rng) * (0.05 + 0.03 * sin(TAU * t / 4.0)), true)
	_amb_player.stream = bed
	_amb_player.play()


func _process(delta: float) -> void:
	if not _ambience_on or _amb_night:
		return
	_chirp_timer -= delta
	if _chirp_timer <= 0.0:
		_chirp_timer = randf_range(1.5, 5.0)
		var k := randi() % 3
		var s := _render("bird_%d" % k, 0.5, func(t: float, _rng: RandomNumberGenerator) -> float:
			var v := 0.0
			var notes: Array = [[2400.0, 3200.0], [3000.0, 2200.0], [2600.0, 3400.0]][k]
			for i in 3:
				var nt := t - i * 0.13
				if nt > 0.0 and nt < 0.1:
					var f: float = lerpf(notes[0], notes[1], nt / 0.1)
					v += sin(TAU * f * nt) * sin(PI * nt / 0.1) * 0.18
			return v)
		_play(s, -18.0, 0.08, &"Music")
