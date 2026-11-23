#!/usr/bin/env bash
# Linux / cloud setup: installs Godot headless so `make test` works in a
# Claude Code cloud session (or any Linux CI box). No export templates:
# the cloud only runs tests, Mac/iPhone builds stay on the Mac (tools/setup.sh).
# Safe to re-run. Usable as a cloud environment setup script:
#   bash tools/setup_cloud.sh
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
[ -w "$INSTALL_DIR" ] || INSTALL_DIR="$HOME/.local/bin"

if command -v godot >/dev/null && godot --version 2>/dev/null | grep -q "^${GODOT_VERSION}\.stable"; then
  echo "Godot already installed: $(godot --version)"
  exit 0
fi

case "$(uname -m)" in
  x86_64)        ARCH=x86_64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

NAME="Godot_v${GODOT_VERSION}-stable_linux.${ARCH}"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${NAME}.zip"

echo "==> Downloading Godot ${GODOT_VERSION} (${ARCH})"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL --retry 4 -o "$TMP/godot.zip" "$URL"
python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$TMP/godot.zip" "$TMP"
mkdir -p "$INSTALL_DIR"
install -m 755 "$TMP/$NAME" "$INSTALL_DIR/godot"

echo "Godot: $("$INSTALL_DIR/godot" --headless --version)  ->  $INSTALL_DIR/godot"
case ":$PATH:" in *":$INSTALL_DIR:"*) ;; *) echo "Note: add $INSTALL_DIR to PATH" ;; esac
