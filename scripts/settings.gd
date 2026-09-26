extends Node
## Things that survive between plays (autoloaded as `Settings`, saved to user://kinder.cfg):
## the difficulty you picked, which chapter you're on, how far you've got, and your records.
## The title screen shows and changes these.

signal changed

enum Difficulty { EASY, NORMAL, NIGHTMARE }

const NAMES: Array[String] = ["EASY", "NORMAL", "NIGHTMARE"]
const BLURBS: Array[String] = [
	"slower monsters, a long wind-up before they swing, they give up quickly, cupboards always work",
	"the real thing",
	"fast, sharp-eyed, they swing quick, they don't forget you and they check the cupboards",
]
## What each difficulty does to every monster (multiplies the numbers in monster.gd).
##   speed   walking + chasing        sight    how far it sees / hears
##   windup  arms-up warning time     recover  how long it's stuck after a swing
##   persist how long it keeps hunting once it lost you      grace  safe seconds after a restart
##   peek    how close to a cupboard it must lose you before it goes and looks inside (0 = never checks)
const TUNING: Array[Dictionary] = [
	{"speed": 0.85, "sight": 0.8, "windup": 1.35, "recover": 1.4, "persist": 0.7, "grace": 1.5, "peek": 0.0},
	{"speed": 1.0, "sight": 1.0, "windup": 1.0, "recover": 1.0, "persist": 1.0, "grace": 1.0, "peek": 1.0},
	{"speed": 1.12, "sight": 1.3, "windup": 0.8, "recover": 0.75, "persist": 1.5, "grace": 0.5, "peek": 1.8},
]
const PATH := "user://kinder.cfg"

var difficulty: int = Difficulty.NORMAL
var chapter := 0         # the chapter you're playing (0-based: 0 = Chapter 1)
var unlocked := 0        # the highest chapter you may play (escape a chapter to unlock the next)
var attempts := 0
var escapes := 0
var best_time := 0.0     # seconds, any chapter; 0 = never escaped
var best_times: Array[float] = []   # per chapter; 0 = never escaped that one
var persist := true      # tests turn this off so they don't touch your records


func _ready() -> void:
	best_times.resize(Chapters.count())
	best_times.fill(0.0)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		difficulty = clampi(cfg.get_value("game", "difficulty", Difficulty.NORMAL), 0, NAMES.size() - 1)
		unlocked = clampi(cfg.get_value("game", "unlocked", 0), 0, Chapters.count() - 1)
		chapter = clampi(cfg.get_value("game", "chapter", 0), 0, unlocked)
		attempts = cfg.get_value("records", "attempts", 0)
		escapes = cfg.get_value("records", "escapes", 0)
		best_time = cfg.get_value("records", "best_time", 0.0)
		for i in best_times.size():
			best_times[i] = cfg.get_value("records", "best_time_%d" % (i + 1), 0.0)


## Pick a chapter to play. Locked chapters can't be picked (returns false).
func set_chapter(c: int) -> bool:
	if c < 0 or c >= Chapters.count() or c > unlocked:
		return false
	if c != chapter:
		chapter = c
		save()
		changed.emit()
	return true


func is_unlocked(c: int) -> bool:
	return c >= 0 and c <= unlocked


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


## Escaped chapter c in `seconds`: unlocks the next chapter. Returns true if this was a new
## record for that chapter.
func record_escape(c: int, seconds: float) -> bool:
	escapes += 1
	if best_time <= 0.0 or seconds < best_time:
		best_time = seconds
	var record := best_times[c] <= 0.0 or seconds < best_times[c]
	if record:
		best_times[c] = seconds
	unlocked = clampi(maxi(unlocked, c + 1), 0, Chapters.count() - 1)
	save()
	changed.emit()
	return record


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "chapter", chapter)
	cfg.set_value("game", "unlocked", unlocked)
	cfg.set_value("records", "attempts", attempts)
	cfg.set_value("records", "escapes", escapes)
	cfg.set_value("records", "best_time", best_time)
	for i in best_times.size():
		cfg.set_value("records", "best_time_%d" % (i + 1), best_times[i])
	cfg.save(PATH)


## 83.4 -> "1:23"
static func fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
