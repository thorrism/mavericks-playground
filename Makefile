GODOT ?= godot
BUILD  := build

.PHONY: run arena touch test maps import editor mac ios ios-sim clean

## Play the game on this Mac (keyboard: WASD / arrows, Space = jump, E = drone, F = flashlight, Esc = pause)
run: import
	$(GODOT) --path . -- $(ARGS)

## Play the original open-arena battery game instead
arena: import
	$(GODOT) --path . scenes/arena.tscn -- $(ARGS)

## Play on the Mac but with the iPhone touch controls showing (click = finger)
touch: import
	$(GODOT) --path . -- --touch

## Headless smoke test - fails loudly if the game is broken (checks all 8 chapter maps first)
test: maps import
	$(GODOT) --headless --path . -s tests/smoke_test.gd

## Check every chapter map: one start, one exit, every toy/button/door reachable, doors have buttons
maps:
	python3 tools/check_maps.py

## Re-import assets (needed after adding files); safe to run any time
import:
	@$(GODOT) --headless --path . --import >/dev/null 2>&1 || true

## Open the Godot editor for this project
editor:
	$(GODOT) --path . --editor &

## Build a double-clickable Mac app -> build/mac/RobotSandbox.app
mac: import
	mkdir -p $(BUILD)/mac
	$(GODOT) --headless --path . --export-release "macOS" $(BUILD)/mac/RobotSandbox.app

## Export the iOS Xcode project -> build/ios/RobotSandbox.xcodeproj
ios: import
	mkdir -p $(BUILD)/ios
	$(GODOT) --headless --path . --export-debug "iOS" $(BUILD)/ios/RobotSandbox.xcodeproj

## Build + install + launch on the booted iPhone Simulator
ios-sim: ios
	./tools/run_ios_sim.sh

clean:
	rm -rf $(BUILD) .godot
