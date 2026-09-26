extends AudioStreamPlayer
## Creepy sound made from maths - no audio files needed.
## A low hum all the time, a heartbeat that speeds up while a monster hunts you,
## and a nasty screech when one gets you.

@export var hum_volume := 0.08
@export var heartbeat_volume := 0.5
@export var screech_volume := 0.7

const RATE := 22050.0

var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _beat_phase := 0.0
var _screech := 0.0
var _hunted := 0.0   # 0..1, eases in/out


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.15
	stream = gen
	volume_db = -6.0
	Game.caught.connect(func(_by: Node3D): _screech = 1.0)
	play()
	_playback = get_stream_playback()


func _process(delta: float) -> void:
	if _playback == null:
		return
	var hunted := false
	for m in get_tree().get_nodes_in_group("monster"):
		if m.chasing:
			hunted = true
			break
	_hunted = move_toward(_hunted, 1.0 if hunted else 0.0, delta * (2.0 if hunted else 0.5))

	var frames := _playback.get_frames_available()
	var beat_rate := lerpf(0.9, 2.4, _hunted)   # beats per second
	for i in frames:
		var t := 1.0 / RATE
		_phase += t
		_beat_phase = fmod(_beat_phase + t * beat_rate, 1.0)

		# hum: two detuned low sines + a whisper of noise
		var hum := (sin(_phase * TAU * 48.0) + sin(_phase * TAU * 48.7) * 0.7) * hum_volume
		hum += (randf() * 2.0 - 1.0) * 0.01

		# heartbeat: two thumps per beat (lub-dub)
		var beat := 0.0
		if _hunted > 0.01:
			beat = _thump(_beat_phase, 0.0) + _thump(_beat_phase, 0.18) * 0.7
			beat *= heartbeat_volume * _hunted

		# screech: falling noisy tone that dies out
		var screech := 0.0
		if _screech > 0.001:
			_screech -= t * 1.2
			var f := 900.0 + _screech * 1400.0
			screech = (sin(_phase * TAU * f) * 0.5 + (randf() * 2.0 - 1.0) * 0.5) * _screech * screech_volume

		var sample := clampf(hum + beat + screech, -1.0, 1.0)
		_playback.push_frame(Vector2(sample, sample))


func _thump(phase: float, at: float) -> float:
	var p := phase - at
	if p < 0.0 or p > 0.12:
		return 0.0
	var env := (1.0 - p / 0.12)
	return sin(p * TAU * 45.0) * env * env
