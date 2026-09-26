extends Control
## Huge letters that slam onto the screen one by one and drip blood, when something sees you.
## Call scare("RUN") and it does the rest.

@export var font_size := 150
@export var color := Color(0.55, 0.02, 0.02)
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.85)

var _text := ""
var _age := 0.0
var _life := 0.0
var _letters: Array[Dictionary] = []
var _drips: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func scare(text: String, seconds := 2.8) -> void:
	_text = text
	_age = 0.0
	_life = seconds
	_letters.clear()
	_drips.clear()
	var fs := font_size if text.length() <= 8 else int(font_size * 8.0 / text.length())
	var total := 0.0
	for ch in text:
		total += _font.get_char_size(ch.unicode_at(0), fs).x
	var x := (size.x - total) / 2.0
	var y := size.y * 0.42
	for i in text.length():
		var ch := text[i]
		var w := _font.get_char_size(ch.unicode_at(0), fs).x
		_letters.append({
			"ch": ch, "x": x, "y": y + randf_range(-14.0, 14.0), "size": fs,
			"rot": randf_range(-0.12, 0.12), "delay": i * 0.05,
		})
		if ch != " ":
			for _k in randi_range(1, 3):
				_drips.append({
					"x": x + w * randf_range(0.15, 0.85), "y": y + fs * 0.08, "len": 0.0,
					"max": randf_range(60.0, 260.0) * fs / font_size, "speed": randf_range(140.0, 380.0),
					"w": randf_range(4.0, 11.0) * fs / font_size, "delay": i * 0.05 + randf_range(0.1, 0.6),
				})
		x += w
	queue_redraw()


func _process(delta: float) -> void:
	if _life <= 0.0:
		return
	_age += delta
	if _age > _life:
		_life = 0.0
		_text = ""
		queue_redraw()
		return
	for d in _drips:
		if _age > d.delay:
			d.speed = maxf(d.speed - delta * 120.0, 40.0)
			d.len = minf(d.len + d.speed * delta, d.max)
	queue_redraw()


func _draw() -> void:
	if _text == "":
		return
	var fade := clampf((_life - _age) / 0.6, 0.0, 1.0)
	var c := color
	c.a = fade
	var sc := shadow_color
	sc.a *= fade
	for l in _letters:
		var t: float = _age - l.delay
		if t < 0.0:
			continue
		var punch := 1.0 + maxf(0.0, 0.3 - t * 2.5) * 2.5   # slams in big, then settles
		draw_set_transform(Vector2(l.x, l.y), l.rot, Vector2.ONE * punch)
		draw_char_outline(_font, Vector2(6, 8), l.ch, l.size, 10, sc)
		draw_char(_font, Vector2(6, 8), l.ch, l.size, sc)
		draw_char_outline(_font, Vector2.ZERO, l.ch, l.size, 6, c.darkened(0.4))
		draw_char(_font, Vector2.ZERO, l.ch, l.size, c)
	draw_set_transform(Vector2.ZERO)
	for d in _drips:
		if d.len <= 0.0:
			continue
		draw_rect(Rect2(d.x - d.w / 2.0, d.y, d.w, d.len), c)
		draw_circle(Vector2(d.x, d.y + d.len), d.w * 0.75, c)
