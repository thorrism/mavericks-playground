#!/usr/bin/env bash
# Build the exported Xcode project for the iPhone Simulator, install it on the
# booted simulator (booting one if needed) and launch it.
set -euo pipefail

cd "$(dirname "$0")/.."
PROJ=build/ios/RobotSandbox.xcodeproj
BUNDLE_ID=com.robotsandbox.game
DERIVED=build/ios/derived

[ -d "$PROJ" ] || { echo "Run 'make ios' first (missing $PROJ)"; exit 1; }

# Godot's official iOS template only ships an x86_64 simulator slice, so on an
# Apple Silicon Mac the simulator app runs under Rosetta.
SIM_LIB=$(find build/ios/RobotSandbox.xcframework -path '*simulator*' -name 'libgodot.a' | head -1)
if lipo -archs "$SIM_LIB" | grep -q arm64; then SIM_ARCH=arm64; else SIM_ARCH=x86_64; fi
if [ "$SIM_ARCH" = x86_64 ] && ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "==> Installing Rosetta (needed to run the x86_64 simulator build)"
  sudo softwareupdate --install-rosetta --agree-to-license
fi

TARGET=$(xcodebuild -project "$PROJ" -list -json | python3 -c 'import json,sys; print(json.load(sys.stdin)["project"]["targets"][0])')

echo "==> Building target '$TARGET' for the iPhone Simulator"
xcodebuild -project "$PROJ" -target "$TARGET" -configuration Debug \
  -sdk iphonesimulator -arch "$SIM_ARCH" \
  SYMROOT="$PWD/$DERIVED" OBJROOT="$PWD/$DERIVED/obj" \
  SDKROOT=iphonesimulator SUPPORTED_PLATFORMS="iphoneos iphonesimulator" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build -quiet

APP=$(find "$DERIVED" -maxdepth 2 -name '*.app' -path '*iphonesimulator*' | head -1)
[ -n "$APP" ] || { echo "No .app produced"; exit 1; }

# Pick an iPhone whose runtime supports SIM_ARCH (prefer one that's already booted).
DEVICE=$(xcrun simctl list -j devices available runtimes | python3 -c '
import json,sys
j=json.load(sys.stdin); want=sys.argv[1]
ok={r["identifier"] for r in j["runtimes"] if want in r.get("supportedArchitectures",[])}
xs=[x for k,v in j["devices"].items() if k in ok for x in v if x["name"].startswith("iPhone")]
if not xs:
    sys.exit(f"No iPhone simulator runtime supports {want}. Install one, e.g.:\n  xcodebuild -downloadPlatform iOS -buildVersion 18.6")
xs.sort(key=lambda x: x["state"]!="Booted")
print(xs[0]["udid"] + " " + xs[0]["state"])' "$SIM_ARCH")
BOOTED=${DEVICE% *}
STATE=${DEVICE#* }
# The simulator must be booted with the same arch as the app (x86_64 => Rosetta).
if [ "$STATE" = Booted ] && [ "$(xcrun simctl getenv "$BOOTED" SIMULATOR_ARCHS 2>/dev/null)" != "$SIM_ARCH" ]; then
  echo "==> Rebooting simulator as $SIM_ARCH"
  xcrun simctl shutdown "$BOOTED"
  STATE=Shutdown
fi
if [ "$STATE" != Booted ]; then
  echo "==> Booting iPhone simulator ($SIM_ARCH)"
  xcrun simctl boot "$BOOTED" --arch="$SIM_ARCH"
fi
open -a Simulator

echo "==> Installing $APP"
xcrun simctl install "$BOOTED" "$APP"
echo "==> Launching $BUNDLE_ID"
xcrun simctl launch "$BOOTED" "$BUNDLE_ID"
echo "Done - the game is running in the iPhone Simulator."
