extends SceneTree
## Headless smoke test. Run with:  make test
## Loads the level, moves the robot, collects a battery, checks the score.

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
	print("Smoke test: loading main scene")
	game = root.get_node_or_null("Game")
	if game == null:
		game = load("res://scripts/game.gd").new()
		game.name = "Game"
		root.add_child(game)
	var main: Node3D = load("res://scenes/main.tscn").instantiate()
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

	# let the robot settle on the floor
	for i in 30:
		await physics_frame
	_check(robot.is_on_floor(), "robot standing on the floor (y=%.2f)" % robot.global_position.y)

	# drive the robot straight onto a battery and check the score goes up
	var target: Node3D = batteries[0]
	robot.global_position = target.global_position + Vector3(0, 0.2, 0)
	for i in 10:
		await physics_frame
	_check(game.score == 10, "collected a battery, score = %d" % game.score)

	# simulate a keyboard press and make sure the robot moves
	var before: Vector3 = robot.global_position
	Input.action_press("move_right")
	for i in 20:
		await physics_frame
	Input.action_release("move_right")
	_check(robot.global_position.x > before.x + 0.5, "robot moves right when D is held")

	if _failures == 0:
		print("ALL CHECKS PASSED")
		quit(0)
	else:
		printerr("%d CHECK(S) FAILED" % _failures)
		quit(1)
