extends Node

# Procedural Sound Synthesizer for Windfall
# Generates crunch bites, elemental chimes, spell casts, and orchard cues

const SAMPLE_RATE := 22050
var _cache: Dictionary = {}


func _generate_wav(samples: PackedByteArray, sample_rate: int = SAMPLE_RATE) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = samples
	return wav


func play_bite(family: int = WindfallTypes.Family.STORM) -> void:
	# 1. Crunch noise burst + 2. Juicy squirt + 3. Elemental chime
	var duration: float = 0.35
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	var fam_color: Color = WindfallTypes.FAMILY_COLORS.get(family, Color.WHITE)
	var freq: float = 440.0 + (family * 75.0)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var val: float = 0.0

		# 0 to 0.08s: crisp dry crunch
		if t < 0.08:
			var env: float = 1.0 - (t / 0.08)
			val += (randf() * 2.0 - 1.0) * env * 0.9
		# 0.04 to 0.22s: juicy squelch / pitch bend
		if t >= 0.04 and t < 0.22:
			var jt: float = t - 0.04
			var squirt_freq: float = 240.0 - (jt * 700.0)
			var env2: float = sin((jt / 0.18) * PI)
			val += sin(jt * maxf(squirt_freq, 60.0) * TAU) * env2 * 0.6
		# 0.08 to 0.35s: elemental melodic chime
		if t >= 0.08:
			var ct: float = t - 0.08
			var env3: float = exp(-ct * 8.0)
			val += sin(ct * freq * TAU) * env3 * 0.5
			val += sin(ct * freq * 1.5 * TAU) * env3 * 0.25

		var b: int = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = b

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, 2.0)


func play_spell(family: int = WindfallTypes.Family.STORM) -> void:
	var duration: float = 0.4
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	var base_freq: float = 300.0 + (family * 60.0)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var val: float = 0.0
		var env: float = exp(-t * 7.0)

		match family:
			WindfallTypes.Family.STORM:
				# Electric zap with noise
				var f := base_freq + sin(t * 80.0) * 150.0
				val = (sin(t * f * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * env
			WindfallTypes.Family.EMBER:
				# Fireball woosh & deep boom
				var f := 180.0 - t * 120.0
				val = (sin(t * maxf(f, 40.0) * TAU) * 0.7 + (randf() * 2.0 - 1.0) * 0.3) * env
			WindfallTypes.Family.FROST:
				# Crystal shatter / sharp bell
				var f := 880.0 + sin(t * 30.0) * 220.0
				val = sin(t * f * TAU) * env
			WindfallTypes.Family.TIDE:
				# Water splash
				var f := 220.0 + sin(t * 40.0) * 90.0
				val = (sin(t * f * TAU) * 0.5 + (randf() * 2.0 - 1.0) * 0.5) * env
			WindfallTypes.Family.GALE:
				# High wind swoosh
				var f := 500.0 + sin(t * 20.0) * 300.0
				val = (randf() * 2.0 - 1.0) * sin(t * f * TAU) * env
			WindfallTypes.Family.LUMEN:
				# Holy harmonic chime
				val = (sin(t * 660.0 * TAU) * 0.5 + sin(t * 990.0 * TAU) * 0.3 + sin(t * 1320.0 * TAU) * 0.2) * env
			_:
				# Verdant / Umbra
				var f := 260.0 + sin(t * 15.0) * 50.0
				val = sin(t * f * TAU) * env

		var b: int = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = b

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, 0.0)


func play_swing() -> void:
	var duration: float = 0.15
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 400.0 - t * 1800.0
		var env: float = sin((t / duration) * PI)
		var val: float = (randf() * 0.4 + sin(t * maxf(freq, 80.0) * TAU) * 0.6) * env
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, -2.0)


func play_hit() -> void:
	var duration: float = 0.16
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 22.0)
		var val: float = (sin(t * 120.0 * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * env
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, 1.0)


func play_harvest() -> void:
	var duration: float = 0.25
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 9.0)
		var val: float = (sin(t * 523.25 * TAU) * 0.6 + sin(t * 659.25 * TAU) * 0.4) * env
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_ui(stream, 1.0)


func play_prime_timing() -> void:
	var duration: float = 0.45
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	# 3-note ascending arpeggio (C - E - G)
	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var note_idx := int(t / 0.12)
		var f := 523.25
		if note_idx == 1: f = 659.25
		elif note_idx >= 2: f = 783.99
		var note_t := fmod(t, 0.12)
		var env: float = exp(-note_t * 10.0)
		var val: float = (sin(t * f * TAU) * 0.7 + sin(t * f * 2.0 * TAU) * 0.3) * env
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_ui(stream, 4.0)


func play_raid_horn() -> void:
	var duration: float = 0.7
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = minf(t * 6.0, 1.0) * (1.0 - (t / duration) * 0.6)
		# Deep brassy buzz (sawtooth approximation)
		var phase := fmod(t * 110.0, 1.0)
		var val: float = (phase * 2.0 - 1.0) * env * 0.8
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, 3.0)


func play_plant() -> void:
	var duration: float = 0.18
	var num_samples: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(num_samples)

	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 18.0)
		var val: float = (sin(t * 90.0 * TAU) * 0.5 + (randf() * 2.0 - 1.0) * 0.5) * env
		bytes[i] = clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)

	var stream := _generate_wav(bytes)
	AudioManager.play_sfx(stream, -1.0)
