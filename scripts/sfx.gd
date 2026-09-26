class_name Sfx
extends RefCounted
## Every sound in the game is made from maths when the game starts - no audio files.
## Ask for a sound by name: Sfx.get_sound("chime"). They are built once and cached.
##
##   step0..step3  your footsteps        land     landing after a jump
##   chime         picking up a toy      scream   something SAW you
##   screech       something GOT you     heart    one heartbeat (lub-dub)
##   note          a music-box note      hum      the building's hum (loops)
##   panic         chase music (loops)   drone    rotor whine (loops)
##   stomp / thud / clack   monster footsteps (giant / tall one / bird)
##   growl / giggle / caw   monster voices (giant / tall one / bird)
##   snarl         a monster winding up to swing    whoosh   the swing itself
##   click         a floor button clunking down     door     a door grinding open

const RATE := 22050

static var _cache := {}


static func get_sound(sound_name: String) -> AudioStreamWAV:
	if not _cache.has(sound_name):
		_cache[sound_name] = _make(sound_name)
	return _cache[sound_name]


static func _make(sound_name: String) -> AudioStreamWAV:
	match sound_name:
		"step0", "step1", "step2", "step3":
			return _footstep(int(sound_name.substr(4)))
		"land":
			return _landing()
		"chime":
			return _chime()
		"scream":
			return _scream()
		"screech":
			return _screech()
		"heart":
			return _heartbeat()
		"note":
			return _music_box_note()
		"hum":
			return _hum()
		"panic":
			return _panic()
		"drone":
			return _drone()
		"stomp":
			return _stomp()
		"thud":
			return _thud()
		"clack":
			return _clack()
		"growl":
			return _growl()
		"giggle":
			return _giggle()
		"caw":
			return _caw()
		"snarl":
			return _snarl()
		"whoosh":
			return _whoosh()
		"click":
			return _click()
		"door":
			return _door()
	push_warning("Sfx: no sound called '%s'" % sound_name)
	return _wav(PackedFloat32Array([0.0]))


# ---------------------------------------------------------------------------
# The player
# ---------------------------------------------------------------------------
## A shoe on a dusty floor: a short burst of muffled noise plus a soft knock.
static func _footstep(variant: int) -> AudioStreamWAV:
	var rng := _rng(100 + variant)
	var n := int(RATE * 0.22)
	var out := _silence(n)
	var lp := _LowPass.new(rng.randf_range(900.0, 2000.0))
	var knock_f := rng.randf_range(70.0, 110.0)
	for i in n:
		var t := float(i) / RATE
		var noise := lp.next(rng.randf_range(-1.0, 1.0))
		var s := noise * exp(-t * 28.0) * 1.6
		s += sin(TAU * knock_f * t) * exp(-t * 40.0) * 0.7
		if t > 0.06:   # the heel-toe scuff
			s += noise * exp(-(t - 0.06) * 30.0) * 0.5
		out[i] = s
	return _wav(_normalize(out, 0.8))


## Landing after a jump: a deep thump with a bit of dust.
static func _landing() -> AudioStreamWAV:
	var rng := _rng(7)
	var n := int(RATE * 0.35)
	var out := _silence(n)
	var lp := _LowPass.new(400.0)
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(60.0, 35.0, t / 0.35)
		var s := sin(TAU * f * t) * exp(-t * 9.0)
		s += lp.next(rng.randf_range(-1.0, 1.0)) * exp(-t * 18.0) * 0.8
		out[i] = s
	return _wav(_normalize(out, 0.9))


## Toy found: three rising music-box notes (E, B, E) - pretty, but a little bit wrong.
static func _chime() -> AudioStreamWAV:
	var n := int(RATE * 1.1)
	var out := _silence(n)
	var notes := [[659.25, 0.0], [987.77, 0.11], [1318.5, 0.22]]
	for note in notes:
		var f: float = note[0] * 1.004   # slightly out of tune on purpose
		var start: float = note[1]
		for i in n:
			var t := float(i) / RATE - start
			if t < 0.0:
				continue
			var env := minf(t / 0.004, 1.0) * exp(-t * 3.2)
			out[i] += (sin(TAU * f * t) + sin(TAU * f * 2.0 * t) * 0.3 + sin(TAU * f * 5.4 * t) * 0.08 * exp(-t * 9.0)) * env
	return _wav(_normalize(out, 0.7))


# ---------------------------------------------------------------------------
# Scares
# ---------------------------------------------------------------------------
## IT SAW YOU: a shriek on top of a low, dissonant orchestra hit.
static func _scream() -> AudioStreamWAV:
	var rng := _rng(13)
	var n := int(RATE * 1.5)
	var out := _silence(n)
	var lp := _LowPass.new(3000.0)
	var hit_lp := _LowPass.new(1500.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		# shriek: pitch jumps up, wobbles, then sinks
		var f := 900.0
		if t < 0.3:
			f = lerpf(900.0, 1300.0, t / 0.3)
		else:
			f = lerpf(1300.0, 500.0, (t - 0.3) / 1.2)
		f *= 1.0 + sin(TAU * 28.0 * t) * 0.06
		phase += f / RATE
		var voice := 0.0
		var amps := [1.0, 0.6, 0.45, 0.3, 0.2]
		for h in 5:
			voice += sin(TAU * phase * (h + 1)) * amps[h]
		voice += lp.next(rng.randf_range(-1.0, 1.0)) * 0.35
		var v_env := minf(t / 0.03, 1.0) * (1.0 if t < 0.9 else exp(-(t - 0.9) * 5.0))
		voice *= v_env * 0.45

		# orchestra hit: two low notes a half-step apart, lots of harmonics
		var hit := 0.0
		for h in 7:
			hit += (sin(TAU * 82.4 * (h + 1) * t) + sin(TAU * 87.3 * (h + 1) * t)) / (h + 1)
		hit *= minf(t / 0.01, 1.0) * exp(-t * 1.6) * 0.5
		hit += hit_lp.next(rng.randf_range(-1.0, 1.0)) * exp(-t * 15.0) * 1.2
		out[i] = voice + hit
	return _wav(_normalize(out, 0.95))


## IT GOT YOU: a falling, tearing screech.
static func _screech() -> AudioStreamWAV:
	var rng := _rng(21)
	var n := int(RATE * 0.9)
	var out := _silence(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var left := 1.0 - t / 0.9
		var f := 900.0 + left * 1400.0
		phase += f / RATE
		var s := sin(TAU * phase) * 0.5 + rng.randf_range(-1.0, 1.0) * 0.5
		s = clampf(s * 2.5, -1.0, 1.0)   # distort
		out[i] = s * left
	return _wav(_normalize(out, 0.9))


## One heartbeat: lub... dub.
static func _heartbeat() -> AudioStreamWAV:
	var n := int(RATE * 0.4)
	var out := _silence(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = _thump_shape(t, 0.0) + _thump_shape(t, 0.18) * 0.7
	return _wav(_normalize(out, 0.9))


static func _thump_shape(t: float, at: float) -> float:
	var p := t - at
	if p < 0.0 or p > 0.12:
		return 0.0
	var env := 1.0 - p / 0.12
	return sin(p * TAU * 45.0) * env * env


# ---------------------------------------------------------------------------
# Music and ambience
# ---------------------------------------------------------------------------
## One note of a broken music box (E6). Other notes are played by changing the pitch.
static func _music_box_note() -> AudioStreamWAV:
	var n := int(RATE * 1.8)
	var out := _silence(n)
	var f := 1318.5
	for i in n:
		var t := float(i) / RATE
		var env := minf(t / 0.002, 1.0) * exp(-t * 2.2)
		var s := sin(TAU * f * t) + sin(TAU * f * 1.003 * t) * 0.6   # two tines, slightly detuned
		s += sin(TAU * f * 2.0 * t) * 0.25 + sin(TAU * f * 3.0 * t) * 0.1
		s += sin(TAU * f * 5.4 * t) * 0.12 * exp(-t * 10.0)   # the metallic "ping"
		out[i] = s * env
	return _wav(_normalize(out, 0.7))


## The building: two low notes slowly beating against each other + a whisper of air. Loops.
static func _hum() -> AudioStreamWAV:
	var rng := _rng(3)
	var n := RATE * 2
	var out := _silence(n)
	var lp := _LowPass.new(600.0)
	for i in n:
		var t := float(i) / RATE
		out[i] = sin(TAU * 48.0 * t) + sin(TAU * 48.5 * t) * 0.7 + lp.next(rng.randf_range(-1.0, 1.0)) * 0.12
	return _wav(_normalize(out, 0.8), true)


## Chase music: growling low notes a half-step apart, shaking fast, with screaming strings on top. Loops.
static func _panic() -> AudioStreamWAV:
	var n := RATE * 2
	var out := _silence(n)
	for i in n:
		var t := float(i) / RATE
		var low := 0.0
		for h in 6:
			low += (sin(TAU * 55.0 * (h + 1) * t) + sin(TAU * 57.5 * (h + 1) * t)) / (h + 1)
		low *= 0.7 + 0.3 * sin(TAU * 8.0 * t)
		var strings := (sin(TAU * 880.0 * t) + sin(TAU * 932.0 * t) + sin(TAU * 1760.0 * t) * 0.4)
		strings *= 0.5 + 0.5 * sin(TAU * 12.0 * t)
		out[i] = low * 0.6 + strings * 0.12
	return _wav(_normalize(out, 0.8), true)


## The drone's rotors: a buzzy whine. Loops (all frequencies fit the loop exactly).
static func _drone() -> AudioStreamWAV:
	var n := RATE / 2
	var out := _silence(n)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for h in 8:
			s += (sin(TAU * 96.0 * (h + 1) * t) + sin(TAU * 98.0 * (h + 1) * t) * 0.8) / (h + 1)
		s += sin(TAU * 1904.0 * t) * 0.06
		out[i] = s
	return _wav(_normalize(out, 0.6), true)


# ---------------------------------------------------------------------------
# Monsters
# ---------------------------------------------------------------------------
## The giant's footstep: the floor shakes.
static func _stomp() -> AudioStreamWAV:
	var rng := _rng(31)
	var n := int(RATE * 0.55)
	var out := _silence(n)
	var lp := _LowPass.new(300.0)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * lerpf(42.0, 30.0, t / 0.55) * t) * exp(-t * 6.0)
		s += lp.next(rng.randf_range(-1.0, 1.0)) * exp(-t * 12.0) * 1.2
		s += sin(TAU * 180.0 * t) * exp(-t * 25.0) * 0.2   # floorboards
		out[i] = s
	return _wav(_normalize(out, 1.0))


## The tall one's footstep: a hard, bony thud.
static func _thud() -> AudioStreamWAV:
	var rng := _rng(32)
	var n := int(RATE * 0.3)
	var out := _silence(n)
	var lp := _LowPass.new(700.0)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * 65.0 * t) * exp(-t * 14.0)
		s += lp.next(rng.randf_range(-1.0, 1.0)) * exp(-t * 22.0) * 1.0
		out[i] = s
	return _wav(_normalize(out, 0.9))


## The bird's footstep: a quick clack of claws on tiles.
static func _clack() -> AudioStreamWAV:
	var rng := _rng(33)
	var n := int(RATE * 0.16)
	var out := _silence(n)
	var lp := _LowPass.new(3500.0)
	for i in n:
		var t := float(i) / RATE
		var noise := lp.next(rng.randf_range(-1.0, 1.0))
		var s := noise * exp(-t * 60.0) * 1.5 + sin(TAU * 240.0 * t) * exp(-t * 40.0) * 0.6
		if t > 0.04:
			s += noise * exp(-(t - 0.04) * 70.0) * 0.9
		out[i] = s
	return _wav(_normalize(out, 0.8))


## The giant's voice: a slow rumbling growl.
static func _growl() -> AudioStreamWAV:
	var rng := _rng(41)
	var n := int(RATE * 1.4)
	var out := _silence(n)
	var lp := _LowPass.new(500.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += lerpf(55.0, 44.0, t / 1.4) / RATE
		var s := 0.0
		for h in 8:
			s += sin(TAU * phase * (h + 1)) / (h + 1)
		s *= 0.4 + 0.6 * (0.5 + 0.5 * sin(TAU * 22.0 * t))
		s += lp.next(rng.randf_range(-1.0, 1.0)) * 0.3
		var env := minf(t / 0.1, 1.0) * (1.0 if t < 1.0 else 1.0 - (t - 1.0) / 0.4)
		out[i] = s * env
	return _wav(_normalize(out, 0.9))


## The tall one's voice: a giggle that is not friendly.
static func _giggle() -> AudioStreamWAV:
	var n := int(RATE * 1.1)
	var out := _silence(n)
	var lp := _LowPass.new(1800.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var burst := int(t / 0.19)
		var bt := t - burst * 0.19
		var f := (250.0 - burst * 12.0) * (1.0 + bt * 1.8)
		phase += f / RATE
		var s := sin(TAU * phase) + sin(TAU * phase * 2.0) * 0.5 + sin(TAU * phase * 3.0) * 0.3
		s = lp.next(clampf(s * 1.6, -1.0, 1.0))
		var env := 0.0 if bt > 0.12 or burst > 4 else sin(bt / 0.12 * PI)
		out[i] = s * env
	return _wav(_normalize(out, 0.8))


## The bird's voice: a raspy screeching caw.
static func _caw() -> AudioStreamWAV:
	var rng := _rng(43)
	var n := int(RATE * 0.75)
	var out := _silence(n)
	var lp := _LowPass.new(4000.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += lerpf(1400.0, 800.0, t / 0.75) / RATE
		var s := sin(TAU * phase) + sin(TAU * phase * 2.0) * 0.5 + sin(TAU * phase * 3.0) * 0.3
		s *= 0.5 + 0.5 * sin(TAU * 60.0 * t)
		s += lp.next(rng.randf_range(-1.0, 1.0)) * 0.3
		var env := minf(t / 0.04, 1.0) * (1.0 if t < 0.5 else 1.0 - (t - 0.5) / 0.25)
		out[i] = s * env
	return _wav(_normalize(out, 0.85))


## Winding up: a sharp breath in, then a rising snarl that breaks up as it peaks.
static func _snarl() -> AudioStreamWAV:
	var rng := _rng(51)
	var n := int(RATE * 0.7)
	var out := _silence(n)
	var breath_lp := _LowPass.new(2500.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		# the breath: hissy noise that swells and stops
		var breath := breath_lp.next(rng.randf_range(-1.0, 1.0)) * (sin(minf(t / 0.2, 1.0) * PI) if t < 0.2 else 0.0) * 0.5
		# the snarl: rises from 90 to 240 Hz, buzzing harder and harder
		var k := clampf((t - 0.12) / 0.5, 0.0, 1.0)
		phase += lerpf(90.0, 240.0, k * k) / RATE
		var s := 0.0
		for h in 7:
			s += sin(TAU * phase * (h + 1)) / (h + 1)
		s *= 0.5 + 0.5 * sin(TAU * lerpf(18.0, 40.0, k) * t)
		s = clampf(s * (1.0 + k * 2.5), -1.0, 1.0)   # distorts as it gets louder
		var env := 0.0 if t < 0.12 else minf((t - 0.12) / 0.08, 1.0) * (1.0 if t < 0.62 else 1.0 - (t - 0.62) / 0.08)
		out[i] = breath + s * env * 0.8
	return _wav(_normalize(out, 0.95))


## The swing: a fast whoosh of air, high to low.
static func _whoosh() -> AudioStreamWAV:
	var rng := _rng(52)
	var n := int(RATE * 0.3)
	var out := _silence(n)
	var lp := _LowPass.new(2800.0)
	var hp_state := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := lp.next(rng.randf_range(-1.0, 1.0))
		hp_state += (noise - hp_state) * lerpf(0.9, 0.05, t / 0.3)   # sweeps from bright to dull
		var env := sin(clampf(t / 0.3, 0.0, 1.0) * PI)
		out[i] = (noise - hp_state * 0.6) * env * env
	return _wav(_normalize(out, 0.85))


## A floor button: a heavy mechanical click, then a deeper clunk as it seats.
static func _click() -> AudioStreamWAV:
	var rng := _rng(53)
	var n := int(RATE * 0.35)
	var out := _silence(n)
	var lp := _LowPass.new(3500.0)
	for i in n:
		var t := float(i) / RATE
		var s := lp.next(rng.randf_range(-1.0, 1.0)) * exp(-t * 90.0) * 1.5
		s += sin(TAU * 1800.0 * t) * exp(-t * 120.0) * 0.6
		if t > 0.09:
			var p := t - 0.09
			s += sin(TAU * 110.0 * p) * exp(-p * 30.0) * 1.2
			s += lp.next(rng.randf_range(-1.0, 1.0)) * exp(-p * 60.0) * 0.6
		out[i] = s
	return _wav(_normalize(out, 0.9))


## A door opening: a grinding metal scrape rising up, then a heavy clunk when it stops.
static func _door() -> AudioStreamWAV:
	var rng := _rng(54)
	var n := int(RATE * 1.2)
	var out := _silence(n)
	var lp := _LowPass.new(1200.0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		if t < 0.85:
			# the grind: buzzy sawtooth-ish tone sliding upward with rattling noise
			phase += lerpf(70.0, 130.0, t / 0.85) / RATE
			var buzz := 0.0
			for h in 9:
				buzz += sin(TAU * phase * (h + 1)) / (h + 1)
			buzz *= 0.6 + 0.4 * sin(TAU * 31.0 * t)
			var env := minf(t / 0.1, 1.0) * (1.0 if t < 0.7 else 1.0 - (t - 0.7) / 0.15)
			s = (buzz * 0.5 + lp.next(rng.randf_range(-1.0, 1.0)) * 0.5) * env
		if t > 0.8:
			# the clunk at the top
			var p := t - 0.8
			s += sin(TAU * lerpf(90.0, 55.0, p / 0.4) * p) * exp(-p * 9.0) * 1.3
			s += lp.next(rng.randf_range(-1.0, 1.0)) * exp(-p * 25.0) * 0.8
		out[i] = s
	return _wav(_normalize(out, 0.9))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
class _LowPass:
	var _alpha: float
	var _value := 0.0

	func _init(cutoff_hz: float) -> void:
		_alpha = 1.0 - exp(-TAU * cutoff_hz / RATE)

	func next(x: float) -> float:
		_value += _alpha * (x - _value)
		return _value


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _silence(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	out.fill(0.0)
	return out


static func _normalize(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var biggest := 0.0001
	for s in samples:
		biggest = maxf(biggest, absf(s))
	var k := peak / biggest
	for i in samples.size():
		samples[i] *= k
	return samples


static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
