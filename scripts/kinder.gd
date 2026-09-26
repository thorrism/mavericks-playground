extends Node3D
## THE ABYSS - a dark, abandoned kindergarten you have to escape from. First person.
## You have a flashlight. THEY have very good eyes - and they know the way around.
## The whole level is drawn with the text map below. Edit the map = edit the level!
##
##   #  wall              .  floor            P  where you start
##   W  low wall (only the drone can fly over it)
##   =  fence (you can jump over it - THEY just step over it)
##   T  toy to collect                         X  exit door (opens when all toys are found)
##   M  the tall one (Banban-ish)   J  the giant (Jumbo Josh-ish)   O  the bird (Opila-ish, not used right now)
##   L  a flickering ceiling lamp
##   H  a cupboard you can hide in (put it against a wall). Inside, THEY can't see you -
##      unless one was already right behind you when you climbed in.
##   t  a little kids' table with chairs (solid: THEY have to walk around it - but they see over it)
##   1 2 3  doors         a b c  buttons       button a opens door 1, b opens 2, c opens 3
##
## Every letter is one tile (TILE metres wide). Rows must all be the same length.

const MAP: Array[String] = [
	"##########X#########",
	"#H.................#",
	"#.T....t.....L...T.#",
	"#......J..........H#",
	"#....T.............#",
	"##########3#########",
	"#......#...........#",
	"#..T..H#...........#",
	"#..L...#.....===...#",
	"#.M....#.....=a=...#",
	"#..t...#.....===...#",
	"#WWWWW.#...........#",
	"#.c..W.1..........H#",
	"#....W.#.....P.....#",
	"#WWWWW.#.....L.....#",
	"#......#..T...t....#",
	"#..T...#...........#",
	"####################",
]

const MONSTER_LETTERS := "MJO"

const TILE := 2.0
const WALL_HEIGHT := 3.0
const LOW_WALL_HEIGHT := 1.6
const FENCE_HEIGHT := 0.7

# Colours - faded kindergarten paint under years of grime. Change these to redecorate!
const FLOOR_COLOR := Color("4a4640")
const CEILING_COLOR := Color("2a2826")
const OUTSIDE_COLOR := Color("101a10")
const WALL_COLORS: Array[Color] = [Color("7a4f62"), Color("4b7a78"), Color("8c7a3c"), Color("5f7d4b"), Color("5c4d80"), Color("8a5a3a")]
const STRIPE_COLORS: Array[Color] = [Color("d9a6bd"), Color("9bd6d0"), Color("e8d27a"), Color("b3d69b"), Color("b3a0e0"), Color("e0a880")]
const SKIRTING_COLOR := Color("1c1a18")
const POSTER_COLORS: Array[Color] = [Color("d94a4a"), Color("4a7bd9"), Color("e0c040"), Color("58b060"), Color("d97ad0"), Color("e08a40")]
const BLOOD_COLOR := Color("4a0808")
const WALL_WORDS: Array[String] = ["RUN", "don't let them see you", "HELP", "they can hear you", "it's behind you", "NO WAY OUT", "hide", "6 toys"]
const LOW_WALL_COLOR := Color("3a4a4c")
const FENCE_COLOR := Color("6b5a1f")
const DOOR_COLORS: Array[Color] = [Color("c0392b"), Color("2e6fd6"), Color("d4a017"), Color("7d3c98"), Color("00897b")]
const EXIT_COLOR := Color("ffd700")
const TOY_COLORS: Array[Color] = [Color("ff5a5a"), Color("4f8dff"), Color("ffcc33"), Color("9b5de5"), Color("00c2a8"), Color("ff8c42")]
const LAMP_COLORS: Array[Color] = [Color("9fffb0"), Color("ffb090"), Color("b0c8ff")]
const CUPBOARD_COLOR := Color("5a4630")
const TABLE_COLOR := Color("7a6a4a")
const CHAIR_COLORS: Array[Color] = [Color("a04040"), Color("3a60a0"), Color("a09030"), Color("40803a")]
const BLOCK_COLORS: Array[Color] = [Color("b03a3a"), Color("3a5ab0"), Color("c0a030"), Color("3a9a50"), Color("8a3aa0")]
const PAPER_COLOR := Color("b0a890")

const TOY_SCENE := preload("res://scenes/toy.tscn")
const DoorScript := preload("res://scripts/door.gd")
const ButtonScript := preload("res://scripts/button_pad.gd")
const MonsterScript := preload("res://scripts/monster.gd")
const DroneScript := preload("res://scripts/drone.gd")
const LampScript := preload("res://scripts/lamp.gd")

## Fences live on this physics layer: the player and drone bump into them, monsters walk through.
const FENCE_LAYER := 2

# Spooky settings
@export_group("Scary")
@export var flashlight_range := 18.0      # how far your light reaches
@export var flashlight_energy := 10.0
@export var flashlight_angle := 38.0      # cone width in degrees
@export var fog_density := 0.045          # bigger = murkier
@export var mouse_sensitivity := 0.0025
@export var touch_sensitivity := 0.006
@export var eye_height := 1.5
## NAME becomes the monster's name ("BANBO SEES YOU").
@export var scare_words: Array[String] = ["RUN", "NAME SEES YOU", "NAME SEES YOU", "DON'T LOOK BACK", "RUN RUN RUN", "NAME IS COMING"]

@onready var robot: CharacterBody3D = $Robot
@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var fade: ColorRect = $HUD/Fade
@onready var vignette: ColorRect = $HUD/Vignette
@onready var blood_text: Control = $HUD/BloodText
@onready var hud: CanvasLayer = $HUD
@onready var menu: CanvasLayer = $Menu
@onready var env: WorldEnvironment = $WorldEnvironment

var drone: CharacterBody3D
var exit_door: StaticBody3D
var _doors := {}       # "1" -> door node
var _escaped := false
var _caught := false
var _playing := false   # false while the title screen is up
var _exit_z := 0.0
var _world: Node3D
var _grid: AStarGrid2D
var _yaw := 0.0
var _pitch := 0.0
var _bob_time := 0.0
var _shake := 0.0
var _flicker := 0.0
var _scare_flash := 0.0
var _time := 0.0
var _toy_count := 0
var _rooms: Dictionary = {}   # Vector2i cell -> room number
var _cupboards: Dictionary = {}   # Vector2i cell -> Vector3 direction the open front faces
var hiding := false   # true while you're tucked inside a cupboard
var flashlight_on := true
var _cupboard_doors: Dictionary = {}   # Vector2i cell -> Array of door hinges (Node3D)
var _door_swing: Dictionary = {}       # Vector2i cell -> 0.0 (hanging open) .. 1.0 (shut)
var _flung: Dictionary = {}            # Vector2i cell -> seconds the doors stay yanked open
const DOOR_OPEN_ANGLES: Array[float] = [1.1, 2.2]   # left / right door, hanging open
const DOOR_SHUT_GAP := 0.05                        # a crack of light between the shut doors


func _ready() -> void:
	Game.hiding = false
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)
	_build_grid()
	_build_level()
	Game.reset_level(_toy_count)
	Game.all_collected.connect(_on_all_toys_found)
	Game.caught.connect(_on_caught)
	Game.spotted.connect(_on_spotted)
	Game.found.connect(_on_found)
	Game.missed.connect(_on_missed)

	robot.collision_mask |= 1 << (FENCE_LAYER - 1)
	drone = CharacterBody3D.new()
	drone.name = "Drone"
	drone.set_script(DroneScript)
	drone.collision_mask |= 1 << (FENCE_LAYER - 1)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	shape.shape = sphere
	shape.name = "Shape"
	drone.add_child(shape)
	add_child(drone)
	drone.set_body_visible(false)   # the camera rides inside it; rotors in your face are no fun
	_set_drone_active(false, true)

	flashlight.spot_range = flashlight_range
	flashlight.light_energy = flashlight_energy
	flashlight.spot_angle = flashlight_angle
	env.environment.fog_density = fog_density

	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 2.0)

	_yaw = 0.0   # face "up" the map, towards the fence and the first door
	_update_camera(0.0)

	menu.opened.connect(func() -> void: hud.visible = false)
	menu.play.connect(_on_menu_play)
	menu.restart.connect(_restart)
	if Game.title_pending:
		# first boot / just escaped: the title screen, with the level frozen behind it
		Game.title_pending = false
		menu.show_title.call_deferred(Game.last_result)
		Game.last_result = ""
	else:
		menu.hide_menu()
		_begin_run()


## PLAY on the title screen, or RESUME from the pause menu.
func _on_menu_play() -> void:
	hud.visible = true
	if not _playing:
		_begin_run()
	elif not TouchControls.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _begin_run() -> void:
	_playing = true
	Settings.record_attempt()
	hud.start_clock()
	if not TouchControls.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * mouse_sensitivity)
	elif event.is_action_pressed("ui_cancel"):
		if _playing and not _caught and not _escaped:
			menu.show_pause()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not TouchControls.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _look(delta: Vector2) -> void:
	_yaw -= delta.x
	_pitch = clamp(_pitch - delta.y, -1.2, 1.2)


func _process(delta: float) -> void:
	_time += delta
	_look(TouchControls.look_delta() * touch_sensitivity)
	_update_camera(delta)
	_update_fear(delta)

	if not _caught and not _escaped and (Input.is_action_just_pressed("drone") or TouchControls.drone_just_pressed()):
		_set_drone_active(not drone.active)
	if not _caught and not _escaped and Input.is_action_just_pressed("flashlight"):
		flashlight_on = not flashlight_on
		if not flashlight_on:
			Game.say("Lights off.  They can still hear you.", 1.5)

	if not _escaped and not _caught and robot.global_position.z < _exit_z - TILE * 0.5:
		_on_escaped()

	var hidden_now: bool = not drone.active and is_hidden(robot.global_position)
	if hidden_now != hiding:
		hiding = hidden_now
		Game.hiding = hiding
		if hiding and not _caught and not _escaped:
			Game.say("You're hiding.  They can't see you in here... stay still.", 2.5)
			_creak(_cell_of(robot.global_position), 0.0, 1.0)
	_swing_cupboard_doors(delta)


## The doors creak shut behind you when you climb in and swing open again as you step out -
## or get yanked wide when one of THEM comes to look.
func _swing_cupboard_doors(delta: float) -> void:
	var inside := cupboard_at(robot.global_position) if not drone.active else Vector2i(-1, -1)
	for cell: Vector2i in _cupboard_doors:
		var flung: float = _flung.get(cell, 0.0)
		if flung > 0.0:
			_flung[cell] = flung - delta
		var want := 1.0 if (cell == inside and flung <= 0.0) else 0.0
		var swing: float = _door_swing.get(cell, 0.0)
		var rate := 6.0 if flung > 0.0 else (1.4 if want > swing else 2.2)
		swing = move_toward(swing, want, delta * rate)
		_door_swing[cell] = swing
		var hinges: Array = _cupboard_doors[cell]
		for i in hinges.size():
			var hinge: Node3D = hinges[i]
			var side := -1.0 if i == 0 else 1.0
			hinge.rotation.y = side * lerpf(DOOR_OPEN_ANGLES[i], DOOR_SHUT_GAP, swing)


## A monster throws the cupboard doors open (they stay open a while).
func fling_cupboard(cell: Vector2i) -> void:
	if not _cupboard_doors.has(cell):
		return
	if _door_swing.get(cell, 0.0) > 0.2:
		_creak(cell, 6.0, 1.6)
	_flung[cell] = 6.0


func _creak(cell: Vector2i, db: float, pitch: float) -> void:
	if not _cupboard_doors.has(cell):
		return
	var hinge: Node3D = _cupboard_doors[cell][0]
	var sound := AudioStreamPlayer3D.new()
	sound.stream = Sfx.get_sound("creak")
	sound.unit_size = 6.0
	sound.max_distance = 40.0
	sound.volume_db = db
	sound.pitch_scale = pitch
	sound.autoplay = true
	sound.finished.connect(sound.queue_free)
	hinge.get_parent().add_child(sound)
	sound.position = Vector3(0, 1.2, 0.1)


func _update_camera(delta: float) -> void:
	var focus: Node3D = drone if drone.active else robot
	robot.move_yaw = _yaw
	drone.move_yaw = _yaw
	var height := 0.35 if drone.active else eye_height
	# a little head-bob while walking
	if not drone.active and Vector2(robot.velocity.x, robot.velocity.z).length() > 1.0 and robot.is_on_floor():
		_bob_time += delta * 10.0
		height += sin(_bob_time) * 0.05
	var shake := Vector3.ZERO
	if _shake > 0.001:
		shake = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake * 0.08
	camera.global_position = focus.global_position + Vector3(0, height, 0) + shake
	camera.rotation = Vector3(_pitch + shake.y * 0.5, _yaw + shake.x * 0.5, shake.x * 0.6)


## Red edges that pulse while hunted, camera shake, a flashlight that stutters when you're scared.
func _update_fear(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, delta * 1.2)
	_scare_flash = move_toward(_scare_flash, 0.0, delta * 0.8)
	_flicker = move_toward(_flicker, 0.0, delta)

	var nearest := INF
	for m in get_tree().get_nodes_in_group("monster"):
		if m.chasing:
			nearest = minf(nearest, m.global_position.distance_to(robot.global_position))
	var hunted := nearest < INF
	var vignette_target := 0.0
	if hunted:
		var closeness: float = clampf(1.0 - nearest / 14.0, 0.0, 1.0)
		vignette_target = 0.35 + closeness * 0.4 + sin(_time * 7.0) * 0.08
		_shake = maxf(_shake, closeness * closeness * 0.25)
	var mat := vignette.material as ShaderMaterial
	var current: float = mat.get_shader_parameter("strength")
	mat.set_shader_parameter("strength", clampf(move_toward(current, vignette_target, delta * 1.5) + _scare_flash * 0.6, 0.0, 1.0))

	var energy := flashlight_energy if flashlight_on else 0.0
	if _flicker > 0.0 and flashlight_on:
		energy = flashlight_energy * (0.15 if randf() < 0.35 else 1.0)
	if flashlight.light_energy != energy:
		flashlight.light_energy = energy


func _set_drone_active(on: bool, silent := false) -> void:
	drone.active = on
	drone.visible = on
	drone.get_node("Shape").set_deferred("disabled", not on)
	robot.active = not on
	robot.set_body_visible(on)   # you can look back and see yourself standing there
	if on:
		# launch from your hand; if that spot is inside a wall, straight up instead
		var ahead := robot.global_position + Vector3(0, 1.2, 0) + Vector3(0, 0, -0.8).rotated(Vector3.UP, _yaw)
		drone.global_position = ahead
		if drone.test_move(drone.global_transform, Vector3.ZERO):
			drone.global_position = robot.global_position + Vector3(0, 1.4, 0)
		drone.velocity = Vector3.ZERO
	if silent:
		return
	Game.say("Drone.  Hold Space to fly up.  E to come back" if on else "Back in your body", 2.0)


func _on_all_toys_found() -> void:
	if exit_door:
		exit_door.open()
		# a golden glow so you can find the way out from across the room
		var beacon := OmniLight3D.new()
		beacon.name = "ExitBeacon"
		beacon.light_color = EXIT_COLOR
		beacon.light_energy = 3.0
		beacon.omni_range = 9.0
		beacon.position.y = 2.2
		exit_door.add_child(beacon)
	Game.say("ALL TOYS FOUND.  The GOLDEN DOOR at the top of the school is open.  RUN!", 6.0)


## You made it out: freeze, fade to white-gold, and start a fresh level.
func _on_escaped() -> void:
	_escaped = true
	if drone.active:
		_set_drone_active(false, true)
	robot.active = false
	robot.velocity = Vector3.ZERO
	hud.stop_clock()
	var record := Settings.record_escape(hud.elapsed)
	Game.last_result = "YOU ESCAPED in %s%s" % [Settings.fmt_time(hud.elapsed), "   -   NEW RECORD!" if record else ""]
	Game.title_pending = true
	Game.say("YOU ESCAPED!", 4.0)
	blood_text.scare("YOU ESCAPED", 3.5)
	fade.color = Color(1.0, 0.9, 0.6, 1.0)
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(fade, "modulate:a", 1.0, 1.5)
	tween.tween_interval(0.8)
	tween.tween_callback(_restart)


## Something SAW you: bloody letters, red flash, shake, flashlight stutters.
func _on_spotted(monster: Node3D) -> void:
	if _caught or _escaped:
		return
	_shake = maxf(_shake, 0.5)
	_scare_flash = 0.85
	_flicker = 0.6
	var words: String = scare_words[randi() % scare_words.size()]
	blood_text.scare(words.replace("NAME", _name_of(monster)), 2.4)


## It opened the cupboard doors and there you were.
func _on_found(monster: Node3D) -> void:
	if _caught or _escaped:
		return
	_shake = maxf(_shake, 0.7)
	_scare_flash = 1.0
	_flicker = 0.8
	blood_text.scare("%s FOUND YOU" % _name_of(monster), 2.4)
	Game.say("GET OUT.  RUN.", 1.5)


## It swung and hit the floor next to you: a jolt, and its name in blood.
func _on_missed(monster: Node3D) -> void:
	if _caught or _escaped:
		return
	_shake = maxf(_shake, 0.8)
	_scare_flash = maxf(_scare_flash, 0.6)
	blood_text.scare("%s MISSED YOU" % _name_of(monster), 1.6)
	Game.say("%s missed!  Keep moving!" % _name_of(monster).capitalize(), 1.5)


func _name_of(monster: Node3D) -> String:
	if "kind_name" in monster:
		return String(monster.kind_name).to_upper()
	return "IT"


## A monster got you: freeze, stare at it, red flash, black... and the whole level starts over.
func _on_caught(monster: Node3D) -> void:
	if _caught or _escaped:
		return
	_caught = true
	if drone.active:
		_set_drone_active(false, true)
	robot.active = false
	hud.stop_clock()
	_shake = 1.0
	var to_monster := monster.global_position - robot.global_position
	_yaw = atan2(-to_monster.x, -to_monster.z)
	_pitch = 0.35
	blood_text.scare("%s GOT YOU" % _name_of(monster), 2.2)
	fade.color = Color(0.5, 0.0, 0.0, 1.0)
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.8, 0.12)
	tween.tween_property(fade, "modulate:a", 0.3, 0.25)
	tween.tween_property(fade, "color", Color.BLACK, 0.5)
	tween.parallel().tween_property(fade, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.2)
	tween.tween_callback(_restart)


func _restart() -> void:
	var tree := get_tree()
	if tree.current_scene == self:
		tree.reload_current_scene()
	else:
		# not the running scene (e.g. inside a test): rebuild in place instead
		var fresh: Node = load(scene_file_path).instantiate()
		get_parent().add_child(fresh)
		queue_free()


# ---------------------------------------------------------------------------
# Finding the way: a grid the monsters use to walk around walls
# ---------------------------------------------------------------------------
func _build_grid() -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	_build_rooms()
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(0, 0, cols, rows)
	_grid.cell_size = Vector2(TILE, TILE)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	for row in rows:
		for col in cols:
			var ch := MAP[row][col]
			if ch == "#" or ch == "W" or ch == "X" or ch == "H" or ch == "t" or (ch >= "1" and ch <= "9"):
				_grid.set_point_solid(Vector2i(col, row), true)


## Waypoints (world positions, tile centres) from one place to another. Empty if unreachable.
## A target inside something solid (you, in a cupboard) becomes the nearest open tile beside it.
func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var a := _cell_of(from)
	var b := _cell_of(to)
	var out := PackedVector3Array()
	if _grid.is_point_solid(a):
		return out
	if _grid.is_point_solid(b):
		var best := b
		var best_dist := INF
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = b + step
			if not _grid.region.has_point(n) or _grid.is_point_solid(n):
				continue
			var d := Vector2(n - a).length()
			if d < best_dist:
				best_dist = d
				best = n
		if best == b:
			return out
		b = best
	for cell in _grid.get_id_path(a, b):
		out.append(_tile_pos(cell.y, cell.x))
	return out


func is_walkable(pos: Vector3) -> bool:
	return not _grid.is_point_solid(_cell_of(pos))


## Rooms: every floor tile gets a room number; walls, low walls and doorways split rooms.
## Monsters never leave the room they were born in, so a doorway is always an escape.
func _build_rooms() -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	var next_room := 0
	for row in rows:
		for col in cols:
			var cell := Vector2i(col, row)
			if _rooms.has(cell) or not _is_room_floor(MAP[row][col]):
				continue
			var stack: Array[Vector2i] = [cell]
			_rooms[cell] = next_room
			while not stack.is_empty():
				var here: Vector2i = stack.pop_back()
				for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = here + step
					if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
						continue
					if _rooms.has(n) or not _is_room_floor(MAP[n.y][n.x]):
						continue
					_rooms[n] = next_room
					stack.append(n)
			next_room += 1


func _is_room_floor(ch: String) -> bool:
	return not (ch == "#" or ch == "W" or ch == "X" or (ch >= "1" and ch <= "9"))


## Room number at a world position; -1 in a doorway, a wall, or outside.
func room_at(pos: Vector3) -> int:
	return _rooms.get(_cell_of(pos), -1)


## Is this spot inside a cupboard (between its sides, behind its open front)?
func is_hidden(pos: Vector3) -> bool:
	var cell := _cell_of(pos)
	if not _cupboards.has(cell):
		return false
	var open: Vector3 = _cupboards[cell]
	var local := pos - _tile_pos(cell.y, cell.x)
	local.y = 0.0
	var depth := local.dot(open)          # +: towards the open front
	var side := (local - open * depth).length()
	return depth < 0.25 and side < 0.75


## The cupboard closest to pos, or an empty Dictionary if none is within max_dist:
##   { "cell": Vector2i, "front": Vector3 (the floor just outside its doors), "inside": Vector3 }
func nearest_cupboard(pos: Vector3, max_dist: float, front_ok: Callable = Callable()) -> Dictionary:
	var best := {}
	var best_dist := max_dist
	for cell: Vector2i in _cupboards:
		var inside := _tile_pos(cell.y, cell.x)
		var d := Vector2(inside.x - pos.x, inside.z - pos.z).length()
		if d > best_dist:
			continue
		var open: Vector3 = _cupboards[cell]
		var front := inside + open * TILE
		if front_ok.is_valid() and not front_ok.call(front):
			continue
		best_dist = d
		best = {"cell": cell, "front": front, "inside": inside}
	return best


## Which cupboard pos is hiding in; Vector2i(-1, -1) if it isn't hiding.
func cupboard_at(pos: Vector3) -> Vector2i:
	return _cell_of(pos) if is_hidden(pos) else Vector2i(-1, -1)


func _cell_of(pos: Vector3) -> Vector2i:
	var cols := MAP[0].length()
	var rows := MAP.size()
	var col := clampi(floori(pos.x / TILE + cols / 2.0), 0, cols - 1)
	var row := clampi(floori(pos.z / TILE + rows / 2.0), 0, rows - 1)
	return Vector2i(col, row)


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
	# invisible fence round the edge of the world so nobody can fall off it
	for side in [-1.0, 1.0]:
		var x_wall := _add_box(_world, Vector3(side * (floor_size.x / 2.0 + 0.5), 2.5, 0), Vector3(1.0, 6.0, floor_size.z + 2.0), OUTSIDE_COLOR, true)
		x_wall.visible = false
		var z_wall := _add_box(_world, Vector3(0, 2.5, side * (floor_size.z / 2.0 + 0.5)), Vector3(floor_size.x + 2.0, 6.0, 1.0), OUTSIDE_COLOR, true)
		z_wall.visible = false
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
					var region := _region_of(row, col)
					var color := WALL_COLORS[region % WALL_COLORS.size()]
					_add_box(_world, pos + Vector3(0, WALL_HEIGHT / 2.0, 0), Vector3(TILE, WALL_HEIGHT, TILE), color, true)
					_decorate_wall(row, col, pos, region)
				"W":
					_add_box(_world, pos + Vector3(0, LOW_WALL_HEIGHT / 2.0, 0), Vector3(TILE, LOW_WALL_HEIGHT, TILE), LOW_WALL_COLOR, true)
				"=":
					var fence := _add_box(_world, pos + Vector3(0, FENCE_HEIGHT / 2.0, 0), Vector3(TILE, FENCE_HEIGHT, TILE), FENCE_COLOR, true)
					fence.collision_layer = 1 << (FENCE_LAYER - 1)
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
					_toy_count = toy_index
				"L":
					var lamp := Node3D.new()
					lamp.name = "Lamp%d" % (lamp_index + 1)
					lamp.set_script(LampScript)
					lamp.color = LAMP_COLORS[lamp_index % LAMP_COLORS.size()]
					lamp.position = pos + Vector3(0, WALL_HEIGHT - 0.2, 0)
					_world.add_child(lamp)
					lamp_index += 1
				"X":
					exit_door = _make_door(pos, EXIT_COLOR, _door_faces_x(row, col, rows, cols), Vector2i(col, row))
					exit_door.name = "ExitDoor"
				"H":
					_add_cupboard(row, col, pos)
				"t":
					_add_table(pos, row * 31 + col * 17)
				".":
					_add_clutter(row, col, pos)
				_:
					if ch in MONSTER_LETTERS:
						var monster := CharacterBody3D.new()
						monster.name = "Monster%d" % (monster_index + 1)
						monster.set_script(MonsterScript)
						monster.kind = MONSTER_LETTERS.find(ch)
						monster.position = pos + Vector3(0, 0.1, 0)
						_world.add_child(monster)
						monster_index += 1
					elif ch >= "1" and ch <= "9":
						var idx := int(ch) - 1
						var door := _make_door(pos, DOOR_COLORS[idx % DOOR_COLORS.size()], _door_faces_x(row, col, rows, cols), Vector2i(col, row))
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


## Which "room" a wall belongs to (for colours): rooms are split by the map's inner walls.
func _region_of(row: int, col: int) -> int:
	if row <= 5:
		return 0
	if col <= 7:
		return 1 if row <= 11 else 2
	return 3 if row <= 10 else 4


## Skirting board, a painted stripe, and now and then a peeling poster, a bloody
## handprint or something scrawled in crayon - on every wall face that looks into a room.
func _decorate_wall(row: int, col: int, pos: Vector3, region: int) -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	var faces: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]   # (drow, dcol)
	for face in faces:
		var r := row + face.x
		var c := col + face.y
		if r < 0 or r >= rows or c < 0 or c >= cols:
			continue
		var beside := MAP[r][c]
		if beside == "#" or beside == "W":
			continue
		var along_x := face.x != 0   # wall face runs left-right
		var normal := Vector3(face.y, 0, face.x)
		var base := pos + normal * (TILE / 2.0 + 0.012)
		var hash_value := (row * 73 + col * 151 + (face.x + 1) * 7 + (face.y + 1) * 3) % 100

		_add_box(_world, base + Vector3(0, 0.15, 0), _flat(along_x, TILE, 0.3), SKIRTING_COLOR, false)
		var stripe_color := STRIPE_COLORS[region % STRIPE_COLORS.size()]
		_add_box(_world, base + Vector3(0, 1.35, 0), _flat(along_x, TILE, 0.22), stripe_color.darkened(0.35), false)
		if hash_value % 3 == 0:
			_add_box(_world, base + Vector3(0, 1.1, 0), _flat(along_x, TILE, 0.06), stripe_color.darkened(0.55), false)

		if hash_value < 22:
			_add_poster(base + normal * 0.01, along_x, POSTER_COLORS[hash_value % POSTER_COLORS.size()], hash_value)
		elif hash_value < 34:
			_add_handprint(base + normal * 0.01, along_x, hash_value)
		elif hash_value < 46:
			_add_scrawl(base + normal * 0.015, normal, WALL_WORDS[hash_value % WALL_WORDS.size()], hash_value)


func _flat(along_x: bool, width: float, height: float) -> Vector3:
	return Vector3(width, height, 0.02) if along_x else Vector3(0.02, height, width)


## A faded kids' poster, hanging crooked, one corner peeled.
func _add_poster(pos: Vector3, along_x: bool, color: Color, seed_value: int) -> void:
	var holder := Node3D.new()
	holder.position = pos + Vector3(0, 1.9 + (seed_value % 5) * 0.06, 0)
	holder.rotation.y = 0.0 if along_x else PI / 2.0
	holder.rotation.z = ((seed_value % 7) - 3) * 0.04
	_world.add_child(holder)
	var paper := _add_box(holder, Vector3.ZERO, Vector3(0.7, 0.9, 0.02), color.darkened(0.45), false)
	_add_box(paper, Vector3(0, 0.1, 0.015), Vector3(0.45, 0.45, 0.01), color.lightened(0.3).darkened(0.2), false)
	_add_box(paper, Vector3(0, -0.3, 0.015), Vector3(0.5, 0.1, 0.01), Color("e8e2d0").darkened(0.35), false)
	var peel := _add_box(paper, Vector3(0.28, 0.38, 0.03), Vector3(0.18, 0.18, 0.01), color.darkened(0.7), false)
	peel.rotation.z = 0.5


## A small red handprint, dragged downwards.
func _add_handprint(pos: Vector3, along_x: bool, seed_value: int) -> void:
	var holder := Node3D.new()
	holder.position = pos + Vector3(0, 1.0 + (seed_value % 4) * 0.15, 0)
	holder.rotation.y = 0.0 if along_x else PI / 2.0
	holder.rotation.z = ((seed_value % 5) - 2) * 0.2
	_world.add_child(holder)
	_add_box(holder, Vector3.ZERO, Vector3(0.16, 0.2, 0.01), BLOOD_COLOR, false)
	for i in 4:
		_add_box(holder, Vector3((i - 1.5) * 0.045, 0.17, 0), Vector3(0.035, 0.16, 0.01), BLOOD_COLOR, false)
	_add_box(holder, Vector3(0.1, 0.05, 0), Vector3(0.035, 0.1, 0.01), BLOOD_COLOR, false)
	for i in 3:
		var drip := _add_box(holder, Vector3((i - 1) * 0.05, -0.2 - i * 0.07, 0), Vector3(0.02, 0.25 + i * 0.1, 0.01), BLOOD_COLOR, false)
		drip.position.y -= drip.mesh.size.y / 2.0 - 0.1


## Words scratched into the paint.
func _add_scrawl(pos: Vector3, normal: Vector3, words: String, seed_value: int) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = 96 if words.length() < 6 else 56
	label.pixel_size = 0.004
	label.modulate = BLOOD_COLOR.lightened(0.15)
	label.outline_modulate = Color(0.1, 0.0, 0.0)
	label.outline_size = 6
	label.shaded = true
	label.position = pos + Vector3(0, 1.75 + (seed_value % 3) * 0.1, 0)
	label.rotation.y = atan2(normal.x, normal.z)
	label.rotation.z = ((seed_value % 5) - 2) * 0.06
	_world.add_child(label)


## A tall wooden cupboard with its doors hanging open, back to the wall. Step inside to hide.
func _add_cupboard(row: int, col: int, pos: Vector3) -> void:
	var rows := MAP.size()
	var cols := MAP[0].length()
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]   # (drow, dcol)
	var open := Vector2i.ZERO
	for d in dirs:
		var front := Vector2i(row + d.x, col + d.y)
		var back := Vector2i(row - d.x, col - d.y)
		if front.x < 0 or front.x >= rows or front.y < 0 or front.y >= cols:
			continue
		if not _is_room_floor(MAP[front.x][front.y]):
			continue
		if open == Vector2i.ZERO or (back.x >= 0 and back.x < rows and back.y >= 0 and back.y < cols and MAP[back.x][back.y] == "#"):
			open = d
	if open == Vector2i.ZERO:
		open = Vector2i(1, 0)
	var facing := Vector3(open.y, 0, open.x)
	_cupboards[Vector2i(col, row)] = facing

	var holder := Node3D.new()
	holder.name = "Cupboard_%d_%d" % [row, col]
	holder.position = pos
	holder.rotation.y = atan2(facing.x, facing.z)   # local +Z = the open front
	_world.add_child(holder)
	var wood := CUPBOARD_COLOR
	_add_box(holder, Vector3(0, 1.2, -0.95), Vector3(1.6, 2.4, 0.06), wood.lightened(0.12), true)
	_add_box(holder, Vector3(-0.77, 1.2, -0.48), Vector3(0.06, 2.4, 1.0), wood, true)
	_add_box(holder, Vector3(0.77, 1.2, -0.48), Vector3(0.06, 2.4, 1.0), wood, true)
	_add_box(holder, Vector3(0, 2.37, -0.48), Vector3(1.6, 0.06, 1.0), wood.darkened(0.2), true)
	_add_box(holder, Vector3(0, 2.05, -0.5), Vector3(1.5, 0.04, 0.9), wood.darkened(0.4), false)   # a shelf above your head
	_add_box(holder, Vector3(0, 0.03, -0.48), Vector3(1.6, 0.06, 1.0), wood.darkened(0.5), false)
	# two doors, hanging open (they swing shut once you're inside - see _swing_cupboard_doors)
	var hinges: Array = []
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var hinge := Node3D.new()
		hinge.position = Vector3(side * 0.8, 1.2, 0.02)
		hinge.rotation.y = side * DOOR_OPEN_ANGLES[i]
		holder.add_child(hinge)
		var panel := _add_box(hinge, Vector3(-side * 0.39, 0.0, 0.0), Vector3(0.78, 2.35, 0.04), wood.darkened(0.1), false)
		_add_box(panel, Vector3(-side * 0.3, 0.0, 0.03), Vector3(0.05, 0.16, 0.03), Color("2a2420"), false)   # handle
		hinges.append(hinge)
	_cupboard_doors[Vector2i(col, row)] = hinges
	# something scratched inside the back
	var label := Label3D.new()
	label.text = "hide"
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = BLOOD_COLOR.lightened(0.15)
	label.outline_modulate = Color(0.1, 0.0, 0.0)
	label.outline_size = 6
	label.shaded = true
	label.position = Vector3(0, 1.5, -0.91)
	holder.add_child(label)


## A little kids' table with two tiny chairs (one usually knocked over) and crayons.
func _add_table(pos: Vector3, seed_value: int) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = (seed_value % 7) * 0.12
	_world.add_child(holder)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.58, 1.0)
	shape.shape = box
	shape.position = Vector3(0, 0.29, 0)
	body.add_child(shape)
	holder.add_child(body)
	_add_box(body, Vector3(0, 0.55, 0), Vector3(1.4, 0.06, 1.0), TABLE_COLOR, false)
	for x in [-0.62, 0.62]:
		for z in [-0.42, 0.42]:
			_add_box(body, Vector3(x, 0.26, z), Vector3(0.06, 0.52, 0.06), TABLE_COLOR.darkened(0.3), false)
	for i in 3:
		var crayon := _add_box(body, Vector3(-0.3 + i * 0.25, 0.6, (i % 2) * 0.3 - 0.15), Vector3(0.04, 0.04, 0.3), BLOCK_COLORS[(seed_value + i) % BLOCK_COLORS.size()], false)
		crayon.rotation.y = (seed_value + i * 3) * 0.3
	_add_chair(holder, Vector3(0, 0, 0.85), PI, CHAIR_COLORS[seed_value % CHAIR_COLORS.size()], false)
	_add_chair(holder, Vector3(0.2, 0, -0.9), 0.4, CHAIR_COLORS[(seed_value + 1) % CHAIR_COLORS.size()], seed_value % 3 != 0)


## A tiny chair. Tipped over on its side if `fallen`.
func _add_chair(parent: Node3D, pos: Vector3, yaw: float, color: Color, fallen: bool) -> void:
	var chair := Node3D.new()
	chair.position = pos
	chair.rotation.y = yaw
	if fallen:
		chair.rotation.z = PI / 2.0
		chair.position.y = 0.18
	parent.add_child(chair)
	_add_box(chair, Vector3(0, 0.3, 0), Vector3(0.36, 0.04, 0.36), color, false)
	_add_box(chair, Vector3(0, 0.5, -0.16), Vector3(0.36, 0.4, 0.04), color.darkened(0.15), false)
	for x in [-0.15, 0.15]:
		for z in [-0.15, 0.15]:
			_add_box(chair, Vector3(x, 0.15, z), Vector3(0.04, 0.3, 0.04), color.darkened(0.4), false)


## Odds and ends on the floor, decided by the tile's position so the level always looks the same:
## spilt building blocks, drawings, a dark puddle, a knocked-over chair.
func _add_clutter(row: int, col: int, pos: Vector3) -> void:
	var hash_value := (row * 53 + col * 97 + (row * col) % 13) % 100
	var spread := Vector3(((hash_value * 7) % 11 - 5) * 0.1, 0, ((hash_value * 13) % 11 - 5) * 0.1)
	if hash_value < 9:
		for i in 2 + hash_value % 2:
			var block := _add_box(_world, pos + spread + Vector3((i - 1) * 0.3, 0.12, (i % 2) * 0.25), Vector3(0.24, 0.24, 0.24), BLOCK_COLORS[(hash_value + i) % BLOCK_COLORS.size()], false)
			block.rotation.y = (hash_value + i * 5) * 0.4
	elif hash_value < 15:
		for i in 2:
			var paper := _add_box(_world, pos + spread + Vector3(i * 0.35, 0.005 + i * 0.003, i * 0.2), Vector3(0.3, 0.004, 0.42), PAPER_COLOR.darkened(0.2 + i * 0.1), false)
			paper.rotation.y = (hash_value + i * 4) * 0.5
			_add_box(paper, Vector3(0, 0.003, 0), Vector3(0.14, 0.002, 0.14), POSTER_COLORS[(hash_value + i) % POSTER_COLORS.size()].darkened(0.5), false)
	elif hash_value < 19:
		var puddle := _add_box(_world, pos + spread + Vector3(0, 0.004, 0), Vector3(0.9 + (hash_value % 3) * 0.2, 0.006, 0.7), BLOOD_COLOR.darkened(0.3), false) as MeshInstance3D
		puddle.rotation.y = hash_value * 0.3
		var mat := puddle.material_override as StandardMaterial3D
		mat.roughness = 0.2
		mat.metallic = 0.2
		for i in 2:
			var drip := _add_box(puddle, Vector3(0.5 + i * 0.2, 0.0, (i - 0.5) * 0.4), Vector3(0.25, 0.006, 0.2), BLOOD_COLOR.darkened(0.3), false) as MeshInstance3D
			drip.material_override = mat
	elif hash_value < 22:
		_add_chair(_world, pos + spread, hash_value * 0.7, CHAIR_COLORS[hash_value % CHAIR_COLORS.size()], true)


func _make_door(pos: Vector3, color: Color, along_x: bool, cell: Vector2i) -> StaticBody3D:
	var door := StaticBody3D.new()
	door.set_script(DoorScript)
	door.color = color
	door.size = Vector3(TILE, WALL_HEIGHT, 0.4) if along_x else Vector3(0.4, WALL_HEIGHT, TILE)
	door.position = pos
	door.opened.connect(func(): _grid.set_point_solid(cell, false))   # monsters can follow you through
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
