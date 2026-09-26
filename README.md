# Robot Sandbox

A tiny 3D game built with [Godot 4](https://godotengine.org) that runs on Mac **and** iPhone.
It exists so a kid + a grown-up + Devin can say "make the robot green and add lava" and see it happen in seconds.

## Kinder Escape (the current game)

First person. You wake up in a dark, abandoned kindergarten with only a flashlight. Three
things live here and hunt you if they see or hear you. Find all six toys, use your drone to
reach buttons the robot can't, open the coloured doors, and escape through the golden exit
at the very top of the school.

- Almost no light: your **flashlight**, a few dying ceiling lamps that flicker, and the glow of the toys.
- Grimy **coloured walls** with stripes, torn posters, bloody handprints and words scrawled on them.
- Step on a **button** (or land the drone on it) and the door of the same colour opens.
- **Low walls**: only the drone can fly over them. **Fences**: the robot can jump over.
- Three **monsters** (map letters `M`, `J`, `O`): a tall teal grinning thing with a bow tie, a huge green
  brute, and a lanky yellow bird - one per room. They know the way around walls, run to where they
  last saw you and search there - but you are a bit faster, and **a monster never leaves its own
  room**: get through a doorway and it gives up. They also leave you alone for the first few seconds
  after a (re)start.
- **Seen**: dripping blood letters, a scream, red screen edges, shaking, your flashlight stutters,
  and the music turns into panic. **Caught**: red flash, black, and the level starts over.
- Collect every toy and the **golden door** opens and glows; walk through it to escape.
- All sound is generated from code: footsteps (yours and theirs, heavier when they chase), a toy chime,
  a broken music-box tune, the drone's rotor whine, and each monster's own voice.
- The **drone** is unlimited: `E` sends it out, `E` again brings you back, as often as you like.
  Monsters ignore your parked body while you fly.

| Action | Mac keyboard | iPhone |
|---|---|---|
| Look around | mouse (Esc releases it, click the window to grab it again) | drag anywhere on screen |
| Move | WASD or arrow keys (relative to where you look) | left joystick |
| Jump / drone up | Space (hold to fly the drone up) | JUMP button |
| Switch robot <-> drone | E | DRONE button |
| Restart | R | - |

Too dark / too scary / too hard? The knobs are at the top of `scripts/kinder.gd`
(`flashlight_*`, `fog_density`, wall colours, the scare words) and `scripts/monster.gd`
(`chase_speed`, `see_distance`, `hear_distance`, `lose_after`, `spawn_grace` - per kind in `_apply_kind`).

The whole level is a **text map** at the top of `scripts/kinder.gd` - move a `T`, add an `M`,
hang a lamp with `L`, draw a new room with `#`, and re-run. The original battery arena is still there too: `make arena`.

## Play it right now

```sh
make run        # opens the game window on the Mac
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
scenes/kinder.tscn      Kinder Escape: dark environment/fog, first-person camera + flashlight, HUD, fade, touch controls
scripts/kinder.gd       THE MAP (text) + colours + scary knobs + builds walls/doors/buttons/toys/monsters/lamps
scripts/monster.gd      the three monsters: behaviour knobs at the top, brain (A* paths, seeing/hearing), then the models
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
