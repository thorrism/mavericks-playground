extends Area3D
## A spinning battery the robot can collect. Touch it = points!

@export var points := 10
@export var spin_speed := 2.0
@export var bob_height := 0.2

var _start_y := 0.0
var _time := 0.0


func _ready() -> void:
	_start_y = position.y
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _start_y + sin(_time * 3.0) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Game.add_score(points)
		_pop()


func _pop() -> void:
	# stop being collectable, then shrink away
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
