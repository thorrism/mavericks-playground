extends Node
## Scripted scares: every now and then, when nothing is hunting you, the building plays a trick.
## The level adds this node (kinder.gd, `scares_enabled`). Each scare starts with a hush - the
## music and the hum drain away - and then one of these:
##   figure    a tall black shape with two red pin-prick eyes stands at the far end of the room,
##             or peeks round a doorway. Put the flashlight on it, or walk at it, and it's gone.
##   words     words appear on the wall right behind you ("TURN AROUND"). You'll see them when you do.
##   cupboard  a cupboard across the room slams its doors shut by itself, with a long creak.
##   giggle    one of the toys you haven't found yet giggles.
##   lamps     the lamps around you die and your flashlight stutters.
## Change the timings here; change the words in BEHIND_WORDS.

@export var first_after := 25.0                 # seconds into a chapter before the first one
@export var every := Vector2(35.0, 70.0)        # seconds between scares (random in this range)
@export var hush_time := 1.8                    # seconds of silence before it happens

const BEHIND_WORDS: Array[String] = ["TURN AROUND", "BEHIND YOU", "I SEE YOU", "you're next", "DON'T LOOK", "it's here", "found you"]
const KINDS: Array[String] = ["figure", "figure", "words", "cupboard", "giggle", "lamps"]

var _level: Node3D
var _in := 0.0
var _pending := ""
var _pending_in := 0.0
var _figure: Node3D
var _figure_age := 0.0
var _sound: AudioStreamPlayer3D


func _ready() -> void:
	_level = get_parent()
	_in = first_after + randf() * 15.0
	_sound = AudioStreamPlayer3D.new()
	_sound.unit_size = 5.0
	_sound.max_distance = 40.0
	add_child(_sound)


func _process(delta: float) -> void:
	if not _level._playing or _level._caught or _level._escaped:
		return
	_update_figure(delta)
	if _pending != "":
		_pending_in -= delta
		if _pending_in <= 0.0:
			var what := _pending
			_pending = ""
			_run(what)
		return
	if _hunted() or _level.drone.active:
		return
	_in -= delta
	if _in > 0.0:
		return
	_in = randf_range(every.x, every.y)
	_pending = KINDS[randi() % KINDS.size()]
	_pending_in = hush_time
	var audio := _level.get_node_or_null("Audio")
	if audio and audio.has_method("hush"):
		audio.hush(hush_time + 1.5)


## Do one now (also handy for testing: scares.run("figure")).
func run(what: String) -> bool:
	return _run(what)


func _run(what: String) -> bool:
	match what:
		"figure":
			return _spawn_figure()
		"words":
			return _write_behind()
		"cupboard":
			return _slam_cupboard()
		"giggle":
			return _giggle()
		"lamps":
			return _lamps_die()
	return false


func _hunted() -> bool:
	for m in get_tree().get_nodes_in_group("monster"):
		if m.chasing:
			return true
	return false


func _eye_pos() -> Vector3:
	return _level.camera.global_position


func _forward() -> Vector3:
	var f: Vector3 = -_level.camera.global_basis.z
	f.y = 0.0
	return f.normalized()


func _clear_line(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var exclude: Array[RID] = []
	for p in get_tree().get_nodes_in_group("player"):
		exclude.append(p.get_rid())
	query.exclude = exclude
	return _level.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _far_from_monsters(pos: Vector3, dist: float) -> bool:
	for m in get_tree().get_nodes_in_group("monster"):
		if m.global_position.distance_to(pos) < dist:
			return false
	return true


# ---------------------------------------------------------------------------
# The figure
# ---------------------------------------------------------------------------
func _spawn_figure() -> bool:
	if _figure:
		return false
	var eye := _eye_pos()
	var ground := Vector3(eye.x, 0.0, eye.z)
	var forward := _forward()
	var spot := Vector3.INF
	# best: peeking round a doorway in front of you
	var doors: Array = []
	for list in _level._doors.values():
		doors.append_array(list)
	if _level.exit_door:
		doors.append(_level.exit_door)
	doors.shuffle()
	for door: Node3D in doors:
		var to: Vector3 = door.global_position - ground
		to.y = 0.0
		if to.length() < 6.0 or to.length() > 16.0 or forward.dot(to.normalized()) < 0.85:
			continue
		var side := to.normalized().cross(Vector3.UP) * (0.75 if randf() < 0.5 else -0.75)
		var candidate: Vector3 = Vector3(door.global_position.x, 0.0, door.global_position.z) + side
		if _clear_line(eye, candidate + Vector3.UP * 1.6):
			spot = candidate
			break
	# otherwise: standing at the far end of the room, a little off to one side
	if spot == Vector3.INF:
		for _try in 14:
			var angle := randf_range(-0.35, 0.35)
			var dist := randf_range(8.0, 16.0)
			var candidate := ground + forward.rotated(Vector3.UP, angle) * dist
			if _level.is_walkable(candidate) and _far_from_monsters(candidate, 4.0) and _clear_line(eye, candidate + Vector3.UP * 1.6):
				spot = candidate
				break
	if spot == Vector3.INF:
		return false
	_figure = _build_figure()
	_figure.position = spot
	_level.add_child(_figure)
	var look := ground - spot
	_figure.rotation.y = atan2(look.x, look.z)
	_figure_age = 0.0
	return true


func _build_figure() -> Node3D:
	var figure := Node3D.new()
	figure.name = "Figure"
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.01, 0.01, 0.012)
	black.roughness = 1.0
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 2.1
	body.mesh = capsule
	body.material_override = black
	body.position.y = 1.05
	body.scale = Vector3(1.0, 1.0, 0.6)
	figure.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.46
	head.mesh = sphere
	head.material_override = black
	head.position = Vector3(0.05, 2.28, 0)
	head.rotation.z = 0.35   # its head hangs to one side
	figure.add_child(head)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.06
		arm_mesh.height = 1.5
		arm.mesh = arm_mesh
		arm.material_override = black
		arm.position = Vector3(side * 0.34, 1.25, 0)
		figure.add_child(arm)
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.025
		eye_mesh.height = 0.05
		eye.mesh = eye_mesh
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.1, 0.05)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.1, 0.05)
		glow.emission_energy_multiplier = 6.0
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye.material_override = glow
		eye.position = Vector3(0.05 + side * 0.07, 2.3 + side * 0.02, 0.17)
		figure.add_child(eye)
	return figure


## Gone when the flashlight finds it, when you walk at it, or after a few seconds anyway.
func _update_figure(delta: float) -> void:
	if _figure == null:
		return
	_figure_age += delta
	var eye := _eye_pos()
	var chest := _figure.global_position + Vector3.UP * 1.4
	var to := chest - eye
	var lit := false
	if _level.flashlight_on:
		var dir: Vector3 = -_level.flashlight.global_basis.z
		lit = to.length() < _level.flashlight_range and dir.dot(to.normalized()) > cos(deg_to_rad(_level.flashlight_angle * 0.45))
	if (lit and _figure_age > 0.35) or to.length() < 5.0 or _figure_age > 5.0 or _hunted():
		_sound.global_position = _figure.global_position + Vector3.UP
		_sound.stream = Sfx.get_sound("whoosh")
		_sound.pitch_scale = 0.6
		_sound.volume_db = -6.0
		_sound.play()
		_level._glitch = maxf(_level._glitch, 0.5)
		_figure.queue_free()
		_figure = null


# ---------------------------------------------------------------------------
# The others
# ---------------------------------------------------------------------------
func _write_behind() -> bool:
	var eye := _eye_pos()
	var back := -_forward()
	var query := PhysicsRayQueryParameters3D.create(eye, eye + back * 10.0)
	var exclude: Array[RID] = []
	for p in get_tree().get_nodes_in_group("player"):
		exclude.append(p.get_rid())
	query.exclude = exclude
	var hit := _level.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var normal: Vector3 = hit["normal"]
	if absf(normal.y) > 0.3 or eye.distance_to(hit["position"]) < 1.5:
		return false
	var label := Label3D.new()
	label.name = "BehindYou"
	label.text = BEHIND_WORDS[randi() % BEHIND_WORDS.size()]
	label.font_size = 84
	label.pixel_size = 0.004
	label.modulate = Color(0.55, 0.03, 0.03)
	label.outline_modulate = Color(0.1, 0.0, 0.0)
	label.outline_size = 6
	label.shaded = true
	var at: Vector3 = hit["position"]
	label.position = Vector3(at.x, 1.6, at.z) + normal * 0.03
	label.rotation.y = atan2(normal.x, normal.z)
	label.rotation.z = randf_range(-0.08, 0.08)
	_level.add_child(label)
	_sound.global_position = label.global_position
	_sound.stream = Sfx.get_sound("rustle")
	_sound.pitch_scale = 1.4
	_sound.volume_db = -8.0
	_sound.play()
	return true


func _slam_cupboard() -> bool:
	var me: Vector3 = _level.robot.global_position
	var cells: Array = _level._cupboard_doors.keys()
	cells.shuffle()
	for cell: Vector2i in cells:
		var hinge: Node3D = _level._cupboard_doors[cell][0]
		var d := hinge.global_position.distance_to(me)
		if d > 6.0 and d < 16.0:
			_level.slam_cupboard(cell)
			return true
	return false


func _giggle() -> bool:
	var me: Vector3 = _level.robot.global_position
	var toys := get_tree().get_nodes_in_group("battery")
	toys.shuffle()
	for toy: Node3D in toys:
		var d := toy.global_position.distance_to(me)
		if d > 4.0 and d < 18.0:
			_sound.global_position = toy.global_position
			_sound.stream = Sfx.get_sound("giggle")
			_sound.pitch_scale = 1.25
			_sound.volume_db = -2.0
			_sound.play()
			return true
	return false


func _lamps_die() -> bool:
	var me: Vector3 = _level.robot.global_position
	var any := false
	for lamp in get_tree().get_nodes_in_group("lamp"):
		if lamp.global_position.distance_to(me) < 14.0:
			lamp.blackout(randf_range(2.0, 3.5))
			any = true
	_level._flicker = maxf(_level._flicker, 1.2)
	_sound.global_position = me + _forward() * 8.0 + Vector3.UP
	_sound.stream = Sfx.get_sound("thud")
	_sound.pitch_scale = 0.5
	_sound.volume_db = 0.0
	_sound.play()
	return any
