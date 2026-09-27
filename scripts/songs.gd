class_name Songs
extends RefCounted
## The songbook. The background music is a collection of slow, wrong little tunes; the level
## starts on the song with its chapter's number and, every couple of minutes, fades out and
## into the next one (see spooky_audio.gd). Add a song here and it joins the rotation.
##
## A tune is written as notes: "E5 B4 G4 -" - letter, optional # or b, octave; "-" is a rest
## (or "keep ringing"); "|" is just a bar line for your eyes. One beat per note.
##   instrument   note (music box) / piano (toy piano) / bell / organ / whistle   - see sfx.gd
##   beat         seconds per note        swing   how out-of-time it plays (0 = a metronome)
##   octave       shift the whole tune up (+1) or down (-1)
##   bass         a second, lower line, one note every `bar` beats, on `bass_instrument`
##   miss         chance a note just doesn't come (a broken tine, a stuck key)
##   db           this song's volume, relative to the others

const LIST: Array[Dictionary] = [
	{
		"name": "Music Box",   # the original: a broken music box in E minor
		"instrument": "note", "beat": 0.42, "swing": 0.1, "octave": 1, "miss": 0.06,
		"melody": "E5 B4 G4 B4 E5 B4 G4 C5 | B4 G4 E4 G4 Eb5 B4 F#4 - | E5 B4 G4 B4 F#5 D5 B4 D5 | E5 C5 A4 C5 Eb5 B4 E4 -",
	},
	{
		"name": "Lullaby",   # somebody is still singing the little ones to sleep
		"instrument": "piano", "beat": 0.5, "swing": 0.06, "miss": 0.03,
		"melody": "A4 - C5 E5 - C5 | A4 - - E4 - - | A4 - C5 E5 - D5 | B4 - - G4 - - | C5 - E5 G5 - E5 | D5 - - B4 - - | C5 - B4 A4 - G#4 | A4 - - - - -",
		"bass": "A3 E3 A3 E3 A3 G3 E3 A3", "bass_instrument": "piano", "bar": 6,
	},
	{
		"name": "Hymn",   # the old organ in the hall, playing itself
		"instrument": "organ", "beat": 0.8, "swing": 0.02, "db": -2.0,
		"melody": "D4 - F4 - E4 - D4 - | C#4 - D4 - E4 - - - | F4 - G4 - A4 - F4 - | E4 - D4 - C#4 - - - | D4 - E4 - F4 - E4 - | D4 - C4 - Bb3 - - - | A3 - Bb3 - C#4 - D4 - | D4 - - - - - - -",
		"bass": "D3 A2 F3 A2 D3 Bb2 A2 D3", "bass_instrument": "organ", "bar": 8,
	},
	{
		"name": "Whistler",   # someone whistling in the next room. Nobody is in the next room.
		"instrument": "whistle", "beat": 0.45, "swing": 0.18, "miss": 0.08, "db": -3.0,
		"melody": "G5 - Bb5 A5 G5 - D5 - | G5 - Bb5 C6 D6 - - - | D6 - C6 Bb5 A5 - G5 - | F#5 - G5 A5 D5 - - - | Bb5 - A5 G5 F5 - Eb5 - | D5 - Eb5 F5 G5 - - - | A5 - Bb5 A5 G5 F#5 G5 - | - - - - - - - -",
	},
	{
		"name": "Bells",   # the school bell, tolling for a class that never comes
		"instrument": "bell", "beat": 0.7, "swing": 0.04, "db": -2.0,
		"melody": "C#5 - - - G#4 - - - | C#5 - - - E5 - - - | D#5 - - - C#5 - - - | B4 - - - G#4 - - - | C#5 - E5 - G#5 - - - | F#5 - E5 - D#5 - - - | C#5 - - - C4 - - - | - - - - - - - -",
		"bass": "C#3 C#3 G#2 G#2 C#3 A2 C#3 -", "bass_instrument": "bell", "bar": 8,
	},
	{
		"name": "Recess",   # a skipping-rope song, in the wrong key
		"instrument": "piano", "beat": 0.28, "swing": 0.08, "miss": 0.04,
		"melody": "F5 F5 Ab5 F5 C6 - Ab5 - | F5 F5 Ab5 F5 Eb5 - - - | Db5 Db5 F5 Db5 Ab5 - F5 - | Eb5 Db5 C5 Bb4 C5 - - - | F5 F5 Ab5 F5 C6 - Ab5 - | Bb5 Ab5 G5 F5 E5 - - - | F5 - C5 - Ab4 - F4 - | E4 - F4 - - - - -",
		"bass": "F3 C3 F3 Db3 F3 Bb2 C3 F3 F3 C3 Db3 Ab2 F3 C3 C3 F3", "bass_instrument": "piano", "bar": 4,
	},
	{
		"name": "Waltz",   # the music box again, but it has learned a new one
		"instrument": "note", "beat": 0.36, "swing": 0.1, "octave": 1, "miss": 0.05,
		"melody": "B4 - - D5 - - F#5 - - B5 - - | A5 - - F#5 - - D5 - - - - - | G5 - - B5 - - D6 - - C#6 - - | A5 - - F#5 - - E5 - - - - - | B4 - - D5 - - F#5 - - B5 - - | C#6 - - A#5 - - F#5 - - - - - | G5 - F#5 E5 - D5 C#5 - B4 A#4 - - | B4 - - - - - - - - - - -",
		"bass": "B3 D4 F#3 F#3 G3 D4 F#3 F#3 B3 D4 F#3 F#3 E3 F#3 B3 -", "bass_instrument": "note", "bar": 6,
	},
	{
		"name": "The Lab",   # two notes that should never be played together, over and over
		"instrument": "bell", "beat": 0.6, "swing": 0.03, "db": -1.0,
		"melody": "C5 - - F#5 - - - - | B4 - - F5 - - - - | C5 - Db5 - C5 - - - | F#5 - - - - - - - | Ab5 - - G5 - - C5 - | Db5 - - - - - - - | C5 - F#5 - C5 - B4 - | - - - - - - - -",
		"bass": "C3 F#2 C3 B2 C3 Db3 C3 C3", "bass_instrument": "organ", "bar": 8,
	},
]

## The pitch each instrument's sample is recorded at (see sfx.gd); other notes shift it.
const BASE := {"note": 1318.5, "piano": 440.0, "bell": 440.0, "organ": 220.0, "whistle": 880.0}
const NAMES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

static var _parsed := {}


## The song a chapter starts on (0-based chapter), then `next()` goes round the book.
static func for_chapter(chapter: int) -> int:
	return posmod(chapter, LIST.size())


static func next(index: int) -> int:
	return (index + 1) % LIST.size()


## The tune as frequencies in Hz, one per beat; 0 = rest. Parsed once.
static func melody(index: int) -> Array[float]:
	return _line(index, "melody")


static func bass(index: int) -> Array[float]:
	return _line(index, "bass")


## How much to speed a sample up or down to sound this note on this instrument.
static func pitch(instrument: String, hz: float) -> float:
	return hz / BASE.get(instrument, 440.0)


## "F#4" -> 369.99 Hz. "-" (or anything it can't read) -> 0.
static func freq(token: String) -> float:
	if token.length() < 2 or not NAMES.has(token[0]):
		return 0.0
	var semitone: int = NAMES[token[0]]
	var rest := token.substr(1)
	if rest.begins_with("#"):
		semitone += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		semitone -= 1
		rest = rest.substr(1)
	if not rest.is_valid_int():
		return 0.0
	var midi := 12 * (rest.to_int() + 1) + semitone
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func _line(index: int, which: String) -> Array[float]:
	var key := "%d/%s" % [index, which]
	if not _parsed.has(key):
		var song := LIST[index]
		var out: Array[float] = []
		var shift: float = pow(2.0, song.get("octave", 0))
		for token in String(song.get(which, "")).split(" ", false):
			if token == "|":
				continue
			out.append(freq(token) * shift)
		_parsed[key] = out
	return _parsed[key]
