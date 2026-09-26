extends CanvasLayer
## Score / toy counter + big messages on screen.

## What the top-left label shows. "score" -> "Score: 40", "count" -> "Toys: 2/6"
@export_enum("score", "count") var counter_mode := "score"
@export var count_word := "Toys"
@export var intro_text := "Collect all the batteries!"
@export var win_text := "YOU WIN!  Press R to play again"

@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel

var _fade: Tween


func _ready() -> void:
	Game.score_changed.connect(_on_score_changed)
	Game.collected_changed.connect(_on_collected_changed)
	Game.all_collected.connect(_on_all_collected)
	Game.message.connect(show_message)
	_on_score_changed(Game.score)
	_on_collected_changed(Game.collected, Game.total_batteries)
	show_message(intro_text)


func _on_score_changed(score: int) -> void:
	if counter_mode == "score":
		score_label.text = "Score: %d" % score


func _on_collected_changed(collected: int, total: int) -> void:
	if counter_mode == "count":
		score_label.text = "%s: %d/%d" % [count_word, collected, total]


func _on_all_collected() -> void:
	show_message(win_text, 0.0)


## Show a big message. seconds > 0 makes it fade out again.
func show_message(text: String, seconds := 3.0) -> void:
	if _fade:
		_fade.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	if seconds > 0.0:
		_fade = create_tween()
		_fade.tween_interval(seconds)
		_fade.tween_property(message_label, "modulate:a", 0.0, 1.0)
