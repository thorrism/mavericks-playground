extends CharacterBody3D
## A big silly monster that wanders around its room. If it sees you it
## waddles after you, and if it catches you, you go back to the start.
## Built from code so colours and sizes are one-line changes.

@export_group("Look")
@export var color := Color("6ad14f")
@export var eye_color := Color("ffffff")
@export var height := 2.2
@export var head_size := 1.3

@export_group("Behaviour")
@export var wander_speed := 2.5
@export var chase_speed := 4.0
@export var see_distance := 8.0       # how far it can spot you
@export var wander_radius := 6.0      # how far it strolls from home
@export var catch_distance := 1.3
@export var gravity := 22.0
@export var caught_text := "Boo!  Back to the start!"

var _home: Vector3
var _target: Vector3
var _retarget_in := 0.0
var _time := 0.0
var _visual: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _cooldown := 0.0


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
	var chasing := false
	var speed := wander_speed
	if player and _can_see(player):
		_target = player.global_position
		chasing = true
		speed = chase_speed
	else:
		_retarget_in -= delta
		if _retarget_in <= 0.0 or global_position.distance_to(_target) < 0.5 or is_on_wall():
			_pick_wander_target()

	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.3:
		var dir := to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), 6.0 * delta)
		var swing := sin(_time * (10.0 if chasing else 6.0)) * 0.6
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# bob the whole body while walking
	_visual.position.y = abs(sin(_time * 8.0)) * 0.08 if velocity.length() > 0.5 else 0.0

	move_and_slide()

	if player and _cooldown <= 0.0 and global_position.distance_to(player.global_position) < catch_distance:
		_catch(player)


func _catch(player: Node3D) -> void:
	_cooldown = 2.0
	Game.say(caught_text)
	if player.has_method("respawn"):
		player.respawn()
	_target = _home
	_retarget_in = 2.0


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
	_retarget_in = randf_range(2.0, 4.0)


# ---------------------------------------------------------------------------
# Building the monster
# ---------------------------------------------------------------------------
func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var leg_h := 0.5
	var body_h := height - head_size - leg_h

	var body := _capsule(0.45, body_h, color)
	body.position.y = leg_h + body_h / 2.0
	_visual.add_child(body)

	var head := _sphere(head_size / 2.0, color)
	head.position.y = leg_h + body_h + head_size / 2.0 - 0.15
	_visual.add_child(head)

	# two huge googly eyes
	for side in [-1.0, 1.0]:
		var eye := _sphere(head_size * 0.2, eye_color)
		eye.position = head.position + Vector3(side * head_size * 0.22, head_size * 0.1, head_size * 0.4)
		_visual.add_child(eye)
		var pupil := _sphere(head_size * 0.09, Color.BLACK)
		pupil.position = eye.position + Vector3(0, 0, head_size * 0.17)
		_visual.add_child(pupil)

	# big grin
	var mouth := _box(Vector3(head_size * 0.5, 0.08, 0.1), Color("3a1b2e"))
	mouth.position = head.position + Vector3(0, -head_size * 0.22, head_size * 0.47)
	_visual.add_child(mouth)

	# little arms
	for side in [-1.0, 1.0]:
		var arm := _capsule(0.12, body_h * 0.7, color.darkened(0.15))
		arm.position = Vector3(side * 0.55, leg_h + body_h * 0.6, 0)
		arm.rotation.z = side * 0.4
		_visual.add_child(arm)

	_left_leg = _make_leg(-0.25, leg_h)
	_right_leg = _make_leg(0.25, leg_h)
	_visual.add_child(_left_leg)
	_visual.add_child(_right_leg)


func _make_leg(x: float, leg_h: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, leg_h, 0)
	var leg := _box(Vector3(0.28, leg_h, 0.35), color.darkened(0.3))
	leg.position.y = -leg_h / 2.0
	pivot.add_child(leg)
	return pivot


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.6
	return mat


func _sphere(radius: float, c: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
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
