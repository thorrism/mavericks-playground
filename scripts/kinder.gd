extends Node3D
## KINDER ESCAPE - a dark, abandoned kindergarten you have to escape from. First person.
## You have a flashlight. THEY have very good eyes.
## The whole level is drawn with the text map below. Edit the map = edit the level!
##
##   #  wall              .  floor            P  where you start
##   W  low wall (only the drone can fly over it)
##   =  fence (you can jump over it)
##   T  toy to collect    M  monster           X  exit door (opens when all toys are found)
##   L  a flickering ceiling lamp
##   1 2 3  doors         a b c  buttons       button a opens door 1, b opens 2, c opens 3
##
## Every letter is one tile (TILE metres wide). Rows must all be the same length.

const MAP: Array[String] = [
	"##########X#########",
	"#..................#",
	"#.T....M....L....T.#",
	"#..................#",
	"#....T.............#",
	"##########3#########",
	"#......#...........#",
	"#..T...#...........#",
	"#..L...#.....===...#",
	"#.M....#.....=a=...#",
	"#......#.....===...#",
	"#WWWWW.#...........#",
	"#.c..W.1...........#",
	"#....W.#.....P.....#",
	"#WWWWW.#.....L.....#",
	"#......#..T........#",
	"#..T...#...........#",
	"####################",
]

const TILE := 2.0
const WALL_HEIGHT := 3.0
const LOW_WALL_HEIGHT := 1.6
const FENCE_HEIGHT := 0.7

# Colours - grimy and faded. Change these to redecorate!
const FLOOR_COLOR := Color("4a4640")
const CEILING_COLOR := Color("2a2826")
const OUTSIDE_COLOR := Color("101a10")
const WALL_COLORS: Array[Color] = [Color("5a3f4a"), Color("3f5a5a"), Color("6b5a2f"), Color("4a5a3f"), Color("4a3f5a")]
const LOW_WALL_COLOR := Color("3a4a4c")
const FENCE_COLOR := Color("6b5a1f")
const DOOR_COLORS: Array[Color] = [Color("c0392b"), Color("2e6fd6"), Color("d4a017"), Color("7d3c98"), Color("00897b")]
const EXIT_COLOR := Color("ffd700")
const MONSTER_COLORS: Array[Color] = [Color("2f5d3a"), Color("6e2b4f"), Color("2b4a6e"), Color("6e4a2b")]
const TOY_COLORS: Array[Color] = [Color("ff5a5a"), Color("4f8dff"), Color("ffcc33"), Color("9b5de5"), Color("00c2a8"), Color("ff8c42")]
const LAMP_COLORS: Array[Color] = [Color("9fffb0"), Color("ffb090"), Color("b0c8ff")]

const TOY_SCENE := preload("res://scenes/toy.tscn")
const DoorScript := preload("res://scripts/door.gd")
const ButtonScript := preload("res://scripts/button_pad.gd")
const MonsterScript := preload("res://scripts/monster.gd")
const DroneScript := preload("res://scripts/drone.gd")
const LampScript := preload("res://scripts/lamp.gd")

# Spooky settings
@export_group("Scary")
@export var flashlight_range := 18.0      # how far your light reaches
@export var flashlight_energy := 10.0
@export var flashlight_angle := 38.0      # cone width in degrees
@export var fog_density := 0.045          # bigger = murkier
@export var mouse_sensitivity := 0.0025
@export var touch_sensitivity := 0.006
@export var eye_height := 1.5

@onready var robot: CharacterBody3D = $Robot
@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var fade: ColorRect = $HUD/Fade
@onready var env: WorldEnvironment = $WorldEnvironment

var drone: CharacterBody3D
var exit_door: StaticBody3D
var _doors := {}       # "1" -> door node
var _escaped := false
var _caught := false
var _exit_z := 0.0
var _world: Node3D
var _yaw := 0.0
var _pitch := 0.0
var _bob_time := 0.0


func _ready() -> void:
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)
	_build_level()
	Game.reset_level(get_tree().get_nodes_in_group("battery").size())
	Game.all_collected.connect(_on_all_toys_found)
	Game.caught.connect(_on_caught)

	drone = CharacterBody3D.new()
	drone.name = "Drone"
	drone.set_script(DroneScript)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	shape.shape = sphere
	shape.name = "Shape"
	drone.add_child(shape)
	add_child(drone)
	_set_drone_active(false, true)

	flashlight.spot_range = flashlight_range
	flashlight.light_energy = flashlight_energy
	flashlight.spot_angle = flashlight_angle
	env.environment.fog_density = fog_density

	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 2.0)

	_yaw = 0.0   # face "up" the map, towards the fence and the first door
	_update_camera(0.0)
	if not TouchControls.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * mouse_sensitivity)
	elif event.is_action_pressed("ui_cancel"):
		# Esc gives the mouse back; click the window to grab it again
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not TouchControls.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _look(delta: Vector2) -> void:
	_yaw -= delta.x
	_pitch = clamp(_pitch - delta.y, -1.2, 1.2)


func _process(delta: float) -> void:
	_look(TouchControls.look_delta() * touch_sensitivity)
	_update_camera(delta)

	if not _caught and not _escaped and (Input.is_action_just_pressed("drone") or TouchControls.drone_just_pressed()):
		_set_drone_active(not drone.active)

	if not _escaped and robot.global_position.z < _exit_z - TILE * 0.5:
		_escaped = true
		Game.say("YOU ESCAPED...  for now.   Press R to go back in")


func _update_camera(delta: float) -> void:
	var focus: Node3D = drone if drone.active else robot
	robot.move_yaw = _yaw
	drone.move_yaw = _yaw
	var height := 0.2 if drone.active else eye_height
	# a little head-bob while walking
	if not drone.active and Vector2(robot.velocity.x, robot.velocity.z).length() > 1.0 and robot.is_on_floor():
		_bob_time += delta * 10.0
		height += sin(_bob_time) * 0.05
	camera.global_position = focus.global_position + Vector3(0, height, 0)
	camera.rotation = Vector3(_pitch, _yaw, 0.0)


func _set_drone_active(on: bool, silent := false) -> void:
	drone.active = on
	drone.visible = on
	drone.get_node("Shape").set_deferred("disabled", not on)
	robot.active = not on
	robot.set_body_visible(on)   # you can look back and see yourself standing there
	if on:
		drone.global_position = robot.global_position + Vector3(0, 1.2, 0) + Vector3(0, 0, -0.8).rotated(Vector3.UP, _yaw)
		drone.velocity = Vector3.ZERO
	if silent:
		return
	Game.say("Drone.  Hold Space to fly up.  E to come back" if on else "Back in your body", 2.0)


func _on_all_toys_found() -> void:
	if exit_door:
		exit_door.open()


## A monster got you: freeze, stare at it, red flash, black, wake up at the start.
func _on_caught(monster: Node3D) -> void:
	if _caught or _escaped:
		return
	_caught = true
	if drone.active:
		_set_drone_active(false, true)
	robot.active = false
	var to_monster := monster.global_position - robot.global_position
	_yaw = atan2(-to_monster.x, -to_monster.z)
	_pitch = 0.35
	fade.color = Color(0.5, 0.0, 0.0, 1.0)
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.8, 0.12)
	tween.tween_property(fade, "modulate:a", 0.3, 0.25)
	tween.tween_property(fade, "color", Color.BLACK, 0.35)
	tween.parallel().tween_property(fade, "modulate:a", 1.0, 0.35)
	tween.tween_callback(func():
		robot.respawn()
		_yaw = 0.0
		_pitch = 0.0
		Game.say("It found you.  Try again...", 3.0))
	tween.tween_interval(0.6)
	tween.tween_property(fade, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func():
		robot.active = true
		_caught = false)


# ---------------------------------------------------------------------------
# Turning the text map into a 3D level
# ---------------------------------------------------------------------------
func _build_level() -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	_exit_z = _tile_pos(0, 0).z

	# floor (a bit bigger than the map so there's an "outside" to escape to) + ceiling
	var floor_size := Vector3((cols + 6) * TILE, 1.0, (rows + 8) * TILE)
	_add_box(_world, Vector3(0, -0.52, 0), floor_size, OUTSIDE_COLOR, true)
	# floor + ceiling are built one strip per map row (the mobile renderer only
	# lights a mesh with its 8 nearest lights, and there are many small lights here)
	for row in rows:
		var z := _tile_pos(row, 0).z
		_add_box(_world, Vector3(0, -0.5, z), Vector3(cols * TILE, 1.0, TILE), FLOOR_COLOR, false)
		_add_box(_world, Vector3(0, WALL_HEIGHT + 0.1, z), Vector3(cols * TILE, 0.2, TILE), CEILING_COLOR, false)

	var toy_index := 0
	var monster_index := 0
	var lamp_index := 0
	var buttons := {}   # "a" -> button node

	for row in rows:
		for col in cols:
			var ch := MAP[row][col]
			var pos := _tile_pos(row, col)
			match ch:
				"#":
					var color := WALL_COLORS[(floori(row / 3.0) + floori(col / 3.0)) % WALL_COLORS.size()]
					_add_box(_world, pos + Vector3(0, WALL_HEIGHT / 2.0, 0), Vector3(TILE, WALL_HEIGHT, TILE), color, true)
				"W":
					_add_box(_world, pos + Vector3(0, LOW_WALL_HEIGHT / 2.0, 0), Vector3(TILE, LOW_WALL_HEIGHT, TILE), LOW_WALL_COLOR, true)
				"=":
					_add_box(_world, pos + Vector3(0, FENCE_HEIGHT / 2.0, 0), Vector3(TILE, FENCE_HEIGHT, TILE), FENCE_COLOR, true)
				"P":
					robot.position = pos + Vector3(0, 0.1, 0)
					robot.set_spawn_here()
				"T":
					var toy := TOY_SCENE.instantiate()
					toy.name = "Toy%d" % (toy_index + 1)
					toy.position = pos + Vector3(0, 0.8, 0)
					_world.add_child(toy)
					_tint_toy(toy, TOY_COLORS[toy_index % TOY_COLORS.size()])
					toy_index += 1
				"M":
					var monster := CharacterBody3D.new()
					monster.name = "Monster%d" % (monster_index + 1)
					monster.set_script(MonsterScript)
					monster.color = MONSTER_COLORS[monster_index % MONSTER_COLORS.size()]
					var shape := CollisionShape3D.new()
					var capsule := CapsuleShape3D.new()
					capsule.radius = 0.5
					capsule.height = 2.0
					shape.shape = capsule
					shape.position.y = 1.0
					monster.add_child(shape)
					monster.position = pos + Vector3(0, 0.1, 0)
					_world.add_child(monster)
					monster_index += 1
				"L":
					var lamp := Node3D.new()
					lamp.name = "Lamp%d" % (lamp_index + 1)
					lamp.set_script(LampScript)
					lamp.color = LAMP_COLORS[lamp_index % LAMP_COLORS.size()]
					lamp.position = pos + Vector3(0, WALL_HEIGHT - 0.2, 0)
					_world.add_child(lamp)
					lamp_index += 1
				"X":
					exit_door = _make_door(pos, EXIT_COLOR, _door_faces_x(row, col, rows, cols))
					exit_door.name = "ExitDoor"
				_:
					if ch >= "1" and ch <= "9":
						var idx := int(ch) - 1
						var door := _make_door(pos, DOOR_COLORS[idx % DOOR_COLORS.size()], _door_faces_x(row, col, rows, cols))
						door.name = "Door%s" % ch
						_doors[ch] = door
					elif ch >= "a" and ch <= "i":
						var idx := ch.unicode_at(0) - "a".unicode_at(0)
						var button := Area3D.new()
						button.name = "Button%s" % ch
						button.set_script(ButtonScript)
						button.color = DOOR_COLORS[idx % DOOR_COLORS.size()]
						button.position = pos
						_world.add_child(button)
						buttons[ch] = button

	# wire buttons to their doors: a -> 1, b -> 2, c -> 3 ...
	for key: String in buttons:
		var door_key := str(key.unicode_at(0) - "a".unicode_at(0) + 1)
		if _doors.has(door_key):
			var door: StaticBody3D = _doors[door_key]
			buttons[key].pressed.connect(func():
				door.open()
				Game.say("*clunk*   A door opened somewhere...", 2.5))


func _make_door(pos: Vector3, color: Color, along_x: bool) -> StaticBody3D:
	var door := StaticBody3D.new()
	door.set_script(DoorScript)
	door.color = color
	door.size = Vector3(TILE, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, TILE)
	door.position = pos
	_world.add_child(door)
	return door


## A door sits in a wall: figure out if that wall runs left-right (true) or up-down.
func _door_faces_x(row: int, col: int, rows: int, cols: int) -> bool:
	var left := col > 0 and MAP[row][col - 1] == "#"
	var right := col < cols - 1 and MAP[row][col + 1] == "#"
	return left or right or row == 0 or row == rows - 1


func _tile_pos(row: int, col: int) -> Vector3:
	var cols := MAP[0].length()
	var rows := MAP.size()
	return Vector3((col - cols / 2.0 + 0.5) * TILE, 0.0, (row - rows / 2.0 + 0.5) * TILE)


func _tint_toy(toy: Node3D, color: Color) -> void:
	var block: MeshInstance3D = toy.get_node("Block")
	var mat: StandardMaterial3D = block.material_override.duplicate()
	mat.albedo_color = color
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	block.material_override = mat
	if toy.has_node("Glow"):
		toy.get_node("Glow").light_color = color


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	if not solid:
		mi.position = pos
		parent.add_child(mi)
		return mi
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(mi)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body
