extends CharacterBody3D
## A tall, skinny thing that lurks in the dark. Its eyes glow, so you see them
## coming before you see the rest. It wanders its room, and if it spots you it
## comes for you - and remembers where it last saw you.
## Built from code so colours and sizes are one-line changes.

@export_group("Look")
@export var color := Color("2f5d3a")
@export var eye_color := Color("ff2020")
@export var height := 3.2
@export var head_size := 1.1

@export_group("Behaviour")
@export var wander_speed := 1.8
@export var chase_speed := 4.6
@export var see_distance := 12.0      # how far it can spot you
@export var wander_radius := 7.0      # how far it strolls from home
@export var catch_distance := 1.4
@export var lose_after := 4.0         # seconds it keeps hunting after losing sight of you
@export var gravity := 22.0

## True while it is hunting you (the audio listens to this for the heartbeat).
var chasing := false

var _home: Vector3
var _target: Vector3
var _retarget_in := 0.0
var _time := 0.0
var _visual: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _head: Node3D
var _cooldown := 0.0
var _hunt_timer := 0.0


func _ready() -> void:
	add_to_group("monster")
	_home = global_position
	_target = _home
	_build()


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown = max(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var player := _find_player()
	var speed := wander_speed
	if player and _can_see(player):
		_target = player.global_position
		_hunt_timer = lose_after
		if not chasing:
			Game.say("...it saw you.  RUN.", 1.5)
		chasing = true
	elif _hunt_timer > 0.0:
		# lost you - keep heading for where you were
		_hunt_timer -= delta
		if global_position.distance_to(_target) < 0.8:
			_hunt_timer = 0.0
	else:
		chasing = false
		_retarget_in -= delta
		if _retarget_in <= 0.0 or global_position.distance_to(_target) < 0.5 or is_on_wall():
			_pick_wander_target()
	if chasing:
		speed = chase_speed

	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.3:
		var dir := to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), 6.0 * delta)
		var swing := sin(_time * (11.0 if chasing else 4.0)) * (0.7 if chasing else 0.4)
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
		_left_arm.rotation.x = -swing * 0.6
		_right_arm.rotation.x = swing * 0.6
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# twitchy head, lurching walk
	_head.rotation.z = sin(_time * 1.7) * 0.12 + (sin(_time * 23.0) * 0.06 if chasing else 0.0)
	_visual.position.y = abs(sin(_time * (8.0 if chasing else 3.0))) * 0.12 if velocity.length() > 0.5 else 0.0

	move_and_slide()

	if player and _cooldown <= 0.0 and global_position.distance_to(player.global_position) < catch_distance:
		_catch(player)


func _catch(_player: Node3D) -> void:
	_cooldown = 4.0
	chasing = false
	_hunt_timer = 0.0
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


func _can_see(player: Node3D) -> bool:
	if global_position.distance_to(player.global_position) > see_distance:
		return false
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.0
	var to := player.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid(), player.get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(2.0, wander_radius)
	_target = _home + Vector3(cos(angle), 0.0, sin(angle)) * dist
	_retarget_in = randf_range(2.0, 5.0)


# ---------------------------------------------------------------------------
# Building the monster
# ---------------------------------------------------------------------------
func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var leg_h := height * 0.42
	var body_h := height - head_size - leg_h

	# thin hunched body
	var body := _capsule(0.32, body_h, color)
	body.position.y = leg_h + body_h / 2.0
	body.rotation.x = 0.15
	_visual.add_child(body)

	# oversized head, slightly squashed, leaning forward
	_head = Node3D.new()
	_head.position.y = leg_h + body_h + head_size * 0.35
	_visual.add_child(_head)
	var head := _sphere(head_size / 2.0, color.darkened(0.1))
	head.scale = Vector3(1.0, 1.15, 0.9)
	head.position.z = 0.15
	_head.add_child(head)

	# glowing eyes - visible from across a dark room
	for side in [-1.0, 1.0]:
		var eye := _sphere(head_size * 0.09, eye_color, true)
		eye.position = Vector3(side * head_size * 0.2, head_size * 0.1, head_size * 0.55)
		_head.add_child(eye)
		var light := OmniLight3D.new()
		light.light_color = eye_color
		light.light_energy = 0.6
		light.omni_range = 2.5
		light.position = eye.position
		_head.add_child(light)

	# too-wide grin
	var mouth := _box(Vector3(head_size * 0.7, 0.06, 0.08), Color("0a0508"))
	mouth.position = Vector3(0, -head_size * 0.2, head_size * 0.55)
	_head.add_child(mouth)
	for i in 6:
		var tooth := _box(Vector3(0.05, 0.1, 0.05), Color("d8d0c0"))
		tooth.position = mouth.position + Vector3((i - 2.5) * head_size * 0.12, -0.07, 0.0)
		_head.add_child(tooth)

	# long dangling arms (pivot at shoulder)
	_left_arm = _make_limb(-0.42, leg_h + body_h * 0.92, body_h * 1.1, 0.09, color.darkened(0.2))
	_right_arm = _make_limb(0.42, leg_h + body_h * 0.92, body_h * 1.1, 0.09, color.darkened(0.2))
	_visual.add_child(_left_arm)
	_visual.add_child(_right_arm)
	for arm in [_left_arm, _right_arm]:
		var claw := _sphere(0.16, color.darkened(0.45))
		claw.position.y = -body_h * 1.1
		arm.add_child(claw)

	# stilt legs
	_left_leg = _make_limb(-0.22, leg_h, leg_h, 0.11, color.darkened(0.35))
	_right_leg = _make_limb(0.22, leg_h, leg_h, 0.11, color.darkened(0.35))
	_visual.add_child(_left_leg)
	_visual.add_child(_right_leg)


func _make_limb(x: float, pivot_y: float, length: float, radius: float, c: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, pivot_y, 0)
	var limb := _capsule(radius, length, c)
	limb.position.y = -length / 2.0
	pivot.add_child(limb)
	return pivot


func _mat(c: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.85
	if glow:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 4.0
	return mat


func _sphere(radius: float, c: Color, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c, glow)
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
