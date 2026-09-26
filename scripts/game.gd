extends Node
## Global game state (autoloaded as `Game`).
## Anything that needs to be shared between scenes lives here.

signal score_changed(score: int)
signal collected_changed(collected: int, total: int)
signal all_collected
signal message(text: String, seconds: float)
signal caught(by: Node3D)

var score := 0
var total_batteries := 0
var collected := 0


func reset_level(battery_count: int) -> void:
	total_batteries = battery_count
	collected = 0
	score = 0
	score_changed.emit(score)
	collected_changed.emit(collected, total_batteries)


func add_score(points: int) -> void:
	score += points
	collected += 1
	score_changed.emit(score)
	collected_changed.emit(collected, total_batteries)
	if collected >= total_batteries:
		all_collected.emit()


## Show a big message in the middle of the screen (the HUD listens for this).
## seconds = how long before it fades; 0 = stays forever.
func say(text: String, seconds := 3.0) -> void:
	message.emit(text, seconds)


## A monster grabbed the player. Levels decide what happens (jump-scare, respawn...).
func player_caught(by: Node3D) -> void:
	caught.emit(by)
