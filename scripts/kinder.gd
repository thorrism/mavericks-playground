extends Node3D
## KINDER ESCAPE - a spooky-but-silly kindergarten you have to escape from.
## The whole level is drawn with the text map below. Edit the map = edit the level!
##
##   #  wall              .  floor            P  where the robot starts
##   W  low wall (only the drone can fly over it)
##   =  fence (the robot can jump over it)
##   T  toy to collect    M  monster           X  exit door (opens when all toys are found)
##   1 2 3  doors         a b c  buttons       button a opens door 1, b opens 2, c opens 3
##
## Every letter is one tile (TILE metres wide). Rows must all be the same length.

const MAP: Array[String] = [
	"##########X#########",
	"#..................#",
	"#.T....M.........T.#",
	"#..................#",
	"#....T.............#",
	"##########3#########",
	"#......#...........#",
	"#..T...#...........#",
	"#......#.....===...#",
	"#.M....#.....=a=...#",
	"#......#.....===...#",
	"#WWWWW.#...........#",
	"#.c..W.1...........#",
	"#....W.#.....P.....#",
	"#WWWWW.#...........#",
	"#......#..T........#",
	"#..T...#...........#",
	"####################",
]

const TILE := 2.0
const WALL_HEIGHT := 2.5
const LOW_WALL_HEIGHT := 1.6
const FENCE_HEIGHT := 0.7

# Colours - change these to redecorate!
const FLOOR_COLOR := Color("f6e7c1")
const OUTSIDE_COLOR := Color("8fd15f")
const WALL_COLORS: Array[Color] = [Color("ff8fab"), Color("8ecae6"), Color("ffd166"), Color("b5e48c"), Color("cdb4db")]
const LOW_WALL_COLOR := Color("a8dadc")
const FENCE_COLOR := Color("ffb703")
const DOOR_COLORS: Array[Color] = [Color("ff5a5a"), Color("4f8dff"), Color("ffcc33"), Color("9b5de5"), Color("00c2a8")]
const EXIT_COLOR := Color("ffd700")
const MONSTER_COLORS: Array[Color] = [Color("6ad14f"), Color("ff6fb5"), Color("5aa9ff"), Color("ffa62b")]
const TOY_COLORS: Array[Color] = [Color("ff5a5a"), Color("4f8dff"), Color("ffcc33"), Color("9b5de5"), Color("00c2a8"), Color("ff8c42")]

const TOY_SCENE := preload("res://scenes/toy.tscn")
const DoorScript := preload("res://scripts/door.gd")
const ButtonScript := preload("res://scripts/button_pad.gd")
const MonsterScript := preload("res://scripts/monster.gd")
const DroneScript := preload("res://scripts/drone.gd")

@export var camera_offset := Vector3(0.0, 17.0, 8.0)
@export var camera_follow_speed := 6.0

@onready var robot: CharacterBody3D = $Robot
@onready var camera: Camera3D = $Camera3D

var drone: CharacterBody3D
var exit_door: StaticBody3D
var _doors := {}       # "1" -> door node
var _escaped := false
var _exit_z := 0.0
var _world: Node3D


func _ready() -> void:
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)
	_build_level()
	Game.reset_level(get_tree().get_nodes_in_group("battery").size())
	Game.all_collected.connect(_on_all_toys_found)

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
	_set_drone_active(false)

	camera.position = robot.position + camera_offset
	camera.look_at(robot.position)


func _process(delta: float) -> void:
	var focus: Node3D = drone if drone.active else robot
	var target := focus.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target, camera_follow_speed * delta)
	camera.look_at(focus.global_position + Vector3.UP * 0.5)

	if Input.is_action_just_pressed("drone") or TouchControls.drone_just_pressed():
		_set_drone_active(not drone.active)

	if not _escaped and robot.global_position.z < _exit_z - TILE * 0.5:
		_escaped = true
		Game.say("YOU ESCAPED!  Press R to play again")


func _set_drone_active(on: bool) -> void:
	if on and _escaped:
		return
	drone.active = on
	drone.visible = on
	drone.get_node("Shape").set_deferred("disabled", not on)
	robot.active = not on
	if on:
		drone.global_position = robot.global_position + Vector3(0, 1.2, 0)
		drone.velocity = Vector3.ZERO
		Game.say("Drone time!  Hold Space to fly up", 2.5)
	else:
		Game.say("Back to the robot", 1.5)


func _on_all_toys_found() -> void:
	if exit_door:
		exit_door.open()


# ---------------------------------------------------------------------------
# Turning the text map into a 3D level
# ---------------------------------------------------------------------------
func _build_level() -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	_exit_z = _tile_pos(0, 0).z

	# floor (a bit bigger than the map so there's an "outside" to escape to)
	var floor_size := Vector3((cols + 6) * TILE, 1.0, (rows + 8) * TILE)
	_add_box(_world, Vector3(0, -0.52, 0), floor_size, OUTSIDE_COLOR, true)
	_add_box(_world, Vector3(0, -0.5, 0), Vector3(cols * TILE, 1.0, rows * TILE), FLOOR_COLOR, false)

	var toy_index := 0
	var monster_index := 0
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
				Game.say("Click!  A door opened somewhere...", 2.5))


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
	mat.emission = color.darkened(0.5)
	block.material_override = mat


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
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
