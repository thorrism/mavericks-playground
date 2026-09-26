#!/usr/bin/env bash
# One-time machine setup: Godot 4.7.2 + the macOS/iOS export templates.
# Safe to re-run.
set -euo pipefail

GODOT_VERSION=4.7.2
TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"

if ! command -v godot >/dev/null; then
  echo "==> Installing Godot via Homebrew"
  brew install --cask godot
fi
echo "Godot: $(godot --version)"

if [ ! -f "$TEMPLATES_DIR/macos.zip" ] || [ ! -f "$TEMPLATES_DIR/ios.zip" ]; then
  echo "==> Downloading export templates (~1.3 GB, one time)"
  TMP=$(mktemp -d)
  curl -sSL -o "$TMP/templates.tpz" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
  mkdir -p "$TEMPLATES_DIR"
  # only keep the two we need (the full set is ~2 GB)
  unzip -q -o -j "$TMP/templates.tpz" templates/macos.zip templates/ios.zip templates/version.txt -d "$TEMPLATES_DIR"
  rm -rf "$TMP"
fi
echo "Export templates: $TEMPLATES_DIR"

cd "$(dirname "$0")/.."
godot --headless --path . --import >/dev/null 2>&1 || true
echo "==> Ready. Try: make run"
