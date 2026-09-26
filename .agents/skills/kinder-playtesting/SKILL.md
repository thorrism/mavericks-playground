---
name: kinder-playtesting
description: Record and inspect first-person Godot gameplay on the macOS VM, including short monster attack animations.
---

# The Abyss (Kinder Escape) runtime testing

- Use the worktree named in the current handoff; several game checkouts can
  exist. Confirm branch/commit and stop stale Godot instances before launching
  `make run`. Capture stdout/stderr in a revision-specific log.
- No service login is required. CoreAudio may fail on the VM and fall back to
  a dummy driver; distinguish that warning from SCRIPT ERROR or Sfx warnings.
- Maximize using the macOS green window control before recording. Escape
  releases the mouse; click recaptures it. Recapture can jerk the view.
  R restores the initial view, but the desktop cursor's stored position may
  differ from the game's captured pointer. Confirm orientation visually rather
  than assuming repeated absolute mouse moves produce repeated turns.
- Use hold_key for gameplay. On the fenced pad, let the first jump land before
  jumping back out. Confirm the visible clunk message before assuming the door
  is open; a jump may land near but not on the button.
- Tool-response latency exceeds short attack windups. Record at 30 fps and
  review raw footage for arms-up warning, strike, blood text, and restart.
  Preserve full-speed clips: condensed recordings can hide keyboard motion.
- For subsecond reaction tests, timestamp windup, actual input edges and
  impact with temporary print-only logging. Native OS key delivery can avoid
  tool latency without changing gameplay, but disclose it and remove logging.
  Measure held durations and gaps: sequential hold_key calls can add pauses.
- Count engaged impacts separately from navigation/calibration attempts,
  drone-disengaged swings and stationary follow-up hits after a dodge.
- A moving dodge can carry the monster offscreen. The miss text establishes
  the dodge outcome, but does not by itself prove the recovery pose or duration.
- If authorized teleport assistance is needed, Godot editor Remote tree →
  Kinder → Robot → filter `position` → Transform Position changes the live node.
  Do not confuse it with Spawn Position or edit score/attack parameters.
- The editor may normalize project.godot comments/default settings. Compare
  before/after and revert only tester-generated changes. Never revert concurrent
  edits owned by another agent. Kill Godot when finished.

## Devin Secrets Needed

None for local gameplay.
