extends SceneTree
## Headless smoke test. Run with:  make test
## Loads the arena, then Chapter 1 of The Abyss, drives the robot around and checks the rules work;
## then builds every chapter (1-8) and checks the maps, the puzzles, the unlocking and the theming.

var _failures := 0
var game: Node
var settings: Node


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_failures += 1
		printerr("  FAIL ", what)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = root.get_node_or_null("Game")
	if game == null:
		game = load("res://scripts/game.gd").new()
		game.name = "Game"
		root.add_child(game)
	settings = root.get_node_or_null("Settings")
	if settings == null:
		settings = load("res://scripts/settings.gd").new()
		settings.name = "Settings"
		root.add_child(settings)
	settings.persist = false   # don't touch the player's saved records
	settings.difficulty = settings.Difficulty.NORMAL
	settings.chapter = 0
	settings.unlocked = 0
	settings.best_times.fill(0.0)
	game.title_pending = false   # no title screen: straight into the level

	await _test_arena()
	await _test_kinder()
	await _test_chapters()

	if _failures == 0:
		print("ALL CHECKS PASSED")
		quit(0)
	else:
		printerr("%d CHECK(S) FAILED" % _failures)
		quit(1)


func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame


# ---------------------------------------------------------------------------
# Arena (battery collecting)
# ---------------------------------------------------------------------------
func _test_arena() -> void:
	print("Smoke test: arena")
	var main: Node3D = load("res://scenes/arena.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var robot: CharacterBody3D = main.get_node_or_null("Robot")
	_check(robot != null, "robot exists")
	_check(robot.get_node_or_null("Visual") != null, "robot body was built from code")
	_check(main.get_node_or_null("HUD/ScoreLabel") != null, "HUD present")

	var batteries := get_nodes_in_group("battery")
	_check(batteries.size() == main.BATTERY_SPOTS.size(), "%d batteries spawned" % batteries.size())
	_check(game.score == 0, "score starts at 0")

	await _settle(30)
	_check(robot.is_on_floor(), "robot standing on the floor (y=%.2f)" % robot.global_position.y)

	# drive the robot straight onto a battery and check the score goes up
	var target: Node3D = batteries[0]
	robot.global_position = target.global_position + Vector3(0, 0.2, 0)
	await _settle(10)
	_check(game.score == 10, "collected a battery, score = %d" % game.score)

	# simulate a keyboard press and make sure the robot moves
	var before: Vector3 = robot.global_position
	Input.action_press("move_right")
	await _settle(20)
	Input.action_release("move_right")
	_check(robot.global_position.x > before.x + 0.5, "robot moves right when D is held")

	# restart (R) must reset the score and the HUD text
	main.queue_free()
	await process_frame
	main = load("res://scenes/arena.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var label: Label = main.get_node("HUD/ScoreLabel")
	_check(game.score == 0 and label.text == "Score: 0", "restart resets score + HUD (%s)" % label.text)

	main.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# The Abyss (map, doors, buttons, drone, monsters, exit)
# ---------------------------------------------------------------------------
func _test_kinder() -> void:
	print("Smoke test: the abyss")
	var level: Node3D = load("res://scenes/kinder.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame

	var robot: CharacterBody3D = level.get_node("Robot")
	var world: Node3D = level.get_node("World")
	var toys := get_nodes_in_group("battery")
	var monsters := get_nodes_in_group("monster")
	var doors := get_nodes_in_group("door")
	var buttons := get_nodes_in_group("button")
	_check(toys.size() == _count_in_map("T"), "%d toys placed from the map" % toys.size())
	var monster_letters := _count_in_map("M") + _count_in_map("J") + _count_in_map("O")
	_check(monsters.size() == monster_letters, "%d monsters placed from the map" % monsters.size())
	var kinds := {}
	for m in monsters:
		kinds[m.kind] = true
	_check(kinds.size() == 2 and not kinds.has(2), "the tall one and the giant are in the level, the bird is not (%d kinds)" % kinds.size())
	var shares_start := false
	for m in monsters:
		shares_start = shares_start or level.room_at(m.global_position) == level.room_at(robot.global_position)
	_check(not shares_start, "no monster shares the start room with you")
	var tall: CharacterBody3D
	var giant: CharacterBody3D
	for m in monsters:
		var has_audio := false
		for child in m.get_children():
			has_audio = has_audio or child is AudioStreamPlayer3D
		_check(has_audio and m.find_children("*", "OmniLight3D", true, false).size() >= 2,
			"%s has glowing eyes and its own 3D sound" % m.kind_name)
		var top: float = m.model_top()
		_check(top > 2.0 and top < level.wall_height - 0.1, "%s fits under the ceiling (top=%.2f m)" % [m.kind_name, top])
		_check(m._left_knee != null and m._left_knee.get_parent() == m._left_leg, "%s has legs that bend at the knee" % m.kind_name)
		if m.kind == 0:
			tall = m
		elif m.kind == 1:
			giant = m
		m.set_physics_process(false)   # stand still while we test the mechanics; woken up further down
	_check(level.get_node("Audio").get_child_count() >= 5, "level audio has hum, music, footsteps and effects players")
	_check(Sfx.get_sound("chime").data.size() > 1000 and Sfx.get_sound("step0").data.size() > 1000 and Sfx.get_sound("scream").data.size() > 1000,
		"generated sounds have data")
	_check(Sfx.get_sound("click").data.size() > 1000 and Sfx.get_sound("door").data.size() > 1000
		and Sfx.get_sound("snarl").data.size() > 1000 and Sfx.get_sound("whoosh").data.size() > 1000,
		"button, door, snarl and whoosh sounds have data")
	_check(get_nodes_in_group("monster").size() == monsters.size(), "monsters registered")
	var labels := world.find_children("*", "Label3D", true, false)
	_check(labels.size() >= 3, "%d words scrawled on the walls" % labels.size())
	_check(doors.size() == 3 and buttons.size() == 2, "%d doors + %d buttons built" % [doors.size(), buttons.size()])
	var label: Label = level.get_node("HUD/ScoreLabel")
	_check(label.text == "Toys: 0/%d" % toys.size(), "HUD counts toys (%s)" % label.text)

	await _settle(30)
	_check(robot.is_on_floor(), "robot standing on the kinder floor (y=%.2f)" % robot.global_position.y)
	var start: Vector3 = robot.global_position

	# first person: camera sits at eye height on the robot, with a flashlight, in the dark
	var camera: Camera3D = level.get_node("Camera3D")
	var flashlight: SpotLight3D = level.get_node("Camera3D/Flashlight")
	var cam_offset: Vector3 = camera.global_position - robot.global_position
	_check(abs(cam_offset.y - level.eye_height) < 0.2 and Vector2(cam_offset.x, cam_offset.z).length() < 0.1,
		"camera is first person at eye height (%.2f)" % cam_offset.y)
	_check(not robot.get_node("Visual").visible, "your own body is hidden in first person")
	_check(flashlight.visible and flashlight.light_energy > 1.0 and flashlight.spot_range > 5.0, "flashlight is on")
	var environment: Environment = level.get_node("WorldEnvironment").environment
	_check(environment.fog_enabled and environment.ambient_light_energy < 0.3, "level is dark and foggy")
	_check(get_nodes_in_group("lamp").size() == _count_in_map("L"), "%d flickering lamps placed from the map" % get_nodes_in_group("lamp").size())

	# looking around turns you: W walks where the camera looks
	level._look(Vector2(PI / 2.0, 0.0))   # mouse moved right = turn 90 degrees to the right
	await physics_frame
	_check(abs(camera.rotation.y + PI / 2.0) < 0.01, "mouse turns the camera (yaw=%.2f)" % camera.rotation.y)
	var before_turn: Vector3 = robot.global_position
	Input.action_press("move_forward")
	await _settle(20)
	Input.action_release("move_forward")
	var moved: Vector3 = robot.global_position - before_turn
	_check(moved.x > 0.5 and abs(moved.z) < 0.3, "W walks the way you are facing (dx=%.1f dz=%.1f)" % [moved.x, moved.z])
	level._look(Vector2(-PI / 2.0, 0.0))   # face forward again

	# walls block: push into the wall right of the start room for a while, must stay inside
	Input.action_press("move_right")
	await _settle(120)
	Input.action_release("move_right")
	_check(robot.global_position.x < level._tile_pos(0, 19).x - 1.0, "outer wall stops the robot (x=%.1f)" % robot.global_position.x)

	# button a opens door 1
	var door1: StaticBody3D = world.get_node("Door1")
	var button_a: Area3D = world.get_node("Buttona")
	_check(not door1.is_open, "door 1 starts closed")
	robot.global_position = button_a.global_position + Vector3(0, 0.3, 0)
	await _settle(10)
	_check(button_a.is_pressed and door1.is_open, "stepping on button a opens door 1")
	_check(button_a.has_node("ClickSound") and door1.has_node("OpenSound"), "...with a click from the button and a grinding sound from the door")

	# drone: E toggles it on, it can rise, and it presses button c
	var drone: CharacterBody3D = level.get_node("Drone")
	_check(not drone.active and not drone.visible, "drone starts parked")
	Input.action_press("drone")
	await process_frame
	Input.action_release("drone")
	await process_frame
	_check(drone.active and drone.visible and not robot.active, "E hands control to the drone")
	_check(robot.get_node("Visual").visible, "you can see your body while flying the drone")
	_check(not drone._visual.visible, "the drone's own rotors are hidden from its camera")
	var drone_y: float = drone.global_position.y
	Input.action_press("jump")
	await _settle(20)
	Input.action_release("jump")
	_check(drone.global_position.y > drone_y + 0.3 and drone.global_position.y <= drone.max_height + 0.05,
		"drone rises while Space is held (y=%.2f)" % drone.global_position.y)
	var door3: StaticBody3D = world.get_node("Door3")
	var button_c: Area3D = world.get_node("Buttonc")
	drone.global_position = button_c.global_position + Vector3(0, 1.0, 0)
	await _settle(10)
	_check(button_c.is_pressed and door3.is_open, "drone landing on button c opens door 3")
	Input.action_press("drone")
	await process_frame
	Input.action_release("drone")
	await process_frame
	_check(not drone.active and robot.active, "E again goes back to the robot")
	for _i in 3:   # the drone is not one-shot: out and back as often as you like
		Input.action_press("drone")
		await process_frame
		Input.action_release("drone")
		await process_frame
	_check(drone.active and not robot.active, "E keeps working: drone can be used again and again")
	Input.action_press("drone")
	await process_frame
	Input.action_release("drone")
	await process_frame
	_check(not drone.active and robot.active, "...and back to the body once more")

	# monsters know the way: the tall one's path from the left room to you goes round through door 1,
	# and the giant can only come down from the top room now that door 3 is open
	var monster: CharacterBody3D = tall
	var path: PackedVector3Array = level.find_path(monster.global_position, start)
	_check(path.size() > 6, "monster finds a %d-step path around the walls to you" % path.size())
	var down: PackedVector3Array = level.find_path(giant.global_position, start)
	_check(not down.is_empty(), "...and the giant can get out of the top room once door 3 is open")
	level._grid.set_point_solid(level._cell_of(world.get_node("Door3").global_position), true)
	_check(level.find_path(giant.global_position, start).is_empty(), "...but not while it's shut")
	level._grid.set_point_solid(level._cell_of(world.get_node("Door3").global_position), false)

	# ...but every monster is tied to its own room: it can't see, hear or grab you from another one
	var start_room: int = level.room_at(start)
	var tall_room: int = level.room_at(monster.global_position)
	var giant_room: int = level.room_at(giant.global_position)
	_check(start_room >= 0 and tall_room >= 0 and giant_room >= 0 and start_room != tall_room and tall_room != giant_room and start_room != giant_room,
		"start, left and top rooms are different rooms (%d/%d/%d)" % [start_room, tall_room, giant_room])
	_check(level.room_at(world.get_node("Door1").global_position) == -1, "a doorway belongs to no room")
	_check(monster._room == tall_room and giant._room == giant_room, "monsters know which room they live in")
	var spotted := [0]
	game.spotted.connect(func(_by): spotted[0] += 1)
	robot.global_position = start
	monster.global_position = start + Vector3(0, 0.1, 6.0)
	monster._visual.rotation.y = PI   # face towards -z, where the robot is
	monster._cooldown = 100.0          # look, don't grab (for now)
	monster._grace = 0.0               # skip the "just spawned, still sleepy" seconds
	monster.set_physics_process(true)
	await _settle(10)
	_check(not monster.chasing and spotted[0] == 0, "a monster from another room ignores you even when you're right in front of it")
	monster._cooldown = 0.0
	monster.global_position = start + Vector3(0.6, 0.1, 0.0)
	await _settle(5)
	_check(not level._caught and robot.active, "...and can't grab you from outside its room either")
	monster._cooldown = 100.0
	monster.set_physics_process(false)

	# cupboards: climb in and a monster in your room can't see or hear you - unless it watched you do it
	_check(level._cupboards.size() == _count_in_map("H") and level._cupboards.size() >= 3, "%d hiding cupboards placed from the map" % level._cupboards.size())
	var hide_cell := Vector2i(-1, -1)
	for cell in level._cupboards.keys():
		if level.room_at(level._tile_pos(cell.y, cell.x)) == start_room:
			hide_cell = cell
	_check(hide_cell.x >= 0, "there is a cupboard in the start room")
	var facing: Vector3 = level._cupboards[hide_cell]
	var hide_pos: Vector3 = level._tile_pos(hide_cell.y, hide_cell.x) - facing * 0.4 + Vector3(0, 0.1, 0)
	_check(level.is_hidden(hide_pos) and not level.is_hidden(start) and not level.is_hidden(hide_pos + facing * 1.5),
		"inside the cupboard counts as hidden, the tile in front of it doesn't")
	_check(level.find_path(start, hide_pos).size() > 0, "monsters can still path up to a cupboard (they stop beside it)")
	monster._room = start_room
	monster._home = hide_pos + facing * 3.5
	monster.global_position = monster._home
	monster._visual.rotation.y = atan2(-facing.x, -facing.z)   # staring straight at the open cupboard
	monster._target = monster.global_position
	monster._idle_for = 60.0   # ...and standing still, having a look around
	monster._cooldown = 100.0
	var seen_before: int = spotted[0]
	robot.global_position = hide_pos
	monster.set_physics_process(true)
	await _settle(15)
	_check(level.hiding and not monster.chasing and spotted[0] == seen_before, "hidden in a cupboard 3.5 m in front of it: it doesn't see you")
	monster._visual.rotation.y = atan2(-facing.x, -facing.z)
	robot.global_position = hide_pos + facing * 1.5
	await _settle(10)
	_check(monster.chasing and spotted[0] > seen_before, "step out of it: seen")
	robot.global_position = hide_pos
	await _settle(2)
	_check(monster._busted and monster._can_see(robot), "...and diving back in while it's right there doesn't save you")
	robot.global_position = start
	monster.chasing = false
	monster._hunt_timer = 0.0
	monster._search_timer = 0.0
	monster._visual.rotation.y = PI
	await _settle(4)
	monster.set_physics_process(false)
	_check(not level.hiding and not monster._busted, "out of the cupboard: not hiding any more")

	# ...but lose it right next to a cupboard and it comes over to look inside
	var near_front: Dictionary = level.nearest_cupboard(hide_pos + facing * 1.0, 3.5)
	_check(not near_front.is_empty() and near_front["cell"] == hide_cell and level.cupboard_at(hide_pos) == hide_cell
		and level.cupboard_at(start) == Vector2i(-1, -1), "the level knows which cupboard is nearest / which one you're in")
	var none_ok := func(_front: Vector3) -> bool: return false
	_check(level.nearest_cupboard(hide_pos, 3.5, none_ok).is_empty(), "nearest_cupboard skips cupboards the caller rejects")
	var found := [0]
	game.found.connect(func(_by): found[0] += 1)
	monster._home = hide_pos + facing * 7.0
	monster.global_position = monster._home
	monster._visual.rotation.y = atan2(-facing.x, -facing.z)
	monster._target = monster.global_position
	monster._idle_for = 60.0
	robot.global_position = hide_pos + facing * 1.0   # standing right in front of the open doors
	monster.set_physics_process(true)
	await _settle(10)
	_check(monster.chasing and not monster._busted, "it sees you from 6 m, in front of the cupboard")
	robot.global_position = hide_pos   # ...you dive in - too far away for it to have 'watched' you
	await _settle(3)
	_check(level.hiding and not monster._busted and not monster._can_see(robot), "you're hidden and it can't see you...")
	await _settle(50)
	var swing: float = level._door_swing.get(hide_cell, 0.0)
	_check(swing > 0.5 and absf(level._cupboard_doors[hide_cell][0].rotation.y) < 0.6, "the cupboard doors creak shut behind you (%.2f)" % swing)
	var found_after := 50
	for _i in 40:
		await _settle(10)
		if found[0] > 0:
			break
		found_after += 10
	_check(not monster._check.is_empty() or monster._peek_timer > 0.0 or found[0] > 0, "...so it walks over to the cupboard to look inside")
	_check(found[0] == 1 and monster._busted and monster._can_see(robot), "...and finds you (after %d frames): FOUND YOU, and it can attack you in there" % found_after)
	_check(level._flung.get(hide_cell, 0.0) > 0.0 and level._door_swing[hide_cell] < 0.5, "it flung the doors open to look")
	robot.global_position = start
	monster.chasing = false
	monster._hunt_timer = 0.0
	monster._search_timer = 0.0
	monster._check = {}
	monster._peek_timer = 0.0
	monster._visual.rotation.y = PI
	await _settle(2)
	monster.set_physics_process(false)
	# on EASY they never check cupboards
	settings.set_difficulty(settings.Difficulty.EASY)
	_check(monster.check_cupboard_range == 0.0 and monster.hide_catch_range < 4.0, "EASY: monsters never check cupboards and need to be closer to bust you")
	settings.set_difficulty(settings.Difficulty.NORMAL)
	_check(is_equal_approx(monster.check_cupboard_range, 3.5), "NORMAL: cupboard checks back on")
	await _settle(60)
	_check(level._door_swing[hide_cell] < 0.05, "back out in the open: the doors hang open again")

	# F: flashlight off - and the room is nearly black
	var torch: SpotLight3D = level.flashlight
	level.flashlight_on = false
	await _settle(2)
	_check(torch.light_energy == 0.0, "flashlight off")
	level.flashlight_on = true
	await _settle(2)
	_check(torch.light_energy == level.flashlight_energy, "flashlight back on")
	_check(level.env.environment.ambient_light_energy < 0.1, "ambient light is almost nothing (%.2f)" % level.env.environment.ambient_light_energy)

	# a monster from YOUR room seeing you: bloody letters + red edges + a scream, and it comes for you
	monster._room = start_room
	monster._home = start + Vector3(0, 0.1, 6.0)
	monster.global_position = monster._home
	monster._visual.rotation.y = PI
	monster.set_physics_process(true)
	await _settle(10)
	var blood: Control = level.get_node("HUD/BloodText")
	var vignette: ColorRect = level.get_node("HUD/Vignette")
	_check(monster.chasing and spotted[0] >= 1, "monster spots you and starts hunting")
	_check(blood._text != "" and blood._letters.size() > 0, "bloody letters on screen: '%s'" % blood._text)
	_check(blood._text.contains("BANBO") or not blood._text.contains("IT "), "the letters use its name, not 'it'")
	var leg_before: float = monster._left_leg.rotation.x
	await _settle(30)
	_check(vignette.material.get_shader_parameter("strength") > 0.1, "red creeps in from the screen edges while hunted")
	_check(monster.global_position.distance_to(robot.global_position) < 5.0, "...and it closes in (%.1fm away)" % monster.global_position.distance_to(robot.global_position))
	_check(absf(monster._left_leg.rotation.x - leg_before) > 0.05 or absf(monster._left_leg.rotation.x) > 0.1, "its legs swing as it walks (hip=%.2f)" % monster._left_leg.rotation.x)
	_check(monster._stride_phase > 1.0, "the walk cycle follows the distance it really moved (phase=%.1f)" % monster._stride_phase)

	# collect one toy so we can see the restart wipe it
	robot.global_position = toys[0].global_position
	await _settle(5)
	_check(game.collected == 1, "one toy collected before dying")

	# touching a monster is not death: it has to WIND UP and SWING, and you can dodge it
	var missed := [0]
	game.missed.connect(func(_by): missed[0] += 1)
	monster._cooldown = 0.0
	monster._room = -1   # let it roam anywhere for this bit
	monster.chasing = true
	monster._hunt_timer = 10.0
	monster.global_position = robot.global_position + Vector3(0, 0, 1.6)
	monster._visual.rotation.y = PI   # facing the robot
	await _settle(3)
	_check(monster.attack == monster.Attack.WINDUP and not level._caught, "in reach: it winds up (arms go high) instead of grabbing you on touch")
	await _settle(8)
	_check(monster._left_arm.rotation.x < -1.5 and not level._caught, "arms are up over its head during the wind-up (%.2f)" % monster._left_arm.rotation.x)
	# while winding up it keeps turning to face you...
	robot.global_position += Vector3(1.5, 0, 0)
	var frames := 0
	while monster._attack_timer > monster.commit_before and monster.attack == monster.Attack.WINDUP and frames < 60:
		await physics_frame
		frames += 1
	var to_robot := (robot.global_position - monster.global_position)
	to_robot.y = 0.0
	_check(monster.attack == monster.Attack.WINDUP and monster._facing().dot(to_robot.normalized()) > 0.9, "it turns to face you during the wind-up (dot=%.2f)" % monster._facing().dot(to_robot.normalized()))
	# ...until it commits: from here the lane is fixed - so a real sidestep now still gets you out
	var lane: Vector3 = monster._facing()
	var side := Vector3(lane.z, 0, -lane.x)
	robot.global_position += side * 4.0
	frames = 0
	while monster.attack != monster.Attack.RECOVER and frames < 120:
		await physics_frame
		frames += 1
	_check(monster._strike_dir.dot(lane) > 0.99, "it did NOT turn after committing (swung where you were)")
	_check(monster.attack == monster.Attack.RECOVER and not level._caught, "it swings and MISSES when you've moved out of the lane")
	_check(missed[0] == 1 and blood._text.contains("MISSED") and blood._text.contains("BANBO"), "'BANBO MISSED YOU' in blood (%s)" % blood._text)
	frames = 0
	while monster.attack != monster.Attack.NONE and frames < 200:
		await physics_frame
		frames += 1
	_check(monster.attack == monster.Attack.NONE and frames > 20, "...and it is stuck recovering for a moment (%d frames)" % frames)

	# get out of its room while it's winding up: the swing lands on nothing and you don't even feel it
	robot.global_position = start   # back in the open (the sidestep can end inside a cupboard)
	monster._cooldown = 0.0
	monster.chasing = true
	monster._hunt_timer = 10.0
	monster.global_position = robot.global_position + Vector3(0, 0, 1.6)
	monster._visual.rotation.y = PI
	await _settle(3)
	_check(monster.attack == monster.Attack.WINDUP, "winding up again")
	monster._room = 999   # you are now in "another room" as far as it's concerned
	frames = 0
	while monster.attack == monster.Attack.WINDUP or monster.attack == monster.Attack.STRIKE:
		await physics_frame
		frames += 1
		if frames > 120:
			break
	_check(missed[0] == 1 and not level._caught, "no 'MISSED YOU' jolt when you've already left its room (misses=%d)" % missed[0])
	frames = 0
	while monster.attack != monster.Attack.NONE and frames < 200:
		await physics_frame
		frames += 1
	monster._room = -1

	# a half-hearted shuffle (less than swing_width to the side) is not a dodge: the swing lands,
	# jump-scare (frozen, screen goes dark), then the LEVEL RESTARTS
	monster._cooldown = 0.0
	monster.chasing = true
	monster._hunt_timer = 10.0
	monster.global_position = robot.global_position + Vector3(0, 0, 1.6)
	monster._visual.rotation.y = PI
	frames = 0
	while monster.attack != monster.Attack.STRIKE and frames < 60:
		await physics_frame
		frames += 1
	robot.global_position += Vector3(monster.swing_width * 0.5, 0, 0)
	frames = 0
	while not level._caught and frames < 120:
		await physics_frame
		frames += 1
	await _settle(3)
	var fade: ColorRect = level.get_node("HUD/Fade")
	_check(level._caught and not robot.active and fade.modulate.a > 0.1, "stay put and the swing lands: frozen + screen flashes")
	_check(blood._text.contains("BANBO") and blood._text.contains("GOT YOU"), "'BANBO GOT YOU' in blood (%s)" % blood._text)
	await create_timer(3.0).timeout
	await _settle(5)
	_check(not is_instance_valid(level) or level.is_queued_for_deletion(), "...then the old level is thrown away")
	level = null
	for child in root.get_children():
		if child.has_method("find_path") and not child.is_queued_for_deletion():
			level = child
	_check(level != null, "...and a fresh one starts")
	await _settle(30)
	robot = level.get_node("Robot")
	world = level.get_node("World")
	toys = get_nodes_in_group("battery")
	_check(game.collected == 0 and toys.size() == _count_in_map("T"), "restart: toys back to 0/%d" % toys.size())
	_check(robot.global_position.distance_to(start) < 1.0 and robot.active and not level._caught, "restart: you're back at the start and can move")
	for m in get_nodes_in_group("monster"):
		m.set_physics_process(false)   # nobody grabs us while we teleport round the toys

	# collect every toy -> exit opens; walk out -> escaped
	var exit_door: StaticBody3D = world.get_node("ExitDoor")
	_check(not exit_door.is_open, "exit starts closed")
	for toy in toys:
		robot.global_position = toy.global_position
		await _settle(3)
	await _settle(5)
	_check(game.collected == toys.size(), "all %d toys collected" % game.collected)
	_check(exit_door.is_open and exit_door.has_node("ExitBeacon"), "exit door opens and glows when every toy is found")
	robot.global_position = exit_door.global_position + Vector3(0, 0.1, -3.0)
	await process_frame
	await process_frame
	_check(level._escaped and not robot.active, "walking out through the exit counts as escaping and stops you")
	await create_timer(4.5).timeout
	var after_escape: Node = null
	for child in root.get_children():
		if child.has_method("find_path"):
			after_escape = child
	_check(after_escape != null and after_escape != level and game.collected == 0, "escaping starts a fresh level")
	_check(settings.escapes == 1 and settings.best_time > 0.0 and settings.best_times[0] > 0.0,
		"escape recorded: %d escape(s), best %s, chapter 1 best %s" % [settings.escapes, settings.fmt_time(settings.best_time), settings.fmt_time(settings.best_times[0])])
	_check(settings.unlocked == 1 and settings.chapter == 1 and after_escape != null and after_escape.chapter == 1,
		"escaping chapter 1 unlocks chapter 2 and the fresh level IS chapter 2 (%s)" % Chapters.title(after_escape.chapter if after_escape else 0))
	_check(game.last_result.contains("CHAPTER 2 UNLOCKED") or (after_escape and after_escape.get_node("Menu")._result.text.contains("CHAPTER 2 UNLOCKED")),
		"the result screen says which chapter you unlocked")
	if after_escape:
		var leftover: Node = await _test_menus(after_escape)
		if is_instance_valid(leftover):
			leftover.queue_free()
	await process_frame


## Title screen after an escape, PLAY, Esc pause menu, difficulty changing monsters live,
## QUIT TO TITLE. Returns whichever level node is left standing at the end.
func _test_menus(level: Node3D) -> Node:
	var menu: CanvasLayer = level.get_node("Menu")
	var hud: CanvasLayer = level.get_node("HUD")
	await process_frame
	_check(menu.mode == menu.Mode.TITLE and paused, "after escaping, the title screen is up and the level is frozen")
	_check(menu._result.visible and menu._result.text.begins_with("CHAPTER 1 ESCAPED in"), "title shows your time: '%s'" % menu._result.text.get_slice("\n", 0))
	_check(not level._playing and not hud.ticking, "clock isn't running on the title screen")
	var tries: int = settings.attempts
	menu._on_play()
	await process_frame
	_check(menu.mode == menu.Mode.HIDDEN and not paused and level._playing and hud.ticking, "PLAY: menu gone, level running, clock ticking")
	_check(settings.attempts == tries + 1, "PLAY counts as a try (%d)" % settings.attempts)

	var monster: CharacterBody3D = get_nodes_in_group("monster")[0]
	var normal_windup: float = monster.windup_time
	var normal_speed: float = monster.chase_speed
	menu.show_pause()
	await process_frame
	_check(menu.mode == menu.Mode.PAUSED and paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause menu freezes the game and frees the mouse")
	settings.set_difficulty(settings.Difficulty.EASY)
	_check(monster.windup_time > normal_windup * 1.2 and monster.chase_speed < normal_speed, "EASY: longer wind-up (%.2fs), slower chase (%.1f)" % [monster.windup_time, monster.chase_speed])
	settings.set_difficulty(settings.Difficulty.NIGHTMARE)
	_check(monster.windup_time < normal_windup and monster.chase_speed > normal_speed, "NIGHTMARE: shorter wind-up (%.2fs), faster chase (%.1f)" % [monster.windup_time, monster.chase_speed])
	settings.set_difficulty(settings.Difficulty.NORMAL)
	_check(is_equal_approx(monster.windup_time, normal_windup), "back to NORMAL restores the numbers exactly")
	menu._on_play()
	await process_frame
	_check(menu.mode == menu.Mode.HIDDEN and not paused, "RESUME unfreezes the game")

	# R is not a restart key any more (RESTART is only in the pause menu)
	var tries_before: int = settings.attempts
	Input.action_press("restart")
	await physics_frame
	await physics_frame
	Input.action_release("restart")
	await _settle(5)
	_check(is_instance_valid(level) and not level.is_queued_for_deletion() and settings.attempts == tries_before,
		"pressing R does nothing (same level, still try #%d)" % settings.attempts)

	# QUIT in the pause menu goes back to the title screen (same chapter), not out of the game
	var chapter_before: int = level.chapter
	menu.show_pause()
	await process_frame
	_check(menu._quit.text == "QUIT TO TITLE" and menu._quit.visible, "pause menu offers QUIT TO TITLE")
	menu._on_quit()
	await _settle(5)
	var after_quit: Node = null
	for child in root.get_children():
		if child.has_method("find_path") and child != level:
			after_quit = child
	_check(after_quit != null and (not is_instance_valid(level) or level.is_queued_for_deletion()),
		"QUIT TO TITLE tears the run down and builds a fresh level")
	if after_quit == null:
		return level
	await process_frame
	var fresh_menu: CanvasLayer = after_quit.get_node("Menu")
	_check(fresh_menu.mode == fresh_menu.Mode.TITLE and paused and not after_quit._playing,
		"...and the title screen is up with the level frozen behind it")
	_check(after_quit.chapter == chapter_before and fresh_menu._quit.text == "QUIT" and not fresh_menu._result.visible,
		"same chapter (%s), QUIT now means quit the game, no stale result text" % Chapters.title(after_quit.chapter))
	return after_quit


func _count_in_map(ch: String, chapter := 0) -> int:
	var n := 0
	for row: String in Chapters.get_chapter(chapter)["map"]:
		n += row.count(ch)
	return n


# ---------------------------------------------------------------------------
# Chapters 1-8: maps, unlocking, escalation, playground night, the lab
# ---------------------------------------------------------------------------
const SYMBOLS := "#W.PTMJOL=XH123456789abcdefghiSZ^t"

func _test_chapters() -> void:
	print("Smoke test: chapters 1-8")
	_check(Chapters.count() == 8, "there are %d chapters" % Chapters.count())
	var names: Array[String] = []
	for i in Chapters.count():
		names.append(Chapters.get_chapter(i)["name"])
	_check(names == ["CLASSROOM", "HALLWAY", "LIBRARY", "LUNCHROOM", "GYM", "ART ROOM", "PLAYGROUND", "THE ABYSS"], "chapter order: %s" % ", ".join(names))
	_check(Chapters.title(0) == "CHAPTER 1  ·  CLASSROOM" and Chapters.title(7).begins_with("CHAPTER 8"), "they're called chapters: '%s'" % Chapters.title(7))

	var prev_scale := 0.0
	var prev_puzzle := 0
	var prev_toys := 0
	var timed_chapters := 0
	for i in Chapters.count():
		var def: Dictionary = Chapters.get_chapter(i)
		var map: Array = def["map"]
		var width: int = map[0].length()
		var rect := true
		var bad := ""
		var p := 0
		var x := 0
		var doors := {}
		var buttons := {}
		for row: String in map:
			rect = rect and row.length() == width
			for ch in row:
				if not SYMBOLS.contains(ch):
					bad += ch
				if ch >= "1" and ch <= "9":
					doors[ch] = true
				elif ch >= "a" and ch <= "i":
					buttons[str(ch.unicode_at(0) - "a".unicode_at(0) + 1)] = true
			p += row.count("P")
			x += row.count("X")
		_check(rect and map.size() >= 12 and width >= 16, "%s: map is a %dx%d rectangle" % [def["name"], width, map.size()])
		_check(bad == "", "%s: only known map symbols%s" % [def["name"], "" if bad == "" else " (bad: %s)" % bad])
		_check(p == 1 and x == 1, "%s: one start, one exit" % def["name"])
		_check(doors.keys() == buttons.keys() or (doors.size() == buttons.size() and doors.keys().all(func(k: String) -> bool: return buttons.has(k))),
			"%s: every door has a button and every button a door (%s)" % [def["name"], "".join(doors.keys())])
		var puzzle: int = doors.size() + def.get("timed", {}).size()
		_check(puzzle >= prev_puzzle, "%s: %d door puzzles%s (no easier than the chapter before)" % [def["name"], doors.size(), "" if def.get("timed", {}).is_empty() else " incl. %d timed" % def["timed"].size()])
		_check(Chapters.toy_count(i) >= prev_toys, "%s: %d toys" % [def["name"], Chapters.toy_count(i)])
		_check(def["monster_scale"] >= prev_scale and def["hunt"] >= 1.0, "%s: creatures x%.2f, hunt x%.2f" % [def["name"], def["monster_scale"], def["hunt"]])
		if not def.get("timed", {}).is_empty():
			timed_chapters += 1
		prev_scale = def["monster_scale"]
		prev_puzzle = puzzle
		prev_toys = Chapters.toy_count(i)
	_check(timed_chapters >= 4 and Chapters.get_chapter(0).get("timed", {}).is_empty(), "%d chapters have timed doors, chapter 1 has none" % timed_chapters)
	_check(Chapters.get_chapter(7)["monster_scale"] > Chapters.get_chapter(6)["monster_scale"] and Chapters.get_chapter(6)["monster_scale"] > 1.2,
		"the playground has bigger creatures (x%.2f) and the lab the biggest (x%.2f)" % [Chapters.get_chapter(6)["monster_scale"], Chapters.get_chapter(7)["monster_scale"]])

	# locked chapters can't be picked
	settings.unlocked = 0
	settings.chapter = 0
	_check(not settings.set_chapter(3) and settings.chapter == 0 and not settings.is_unlocked(1), "a locked chapter can't be picked")
	settings.record_escape(0, 60.0)
	_check(settings.unlocked == 1 and settings.set_chapter(1) and settings.chapter == 1, "escaping chapter 1 unlocks chapter 2 and it can be picked")
	settings.record_escape(7, 60.0)
	_check(settings.unlocked == 7, "escaping the last chapter doesn't unlock a 9th (%d)" % (settings.unlocked + 1))

	# build every chapter for real
	settings.unlocked = 7
	var chapter1_top := 0.0
	for i in Chapters.count():
		settings.chapter = i
		var def: Dictionary = Chapters.get_chapter(i)
		var level: Node3D = load("res://scenes/kinder.tscn").instantiate()
		root.add_child(level)
		await process_frame
		await physics_frame
		var robot: CharacterBody3D = level.get_node("Robot")
		var world: Node3D = level.get_node("World")
		var toys := get_nodes_in_group("battery")
		var monsters := get_nodes_in_group("monster")
		var doors := get_nodes_in_group("door")
		var buttons := get_nodes_in_group("button")
		var title: String = Chapters.title(i)
		_check(level.chapter == i and level.hud.subtitle == title.to_lower(), "%s: built, HUD says '%s'" % [def["name"], level.hud.subtitle])
		_check(toys.size() == _count_in_map("T", i) and toys.size() == Chapters.toy_count(i), "%s: %d toys from the map" % [def["name"], toys.size()])
		var letters := _count_in_map("M", i) + _count_in_map("J", i) + _count_in_map("O", i)
		_check(monsters.size() == letters and monsters.size() >= 2, "%s: %d creatures from the map" % [def["name"], monsters.size()])
		var door_letters := 0
		var button_letters := 0
		for row: String in def["map"]:
			for ch in row:
				if ch >= "1" and ch <= "9":
					door_letters += 1
				elif ch >= "a" and ch <= "i":
					button_letters += 1
		_check(doors.size() == door_letters + 1 and buttons.size() == button_letters, "%s: %d doors (+exit) and %d buttons built" % [def["name"], door_letters, buttons.size()])
		var shares_start := false
		for m in monsters:
			shares_start = shares_start or level.room_at(m.global_position) == level.room_at(robot.global_position)
			m.set_physics_process(false)
		_check(not shares_start, "%s: no creature in your start room" % def["name"])
		_check(level.get_node("HUD/ScoreLabel").text == "Toys: 0/%d" % toys.size(), "%s: HUD counts %d toys" % [def["name"], toys.size()])
		await _settle(20)
		_check(robot.is_on_floor() and robot.global_position.y > -0.5, "%s: you're standing on the floor" % def["name"])

		# size: chapter 1 is the baseline, everything else is at least as big, indoors under the ceiling
		var top: float = monsters[0].model_top()
		if i == 0:
			chapter1_top = top
		var ceiling_ok := true
		for m in monsters:
			if not level.outdoors:
				ceiling_ok = ceiling_ok and m.model_top() < level.wall_height - 0.1
		_check(ceiling_ok and top >= chapter1_top - 0.01, "%s: creature top %.2f m (ceiling %s)" % [def["name"], top, "none" if level.outdoors else "%.1f m" % level.wall_height])
		_check(is_equal_approx(monsters[0].size, def["monster_scale"]), "%s: creatures are x%.2f" % [def["name"], monsters[0].size])

		var environment: Environment = level.get_node("WorldEnvironment").environment
		if def["theme"] == "playground":
			var ceilings := 0
			for child in world.get_children():
				if child is MeshInstance3D and child.position.y > 2.5 and child.position.y < 3.5 and (child.mesh as BoxMesh) and (child.mesh as BoxMesh).size.x > 20.0:
					ceilings += 1
			_check(level.outdoors and ceilings == 0, "PLAYGROUND: outdoors, no ceiling")
			_check(environment.background_mode == Environment.BG_SKY and environment.sky != null and world.has_node("Moon"), "PLAYGROUND: night sky with a moon")
			_check(environment.ambient_light_energy <= 0.12, "PLAYGROUND: it's night (ambient %.2f)" % environment.ambient_light_energy)
			_check(world.find_children("Tree*", "Node3D", false, false).size() >= 3 and world.find_children("Swings*", "Node3D", false, false).size() >= 1
				and world.find_children("Slide*", "Node3D", false, false).size() >= 1, "PLAYGROUND: trees, swings and a slide")
			_check(top > chapter1_top * 1.2, "PLAYGROUND: creatures really are bigger (%.2f m vs %.2f m in chapter 1)" % [top, chapter1_top])
		else:
			_check(not level.outdoors, "%s: indoors" % def["name"])
		if def["theme"] == "lab":
			_check(level.wall_height > 4.0 and world.find_children("Tank*", "Node3D", false, false).size() >= 3, "THE ABYSS: a tall lab with %d containment tanks" % world.find_children("Tank*", "Node3D", false, false).size())
			var words := ""
			for l in world.find_children("*", "Label3D", true, false):
				words += (l as Label3D).text + " | "
			_check(words.to_lower().contains("tank") or words.to_lower().contains("lab") or words.to_lower().contains("subject") or words.to_lower().contains("made"), "THE ABYSS: the walls tell you the experiment went wrong")
			_check(top > chapter1_top * 1.4, "THE ABYSS: the biggest creatures (%.2f m)" % top)

		# timed doors: press the button, the door opens, the timer runs out, it slams shut and is solid again
		var timed: Dictionary = def.get("timed", {})
		if not timed.is_empty():
			var key: String = timed.keys()[0]
			var door: StaticBody3D = level._doors[key][0]
			var cell := Vector2i(-1, -1)
			for r in def["map"].size():
				var c: int = def["map"][r].find(key)
				if c >= 0 and cell.x < 0:
					cell = Vector2i(c, r)
			_check(door.close_after == float(timed[key]) and not door.is_open, "%s: door %s is timed (%.0fs) and starts shut" % [def["name"], key, door.close_after])
			level._on_button_pressed(key)
			await _settle(2)
			_check(door.is_open and not level._grid.is_point_solid(cell) and level.door_time_left(door) > 0.0, "%s: button opens it and the countdown starts (%.1fs)" % [def["name"], level.door_time_left(door)])
			level._door_timers[door] = 0.01
			await _settle(3)
			_check(not door.is_open and level._grid.is_point_solid(cell) and level.door_time_left(door) == 0.0, "%s: ...then it slams shut and is solid again" % def["name"])
			level._on_button_pressed(key)
			await _settle(2)
			_check(door.is_open, "%s: pressing the button again re-opens it" % def["name"])
			robot.global_position = door.global_position + Vector3(0, 0.1, 0)
			level._door_timers[door] = 0.01
			await _settle(3)
			_check(door.is_open and level.door_time_left(door) > 0.0, "%s: it won't slam shut on you while you're in the doorway" % def["name"])

		level.queue_free()
		await process_frame
		await process_frame
	settings.chapter = 0
	settings.unlocked = 0
