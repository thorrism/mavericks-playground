extends CanvasLayer
## The title screen and the pause menu (Esc), built in code. The game is frozen while
## it's up. Pick a difficulty here; it saves and applies straight away.
##   Title:  THE ABYSS in dripping blood, difficulty, PLAY, your records
##   Pause:  RESUME / RESTART / difficulty / QUIT
## Enter or Space = play/resume, Left/Right = change difficulty, Esc = back to the game.

signal opened
signal play
signal restart

enum Mode { HIDDEN, TITLE, PAUSED }

const BLOOD := Color(0.55, 0.02, 0.02)
const BONE := Color(0.85, 0.8, 0.7)
const DIM := Color(0.75, 0.75, 0.75)
const BloodTextScript := preload("res://scripts/blood_text.gd")

var mode := Mode.HIDDEN

var _dim: ColorRect
var _title: Control
var _heading: Label
var _result: Label
var _tagline: Label
var _diff_buttons: Array[Button] = []
var _blurb: Label
var _play: Button
var _restart: Button
var _quit: Button
var _stats: Label
var _controls: Label
var _pause_tap: Button
var _box: VBoxContainer
var _gap: Control


func _ready() -> void:
	layer = 20
	process_mode = PROCESS_MODE_ALWAYS
	_build()
	_dim.visible = false
	_box.visible = false
	_title.visible = false
	Settings.changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.HIDDEN:
		return
	if event.is_action_pressed("ui_accept"):
		_on_play()
	elif event.is_action_pressed("ui_cancel") and mode == Mode.PAUSED:
		_on_play()
	elif event.is_action_pressed("ui_left"):
		Settings.set_difficulty(wrapi(Settings.difficulty - 1, 0, Settings.NAMES.size()))
	elif event.is_action_pressed("ui_right"):
		Settings.set_difficulty(wrapi(Settings.difficulty + 1, 0, Settings.NAMES.size()))
	else:
		return
	get_viewport().set_input_as_handled()   # so the level doesn't also see this key


## The big screen at the start (and after you escape). result = "YOU ESCAPED in 1:23" or "".
func show_title(result := "") -> void:
	mode = Mode.TITLE
	_heading.visible = false
	_title.visible = true
	_gap.visible = true
	_title.scare("THE ABYSS", 1.0e9)
	_result.text = result
	_result.visible = result != ""
	_tagline.visible = true
	_play.text = "PLAY"
	_restart.visible = false
	_stats.visible = true
	_open()


func show_pause() -> void:
	mode = Mode.PAUSED
	_title.visible = false
	_gap.visible = false
	_heading.visible = true
	_result.visible = false
	_tagline.visible = false
	_play.text = "RESUME"
	_restart.visible = true
	_stats.visible = false
	_open()


func hide_menu() -> void:
	mode = Mode.HIDDEN
	_dim.visible = false
	_box.visible = false
	_title.visible = false
	_pause_tap.visible = TouchControls.is_touch()
	get_tree().paused = false


func _open() -> void:
	_refresh()
	_dim.visible = true
	_box.visible = true
	_pause_tap.visible = false
	_quit.visible = not OS.has_feature("mobile")
	TouchControls.release_all()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_play.grab_focus()
	opened.emit()


func _on_play() -> void:
	hide_menu()
	play.emit()


func _on_restart() -> void:
	hide_menu()
	restart.emit()


func _refresh() -> void:
	for i in _diff_buttons.size():
		var b := _diff_buttons[i]
		var picked := i == Settings.difficulty
		b.add_theme_stylebox_override("normal", _style(BLOOD if picked else Color(0.1, 0.08, 0.08), BLOOD if picked else Color(0.3, 0.25, 0.25)))
		b.add_theme_color_override("font_color", Color.WHITE if picked else DIM)
	_blurb.text = Settings.BLURBS[Settings.difficulty]
	var stats := "escapes %d   ·   tries %d" % [Settings.escapes, Settings.attempts]
	if Settings.best_time > 0.0:
		stats += "   ·   best %s" % Settings.fmt_time(Settings.best_time)
	_stats.text = stats
	_controls.text = ("drag to look   ·   joystick to move   ·   JUMP   ·   DRONE" if TouchControls.is_touch()
		else "WASD move   ·   mouse look   ·   Space jump   ·   E drone   ·   Esc pause / restart")


# ---------------------------------------------------------------------------
# Building the screen
# ---------------------------------------------------------------------------
func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.0, 0.0, 0.0, 0.78)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_title = Control.new()
	_title.name = "Title"
	_title.set_script(BloodTextScript)
	_title.font_size = 175
	_title.y_fraction = 0.2
	_title.drip_length = 0.55
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_title)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_box = VBoxContainer.new()
	_box.name = "Box"
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 18)
	center.add_child(_box)

	_heading = _label("PAUSED", 96, BLOOD)
	_heading.add_theme_color_override("font_outline_color", Color.BLACK)
	_heading.add_theme_constant_override("outline_size", 16)
	_box.add_child(_heading)

	_gap = _spacer(170)   # room for the dripping title above
	_box.add_child(_gap)

	_result = _label("", 40, Color(1.0, 0.85, 0.4))
	_box.add_child(_result)
	_tagline = _label("find the 6 toys.  don't let them find you.", 30, BONE)
	_box.add_child(_tagline)

	var row := HBoxContainer.new()
	row.name = "Difficulty"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	for i in Settings.NAMES.size():
		var b := _button(Settings.NAMES[i], 30)
		b.custom_minimum_size = Vector2(220, 60)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): Settings.set_difficulty(i))
		row.add_child(b)
		_diff_buttons.append(b)
	_blurb = _label("", 24, DIM)
	_box.add_child(_blurb)

	_box.add_child(_spacer(10))
	_play = _button("PLAY", 48)
	_play.custom_minimum_size = Vector2(360, 90)
	_play.add_theme_stylebox_override("normal", _style(Color(0.35, 0.02, 0.02), BLOOD))
	_play.add_theme_stylebox_override("hover", _style(BLOOD, Color(0.8, 0.1, 0.1)))
	_play.add_theme_stylebox_override("focus", _style(Color(0.45, 0.03, 0.03), Color(0.9, 0.2, 0.2)))
	_play.pressed.connect(_on_play)
	_box.add_child(_play)

	_restart = _button("RESTART", 30)
	_restart.custom_minimum_size = Vector2(360, 60)
	_restart.pressed.connect(_on_restart)
	_box.add_child(_restart)

	_quit = _button("QUIT", 24)
	_quit.custom_minimum_size = Vector2(360, 50)
	_quit.pressed.connect(func(): get_tree().quit())
	_box.add_child(_quit)

	_box.add_child(_spacer(10))
	_stats = _label("", 24, DIM)
	_box.add_child(_stats)
	_controls = _label("", 20, Color(0.6, 0.6, 0.6))
	_box.add_child(_controls)

	# phones have no Esc key: a little pause button in the corner while playing
	_pause_tap = _button("II", 28)
	_pause_tap.name = "PauseTap"
	_pause_tap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_tap.offset_left = -100
	_pause_tap.offset_right = -30
	_pause_tap.offset_top = 80
	_pause_tap.offset_bottom = 140
	_pause_tap.focus_mode = Control.FOCUS_NONE
	_pause_tap.pressed.connect(show_pause)
	_pause_tap.visible = false
	add_child(_pause_tap)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	return l


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BONE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.08, 0.08), Color(0.3, 0.25, 0.25)))
	b.add_theme_stylebox_override("hover", _style(Color(0.2, 0.1, 0.1), BLOOD))
	b.add_theme_stylebox_override("pressed", _style(BLOOD, BLOOD))
	b.add_theme_stylebox_override("focus", _style(Color(0.2, 0.1, 0.1), Color(0.8, 0.2, 0.2)))
	return b


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(10)
	return s


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
