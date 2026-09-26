extends Node
## Things that survive between plays (autoloaded as `Settings`, saved to user://kinder.cfg):
## the difficulty you picked and your records. The title screen shows and changes these.

signal changed

enum Difficulty { EASY, NORMAL, NIGHTMARE }

const NAMES: Array[String] = ["EASY", "NORMAL", "NIGHTMARE"]
const BLURBS: Array[String] = [
	"slower monsters, a long wind-up before they swing, they give up quickly",
	"the real thing",
	"fast, sharp-eyed, they swing quick and they don't forget you",
]
## What each difficulty does to every monster (multiplies the numbers in monster.gd).
##   speed   walking + chasing        sight    how far it sees / hears
##   windup  arms-up warning time     recover  how long it's stuck after a swing
##   persist how long it keeps hunting once it lost you      grace  safe seconds after a restart
const TUNING: Array[Dictionary] = [
	{"speed": 0.85, "sight": 0.8, "windup": 1.35, "recover": 1.4, "persist": 0.7, "grace": 1.5},
	{"speed": 1.0, "sight": 1.0, "windup": 1.0, "recover": 1.0, "persist": 1.0, "grace": 1.0},
	{"speed": 1.12, "sight": 1.3, "windup": 0.8, "recover": 0.75, "persist": 1.5, "grace": 0.5},
]
const PATH := "user://kinder.cfg"

var difficulty: int = Difficulty.NORMAL
var attempts := 0
var escapes := 0
var best_time := 0.0   # seconds; 0 = never escaped
var persist := true    # tests turn this off so they don't touch your records


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		difficulty = clampi(cfg.get_value("game", "difficulty", Difficulty.NORMAL), 0, NAMES.size() - 1)
		attempts = cfg.get_value("records", "attempts", 0)
		escapes = cfg.get_value("records", "escapes", 0)
		best_time = cfg.get_value("records", "best_time", 0.0)


func set_difficulty(d: int) -> void:
	if d == difficulty:
		return
	difficulty = d
	save()
	changed.emit()


func monster_tuning() -> Dictionary:
	return TUNING[difficulty]


func record_attempt() -> void:
	attempts += 1
	save()


## Returns true if this was a new record.
func record_escape(seconds: float) -> bool:
	escapes += 1
	var record := best_time <= 0.0 or seconds < best_time
	if record:
		best_time = seconds
	save()
	return record


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("records", "attempts", attempts)
	cfg.set_value("records", "escapes", escapes)
	cfg.set_value("records", "best_time", best_time)
	cfg.save(PATH)


## 83.4 -> "1:23"
static func fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
