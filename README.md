# Robot Sandbox

A tiny 3D game built with [Godot 4](https://godotengine.org) that runs on Mac **and** iPhone.
It exists so a kid + a grown-up + Devin can say "make the robot green and add lava" and see it happen in seconds.

You play a little robot that runs around an arena collecting glowing batteries.
Collect them all and you win.

| Action | Mac keyboard | iPhone |
|---|---|---|
| Move | WASD or arrow keys | left joystick |
| Jump | Space | JUMP button |
| Restart | R | - |

## Play it right now

```sh
make run        # opens the game window on the Mac
make touch      # same, but shows the iPhone touch controls (click = finger)
make test       # 2-second headless check that nothing is broken
make mac        # double-clickable app -> build/mac/RobotSandbox.app
make ios-sim    # builds + launches in the iPhone Simulator
make editor     # opens the Godot editor if you want to poke around visually
```

Requirements: `brew install --cask godot` (4.7) and Xcode (only for iPhone).
Export templates go in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`
(see `tools/setup.sh`, which does all of this for you).

## Where things live (the whole game is ~400 lines)

```
scenes/main.tscn        the arena: floor, walls, ramp, block, camera, sun, HUD
scenes/robot.tscn       the player (collision capsule only - the body is built by robot.gd)
scenes/battery.tscn     one collectable battery
scripts/robot.gd        ROBOT DESIGN settings at the top + movement + jump
scripts/main.gd         BATTERY_SPOTS list + follow camera
scripts/battery.gd      spin, bob, get collected
scripts/game.gd         score (autoload singleton called `Game`)
scripts/hud.gd          score text + "YOU WIN!"
scripts/touch_controls.gd  on-screen joystick + jump button (iPhone only)
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
