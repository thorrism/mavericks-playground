extends Node3D
## The level. Places batteries, follows the player with the camera.

@export var camera_offset := Vector3(0.0, 7.5, 9.5)
@export var camera_follow_speed := 5.0

@onready var robot: CharacterBody3D = $Robot
@onready var camera: Camera3D = $Camera3D

const BATTERY_SCENE := preload("res://scenes/battery.tscn")

# Where the batteries go. Add more Vector3s to add more batteries!
const BATTERY_SPOTS: Array[Vector3] = [
	Vector3(4, 1, 4),
	Vector3(-4, 1, 4),
	Vector3(4, 1, -4),
	Vector3(-4, 1, -4),
	Vector3(0, 1, 8),
	Vector3(0, 1, -8),
	Vector3(8, 1, 0),
	Vector3(-8, 1, 0),
	Vector3(-9, 3.2, -9),   # on top of the tall block
	Vector3(9, 2.9, 13),    # top of the ramp
]


func _ready() -> void:
	Game.reset_level(BATTERY_SPOTS.size())
	for i in BATTERY_SPOTS.size():
		var battery := BATTERY_SCENE.instantiate()
		battery.name = "Battery%d" % (i + 1)
		battery.position = BATTERY_SPOTS[i]
		add_child(battery)
	camera.position = robot.position + camera_offset
	camera.look_at(robot.position)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	var target := robot.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target, camera_follow_speed * delta)
	camera.look_at(robot.global_position + Vector3.UP * 0.5)
