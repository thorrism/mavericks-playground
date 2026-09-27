extends Node3D
## THE ABYSS - a dark, abandoned school you have to escape from, one chapter at a time. First person.
## You have a flashlight. THEY have very good eyes - and they know the way around.
## Every chapter is a text map in scripts/chapters.gd. Edit the map = edit the chapter!
##
##   #  wall (a hedge outside)   .  floor      P  where you start
##   W  low wall (only the drone can fly over it)
##   =  fence (you can jump over it - THEY just step over it)
##   T  toy to collect                         X  exit door (opens when all toys are found)
##   M  the tall one (Banban-ish)   J  the giant (Jumbo Josh-ish)   O  the bird (Opila-ish, not used right now)
##   L  a flickering ceiling lamp (a street lamp outside)
##   H  a cupboard you can hide in (put it against a wall). Inside, THEY can't see you -
##      unless one was already right behind you when you climbed in.
##   t  a little kids' table with chairs (solid: THEY have to walk around it - but they see over it)
##   S  a tall shelf: lockers / bookcase / a lab tank - swings on the playground     (solid)
##   Z  stacked crates or gym mats - a slide on the playground                       (solid)
##   ^  a pillar - a tree on the playground                                          (solid)
##   1 2 3  doors         a b c  buttons       button a opens door 1, b opens 2, c opens 3
##          a chapter can make a door TIMED: it slams shut again after a while (press a button again)
##
## Every letter is one tile (TILE metres wide). Rows must all be the same length.

## The map of the chapter being played (copied from Chapters.CHAPTERS[chapter] in _ready).
var MAP: Array[String] = []
var chapter := 0
var chapter_def: Dictionary = {}
var theme: Dictionary = {}
var outdoors := false          # no ceiling, night sky, street lamps; THEY can be as tall as they like
var wall_height := 3.0
var monster_scale := 1.0       # how big THEY are in this chapter
var hunt := 1.0                # how far THEY see / hear and how long they keep hunting, this chapter

const MONSTER_LETTERS := "MJO"

const TILE := 2.0
const LOW_WALL_HEIGHT := 1.6
const FENCE_HEIGHT := 0.7

## How each chapter is decorated. Anything missing falls back to the classroom look.
##   floor / ceiling / walls / stripes / words  colours + what's scrawled on the walls
##   decor       posters, handprints and scrawls on the walls (off outside)
##   outdoors    no ceiling, night sky, moon, street lamps, hedges for walls
##   wall_height taller rooms as the chapters go on, so the bigger creatures fit under the ceiling
##   ambient     background light (0.07 is the dark school; the moonlit playground is a little brighter)
##   glow        the lamps' colour; tanks and crates glow this colour in the lab
const THEMES: Dictionary = {
	"classroom": {},
	"hallway": {
		"wall_height": 3.2,
		"floor": Color("3e3f44"), "walls": [Color("5a6a7a"), Color("6a5a48"), Color("4d6a5a")],
		"stripes": [Color("a8c0d8"), Color("d8b890"), Color("98c8a8")],
		"words": ["RUN", "don't stop", "it walks the hall at night", "HELP", "they can hear you", "lockers won't save you"],
		"shelf": Color("5a6068"), "table": Color("6a6a70"),
	},
	"library": {
		"wall_height": 3.4,
		"floor": Color("4a3a30"), "walls": [Color("5a3e2c"), Color("4c4a3a"), Color("6a4a3a")],
		"stripes": [Color("c8a878"), Color("b8b080"), Color("d0a080")],
		"words": ["shhh", "quiet", "it reads in the dark", "HELP", "don't turn the page", "they can hear you"],
		"shelf": Color("4a3020"), "table": Color("5a4030"), "lamps": [Color("ffb070"), Color("ffd090")],
	},
	"lunchroom": {
		"wall_height": 3.5,
		"floor": Color("5a5850"), "walls": [Color("7a7a4a"), Color("8a5a4a"), Color("4a6a6a")],
		"stripes": [Color("e0d890"), Color("e0a898"), Color("98c8c8")],
		"words": ["EAT", "hungry", "it's still hungry", "HELP", "they can smell you", "don't eat that"],
		"table": Color("8a8070"), "table_size": Vector3(1.8, 0.58, 0.9), "lamps": [Color("ffe0a0"), Color("c0ffc0")],
	},
	"gym": {
		"wall_height": 4.2,
		"floor": Color("6a5a3a"), "walls": [Color("3a5a8a"), Color("8a3a3a"), Color("5a5a5a")],
		"stripes": [Color("90b0e0"), Color("e09090"), Color("c0c0c0")],
		"words": ["RUN FASTER", "jump", "it never gets tired", "HELP", "no time outs", "they can hear you"],
		"crate": Color("2a4a8a"), "table": Color("6a6a6a"), "lamps": [Color("ffffff"), Color("e0e0ff")],
	},
	"art": {
		"wall_height": 3.8,
		"floor": Color("4a4048"), "walls": [Color("8a3a6a"), Color("3a7a8a"), Color("8a7a2a"), Color("5a3a8a")],
		"stripes": [Color("e090c0"), Color("90d0e0"), Color("e0d070"), Color("b090e0")],
		"words": ["it's not paint", "draw me", "HELP", "RED", "they can hear you", "look what I made"],
		"table": Color("9a8a7a"), "crate": Color("7a6a5a"),
	},
	"playground": {
		"outdoors": true, "decor": false, "ambient": 0.10,
		"floor": Color("22301c"), "outside": Color("151e12"), "walls": [Color("1e3a1e"), Color("243e22")],
		"low_wall": Color("4a3a34"), "fence": Color("555a5e"), "shelf": Color("6a3a2a"), "crate": Color("8a3a2a"),
		"lamps": [Color("ffd9a0")], "words": [],
	},
	"lab": {
		"wall_height": 5.4, "ambient": 0.05, "glow": Color("46ff70"),
		"floor": Color("2a2e2c"), "ceiling": Color("1a1c1c"), "walls": [Color("3a4a48"), Color("4a4a52"), Color("2e3e3e")],
		"stripes": [Color("80c0b0"), Color("a0a0c0"), Color("70b0a0")],
		"words": ["SUBJECT 7 ESCAPED", "it went wrong", "seal the lab", "HELP", "we made them", "DON'T OPEN THE TANKS", "they grew"],
		"shelf": Color("2a3a3a"), "crate": Color("3a3a3a"), "table": Color("5a6a6a"), "lamps": [Color("70ff90"), Color("c0ffd0")],
	},
}

# Colours - faded kindergarten paint under years of grime. Change these to redecorate!
const FLOOR_COLOR := Color("4a4640")
const CEILING_COLOR := Color("2a2826")
const OUTSIDE_COLOR := Color("101a10")
const SHELF_COLOR := Color("4a3a2a")
const CRATE_COLOR := Color("6a5a3a")
const PILLAR_COLOR := Color("3a3a3a")
const TREE_COLORS: Array[Color] = [Color("1a2e18"), Color("22381e")]
const BOOK_COLORS: Array[Color] = [Color("6a2a2a"), Color("2a3a6a"), Color("5a5a2a"), Color("2a4a3a"), Color("4a2a5a")]
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
var _door_timers: Dictionary = {}   # door node -> seconds until a timed door slams shut again
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
	_load_chapter(Settings.chapter)
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
	_apply_theme_environment()

	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 2.0)

	_yaw = 0.0   # face "up" the map, towards the fence and the first door
	_update_camera(0.0)

	hud.subtitle = Chapters.title(chapter).to_lower()
	menu.opened.connect(func() -> void: hud.visible = false)
	menu.play.connect(_on_menu_play)
	menu.restart.connect(_restart)
	menu.quit_to_title.connect(_quit_to_title)
	menu.chapter_picked.connect(_on_chapter_picked)
	if Game.title_pending:
		# first boot / just escaped: the title screen, with the level frozen behind it
		Game.title_pending = false
		menu.show_title.call_deferred(Game.last_result)
		Game.last_result = ""
	else:
		menu.hide_menu()
		_begin_run()


## Which chapter we're in, and what it looks like. Everything below reads MAP / theme from here.
func _load_chapter(index: int) -> void:
	chapter = clampi(index, 0, Chapters.count() - 1)
	chapter_def = Chapters.get_chapter(chapter)
	MAP.assign(chapter_def["map"])
	theme = THEMES.get(chapter_def.get("theme", "classroom"), {})
	outdoors = theme.get("outdoors", false)
	wall_height = theme.get("wall_height", 3.0)
	monster_scale = chapter_def.get("monster_scale", 1.0)
	hunt = chapter_def.get("hunt", 1.0)


## Night sky and moonlight outside; a little darker / greener in the lab.
func _apply_theme_environment() -> void:
	var e: Environment = env.environment.duplicate()
	env.environment = e
	e.ambient_light_energy = theme.get("ambient", 0.07)
	var moon: DirectionalLight3D = get_node_or_null("Moon")
	if outdoors:
		var sky := Sky.new()
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.01, 0.015, 0.04)
		sky_mat.sky_horizon_color = Color(0.04, 0.05, 0.09)
		sky_mat.ground_bottom_color = Color(0.0, 0.0, 0.0)
		sky_mat.ground_horizon_color = Color(0.03, 0.04, 0.06)
		sky_mat.sun_angle_max = 0.0
		sky.sky_material = sky_mat
		e.background_mode = Environment.BG_SKY
		e.sky = sky
		e.fog_density = fog_density * 0.5
		e.fog_light_color = Color(0.03, 0.04, 0.07)
		e.ambient_light_color = Color(0.4, 0.5, 0.8)
		if moon:
			moon.light_energy = 0.35
		# the moon itself, hanging low over the far hedge
		var moon_ball := MeshInstance3D.new()
		moon_ball.name = "Moon"
		var sphere := SphereMesh.new()
		sphere.radius = 6.0
		sphere.height = 12.0
		moon_ball.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.88, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.75, 0.95)
		mat.emission_energy_multiplier = 1.4
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		moon_ball.material_override = mat
		moon_ball.position = Vector3(-70, 55, -140)
		_world.add_child(moon_ball)
	elif theme.has("glow"):
		e.ambient_light_color = Color(0.3, 0.5, 0.4)
		e.fog_light_color = Color(0.01, 0.03, 0.02)


## Picked another chapter on the title screen: rebuild behind the menu.
func _on_chapter_picked(index: int) -> void:
	if index == chapter or _playing:
		return
	Game.title_pending = true
	_restart()


## QUIT TO TITLE in the pause menu: drop this run, rebuild the chapter behind the title screen.
func _quit_to_title() -> void:
	Game.title_pending = true
	Game.last_result = ""
	_restart()


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
	_tick_timed_doors(delta)

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
	Game.say("ALL TOYS FOUND.  %s" % chapter_def.get("exit_hint", "The GOLDEN DOOR is open.  RUN!"), 6.0)


## You made it out: freeze, fade to white-gold, and start a fresh level.
func _on_escaped() -> void:
	_escaped = true
	if drone.active:
		_set_drone_active(false, true)
	robot.active = false
	robot.velocity = Vector3.ZERO
	hud.stop_clock()
	var record := Settings.record_escape(chapter, hud.elapsed)
	var last := chapter >= Chapters.count() - 1
	var result := "CHAPTER %d ESCAPED in %s%s" % [chapter + 1, Settings.fmt_time(hud.elapsed), "   -   NEW RECORD!" if record else ""]
	if last:
		result += "\nYOU GOT OUT OF THE ABYSS.  ALL 8 CHAPTERS."
	else:
		result += "\nCHAPTER %d UNLOCKED: %s" % [chapter + 2, Chapters.get_chapter(chapter + 1)["name"]]
		Settings.set_chapter(chapter + 1)   # the next one is waiting behind the title screen
	Game.last_result = result
	Game.title_pending = true
	Game.say("YOU ESCAPED!", 4.0)
	blood_text.scare("YOU ESCAPED" if not last else "YOU GOT OUT", 3.5)
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
			if ch in "#WXHtSZ^" or (ch >= "1" and ch <= "9"):
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
	if outdoors:
		floor_size = Vector3((cols + 60) * TILE, 1.0, (rows + 60) * TILE)   # a dark field all round
	_add_box(_world, Vector3(0, -0.52, 0), floor_size, theme.get("outside", OUTSIDE_COLOR), true)
	# invisible fence round the edge of the world so nobody can fall off it
	for side in [-1.0, 1.0]:
		var x_wall := _add_box(_world, Vector3(side * (floor_size.x / 2.0 + 0.5), 2.5, 0), Vector3(1.0, 6.0, floor_size.z + 2.0), OUTSIDE_COLOR, true)
		x_wall.visible = false
		var z_wall := _add_box(_world, Vector3(0, 2.5, side * (floor_size.z / 2.0 + 0.5)), Vector3(floor_size.x + 2.0, 6.0, 1.0), OUTSIDE_COLOR, true)
		z_wall.visible = false
	# floor + ceiling are built one strip per map row (the mobile renderer only
	# lights a mesh with its 8 nearest lights, and there are many small lights here)
	var floor_color: Color = theme.get("floor", FLOOR_COLOR)
	var ceiling_color: Color = theme.get("ceiling", CEILING_COLOR)
	for row in rows:
		var z := _tile_pos(row, 0).z
		_add_box(_world, Vector3(0, -0.5, z), Vector3(cols * TILE, 1.0, TILE), floor_color, false)
		if not outdoors:
			_add_box(_world, Vector3(0, wall_height + 0.1, z), Vector3(cols * TILE, 0.2, TILE), ceiling_color, false)
	var timed: Dictionary = chapter_def.get("timed", {})

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
					var palette: Array = theme.get("walls", WALL_COLORS)
					var color: Color = palette[region % palette.size()]
					if outdoors:
						_add_hedge(pos, color, row * 7 + col * 13)
					else:
						_add_box(_world, pos + Vector3(0, wall_height / 2.0, 0), Vector3(TILE, wall_height, TILE), color, true)
						if theme.get("decor", true):
							_decorate_wall(row, col, pos, region)
				"W":
					_add_box(_world, pos + Vector3(0, LOW_WALL_HEIGHT / 2.0, 0), Vector3(TILE, LOW_WALL_HEIGHT, TILE), theme.get("low_wall", LOW_WALL_COLOR), true)
				"=":
					var fence := _add_box(_world, pos + Vector3(0, FENCE_HEIGHT / 2.0, 0), Vector3(TILE, FENCE_HEIGHT, TILE), theme.get("fence", FENCE_COLOR), true)
					fence.collision_layer = 1 << (FENCE_LAYER - 1)
				"S":
					if outdoors:
						_add_swings(row, col, pos)
					else:
						_add_shelf(row, col, pos)
				"Z":
					if outdoors:
						_add_slide(row, col, pos)
					else:
						_add_crates(pos, row * 31 + col * 17)
				"^":
					if outdoors:
						_add_tree(pos, row * 19 + col * 23)
					else:
						_add_box(_world, pos + Vector3(0, wall_height / 2.0, 0), Vector3(1.0, wall_height, 1.0), PILLAR_COLOR, true)
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
					var lamp_colors: Array = theme.get("lamps", LAMP_COLORS)
					lamp.color = lamp_colors[lamp_index % lamp_colors.size()]
					if outdoors:
						# a street lamp: a pole with the light up top, a wider but no brighter pool
						lamp.position = pos + Vector3(0.6, 4.2, 0.6)
						lamp.light_range = 8.0
						_add_box(_world, pos + Vector3(0.6, 2.1, 0.6), Vector3(0.14, 4.2, 0.14), Color("2a2a2e"), true)
					else:
						lamp.position = pos + Vector3(0, wall_height - 0.2, 0)
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
						monster.size = monster_scale
						monster.position = pos + Vector3(0, 0.1, 0)
						_world.add_child(monster)
						monster_index += 1
					elif ch >= "1" and ch <= "9":
						var idx := int(ch) - 1
						var door := _make_door(pos, DOOR_COLORS[idx % DOOR_COLORS.size()], _door_faces_x(row, col, rows, cols), Vector2i(col, row))
						door.name = "Door%s" % ch if not _doors.has(ch) else "Door%s_%d" % [ch, _doors[ch].size()]
						door.close_after = float(timed.get(ch, 0.0))
						if not _doors.has(ch):
							_doors[ch] = []
						_doors[ch].append(door)
					elif ch >= "a" and ch <= "i":
						var idx := ch.unicode_at(0) - "a".unicode_at(0)
						var button := Area3D.new()
						button.name = "Button%s" % ch
						button.set_script(ButtonScript)
						button.color = DOOR_COLORS[idx % DOOR_COLORS.size()]
						button.position = pos
						_world.add_child(button)
						if not buttons.has(ch):
							buttons[ch] = []
						buttons[ch].append(button)

	# wire buttons to their doors: a -> 1, b -> 2, c -> 3 ... (every a opens every door 1)
	for key: String in buttons:
		var door_key := str(key.unicode_at(0) - "a".unicode_at(0) + 1)
		if not _doors.has(door_key):
			continue
		for button: Area3D in buttons[key]:
			button.pressed.connect(_on_button_pressed.bind(door_key))


## A button was stepped on: open its door(s). Timed doors start their countdown.
func _on_button_pressed(door_key: String) -> void:
	var opened_any := false
	for door: StaticBody3D in _doors[door_key]:
		if door.close_after > 0.0:
			_door_timers[door] = door.close_after
		if door.is_open:
			continue
		opened_any = true
		door.open()
	var first: StaticBody3D = _doors[door_key][0]
	if first.close_after > 0.0:
		Game.say("*clunk*   A door opened somewhere... it won't stay open long.  %d seconds." % int(first.close_after), 3.0)
	elif opened_any:
		Game.say("*clunk*   A door opened somewhere...", 2.5)


## Timed doors count down and slam shut again - unless someone is standing in the doorway.
func _tick_timed_doors(delta: float) -> void:
	if _door_timers.is_empty() or _caught or _escaped:
		return
	for door: StaticBody3D in _door_timers.keys():
		var left: float = _door_timers[door] - delta
		if left > 0.0:
			_door_timers[door] = left
			if left <= 5.0 and int(left + delta) != int(left):
				Game.say("the door...  %d" % (int(left) + 1), 0.9)
			continue
		var in_the_way := door.global_position.distance_to(robot.global_position) < TILE * 0.9
		in_the_way = in_the_way or (drone.active and door.global_position.distance_to(drone.global_position) < TILE * 0.9)
		for monster: CharacterBody3D in get_tree().get_nodes_in_group("monster"):
			in_the_way = in_the_way or door.global_position.distance_to(monster.global_position) < TILE * 0.9
		if in_the_way:
			_door_timers[door] = 0.5   # hold it until you're through
			continue
		_door_timers.erase(door)
		door.close()
		Game.say("*SLAM*", 1.5)


## How long (seconds) until this door slams shut; 0 if it isn't counting down.
func door_time_left(door: StaticBody3D) -> float:
	return _door_timers.get(door, 0.0)


## Which room a wall belongs to (for colours): the room of the floor tile it looks into.
func _region_of(row: int, col: int) -> int:
	for step in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var room: int = _rooms.get(Vector2i(col, row) + step, -1)
		if room >= 0:
			return room
	return 0


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
		var stripes: Array = theme.get("stripes", STRIPE_COLORS)
		var words: Array = theme.get("words", WALL_WORDS)
		var stripe_color: Color = stripes[region % stripes.size()]
		_add_box(_world, base + Vector3(0, 1.35, 0), _flat(along_x, TILE, 0.22), stripe_color.darkened(0.35), false)
		if hash_value % 3 == 0:
			_add_box(_world, base + Vector3(0, 1.1, 0), _flat(along_x, TILE, 0.06), stripe_color.darkened(0.55), false)

		if hash_value < 22:
			_add_poster(base + normal * 0.01, along_x, POSTER_COLORS[hash_value % POSTER_COLORS.size()], hash_value)
		elif hash_value < 34:
			_add_handprint(base + normal * 0.01, along_x, hash_value)
		elif hash_value < 46 and not words.is_empty():
			_add_scrawl(base + normal * 0.015, normal, words[hash_value % words.size()], hash_value)


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
	var size: Vector3 = theme.get("table_size", Vector3(1.4, 0.58, 1.0))
	var wood: Color = theme.get("table", TABLE_COLOR)
	box.size = size
	shape.shape = box
	shape.position = Vector3(0, size.y / 2.0, 0)
	body.add_child(shape)
	holder.add_child(body)
	_add_box(body, Vector3(0, size.y - 0.03, 0), Vector3(size.x, 0.06, size.z), wood, false)
	for x in [-size.x / 2.0 + 0.08, size.x / 2.0 - 0.08]:
		for z in [-size.z / 2.0 + 0.08, size.z / 2.0 - 0.08]:
			_add_box(body, Vector3(x, size.y / 2.0 - 0.03, z), Vector3(0.06, size.y - 0.06, 0.06), wood.darkened(0.3), false)
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
	if outdoors:
		if hash_value < 12:   # a tuft of long grass
			for i in 3:
				var blade := _add_box(_world, pos + Vector3((i - 1) * 0.25, 0.2, (i % 2) * 0.2), Vector3(0.05, 0.4, 0.05), TREE_COLORS[i % 2].lightened(0.15), false)
				blade.rotation.z = ((hash_value + i) % 5 - 2) * 0.15
		return
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
	door.size = Vector3(TILE, wall_height, 0.4) if along_x else Vector3(0.4, wall_height, TILE)
	door.position = pos
	door.opened.connect(func(): _grid.set_point_solid(cell, false))   # monsters can follow you through
	door.closed.connect(func(): _grid.set_point_solid(cell, true))
	_world.add_child(door)
	return door


# ---------------------------------------------------------------------------
# Chapter furniture: shelves, crates, pillars indoors - hedges, trees, swings, a slide outside
# ---------------------------------------------------------------------------

## A tall shelf unit filling the tile: lockers in the hallway, a bookcase in the library,
## a cracked containment tank (glowing) in the lab.
func _add_shelf(row: int, col: int, pos: Vector3) -> void:
	var color: Color = theme.get("shelf", SHELF_COLOR)
	var h := minf(wall_height - 0.3, 2.6)
	if theme.has("glow"):
		_add_tank(pos, theme["glow"], row * 11 + col * 5)
		return
	var body := _add_box(_world, pos + Vector3(0, h / 2.0, 0), Vector3(TILE - 0.1, h, TILE - 0.1), color, true)
	var seed_value := row * 11 + col * 5
	if chapter_def.get("theme", "") == "hallway":
		# locker doors down each side, a couple hanging open
		for side in [-1.0, 1.0]:
			for i in 3:
				var z := (i - 1) * 0.62
				var door := _add_box(body, Vector3(side * (TILE / 2.0 - 0.03), h / 2.0, z), Vector3(0.03, h - 0.2, 0.56), color.lightened(0.1 if (seed_value + i) % 4 else 0.25), false)
				_add_box(door, Vector3(side * 0.02, 0.2, 0.18), Vector3(0.02, 0.12, 0.04), Color("9a9a9a"), false)
				if (seed_value + i) % 5 == 0:
					door.rotation.y = side * 0.9
					door.position.x += side * 0.25
	else:
		# rows of books, some fallen out
		for side in [-1.0, 1.0]:
			for shelf_i in 4:
				var y := 0.35 + shelf_i * 0.6
				_add_box(body, Vector3(side * (TILE / 2.0 - 0.15), y - 0.02, 0), Vector3(0.3, 0.04, TILE - 0.2), color.darkened(0.3), false)
				var z := -0.75
				var k := 0
				while z < 0.75:
					var w := 0.08 + ((seed_value + k + shelf_i) % 3) * 0.04
					if (seed_value + k * 3 + shelf_i) % 7 != 0:
						_add_box(body, Vector3(side * (TILE / 2.0 - 0.15), y + 0.2, z + w / 2.0), Vector3(0.22, 0.4 - ((k + shelf_i) % 3) * 0.05, w), BOOK_COLORS[(seed_value + k + shelf_i) % BOOK_COLORS.size()], false)
					z += w + 0.01
					k += 1


## A cracked containment tank: green liquid, something's outline still floating inside, glass
## smashed outwards. This is where THEY came from.
func _add_tank(pos: Vector3, glow: Color, seed_value: int) -> void:
	var holder := Node3D.new()
	holder.name = "Tank%d" % (_world.find_children("Tank*", "Node3D", false, false).size() + 1)
	holder.position = pos
	holder.rotation.y = (seed_value % 4) * PI / 2.0
	_world.add_child(holder)
	var h := 3.2
	var metal := Color("3a4444")
	_add_box(holder, Vector3(0, 0.2, 0), Vector3(TILE - 0.2, 0.4, TILE - 0.2), metal, true)
	_add_box(holder, Vector3(0, h - 0.15, 0), Vector3(TILE - 0.2, 0.3, TILE - 0.2), metal, false)
	var broken := seed_value % 3 != 1
	var liquid := _add_box(holder, Vector3(0, 0.4 + (0.6 if broken else h - 0.7) / 2.0, 0), Vector3(TILE - 0.5, 0.6 if broken else h - 0.7, TILE - 0.5), glow.darkened(0.3), true) as StaticBody3D
	var liquid_mesh: MeshInstance3D = liquid.get_child(0)
	var mat := liquid_mesh.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.75
	var glass := _add_box(holder, Vector3(0, 0.4 + (h - 0.7) / 2.0, 0), Vector3(TILE - 0.3, h - 0.7, TILE - 0.3), Color(0.6, 0.9, 0.8, 0.12), false) as MeshInstance3D
	var glass_mat := glass.material_override as StandardMaterial3D
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	if broken:
		glass.scale.y = 0.35   # only the bottom of the glass is left
		glass.position.y = 0.4 + (h - 0.7) * 0.35 / 2.0
		for i in 5:   # shards on the floor outside
			var shard := _add_box(holder, Vector3(0.9 + (i % 3) * 0.25, 0.01, (i - 2) * 0.3), Vector3(0.2 + (i % 2) * 0.15, 0.01, 0.12), Color(0.7, 0.95, 0.85), false)
			shard.rotation.y = i * 1.1 + seed_value
		var spill := _add_box(holder, Vector3(1.2, 0.004, 0.2), Vector3(1.2, 0.006, 1.4), glow.darkened(0.5), false) as MeshInstance3D
		var spill_mat := spill.material_override as StandardMaterial3D
		spill_mat.emission_enabled = true
		spill_mat.emission = glow
		spill_mat.emission_energy_multiplier = 0.5
	else:
		# something still in there
		_add_box(holder, Vector3(0, 1.4, 0), Vector3(0.5, 1.6, 0.4), Color(0.05, 0.12, 0.08), false)
		_add_box(holder, Vector3(0, 2.4, 0), Vector3(0.36, 0.4, 0.36), Color(0.05, 0.12, 0.08), false)
		for x in [-0.09, 0.09]:
			var eye := _add_box(holder, Vector3(x, 2.45, 0.19), Vector3(0.06, 0.06, 0.02), Color(1.0, 0.9, 0.7), false) as MeshInstance3D
			var eye_mat := eye.material_override as StandardMaterial3D
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 0.8, 0.5)
			eye_mat.emission_energy_multiplier = 2.0
	var light := OmniLight3D.new()
	light.light_color = glow
	light.light_energy = 1.1
	light.omni_range = 5.5
	light.shadow_enabled = false
	light.position = Vector3(0, 1.4, 0)
	holder.add_child(light)
	var label := Label3D.new()
	label.text = "SUBJECT %d" % (seed_value % 9 + 1)
	label.font_size = 40
	label.pixel_size = 0.004
	label.modulate = Color(0.8, 0.9, 0.85)
	label.position = Vector3(0, 0.55, TILE / 2.0 - 0.08)
	holder.add_child(label)


## A pile of crates (gym mats in the gym, paint tins in the art room).
func _add_crates(pos: Vector3, seed_value: int) -> void:
	var color: Color = theme.get("crate", CRATE_COLOR)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = (seed_value % 5) * 0.1
	_world.add_child(holder)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE - 0.2, 1.7, TILE - 0.2)
	shape.shape = box
	shape.position = Vector3(0, 0.85, 0)
	body.add_child(shape)
	holder.add_child(body)
	_add_box(body, Vector3(-0.4, 0.4, -0.35), Vector3(0.9, 0.8, 0.9), color, false)
	_add_box(body, Vector3(0.45, 0.4, 0.4), Vector3(0.85, 0.8, 0.85), color.darkened(0.15), false)
	_add_box(body, Vector3(-0.35, 0.4, 0.5), Vector3(0.8, 0.8, 0.7), color.lightened(0.1), false)
	var top := _add_box(body, Vector3(0.0, 1.2, 0.0), Vector3(0.85, 0.8, 0.85), color.darkened(0.3), false)
	top.rotation.y = 0.3 + (seed_value % 3) * 0.2
	if theme.has("glow"):
		var tape := _add_box(body, Vector3(0, 0.9, 0), Vector3(TILE - 0.1, 0.08, TILE - 0.1), Color("d8c020"), false)
		tape.rotation.y = 0.2


## Playground hedge instead of a wall: dark, lumpy, a bit shorter than a wall - but you can't get over it.
func _add_hedge(pos: Vector3, color: Color, seed_value: int) -> void:
	var h := 2.6
	var body := _add_box(_world, pos + Vector3(0, h / 2.0, 0), Vector3(TILE, h, TILE), color, true)
	for i in 3:
		var lump := _add_box(body, Vector3(((seed_value + i * 7) % 5 - 2) * 0.25, h / 2.0 - 0.3 + (i % 2) * 0.5, ((seed_value + i * 3) % 5 - 2) * 0.25), Vector3(1.4 + (i % 2) * 0.5, 1.0, 1.4 + ((i + 1) % 2) * 0.5), color.lightened(0.08 * i), false)
		lump.rotation.y = (seed_value + i) * 0.4


## A tree: trunk you can't walk through, a dark blob of leaves overhead.
func _add_tree(pos: Vector3, seed_value: int) -> void:
	var holder := Node3D.new()
	holder.name = "Tree%d" % (_world.find_children("Tree*", "Node3D", false, false).size() + 1)
	holder.position = pos
	holder.rotation.y = (seed_value % 6) * 0.5
	_world.add_child(holder)
	var trunk := _add_box(holder, Vector3(0, 2.2, 0), Vector3(0.7, 4.4, 0.7), Color("2a1e16"), true)
	trunk.rotation.y = 0.3
	for i in 3:
		var branch := _add_box(holder, Vector3(((i % 2) * 2 - 1) * 0.6, 3.0 + i * 0.6, (i - 1) * 0.5), Vector3(0.2, 1.6, 0.2), Color("2a1e16"), false)
		branch.rotation.z = ((i % 2) * 2 - 1) * 0.7
	for i in 4:
		var leaves := _add_box(holder, Vector3(((seed_value + i * 5) % 5 - 2) * 0.5, 4.8 + (i % 2) * 0.9, ((seed_value + i * 3) % 5 - 2) * 0.5), Vector3(2.6 + (i % 2) * 0.8, 1.6, 2.6 + ((i + 1) % 2) * 0.8), TREE_COLORS[(seed_value + i) % 2], false)
		leaves.rotation.y = (seed_value + i) * 0.5


## A swing set: two rusty A-frames, chains and a seat - one swing hanging by a single chain.
func _add_swings(row: int, col: int, pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Swings%d" % (_world.find_children("Swings*", "Node3D", false, false).size() + 1)
	holder.position = pos
	holder.rotation.y = 0.0 if (row + col) % 2 == 0 else PI / 2.0
	_world.add_child(holder)
	var rust: Color = theme.get("shelf", SHELF_COLOR)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE - 0.2, 2.6, 1.2)
	shape.shape = box
	shape.position = Vector3(0, 1.3, 0)
	body.add_child(shape)
	holder.add_child(body)
	for side in [-1.0, 1.0]:
		for z in [-0.5, 0.5]:
			var leg := _add_box(body, Vector3(side * 0.85, 1.3, z), Vector3(0.1, 2.7, 0.1), rust, false)
			leg.rotation.x = -z * 0.35
	_add_box(body, Vector3(0, 2.6, 0), Vector3(TILE, 0.1, 0.1), rust, false)
	for i in 2:
		var x := (i - 0.5) * 0.9
		var hanging := i == (row + col) % 2
		for c in (2 if hanging else 1):
			var chain := _add_box(body, Vector3(x + (c - 0.5) * 0.4 if hanging else x, 1.6, 0), Vector3(0.03, 1.9, 0.03), Color("6a6a70"), false)
			if not hanging:
				chain.rotation.z = 0.25
		var seat := _add_box(body, Vector3(x, 0.65, 0), Vector3(0.5, 0.05, 0.2), Color("2a2a2a"), false)
		if not hanging:
			seat.position = Vector3(x + 0.25, 0.6, 0)
			seat.rotation.z = 0.9


## A slide: steps up one side, a long slope down the other. Solid all the way round.
func _add_slide(row: int, col: int, pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Slide%d" % (_world.find_children("Slide*", "Node3D", false, false).size() + 1)
	holder.position = pos
	holder.rotation.y = 0.0 if row % 2 == 0 else PI / 2.0
	_world.add_child(holder)
	var paint: Color = theme.get("crate", CRATE_COLOR)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE - 0.2, 2.0, TILE - 0.2)
	shape.shape = box
	shape.position = Vector3(0, 1.0, 0)
	body.add_child(shape)
	holder.add_child(body)
	_add_box(body, Vector3(-0.6, 0.9, 0), Vector3(0.7, 1.8, 0.8), paint.darkened(0.4), false)   # ladder tower
	for i in 5:
		_add_box(body, Vector3(-0.6, 0.3 + i * 0.35, 0.42), Vector3(0.5, 0.04, 0.04), Color("9a9a9a"), false)
	var slope := _add_box(body, Vector3(0.35, 1.05, 0), Vector3(1.6, 0.08, 0.6), paint, false)
	slope.rotation.z = -0.8
	for side in [-1.0, 1.0]:
		var rail := _add_box(body, Vector3(0.35, 1.15, side * 0.32), Vector3(1.6, 0.25, 0.04), paint.darkened(0.2), false)
		rail.rotation.z = -0.8


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
