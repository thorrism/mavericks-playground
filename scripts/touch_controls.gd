class_name TouchControls
extends CanvasLayer
## On-screen joystick + jump/drone buttons for iPhone/iPad. Dragging a finger
## anywhere else on the screen looks around (first-person levels).
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
var _look_touch_index := -1
var _look_delta := Vector2.ZERO


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
		elif event.pressed and _look_touch_index == -1 and not _over_button(event.position):
			_look_touch_index = event.index
		elif not event.pressed and event.index == _joy_touch_index:
			_joy_touch_index = -1
			_joy_vector = Vector2.ZERO
			_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0
		elif not event.pressed and event.index == _look_touch_index:
			_look_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _joy_touch_index:
		_update_joystick(event.position)
	elif event is InputEventScreenDrag and event.index == _look_touch_index:
		_look_delta += event.relative


## Forget every finger currently on the screen (called when a menu takes over the input).
static func release_all() -> void:
	if _instance == null:
		return
	_instance._joy_touch_index = -1
	_instance._joy_vector = Vector2.ZERO
	_instance._joy_knob.position = (_instance._joy_base.size - _instance._joy_knob.size) / 2.0
	_instance._look_touch_index = -1
	_instance._look_delta = Vector2.ZERO
	_instance._jump_queued = false
	_instance._jump_held = false
	_instance._drone_queued = false


func _over_button(pos: Vector2) -> bool:
	for child in get_children():
		if child is Button and child.get_global_rect().has_point(pos):
			return true
	return false


func _update_joystick(touch_pos: Vector2) -> void:
	var center := _joy_base.get_global_rect().get_center()
	var offset := touch_pos - center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	_joy_vector = offset / joystick_radius
	_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0 + offset


static func direction() -> Vector2:
	return _instance._joy_vector if _instance else Vector2.ZERO


## True when the touch UI is showing (real phone, or `make touch` on the Mac).
static func is_touch() -> bool:
	return _instance != null and _instance.visible


## How far a finger dragged on the screen since last frame (for looking around).
static func look_delta() -> Vector2:
	if _instance == null:
		return Vector2.ZERO
	var d := _instance._look_delta
	_instance._look_delta = Vector2.ZERO
	return d


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
