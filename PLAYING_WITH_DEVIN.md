# Playing with Devin

How a session goes: you (or your kid) describe a change, Devin edits a file or two,
runs `make test` and `make run`, and shows a screenshot. Aim for one small idea per prompt -
every prompt below is a 1-3 minute change so nobody gets bored waiting.

**Tip for Devin:** always `make test && make run`, take a screenshot (`screencapture`), and
attach it. Kids want to *see* it. Keep the code in the existing files; no new systems unless asked.

## Kinder Escape - the level is a text map

The whole kindergarten is drawn at the top of `scripts/kinder.gd`:

```
##########X#########      #  wall        T  toy        X  golden exit door
#..................#      W  low wall (drone only)     =  fence (jump over)
#.T..J......L..M.T.#      L  flickering lamp            1 2 3 doors   a b c buttons  (a opens 1, b opens 2 ...)
#..................#      M  Banbo (tall teal)   J  Jumbo (big green)   O  Opi the bird (not on the map right now)
```

So "add a bird in the top room" is literally typing one `O`. It's dark and first person:
the scary knobs (`flashlight_*`, `fog_density`, wall colours, `scare_words`) are right under the map,
and how hard the monsters are is at the top of `scripts/monster.gd`. The title screen has
EASY / NORMAL / NIGHTMARE (multipliers in `scripts/settings.gd`; it remembers your pick, your
tries and your best escape time), Esc pauses (RESTART lives in that menu - no restart key, so nobody hits it by accident). Best first prompts:

## Warm-up (30 seconds each) - change a letter, a number or a colour

- "Put 3 more toys in the big room." (add `T`s to the map)
- "Add another bird next to the start." (add an `O`; `M` and `J` for the other two)
- "Make the tall one pink." / "Make the bird's legs purple." (`color` per kind in `_apply_kind`, monster.gd)
- "Make the monsters slower / faster / easier." (`chase_speed`, `see_distance`, `lose_after` in monster.gd)
- "Give me more time to dodge" / "make Jumbo's swing reach further." (`windup_time`, `commit_before`, `swing_width`, `strike_range` in monster.gd's Attack group)
- "Make EASY even easier" / "add an IMPOSSIBLE mode." (`TUNING`, `NAMES`, `BLURBS` in settings.gd)
- "Call the game something else on the title screen." (`"KINDER ESCAPE"` in menu.gd)
- "Make the button sound louder" / "make the door creak longer." (`click` and `door` in sfx.gd)
- "Make them hear me from further away." (`hear_distance`)
- "Let the bird follow me anywhere / through doors." (set that monster's `_room = -1` in monster.gd)
- "Change the bloody words when I get seen." (`scare_words` in kinder.gd)
- "Paint the walls green and purple." (`WALL_COLORS` in kinder.gd)
- "Make the drone sound higher / louder." (`drone` in sfx.gd, `_update_whine` in drone.gd)
- "Make it even darker" / "a bit brighter". (`flashlight_energy`, `fog_density`, `ambient_light_energy` in kinder.tscn)
- "Make the lamps flicker like crazy" / "add a lamp in the start room." (`flicker` in lamp.gd, an `L` on the map)
- "Make the walls black and the floor lava." (colours at the top of kinder.gd)
- "Make the drone go super fast." (`speed` in drone.gd)
- "Make the robot red with a round head." (ROBOT DESIGN in robot.gd - you see it when you fly the drone)
- "Change what it says when the monster gets me." (`_on_caught` in kinder.gd)

## Small features (1-3 minutes)

- "Add a new room on the right with a purple door and a purple button." (draw it in the map: door `2`, button `b`)
- "Make a secret room only the drone can get into." (surround it with `W`)
- "Put the exit on the left side instead." (move the `X`)
- "Make the monsters give up chasing sooner." (`see_distance`)
- "Show the best time on the screen while I play." (`time_label` in hud.gd, `Settings.best_time`)
- "Make the toys spin faster and glow more."
- "When you escape, show fireworks / say 'MAVERICK WINS!'."
- "Put a fence maze in the middle room."

## Bigger ideas (5-10 minutes) - good for when attention is high

- "Make a level 2 that loads after you escape." (a second `MAP`)
- "Let me throw a toy to distract the monster."
- "Make the flashlight run out of battery - find batteries to recharge it."
- "Add a friendly monster that follows you and blocks the mean ones."
- "Add keys: a red key opens the red door instead of a button."
- "Add a monster that only moves when you're not looking at it."
- "Add hiding spots (lockers) the monster can't see into."
- "Make the monster knock on the door before it comes in."

## The old arena is still there

`make arena` runs the original battery-collecting game (`scenes/arena.tscn`). All the old
prompts still work on it: "add 20 batteries", "add a ramp", "make the robot huge", etc.

## Totally different game? Also fine

The engine doesn't care that it's robots and monsters. Reuse `robot.gd` as any character,
draw a different map, or start a new `scenes/whatever.tscn` and point `run/main_scene` in
`project.godot` at it. Ideas that fit the same skeleton: dinosaur collecting eggs, spaceship
dodging asteroids, cat knocking cups off tables, racing a car through cones.

## Checking it on the phone

- `make touch` shows the on-screen joystick + JUMP + DRONE buttons on the Mac (click and drag = finger).
- Real iPhone: `make ios`, open `build/ios/RobotSandbox.xcodeproj` in Xcode and press Run.
