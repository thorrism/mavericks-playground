extends SceneTree
## Headless smoke test. Run with:  make test
## Loads both levels, drives the robot around, and checks the rules work.

var _failures := 0
var game: Node


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

	await _test_arena()
	await _test_kinder()

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
# Kinder Escape (map, doors, buttons, drone, monsters, exit)
# ---------------------------------------------------------------------------
func _test_kinder() -> void:
	print("Smoke test: kinder escape")
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
	_check(monsters.size() == _count_in_map("M"), "%d monsters placed from the map" % monsters.size())
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

	# drone: E toggles it on, it can rise, and it presses button c
	var drone: CharacterBody3D = level.get_node("Drone")
	_check(not drone.active and not drone.visible, "drone starts parked")
	Input.action_press("drone")
	await process_frame
	Input.action_release("drone")
	await process_frame
	_check(drone.active and drone.visible and not robot.active, "E hands control to the drone")
	_check(robot.get_node("Visual").visible, "you can see your body while flying the drone")
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

	# a monster catching the robot: jump-scare (frozen, screen goes dark), then wake up at the start
	robot.global_position = start + Vector3(6, 0.1, 0)
	var monster: CharacterBody3D = monsters[0]
	monster.global_position = robot.global_position + Vector3(0.5, 0, 0)
	await _settle(5)
	var fade: ColorRect = level.get_node("HUD/Fade")
	_check(level._caught and not robot.active and fade.modulate.a > 0.1, "monster grabs you: frozen + screen flashes")
	await create_timer(3.5).timeout
	await _settle(5)
	_check(robot.global_position.distance_to(start) < 1.0, "...then you wake up back at the start")
	_check(not level._caught and robot.active and fade.modulate.a < 0.05, "...and can move again")

	# collect every toy -> exit opens; walk out -> escaped
	var exit_door: StaticBody3D = world.get_node("ExitDoor")
	_check(not exit_door.is_open, "exit starts closed")
	for toy in toys:
		robot.global_position = toy.global_position
		await _settle(3)
	await _settle(5)
	_check(game.collected == toys.size(), "all %d toys collected" % game.collected)
	_check(exit_door.is_open, "exit door opens when every toy is found")
	robot.global_position = exit_door.global_position + Vector3(0, 0.1, -3.0)
	await process_frame
	await process_frame
	_check(level._escaped, "walking out through the exit counts as escaping")

	level.queue_free()
	await process_frame


func _count_in_map(ch: String) -> int:
	var n := 0
	for row in load("res://scripts/kinder.gd").MAP:
		n += row.count(ch)
	return n
