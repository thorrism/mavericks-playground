class_name Chapters
## THE ABYSS - the eight chapters, in order. Escape one and the next unlocks.
## Every chapter is a text map (see the legend in kinder.gd). Edit the map = edit the chapter!
##
##   #  wall / hedge        .  floor            P  where you start        X  exit door
##   W  low wall (only the drone flies over)    =  fence (jump it; THEY have to walk round)
##   T  toy                 L  lamp              H  cupboard to hide in    t  table
##   S  shelf (lockers / bookcase / lab tank / swings outside)   Z  crates (slide outside)
##   ^  pillar (a tree outside)
##   The creatures (bigger every chapter - see "monster_scale"). Never two of the same kind in
##   one chapter: each is a character, and you meet a new one every couple of chapters.
##   M  Banbo, the tall one (ch 1)     J  Jumbo, the giant (ch 1)
##   N  Natchee, the one-eyed flower that crawls on its roots (from chapter 3)
##   D  Howler, the four-legged one (from chapter 4)   K  Skitter, six legs (from chapter 6)
##   G  Gloop, what came out of the lab tanks (chapter 8)
##   1-9 doors, a-i buttons: a opens 1, b opens 2 ... A letter can appear more than once:
##   both buttons open the same door (handy for a timed door you need to open from the far side).
##
## Per chapter:
##   name / place    shown on the title screen and the HUD
##   theme           how it's decorated (kinder.gd THEMES): classroom, hallway, library,
##                   lunchroom, gym, art, playground (outdoors, night), lab
##   timed           { "3": 20.0 } = door 3 slams shut 20 s after it opens. Hit its button again to reopen.
##   monster_scale   how big the creatures are (1 = normal). Outdoors / high ceilings let them be huge.
##   hunt            multiplies how far they see + hear and how long they keep hunting
##   exit_hint       what the game says when the last toy is found

const CHAPTERS: Array[Dictionary] = [
	{
		"name": "CLASSROOM",
		"tagline": "don't let them find you.",
		"theme": "classroom",
		"timed": {},
		"monster_scale": 1.0,
		"hunt": 1.0,
		"exit_hint": "The GOLDEN DOOR at the top of the classroom is open.  RUN!",
		"map": [
			"##########X#########",
			"#H.................#",
			"#.T....t.....L...T.#",
			"#......J..........H#",
			"#....T.............#",
			"##########3#########",
			"#......#...........#",
			"#..T..H#...........#",
			"#..L...#.....===...#",
			"#.M....#.....=a=...#",
			"#..t...#.....===...#",
			"#WWWWW.#...........#",
			"#.c..W.1..........H#",
			"#....W.#.....P.....#",
			"#WWWWW.#.....L.....#",
			"#......#..T...t....#",
			"#..T...#...........#",
			"####################",
		],
	},
	{
		"name": "HALLWAY",
		"tagline": "a long corridor of lockers.  something is walking it.",
		"theme": "hallway",
		"timed": {},
		"monster_scale": 1.05,
		"hunt": 1.05,
		"exit_hint": "The GOLDEN DOOR at the end of the hallway is open.  RUN!",
		"map": [
			"#########X############",
			"#H......#.#.........H#",
			"#.T.....#4#..T.......#",
			"#....M..2.2....c.....#",
			"#..L....#.#..J...L...#",
			"#.....T.#.#..........#",
			"#....t..#.#.....t....#",
			"#########.############",
			"#................WWW.#",
			"#..T.S...S...S...WbW.#",
			"#....S.......S...WWW.#",
			"#..L.S...S...S..S....#",
			"#....S...S.....H...L.#",
			"###3########1#########",
			"#H..WWW....#.........#",
			"#...WdW....#..===....#",
			"#...WWW....#..=a=..T.#",
			"#.....L....#..===..L.#",
			"#.......t..#....P....#",
			"#.....T....#........H#",
			"######################",
		],
	},
	{
		"name": "LIBRARY",
		"tagline": "keep quiet in the stacks.  something has taken root in the reading room.",
		"theme": "library",
		"timed": {"3": 25.0},
		"monster_scale": 1.1,
		"hunt": 1.1,
		"exit_hint": "The GOLDEN DOOR past the reading room is open.  RUN!",
		"map": [
			"###########X##########",
			"#H.......#......T....#",
			"#..T..L..#..L........#",
			"#........#......J....#",
			"#....SS..#......c....#",
			"#tt..SS..#.....t.....#",
			"#........3...........#",
			"#..N...t.#.T.........#",
			"#.T......#......L...H#",
			"#H.......#...........#",
			"##########2###########",
			"#.....S.S.....#WWW...#",
			"#..T..S.S.....#WbW...#",
			"#.SS..S.S.SS..#WWW...#",
			"#.SS..M.S.SS..#......#",
			"#.....S.S.....#......#",
			"#.....S.S....L1......#",
			"#..T..S.S.....#......#",
			"#.SS..S.S.SS..#.===..#",
			"#.SS....S.SS..#.=a=..#",
			"#..L..S.T.....#.===..#",
			"#H............#..P..H#",
			"######################",
		],
	},
	{
		"name": "LUNCHROOM",
		"tagline": "long tables, a dark kitchen.  three of them now - and one of them runs.",
		"theme": "lunchroom",
		"timed": {"2": 20.0},
		"monster_scale": 1.15,
		"hunt": 1.15,
		"exit_hint": "The GOLDEN DOOR at the top of the lunch hall is open.  RUN!",
		"map": [
			"####X#################",
			"#H.......#.....T.....#",
			"#..T..L..#..L........#",
			"#tt.tt...#....WWWWW..#",
			"#........3..T.W...W..#",
			"#tt.tt.J.#..M.W.c.W..#",
			"#........#....WWWWW..#",
			"#...T..H.#.b.......H.#",
			"##############2#######",
			"#........#...........#",
			"#..D.....#...........#",
			"#HT......#.....===...#",
			"#........#.....=a=...#",
			"#..L.....1.....===...#",
			"#.....T..#.....L.....#",
			"#WWWW....#.....P.....#",
			"#b..W....#.....T.....#",
			"#WWWW....#.....H.....#",
			"######################",
		],
	},
	{
		"name": "GYM",
		"tagline": "hurdles.  a storeroom.  two doors on a clock.",
		"theme": "gym",
		"timed": {"3": 20.0, "4": 20.0},
		"monster_scale": 1.2,
		"hunt": 1.2,
		"exit_hint": "The GOLDEN DOOR at the top of the gym is open.  RUN!",
		"map": [
			"###########X############",
			"#H...T.........L.....T.#",
			"#......J.......d.......#",
			"#..L..................H#",
			"######4#################",
			"#..............#......H#",
			"#.T..=====.....#..ZZ...#",
			"#....L.........#......T#",
			"#...N..........#..D....#",
			"#..=======.....3.d.c...#",
			"#..............#..ZZ...#",
			"#.....L..WWW...#...T...#",
			"#H.T.....WcW...#.......#",
			"#........WWW...#.......#",
			"####1###################",
			"#......===.....L.......#",
			"#..P...=a=.........T..H#",
			"#......===.............#",
			"########################",
		],
	},
	{
		"name": "ART ROOM",
		"tagline": "paint on the walls.  not all of it is paint.  mind the webs.",
		"theme": "art",
		"timed": {"3": 15.0, "4": 15.0},
		"monster_scale": 1.25,
		"hunt": 1.25,
		"exit_hint": "The GOLDEN DOOR at the top of the gallery is open.  RUN!",
		"map": [
			"############X###########",
			"#H..T.....L......T.....#",
			"#.....M....t...........#",
			"#..t........WWW........#",
			"#...........WdW...t....#",
			"#.T.........WWW......T.#",
			"##########4#############",
			"#......#.......#.......#",
			"#..T...#.......#..T....#",
			"#.N..L.#.......#...L...#",
			"#......#..===..#.ZZ....#",
			"#WWW...#..=a=..#.ZZ.K..#",
			"#WcW...1..===..3......H#",
			"#WWW...#.......#.......#",
			"#......#...P...#..d....#",
			"#..T..H#...L...#WWW....#",
			"#......#.......#WcW..T.#",
			"#......#.......#WWW....#",
			"#......#...H...#.......#",
			"########################",
		],
	},
	{
		"name": "PLAYGROUND",
		"tagline": "outside.  night.  the things out here are BIGGER.",
		"theme": "playground",
		"timed": {"2": 15.0, "3": 15.0},
		"monster_scale": 1.6,
		"hunt": 1.3,
		"exit_hint": "The GOLDEN GATE at the top of the field is open.  RUN!",
		"map": [
			"#####X##################",
			"#.....^....#.....T.....#",
			"#.T.......^#...WWWWW...#",
			"#..SS......#...W...W..^#",
			"#..SS..K...#...W.c.W...#",
			"#..........3...WWWWW...#",
			"#^.....T...#.......J...#",
			"#.....c....#..ZZ.......#",
			"#..L.......#..ZZ...b..T#",
			"#H.........#........T..#",
			"#.........^#...L......H#",
			"#..........#######2#####",
			"#T....^....#...........#",
			"#..........#.......^...#",
			"############...........#",
			"#....L.....#..T........#",
			"#.....===..#...WWW.....#",
			"#..^..=a=..1...WbW..D..#",
			"#.....===..#...WWW.....#",
			"#.P........#........T..#",
			"#....H..T..#..H........#",
			"########################",
		],
	},
	{
		"name": "THE ABYSS",
		"tagline": "the science lab.  this is where it all went wrong.  they're ALL here.",
		"theme": "lab",
		"timed": {"2": 12.0, "3": 12.0, "4": 12.0},
		"monster_scale": 1.9,
		"hunt": 1.4,
		"exit_hint": "The AIRLOCK at the top of the lab is open.  GET OUT!",
		"map": [
			"#####X##################",
			"#H....T...d#..T.......c#",
			"#..L...M...#.....S.S...#",
			"#....T.....#..J........#",
			"#####4######..G........#",
			"#..........#....S.S..b.#",
			"#..S.WWW...3....c.....T#",
			"#....WdW...######2######",
			"#....WWW...#......S....#",
			"#K...c.....#..T........#",
			"#..........#..........H#",
			"#..T......H#..ZZ.......#",
			"#..........#..ZZ....N..#",
			"#.T..L.....#....WWW....#",
			"#..........#....WbW....#",
			"############....WWW....#",
			"#..........#..S......T.#",
			"#..===.....#...........#",
			"#..=a=.....1...........#",
			"#..===.....#...........#",
			"#P.....H...#.H......T..#",
			"########################",
		],
	},
]


static func count() -> int:
	return CHAPTERS.size()


static func get_chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)]


## "CHAPTER 3  ·  LIBRARY"
static func title(index: int) -> String:
	return "CHAPTER %d  ·  %s" % [index + 1, get_chapter(index)["name"]]


## How many toys are on a chapter's map.
static func toy_count(index: int) -> int:
	var n := 0
	for row: String in get_chapter(index)["map"]:
		n += row.count("T")
	return n
