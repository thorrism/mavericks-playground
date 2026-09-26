extends CharacterBody3D
## The player's robot. The whole robot is BUILT FROM CODE using the
## settings below, so changing a colour or shape is a one-line edit.

# ---------------------------------------------------------------------------
# ROBOT DESIGN - change these to build your own robot!
# ---------------------------------------------------------------------------
enum HeadShape { BOX, BALL, CAN }

@export_group("Robot Design")
@export var body_color := Color("4fa3ff")        # main body colour
@export var head_color := Color("dfe8ff")        # head colour
@export var eye_color := Color("ffe14d")         # glowing eyes
@export var limb_color := Color("2a2f3a")        # arms + legs / wheels
@export var head_shape := HeadShape.BOX
@export var body_size := Vector3(0.9, 1.0, 0.6)  # width, height, depth
@export var has_antenna := true
@export var has_wheels := false                  # false = legs, true = wheels
@export var robot_scale := 1.0

# ---------------------------------------------------------------------------
# MOVEMENT - how the robot moves
# ---------------------------------------------------------------------------
@export_group("Movement")
@export var speed := 7.0
@export var jump_power := 9.0
@export var gravity := 22.0
@export var turn_speed := 12.0

## False while you are flying the drone: the robot stands still and waits.
var active := true
## Which way is "forward" (radians). 0 = the map's up. First-person levels set this from the camera.
var move_yaw := 0.0

var _visual: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _time := 0.0
var _spawn_position: Vector3


func _ready() -> void:
	_spawn_position = global_position
	_build_robot()


func _physics_process(delta: float) -> void:
	_time += delta

	# --- gravity ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- jump ---
	if active and is_on_floor() and (Input.is_action_just_pressed("jump") or TouchControls.jump_just_pressed()):
		velocity.y = jump_power

	# --- walk (keyboard / gamepad / touch joystick) ---
	var input := Vector2.ZERO
	if active:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input.length() < 0.1:
			input = TouchControls.direction()
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, move_yaw)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# --- face the way we're going, swing the arms ---
	if direction.length() > 0.1:
		var target_yaw := atan2(direction.x, direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, turn_speed * delta)
		var swing := sin(_time * 12.0) * 0.8
		_left_arm.rotation.x = swing
		_right_arm.rotation.x = -swing
	else:
		_left_arm.rotation.x = lerp(_left_arm.rotation.x, 0.0, 10.0 * delta)
		_right_arm.rotation.x = lerp(_right_arm.rotation.x, 0.0, 10.0 * delta)

	move_and_slide()

	# --- fell off the world? go back to the start ---
	if global_position.y < -10.0:
		respawn()


func respawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO


## Make wherever the robot is right now the place it goes back to.
func set_spawn_here() -> void:
	_spawn_position = global_position


## Hide the body (first-person view) or show it again.
func set_body_visible(shown: bool) -> void:
	_visual.visible = shown


# ---------------------------------------------------------------------------
# Building the robot out of simple shapes
# ---------------------------------------------------------------------------
func _build_robot() -> void:
	if _visual:
		_visual.queue_free()
	_visual = Node3D.new()
	_visual.name = "Visual"
	_visual.scale = Vector3.ONE * robot_scale
	add_child(_visual)

	var leg_height := 0.35
	var body_bottom := leg_height

	# body
	var body := _box(body_size, body_color)
	body.position.y = body_bottom + body_size.y / 2.0
	_visual.add_child(body)

	# head
	var head_size := body_size.x * 0.65
	var head: MeshInstance3D
	match head_shape:
		HeadShape.BALL:
			head = _sphere(head_size / 2.0, head_color)
		HeadShape.CAN:
			head = _cylinder(head_size / 2.0, head_size, head_color)
		_:
			head = _box(Vector3.ONE * head_size, head_color)
	head.position.y = body_bottom + body_size.y + head_size / 2.0 + 0.05
	_visual.add_child(head)

	# eyes (glow!)
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.08, eye_color, true)
		eye.position = head.position + Vector3(side * head_size * 0.25, head_size * 0.1, head_size / 2.0)
		_visual.add_child(eye)

	# antenna
	if has_antenna:
		var stick := _cylinder(0.03, 0.35, limb_color)
		stick.position = head.position + Vector3(0, head_size / 2.0 + 0.17, 0)
		_visual.add_child(stick)
		var ball := _sphere(0.08, Color.RED, true)
		ball.position = stick.position + Vector3(0, 0.2, 0)
		_visual.add_child(ball)

	# arms (pivot at the shoulder so they can swing)
	_left_arm = _make_arm(-1.0, body_bottom)
	_right_arm = _make_arm(1.0, body_bottom)
	_visual.add_child(_left_arm)
	_visual.add_child(_right_arm)

	# legs or wheels
	if has_wheels:
		for side in [-1.0, 1.0]:
			var wheel := _cylinder(0.25, 0.15, limb_color)
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(side * (body_size.x / 2.0 + 0.08), 0.25, 0)
			_visual.add_child(wheel)
	else:
		for side in [-0.5, 0.5]:
			var leg := _box(Vector3(0.22, leg_height, 0.25), limb_color)
			leg.position = Vector3(side * body_size.x * 0.5, leg_height / 2.0, 0)
			_visual.add_child(leg)


func _make_arm(side: float, body_bottom: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * (body_size.x / 2.0 + 0.12), body_bottom + body_size.y * 0.9, 0)
	var arm := _box(Vector3(0.18, body_size.y * 0.8, 0.18), limb_color)
	arm.position.y = -body_size.y * 0.4
	pivot.add_child(arm)
	var hand := _sphere(0.12, head_color)
	hand.position.y = -body_size.y * 0.8
	pivot.add_child(hand)
	return pivot


# --- tiny helpers that make coloured shapes ---
func _material(color: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mat.metallic = 0.3
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color)
	return mi


func _sphere(radius: float, color: Color, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color, glow)
	return mi


func _cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color)
	return mi
