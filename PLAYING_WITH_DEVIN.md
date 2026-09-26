# Playing with Devin

How a session goes: you (or your kid) describe a change, Devin edits a file or two,
runs `make test` and `make run`, and shows a screenshot. Aim for one small idea per prompt -
every prompt below is a 1-3 minute change so nobody gets bored waiting.

**Tip for Devin:** always `make test && make run`, take a screenshot (`screencapture`), and
attach it. Kids want to *see* it. Keep the code in the existing files; no new systems unless asked.

## Warm-up (30 seconds each) - change a number or a colour

- "Make the robot red with a round head."
- "Give the robot wheels instead of legs."
- "Make the robot HUGE." / "Make the robot tiny."
- "Make the robot jump way higher." (`jump_power` in robot.gd)
- "Make the robot super fast."
- "Take the antenna off." / "Put two antennas on."
- "Make the floor lava-orange and the walls black."
- "Make the sky purple." (sky colours in main.tscn)

## Small features (1-3 minutes)

- "Add 20 more batteries all over the place." (`BATTERY_SPOTS` in main.gd)
- "Make batteries worth 100 points."
- "Add a bunch of boxes to jump on." (copy the `TallBlock` node in main.tscn)
- "Add a second ramp."
- "Make the camera closer / further away / look from the top."
- "When you win, say 'ROBOT CHAMPION!' instead."
- "Add a timer that counts down from 60 and shows it on screen."
- "Make the batteries different colours."
- "Make a big hole in the floor you can fall through." (then the robot respawns - already handled)

## Bigger ideas (5-10 minutes) - good for when attention is high

- "Add a bad robot that chases you. If it touches you, you go back to the start."
- "Add a dash move when you press Shift."
- "Let me build the robot in-game: press 1/2/3 to change the head, 4/5 to change colours."
- "Add a second level that loads after you collect everything."
- "Add coins that make you grow bigger, and spikes that make you smaller."
- "Add a rocket boost: hold Space in the air to fly."
- "Make trampolines that bounce you really high."
- "Add a robot friend that follows you around."

## Totally different game? Also fine

The engine doesn't care that it's robots. Reuse `robot.gd` as any character, swap the arena,
or start a new `scenes/whatever.tscn` and point `run/main_scene` in `project.godot` at it.
Ideas that fit the same skeleton: dinosaur collecting eggs, spaceship dodging asteroids,
cat knocking cups off tables, racing a car through cones.

## Checking it on the phone

- `make touch` shows the on-screen joystick on the Mac (click and drag = finger).
- `make ios-sim` runs it in the iPhone Simulator.
- Real iPhone: open `build/ios/RobotSandbox.xcodeproj` in Xcode and press Run.
