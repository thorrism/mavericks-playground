# Robot Sandbox

A tiny 3D game built with [Godot 4](https://godotengine.org) that runs on Mac **and** iPhone.
It exists so a kid + a grown-up + Devin can say "make the robot green and add lava" and see it happen in seconds.

## Kinder Escape (the current game)

First person. You wake up in a dark, abandoned kindergarten with only a flashlight. Tall
things with glowing eyes wander the rooms - if one sees you it hunts you. Find all six toys,
use your drone to reach buttons the robot can't, open the coloured doors, and escape
through the golden exit.

- Almost no light: your **flashlight**, a few dying ceiling lamps that flicker, and the glow of the toys.
- Step on a **button** (or land the drone on it) and the door of the same colour opens.
- **Low walls**: only the drone can fly over them. **Fences**: the robot can jump over.
- A **monster** that grabs you: the screen flashes red, goes black, and you wake up at the start (you keep your toys).
- Collect every toy and the **golden door** opens.
- Sound is generated from code: a low hum, a heartbeat that speeds up when you're being hunted, a screech when caught.

| Action | Mac keyboard | iPhone |
|---|---|---|
| Look around | mouse (Esc releases it, click the window to grab it again) | drag anywhere on screen |
| Move | WASD or arrow keys (relative to where you look) | left joystick |
| Jump / drone up | Space (hold to fly the drone up) | JUMP button |
| Switch robot <-> drone | E | DRONE button |
| Restart | R | - |

Too dark / too scary / not scary enough? The knobs are at the top of `scripts/kinder.gd`
(`flashlight_*`, `fog_density`, the colours) and `scripts/monster.gd` (speed, eyes, how far it sees).

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
scripts/monster.gd      the lurking/hunting monster (look + behaviour settings at the top)
scripts/lamp.gd         a flickering ceiling lamp (`L` on the map)
scripts/spooky_audio.gd hum / heartbeat / screech, all generated from maths
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
