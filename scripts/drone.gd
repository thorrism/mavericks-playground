extends CharacterBody3D
## A little flying drone. Press E (or the DRONE button) to fly it.
## It can go over low walls and land on buttons the robot can't reach.

@export var color := Color("ff7a3d")
@export var speed := 6.0
@export var rise_speed := 3.0       # how fast it goes up when you hold Space
@export var sink_speed := 1.5       # how fast it drifts down when you don't
@export var min_height := 0.6
@export var max_height := 2.1       # lower than the walls, so it can't leave a room

var active := false
## Which way is "forward" (radians). First-person levels set this from the camera.
var move_yaw := 0.0

var _rotors: Array[Node3D] = []
var _visual: Node3D


func _ready() -> void:
	add_to_group("drone")
	_build()


func _physics_process(delta: float) -> void:
	for rotor in _rotors:
		rotor.rotate_y(25.0 * delta)
	if not active:
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.length() < 0.1:
		input = TouchControls.direction()
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, move_yaw)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if Input.is_action_pressed("jump") or TouchControls.jump_held():
		velocity.y = rise_speed
	else:
		velocity.y = -sink_speed
	if global_position.y <= min_height and velocity.y < 0.0:
		velocity.y = 0.0
	if global_position.y >= max_height and velocity.y > 0.0:
		velocity.y = 0.0

	# face the camera, tilt a little in the direction we fly
	_visual.rotation.y = move_yaw
	_visual.rotation.x = lerp(_visual.rotation.x, input.y * 0.35, 8.0 * delta)
	_visual.rotation.z = lerp(_visual.rotation.z, -input.x * 0.35, 8.0 * delta)

	move_and_slide()
	global_position.y = clamp(global_position.y, min_height, max_height)


func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 0.3
	body.mesh = body_mesh
	body.material_override = _mat(color)
	_visual.add_child(body)

	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.08
	eye_mesh.height = 0.16
	eye.mesh = eye_mesh
	eye.material_override = _mat(Color("7ff7ff"), true)
	eye.position = Vector3(0, 0, -0.22)
	_visual.add_child(eye)

	# a small lamp so the drone lights up the floor under it in the dark
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("7ff7ff")
	lamp.light_energy = 1.2
	lamp.omni_range = 5.0
	lamp.position.y = -0.2
	_visual.add_child(lamp)

	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var arm := MeshInstance3D.new()
			var arm_mesh := BoxMesh.new()
			arm_mesh.size = Vector3(0.35, 0.05, 0.05)
			arm.mesh = arm_mesh
			arm.material_override = _mat(Color("2a2f3a"))
			arm.position = Vector3(x * 0.3, 0.05, z * 0.3)
			arm.rotation.y = atan2(z, x)
			_visual.add_child(arm)

			var rotor := MeshInstance3D.new()
			var rotor_mesh := BoxMesh.new()
			rotor_mesh.size = Vector3(0.45, 0.02, 0.08)
			rotor.mesh = rotor_mesh
			rotor.material_override = _mat(Color("dfe8ff"))
			rotor.position = Vector3(x * 0.42, 0.1, z * 0.42)
			_visual.add_child(rotor)
			_rotors.append(rotor)


func _mat(c: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.4
	mat.metallic = 0.3
	if glow:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 2.0
	return mat
