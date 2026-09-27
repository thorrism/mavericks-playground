# The Abyss

A tiny 3D game built with [Godot 4](https://godotengine.org) that runs on Mac **and** iPhone.
It exists so a kid + a grown-up + Devin can say "make the robot green and add lava" and see it happen in seconds.

## The Abyss (the current game)

First person. You wake up in a dark, abandoned school with only a flashlight. Things live here
and hunt you if they see or hear you. Find every toy, use your drone to reach buttons the robot
can't, open the coloured doors, and escape through the golden exit - eight times.

### Eight chapters

| # | Chapter | What's new |
|---|---|---|
| 1 | **Classroom** | learn the rules: 6 toys, 2 doors, 2 creatures, a cupboard to hide in |
| 2 | **Hallway** | lockers, 4 doors, long corridors - and something walks them |
| 3 | **Library** | bookcases you have to weave through; the first **timed door** (it slams shut again) |
| 4 | **Lunchroom** | kitchen and dining hall, 3 creatures, a faster timed door |
| 5 | **Gym** | huge open hall (nowhere to hide), stacked mats, doors on a short fuse |
| 6 | **Art Room** | a maze of easels and paint tins, four colours of door, quick fuses |
| 7 | **Playground** | **outside at night**: moon, trees, hedges, swings, a slide - and the creatures are *big* |
| 8 | **The Abyss** | the science lab where it all went wrong: cracked tanks, green glow, three 12-second doors, the biggest creatures of all |

Escape a chapter to unlock the next one; the title screen lets you pick any chapter you've
unlocked (`Up`/`Down`, or tap it). Each chapter is its own **text map** in `scripts/chapters.gd`,
so "put a tree in the playground" is a one-letter edit. Creatures get bigger and hunt harder every
chapter (`monster_scale` / `hunt` in the same file); later rooms have higher ceilings so they fit.

- Almost no light: your **flashlight** (`F` switches it off - then it's just the dying ceiling lamps,
  the glow of the toys and their eyes).
- Grimy **coloured walls** with stripes, torn posters, bloody handprints and words scrawled on them;
  little tables and chairs, spilt building blocks, drawings and dark puddles on the floor.
- **Hide**: step into an open cupboard (`H` on the map); the doors creak shut behind you and they
  can't see or hear you - unless one was right behind you when you climbed in. Your heartbeat tells
  you when one is close. On NORMAL and NIGHTMARE a monster that loses you *next to* a cupboard
  comes over, flings the doors open and looks inside (`BANBO FOUND YOU`). On EASY cupboards always work.
- Now and then something thuds, clacks or giggles in another room. It's nothing. Probably.
- Step on a **button** (or land the drone on it) and the door of the same colour opens. From
  chapter 3 some doors are **timed**: they grind shut again after a few seconds (the last five are
  counted down on screen), so you have to run for it - or press the button again. A door never shuts
  on anyone standing in it.
- **Low walls**: only the drone can fly over them. **Fences**: the robot can jump over.
- The **creatures** - never two of the same kind in a chapter, and you meet new ones as you go:
  `M` Banbo (tall teal grin, bow tie) and `J` Jumbo (huge green brute) from chapter 1;
  `N` Natchee (a one-eyed flower that stands rooted, then crawls at you on five roots) from chapter 3;
  `D` Howler (low, fast, four legs) from chapter 4; `K` Skitter (six legs, a face full of eyes) from
  chapter 6; `G` Gloop (what climbed out of the lab tanks - it slides) in chapter 8. `O` adds a lanky
  yellow bird if you want one. They really move the way they're built (knees bend and feet plant,
  roots plant and pull, paws pad, a blob squashes and stretches), know the way around walls, run to where they last
  saw you and search there, and stop to look around between wanders - but you are a bit faster, and **a monster never leaves its own room**:
  get through a doorway and it gives up. They also leave you alone for the first few seconds after a (re)start.
- **Seen**: dripping blood letters (`BANBO SEES YOU`), a scream, red screen edges, shaking, your
  flashlight stutters, and the music turns into panic.
- **The swing**: touching a monster doesn't kill you. When it gets close it snarls and raises both
  arms - that is your warning - then slams them down and lunges. Sidestep out of the arc and it
  misses (`JUMBO MISSED YOU`) and is stuck for a moment; stand there and it lands: red flash, black,
  and the chapter starts over.
- Buttons clunk when pressed and doors grind open, so you can hear that something happened.
- Collect every toy and the **golden door** opens and glows; walk through it to escape.
- All sound is generated from code: footsteps (yours and theirs, heavier when they chase), a toy chime,
  a broken music-box tune, the drone's rotor whine, and each monster's own voice.
- The **drone** is unlimited: `E` sends it out, `E` again brings you back, as often as you like.
  Monsters ignore your parked body while you fly.

| Action | Mac keyboard | iPhone |
|---|---|---|
| Look around | mouse | drag anywhere on screen |
| Pause / difficulty | Esc | the `II` button top-right |
| Move | WASD or arrow keys (relative to where you look) | left joystick |
| Jump / drone up | Space (hold to fly the drone up) | JUMP button |
| Switch robot <-> drone | E | DRONE button |
| Flashlight on / off | F | - |
| Restart | Esc -> RESTART (or Esc, Down, Enter) | `II` -> RESTART |
| Back to the title screen (pick another chapter) | Esc -> QUIT TO TITLE | `II` -> QUIT TO TITLE |

Too dark / too scary / too hard? The knobs are at the top of `scripts/kinder.gd`
(`flashlight_*`, `fog_density`, wall colours, the scare words) and `scripts/monster.gd`
(`chase_speed`, `see_distance`, `hear_distance`, `lose_after`, `spawn_grace` - per kind in `_apply_kind`).

Every chapter is a **text map** in `scripts/chapters.gd` - move a `T`, add an `M`, hang a lamp with `L`,
put a hiding cupboard against a wall with `H`, a table with `t`, a shelf/locker/tank/swing with `S`,
crates or a slide with `Z`, a tree or pillar with `^`, draw a new room with `#`, and re-run.
`python3 tools/check_maps.py` tells you if a map is broken (unreachable toy, door without a button...)
and `make test` runs it too. The original battery arena is still there: `make arena`.

## Play it right now

```sh
make run        # opens the game fullscreen on the Mac (make window = in a window)
make arena      # the original open-arena battery game instead
make touch      # same, but shows the iPhone touch controls (click = finger)
make test       # 2-second headless check that nothing is broken
make mac        # double-clickable app -> build/mac/RobotSandbox.app
make ios        # Xcode project -> build/ios/RobotSandbox.xcodeproj (see iPhone below)
make ios-sim    # tries to build + launch in the iPhone Simulator (see caveat below)
make editor     # opens the Godot editor if you want to poke around visually
```

Requirements: `brew install --cask godot` (4.7) and Xcode (only for iPhone).
Export templates go in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`
(see `tools/setup.sh`, which does all of this for you).

## Where things live

```
scenes/kinder.tscn      The Abyss: dark environment/fog, first-person camera + flashlight, HUD, fade, touch controls
scripts/chapters.gd     THE 8 CHAPTERS: a text map + name + timed doors + creature size for each
scripts/kinder.gd       builds the chapter: colours/themes per room, scary knobs, walls/doors/buttons/toys/monsters/lamps
scripts/settings.gd     difficulty, which chapter you're on, what's unlocked, best times (saved between runs)
tools/check_maps.py     checks every chapter map is solvable (run by `make test`)
scripts/monster.gd      the creatures: behaviour knobs at the top, brain (A* paths, seeing/hearing), then a model per kind
scripts/lamp.gd         a flickering ceiling lamp (`L` on the map)
scripts/spooky_audio.gd hum / music box / panic music / your footsteps / chime / scream
scripts/sfx.gd          every sound effect, generated from maths (add a new one here)
scripts/blood_text.gd   the dripping blood letters
scripts/drone.gd        the flying drone (speed, how high it can go)
scripts/door.gd         a sliding door
scripts/button_pad.gd   a floor button
scenes/toy.tscn         one collectable toy (uses battery.gd)
scenes/robot.tscn       the player (collision capsule only - the body is built by robot.gd)
scripts/robot.gd        ROBOT DESIGN settings at the top + movement + jump
scenes/arena.tscn       the original open arena with batteries
scripts/arena.gd        BATTERY_SPOTS list + follow camera
scripts/battery.gd      spin, bob, get collected (toys and batteries)
scripts/game.gd         score / toy counter + on-screen messages (autoload singleton `Game`)
scripts/hud.gd          counter text + big messages
scripts/touch_controls.gd  on-screen joystick + JUMP + DRONE buttons (iPhone only)
tests/smoke_test.gd     headless test run by `make test`
```

The robot is **built from code** in `robot.gd`. Change the values under
`ROBOT DESIGN` (colours, head shape, wheels vs legs, antenna, size) and re-run.

## Playing with Devin

See [PLAYING_WITH_DEVIN.md](PLAYING_WITH_DEVIN.md) for a menu of prompts that work well
with an 8-year-old's attention span (each one is a ~1-minute change).

## iPhone (real device)

`make ios` writes an Xcode project to `build/ios/RobotSandbox.xcodeproj`.
Open it in Xcode, pick your Team under *Signing & Capabilities*, plug in the phone, press Run.
The placeholder team id in `export_presets.cfg` (`ABCDE12345`) only needs replacing if you
want Godot to sign the build for you.

## iPhone Simulator caveat

Godot's official iOS template only ships an **x86_64** simulator slice, and iOS 26+ simulator
runtimes are arm64-only. So on an Apple Silicon Mac `make ios-sim` needs Rosetta plus an
older runtime (`xcodebuild -downloadPlatform iOS -buildVersion 18.6`) and boots the simulator
in x86_64 mode. The Xcode project builds and links fine that way, but the Rosetta simulator
never finished booting on the (virtualised) Mac this was developed on, so the simulator path
is **unverified**. A real iPhone via Xcode is the reliable route.
