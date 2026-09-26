extends Node
## Global game state (autoloaded as `Game`).
## Anything that needs to be shared between scenes lives here.

signal score_changed(score: int)
signal all_collected

var score := 0
var total_batteries := 0
var collected := 0


func reset_level(battery_count: int) -> void:
	total_batteries = battery_count
	collected = 0


func add_score(points: int) -> void:
	score += points
	collected += 1
	score_changed.emit(score)
	if collected >= total_batteries:
		all_collected.emit()
