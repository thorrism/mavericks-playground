extends CanvasLayer
## Score + big messages on screen.

@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	Game.score_changed.connect(_on_score_changed)
	Game.all_collected.connect(_on_all_collected)
	_on_score_changed(Game.score)
	message_label.text = "Collect all the batteries!"
	_fade_message_later(3.0)


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d" % score


func _on_all_collected() -> void:
	message_label.text = "YOU WIN!  Press R to play again"
	message_label.modulate.a = 1.0


func _fade_message_later(seconds: float) -> void:
	var tween := create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(message_label, "modulate:a", 0.0, 1.0)
