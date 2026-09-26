extends CharacterBody3D
## The things that live in the kindergarten. Three kinds, all built from shapes in code:
##   TALL_ONE  a tall teal grinning thing with a red bow tie          (map letter M)
##   GIANT     a huge green brute with tiny eyes and fists like rocks  (map letter J)
##   BIRD      a lanky yellow bird with long orange legs and a beak    (map letter O)
## They wander their room. If one SEES you (in front of it, nothing in the way) or HEARS you
## walking close by, it hunts you: it knows the way around walls, goes to where it last saw
## you, searches around there, and only gives up after a while. But each one is tied to the
## room it was born in - it can't follow you through a doorway, so a door is always an escape.

enum Kind { TALL_ONE, GIANT, BIRD }

@export var kind := Kind.TALL_ONE

@export_group("Behaviour (set per kind in _apply_kind, tweak here to override)")
@export var wander_speed := 1.8
@export var chase_speed := 4.6         # the robot runs at 7, so you can outrun it
@export var see_distance := 9.0        # how far it can spot you
@export var see_angle := 100.0         # degrees: how wide its eyes look (360 = all round)
@export var hear_distance := 3.0       # you walking this close = it comes to look
@export var wander_radius := 8.0       # how far it strolls from home
@export var catch_distance := 1.5
@export var lose_after := 2.0          # seconds it keeps going for your last spot after losing you
@export var search_time := 4.0         # ...then how long it searches around there
@export var spawn_grace := 4.0         # seconds after the level starts before it will notice you
@export var gravity := 22.0

## Nothing may poke through the ceiling (walls are 3 m).
const MAX_TOP := 2.8

## True while it is hunting you (audio + screen effects listen to this).
var chasing := false
var kind_name := "the tall one"
var color := Color("2a9aa8")

var _level: Node3D
var _room := -1        # the room it lives in (-1 = free to roam anywhere)
var _home: Vector3
var _target: Vector3
var _path := PackedVector3Array()
var _path_index := 0
var _repath_in := 0.0
var _retarget_in := 0.0
var _hunt_timer := 0.0
var _search_timer := 0.0
var _cooldown := 0.0
var _grace := 0.0
var _time := 0.0
var _voice_in := 4.0
var _stride_phase := 0.0
var _last_swing := 0.0

var _visual: Node3D
var _head: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _jaw: Node3D
var _audio: AudioStreamPlayer3D

# per-kind looks/sounds
var _height := 3.3
var _swing_walk := 4.0
var _swing_run := 11.0
var _step_sound := "thud"
var _voice_sound := "giggle"
var _step_db := 0.0


func _ready() -> void:
	add_to_group("monster")
	_apply_kind()
	_grace = spawn_grace
	_home = global_position
	_target = _home
	_level = get_parent()
	while _level and not _level.has_method("find_path"):
		_level = _level.get_parent()
	if _level and _level.has_method("room_at"):
		_room = _level.room_at(_home)
	_build()
	_add_collision()
	_audio = AudioStreamPlayer3D.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 4
	_audio.stream = poly
	_audio.unit_size = 5.0
	_audio.max_distance = 45.0
	_audio.autoplay = true
	_audio.position.y = 1.0
	add_child(_audio)


func _apply_kind() -> void:
	match kind:
		Kind.TALL_ONE:
			kind_name = "Banbo"
			color = Color("2a9aa8")
			_height = 3.4
			wander_speed = 2.0
			chase_speed = 4.8
			see_distance = 9.0
			_swing_walk = 4.0
			_swing_run = 10.0
			_step_sound = "thud"
			_voice_sound = "giggle"
		Kind.GIANT:
			kind_name = "Jumbo"
			color = Color("3aa040")
			_height = 2.9
			wander_speed = 1.4
			chase_speed = 4.0
			see_distance = 8.0
			see_angle = 110.0
			hear_distance = 4.0
			catch_distance = 1.8
			lose_after = 2.5
			search_time = 5.0
			_swing_walk = 3.0
			_swing_run = 7.0
			_step_sound = "stomp"
			_voice_sound = "growl"
			_step_db = 4.0
		Kind.BIRD:
			kind_name = "Opi"
			color = Color("e8c53a")
			_height = 3.2
			wander_speed = 2.4
			chase_speed = 5.2
			see_distance = 9.0
			see_angle = 120.0
			hear_distance = 2.5
			catch_distance = 1.4
			lose_after = 1.5
			search_time = 3.0
			_swing_walk = 5.0
			_swing_run = 13.0
			_step_sound = "clack"
			_voice_sound = "caw"
			_step_db = -3.0


func _add_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.8 if kind == Kind.GIANT else 0.45
	capsule.height = 2.2
	shape.shape = capsule
	shape.position.y = 1.1
	add_child(shape)


# ---------------------------------------------------------------------------
# Brain
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown = max(_cooldown - delta, 0.0)
	_grace = max(_grace - delta, 0.0)
	_repath_in -= delta
	if not is_on_floor():
		velocity.y -= gravity * delta

	var player := _find_player()
	var awake := _grace <= 0.0
	var sees := awake and player != null and _can_see(player)
	var hears := awake and player != null and not sees and _can_hear(player)

	if not _in_my_room(global_position) and _in_my_room(_home):
		# somehow shoved out of its room: forget you and go home
		sees = false
		hears = false
		_hunt_timer = 0.0
		_search_timer = 0.0
		_target = _home
		_repath_in = minf(_repath_in, 0.0)

	if sees:
		_target = player.global_position
		_hunt_timer = lose_after
		_search_timer = search_time
		if not chasing:
			Game.player_spotted(self)
			_say(6.0)
			_repath_in = 0.0
		chasing = true
	elif hears and not chasing:
		# something moved over there... go and look
		_target = player.global_position
		_retarget_in = 3.0
		_repath_in = 0.0
	elif _hunt_timer > 0.0:
		# lost you - run to where you were
		_hunt_timer -= delta
		if _flat_distance(_target) < 1.0:
			_hunt_timer = 0.0
	elif chasing and _search_timer > 0.0:
		# ...and poke around nearby for a while
		_search_timer -= delta
		if _flat_distance(_target) < 1.0 or _retarget_in <= 0.0:
			_pick_search_target()
		_retarget_in -= delta
	else:
		if chasing:
			Game.say("...it lost you.  It won't leave its room.", 2.0)
		chasing = false
		_retarget_in -= delta
		if _retarget_in <= 0.0 or _flat_distance(_target) < 0.6:
			_pick_wander_target()

	var speed := chase_speed if chasing else wander_speed
	var direct := sees or _flat_distance(_target) < 2.5
	var step := _next_waypoint(direct)
	var to_step := step - global_position
	to_step.y = 0.0
	var moving := to_step.length() > 0.25
	if moving:
		var dir := to_step.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), 7.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 4.0 * delta)

	_animate(delta, moving, speed)
	move_and_slide()

	if moving and is_on_wall() and _repath_in > 0.1:
		_repath_in = 0.1   # bumped into something: think again

	# voice: mutters now and then, more when hunting
	_voice_in -= delta * (2.5 if chasing else 1.0)
	if _voice_in <= 0.0:
		_say(0.0)

	if player and awake and _cooldown <= 0.0 and _in_my_room(player.global_position) \
			and global_position.distance_to(player.global_position) < catch_distance:
		_catch(player)


## Where to walk right now: straight at the target, or along the grid path around the walls.
func _next_waypoint(direct: bool) -> Vector3:
	if direct or _level == null:
		_path = PackedVector3Array()
		return _target
	if _repath_in <= 0.0 or _path.is_empty():
		_repath_in = 0.35
		_path = _level.find_path(global_position, _target)
		_path_index = 0
		# skip the tile we're standing on
		if _path.size() > 1 and _flat_distance(_path[0]) < 1.2:
			_path_index = 1
	while _path_index < _path.size() - 1 and _flat_distance(_path[_path_index]) < 0.8:
		_path_index += 1
	if _path.is_empty():
		return _target
	if _path_index >= _path.size() - 1:
		return _target
	return _path[_path_index]


func _animate(delta: float, moving: bool, speed: float) -> void:
	if moving:
		var rate := _swing_run if chasing else _swing_walk
		_stride_phase += delta * rate * clampf(speed / chase_speed, 0.4, 1.2)
		var swing := sin(_stride_phase) * (0.75 if chasing else 0.4)
		if kind == Kind.GIANT:
			swing *= 0.6
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
		_left_arm.rotation.x = -swing * (0.9 if kind == Kind.GIANT else 0.6)
		_right_arm.rotation.x = swing * (0.9 if kind == Kind.GIANT else 0.6)
		_visual.position.y = abs(swing) * 0.15
		# a foot hits the floor every time the swing crosses the middle
		if signf(swing) != signf(_last_swing) and _last_swing != 0.0:
			_footstep()
		_last_swing = swing
	else:
		_left_leg.rotation.x = lerp(_left_leg.rotation.x, 0.0, 6.0 * delta)
		_right_leg.rotation.x = lerp(_right_leg.rotation.x, 0.0, 6.0 * delta)
		_visual.position.y = lerp(_visual.position.y, 0.0, 6.0 * delta)
	# breathing, twitching head, working jaw
	_head.rotation.z = sin(_time * 1.7) * 0.08 + (sin(_time * 23.0) * 0.06 if chasing else 0.0)
	_head.rotation.x = -0.1 + sin(_time * 0.9) * 0.05 + (0.15 if chasing else 0.0)
	if _jaw:
		_jaw.rotation.x = (0.25 + sin(_time * 14.0) * 0.2) if chasing else absf(sin(_time * 0.7)) * 0.08


func _footstep() -> void:
	var db := _step_db + (3.0 if chasing else -4.0)
	_play(_step_sound, db, randf_range(0.92, 1.08))


func _say(extra_db: float) -> void:
	_voice_in = randf_range(7.0, 16.0)
	_play(_voice_sound, extra_db - 2.0, randf_range(0.9, 1.1))


func _play(sound: String, db: float, pitch: float) -> void:
	if _audio == null:
		return
	var pb := _audio.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if pb:
		pb.play_stream(Sfx.get_sound(sound), 0.0, db, pitch)


func _catch(_player: Node3D) -> void:
	_cooldown = 6.0
	chasing = false
	_hunt_timer = 0.0
	_search_timer = 0.0
	_say(8.0)
	Game.player_caught(self)
	_target = _home
	_retarget_in = 3.0


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	var p: Node3D = players[0]
	# don't chase the robot while it's parked and you're flying the drone
	if "active" in p and not p.active:
		return null
	return p


## Is this spot inside the room it belongs to? (Doorways count as outside.)
func _in_my_room(pos: Vector3) -> bool:
	if _room < 0 or _level == null:
		return true
	return _level.room_at(pos) == _room


func _can_see(player: Node3D) -> bool:
	if not _in_my_room(player.global_position):
		return false
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist > see_distance:
		return false
	# only in front of it (unless it's already hunting you - then it keeps you in the corner of its eye)
	if not chasing and dist > 2.0:
		var forward := Vector3(sin(_visual.rotation.y), 0.0, cos(_visual.rotation.y))
		var flat := Vector3(to_player.x, 0.0, to_player.z).normalized()
		if forward.dot(flat) < cos(deg_to_rad(see_angle / 2.0)):
			return false
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.0
	var to := player.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid(), player.get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _can_hear(player: Node3D) -> bool:
	if not _in_my_room(player.global_position):
		return false
	if global_position.distance_to(player.global_position) > hear_distance:
		return false
	var v: Vector3 = player.velocity if "velocity" in player else Vector3.ZERO
	return Vector2(v.x, v.z).length() > 2.0


func _flat_distance(to: Vector3) -> float:
	return Vector2(to.x - global_position.x, to.z - global_position.z).length()


func _pick_wander_target() -> void:
	for _try in 8:
		var angle := randf() * TAU
		var dist := randf_range(2.0, wander_radius)
		var candidate := _home + Vector3(cos(angle), 0.0, sin(angle)) * dist
		if _level == null or (_level.is_walkable(candidate) and _in_my_room(candidate)):
			_target = candidate
			break
	_retarget_in = randf_range(2.0, 5.0)
	_repath_in = 0.0


func _pick_search_target() -> void:
	for _try in 8:
		var candidate := _target + Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
		if _level == null or (_level.is_walkable(candidate) and _in_my_room(candidate)):
			_target = candidate
			break
	_retarget_in = randf_range(1.5, 3.0)
	_repath_in = 0.0


# ---------------------------------------------------------------------------
# Building the monsters
# ---------------------------------------------------------------------------
func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	match kind:
		Kind.GIANT:
			_build_giant()
		Kind.BIRD:
			_build_bird()
		_:
			_build_tall_one()
	_fit_under_ceiling()


## Shrink the whole model (keeping its proportions) so its highest point stays below the ceiling.
func _fit_under_ceiling() -> void:
	var top := model_top()
	if top > MAX_TOP:
		_visual.scale = Vector3.ONE * (MAX_TOP / top)


## Highest point of the model, in metres above its feet.
func model_top() -> float:
	var top := 0.0
	var to_visual := _visual.global_transform.affine_inverse()
	for node in _visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var xform := to_visual * mesh.global_transform
		var aabb := mesh.get_aabb()
		for i in 8:
			top = maxf(top, (xform * aabb.get_endpoint(i)).y * _visual.scale.y)
	return top


## Tall, thin, teal. Huge oval head, enormous white eyes, a grin too wide for its face,
## a red bow tie. Long arms, four-fingered hands.
func _build_tall_one() -> void:
	var leg_h := _height * 0.40
	var head_h := 1.15
	var body_h := _height - leg_h - head_h * 0.7
	var belly := color.lightened(0.25)

	var body := _capsule(0.36, body_h, color)
	body.position.y = leg_h + body_h / 2.0
	body.scale = Vector3(1.0, 1.0, 0.8)
	_visual.add_child(body)
	var tummy := _sphere(0.3, belly)
	tummy.scale = Vector3(0.9, 1.5, 0.5)
	tummy.position = Vector3(0, leg_h + body_h * 0.45, 0.22)
	_visual.add_child(tummy)
	# grime
	for i in 4:
		var spot := _sphere(0.09, color.darkened(0.45))
		spot.scale = Vector3(1.4, 0.7, 0.4)
		spot.position = Vector3(sin(i * 2.1) * 0.25, leg_h + body_h * (0.25 + i * 0.18), 0.28)
		_visual.add_child(spot)

	# red bow tie at the neck
	var neck_y := leg_h + body_h - 0.05
	var knot := _sphere(0.08, Color("c81e1e"))
	knot.position = Vector3(0, neck_y, 0.3)
	_visual.add_child(knot)
	for side in [-1.0, 1.0]:
		var wing := _box(Vector3(0.28, 0.16, 0.06), Color("c81e1e"))
		wing.position = Vector3(side * 0.18, neck_y, 0.3)
		wing.rotation.z = side * 0.25
		_visual.add_child(wing)

	# head: tall oval, leaning towards you
	_head = Node3D.new()
	_head.position.y = neck_y + 0.15
	_visual.add_child(_head)
	var skull := _sphere(0.5, color)
	skull.scale = Vector3(0.95, head_h / 1.0, 0.9)
	skull.position.y = head_h * 0.45
	_head.add_child(skull)
	var face := _sphere(0.4, belly)
	face.scale = Vector3(0.9, 1.0, 0.5)
	face.position = Vector3(0, head_h * 0.35, 0.32)
	_head.add_child(face)

	# eyes: big, white, glowing, with tiny pupils that stare
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.17, Color("f4f4ff"), true, 1.6)
		eye.scale = Vector3(1.0, 1.35, 0.7)
		eye.position = Vector3(side * 0.21, head_h * 0.55, 0.42)
		_head.add_child(eye)
		var pupil := _sphere(0.055, Color("120000"))
		pupil.position = eye.position + Vector3(side * -0.02, -0.02, 0.15)
		_head.add_child(pupil)
		var brow := _box(Vector3(0.22, 0.05, 0.06), color.darkened(0.5))
		brow.position = eye.position + Vector3(0, 0.26, 0.05)
		brow.rotation.z = side * -0.35
		_head.add_child(brow)
		var light := OmniLight3D.new()
		light.light_color = Color("dfe8ff")
		light.light_energy = 0.5
		light.omni_range = 2.5
		light.position = eye.position
		_head.add_child(light)

	# the grin: a wide dark curve made of pieces, upper teeth, a moving lower jaw
	var mouth_y := head_h * 0.15
	for i in 7:
		var k := (i - 3) / 3.0
		var piece := _box(Vector3(0.14, 0.13, 0.08), Color("0a0508"))
		piece.position = Vector3(k * 0.42, mouth_y + k * k * 0.14, 0.44 - k * k * 0.08)
		piece.rotation.z = -k * 0.45
		_head.add_child(piece)
		var tooth := _box(Vector3(0.07, 0.09, 0.04), Color("e8e2d0"))
		tooth.position = piece.position + Vector3(0, 0.03, 0.03)
		_head.add_child(tooth)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, mouth_y - 0.06, 0.3)
	_head.add_child(_jaw)
	var chin := _box(Vector3(0.7, 0.12, 0.18), color)
	chin.position = Vector3(0, -0.06, 0.1)
	_jaw.add_child(chin)
	for i in 6:
		var tooth := _box(Vector3(0.06, 0.08, 0.04), Color("e8e2d0"))
		tooth.position = Vector3((i - 2.5) * 0.11, 0.02, 0.17)
		_jaw.add_child(tooth)

	# arms with hands
	_left_arm = _make_limb(-0.46, leg_h + body_h * 0.9, body_h * 1.05, 0.08, color)
	_right_arm = _make_limb(0.46, leg_h + body_h * 0.9, body_h * 1.05, 0.08, color)
	for arm in [_left_arm, _right_arm]:
		_visual.add_child(arm)
		var side := signf(arm.position.x)
		var palm := _sphere(0.13, color.darkened(0.15))
		palm.scale = Vector3(1.0, 1.2, 0.6)
		palm.position.y = -body_h * 1.05
		arm.add_child(palm)
		for f in 4:
			var finger := _capsule(0.03, 0.26, color.darkened(0.25))
			finger.position = palm.position + Vector3(side * (f - 1.5) * 0.06, -0.2, 0.0)
			finger.rotation.x = 0.3
			arm.add_child(finger)

	# legs with big flat feet
	_left_leg = _make_limb(-0.2, leg_h, leg_h, 0.1, color.darkened(0.1))
	_right_leg = _make_limb(0.2, leg_h, leg_h, 0.1, color.darkened(0.1))
	for leg in [_left_leg, _right_leg]:
		_visual.add_child(leg)
		var foot := _box(Vector3(0.24, 0.12, 0.45), color.darkened(0.35))
		foot.position = Vector3(0, -leg_h + 0.06, 0.12)
		leg.add_child(foot)


## Enormous, green, hunched. A tiny head sunk between mountainous shoulders, little far-apart
## eyes, a mouth full of teeth. Arms as thick as tree trunks that nearly drag on the floor.
func _build_giant() -> void:
	var leg_h := _height * 0.28
	var body_h := _height * 0.55
	var dark := color.darkened(0.3)

	var torso := _sphere(0.8, color)
	torso.scale = Vector3(1.35, body_h / 1.6, 1.0)
	torso.position.y = leg_h + body_h / 2.0
	_visual.add_child(torso)
	var belly := _sphere(0.55, color.lightened(0.2))
	belly.scale = Vector3(1.1, 1.0, 0.6)
	belly.position = Vector3(0, leg_h + body_h * 0.4, 0.55)
	_visual.add_child(belly)
	for side in [-1.0, 1.0]:
		var shoulder := _sphere(0.5, color)
		shoulder.position = Vector3(side * 0.85, leg_h + body_h * 0.92, 0)
		_visual.add_child(shoulder)
		# ragged torn shorts
		var shorts := _box(Vector3(0.5, 0.35, 0.55), Color("3b2a4a"))
		shorts.position = Vector3(side * 0.3, leg_h + 0.05, 0)
		_visual.add_child(shorts)
	# veins / scars
	for i in 5:
		var scar := _box(Vector3(0.05, 0.5 + i * 0.05, 0.04), dark)
		scar.position = Vector3(-0.6 + i * 0.3, leg_h + body_h * 0.65, 0.78 - absf(i - 2) * 0.08)
		scar.rotation.z = (i - 2) * 0.3
		_visual.add_child(scar)

	_head = Node3D.new()
	_head.position = Vector3(0, leg_h + body_h * 0.95, 0.25)
	_visual.add_child(_head)
	var skull := _sphere(0.36, color)
	skull.scale = Vector3(1.1, 0.85, 1.0)
	skull.position.y = 0.2
	_head.add_child(skull)
	var brow := _box(Vector3(0.7, 0.14, 0.2), dark)
	brow.position = Vector3(0, 0.36, 0.25)
	_head.add_child(brow)
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.075, Color("f4f4ff"), true, 1.6)
		eye.position = Vector3(side * 0.24, 0.25, 0.33)
		_head.add_child(eye)
		var pupil := _sphere(0.03, Color("120000"))
		pupil.position = eye.position + Vector3(0, 0, 0.06)
		_head.add_child(pupil)
		var light := OmniLight3D.new()
		light.light_color = Color("dfe8ff")
		light.light_energy = 0.4
		light.omni_range = 2.0
		light.position = eye.position
		_head.add_child(light)
	# mouth: huge, wide, all teeth
	var mouth := _box(Vector3(0.7, 0.2, 0.12), Color("0a0508"))
	mouth.position = Vector3(0, -0.02, 0.32)
	_head.add_child(mouth)
	for i in 8:
		var tooth := _box(Vector3(0.06, 0.12, 0.05), Color("e8e2d0"))
		tooth.position = Vector3((i - 3.5) * 0.085, 0.06, 0.38)
		_head.add_child(tooth)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, -0.12, 0.2)
	_head.add_child(_jaw)
	var chin := _box(Vector3(0.75, 0.16, 0.25), color)
	chin.position = Vector3(0, -0.08, 0.1)
	_jaw.add_child(chin)
	for i in 7:
		var tooth := _box(Vector3(0.06, 0.1, 0.05), Color("e8e2d0"))
		tooth.position = Vector3((i - 3.0) * 0.1, 0.03, 0.22)
		_jaw.add_child(tooth)

	# tree-trunk arms and fists
	var arm_len := leg_h + body_h * 0.85
	_left_arm = _make_limb(-1.05, leg_h + body_h * 0.9, arm_len, 0.24, color)
	_right_arm = _make_limb(1.05, leg_h + body_h * 0.9, arm_len, 0.24, color)
	for arm in [_left_arm, _right_arm]:
		_visual.add_child(arm)
		var fist := _sphere(0.36, color.darkened(0.15))
		fist.scale = Vector3(1.0, 0.9, 1.1)
		fist.position.y = -arm_len + 0.1
		arm.add_child(fist)
		for k in 4:
			var knuckle := _sphere(0.09, dark)
			knuckle.position = fist.position + Vector3((k - 1.5) * 0.17, 0.05, 0.3)
			arm.add_child(knuckle)

	_left_leg = _make_limb(-0.42, leg_h, leg_h, 0.26, color.darkened(0.1))
	_right_leg = _make_limb(0.42, leg_h, leg_h, 0.26, color.darkened(0.1))
	for leg in [_left_leg, _right_leg]:
		_visual.add_child(leg)
		var foot := _box(Vector3(0.5, 0.18, 0.7), dark)
		foot.position = Vector3(0, -leg_h + 0.09, 0.15)
		leg.add_child(foot)


## Very tall, very yellow. Stilt legs that bend backwards, a fat feathered body, a long neck,
## a small head with big staring eyes, an orange beak and a crest of feathers.
func _build_bird() -> void:
	var leg_h := _height * 0.5
	var body_r := 0.5
	var neck_h := _height * 0.28
	var orange := Color("e07a1e")
	var dark := color.darkened(0.35)

	var body := _sphere(body_r, color)
	body.scale = Vector3(1.0, 0.95, 1.35)
	body.position.y = leg_h + body_r * 0.8
	_visual.add_child(body)
	var chest := _sphere(0.32, color.lightened(0.3))
	chest.scale = Vector3(0.9, 1.0, 0.7)
	chest.position = Vector3(0, leg_h + body_r * 0.7, 0.45)
	_visual.add_child(chest)
	# tail feathers
	for i in 3:
		var feather := _box(Vector3(0.14, 0.05, 0.7), dark)
		feather.position = Vector3((i - 1) * 0.16, leg_h + body_r * 1.0, -0.8)
		feather.rotation.x = -0.5 - (i % 2) * 0.15
		feather.rotation.y = (i - 1) * 0.25
		_visual.add_child(feather)
	# stubby wings, folded
	_left_arm = _make_limb(-body_r * 0.95, leg_h + body_r * 1.0, 0.7, 0.1, dark)
	_right_arm = _make_limb(body_r * 0.95, leg_h + body_r * 1.0, 0.7, 0.1, dark)
	for wing in [_left_arm, _right_arm]:
		wing.rotation.x = 0.6
		wing.get_child(0).scale = Vector3(0.5, 1.0, 2.2)
		_visual.add_child(wing)

	# long neck, small head
	var neck := _capsule(0.11, neck_h, color)
	neck.position = Vector3(0, leg_h + body_r * 1.3 + neck_h / 2.0, 0.25)
	neck.rotation.x = -0.15
	_visual.add_child(neck)
	_head = Node3D.new()
	_head.position = Vector3(0, leg_h + body_r * 1.3 + neck_h, 0.32)
	_visual.add_child(_head)
	var skull := _sphere(0.26, color)
	skull.scale = Vector3(1.0, 1.05, 1.15)
	_head.add_child(skull)
	for i in 3:
		var crest := _box(Vector3(0.05, 0.4, 0.1), orange)
		crest.position = Vector3((i - 1) * 0.08, 0.35, -0.05 - i * 0.03)
		crest.rotation.x = -0.4 - i * 0.2
		crest.rotation.z = (i - 1) * 0.25
		_head.add_child(crest)
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.11, Color("f4f4ff"), true, 1.6)
		eye.position = Vector3(side * 0.17, 0.08, 0.16)
		_head.add_child(eye)
		var pupil := _sphere(0.045, Color("120000"))
		pupil.position = eye.position + Vector3(side * 0.02, 0.0, 0.09)
		_head.add_child(pupil)
		var light := OmniLight3D.new()
		light.light_color = Color("dfe8ff")
		light.light_energy = 0.4
		light.omni_range = 2.0
		light.position = eye.position
		_head.add_child(light)
	# beak: a pointed cone on top, a jaw underneath that opens
	var beak := _cone(0.12, 0.5, orange)
	beak.position = Vector3(0, -0.02, 0.45)
	beak.rotation.x = PI / 2.0
	_head.add_child(beak)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, -0.08, 0.2)
	_head.add_child(_jaw)
	var lower := _cone(0.09, 0.4, orange.darkened(0.2))
	lower.position = Vector3(0, -0.02, 0.2)
	lower.rotation.x = PI / 2.0
	_jaw.add_child(lower)
	for i in 5:
		var tooth := _box(Vector3(0.025, 0.06, 0.025), Color("e8e2d0"))
		tooth.position = Vector3((i - 2) * 0.035, 0.02, 0.15 + absf(i - 2) * 0.03)
		_jaw.add_child(tooth)

	# backwards-bending stilt legs with three-toed feet
	_left_leg = _make_bird_leg(-0.22, leg_h, orange)
	_right_leg = _make_bird_leg(0.22, leg_h, orange)
	_visual.add_child(_left_leg)
	_visual.add_child(_right_leg)


func _make_bird_leg(x: float, leg_h: float, c: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, leg_h, 0)
	var thigh := _capsule(0.06, leg_h * 0.5, c)
	thigh.position = Vector3(0, -leg_h * 0.25, -0.12)
	thigh.rotation.x = -0.45
	pivot.add_child(thigh)
	var knee := _sphere(0.08, c.darkened(0.2))
	knee.position = Vector3(0, -leg_h * 0.48, -0.22)
	pivot.add_child(knee)
	var shin := _capsule(0.05, leg_h * 0.55, c)
	shin.position = Vector3(0, -leg_h * 0.75, -0.1)
	shin.rotation.x = 0.4
	pivot.add_child(shin)
	for t in 3:
		var toe := _box(Vector3(0.04, 0.04, 0.3), c.darkened(0.25))
		toe.position = Vector3((t - 1) * 0.07, -leg_h + 0.02, 0.15)
		toe.rotation.y = (t - 1) * 0.45
		pivot.add_child(toe)
	return pivot


func _make_limb(x: float, pivot_y: float, length: float, radius: float, c: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, pivot_y, 0)
	var limb := _capsule(radius, length, c)
	limb.position.y = -length / 2.0
	pivot.add_child(limb)
	return pivot


func _mat(c: Color, glow := false, glow_strength := 4.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.85
	if glow:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = glow_strength
	return mat


func _sphere(radius: float, c: Color, glow := false, glow_strength := 4.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c, glow, glow_strength)
	return mi


func _box(size: Vector3, c: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	return mi


func _capsule(radius: float, h: float, c: Color) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = max(h, radius * 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	return mi


func _cone(radius: float, h: float, c: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = h
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	return mi
