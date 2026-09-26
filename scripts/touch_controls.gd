class_name TouchControls
extends CanvasLayer
## On-screen joystick + jump button for iPhone/iPad.
## Hidden automatically on Mac (keyboard), shown on touch screens.
## The robot reads input through the static helpers at the bottom.

@export var joystick_radius := 90.0

static var _instance: TouchControls

var _joy_base: Control
var _joy_knob: Control
var _joy_touch_index := -1
var _joy_vector := Vector2.ZERO
var _jump_queued := false
var _jump_held := false
var _drone_queued := false


func _ready() -> void:
	_instance = self
	_joy_base = $Joystick
	_joy_knob = $Joystick/Knob
	# run with `godot -- --touch` to try the touch controls on a Mac
	visible = OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()
	$JumpButton.button_down.connect(func(): _jump_queued = true; _jump_held = true)
	$JumpButton.button_up.connect(func(): _jump_held = false)
	if has_node("DroneButton"):
		$DroneButton.pressed.connect(func(): _drone_queued = true)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _joy_touch_index == -1 and _joy_base.get_global_rect().grow(60).has_point(event.position):
			_joy_touch_index = event.index
			_update_joystick(event.position)
		elif not event.pressed and event.index == _joy_touch_index:
			_joy_touch_index = -1
			_joy_vector = Vector2.ZERO
			_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0
	elif event is InputEventScreenDrag and event.index == _joy_touch_index:
		_update_joystick(event.position)


func _update_joystick(touch_pos: Vector2) -> void:
	var center := _joy_base.get_global_rect().get_center()
	var offset := touch_pos - center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	_joy_vector = offset / joystick_radius
	_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0 + offset


static func direction() -> Vector2:
	return _instance._joy_vector if _instance else Vector2.ZERO


## Returns true once per tap of the jump button.
static func jump_just_pressed() -> bool:
	if _instance and _instance._jump_queued:
		_instance._jump_queued = false
		return true
	return false


## True while the jump button is being held down (the drone uses this to rise).
static func jump_held() -> bool:
	return _instance != null and _instance._jump_held


## Returns true once per tap of the DRONE button.
static func drone_just_pressed() -> bool:
	if _instance and _instance._drone_queued:
		_instance._drone_queued = false
		return true
	return false
