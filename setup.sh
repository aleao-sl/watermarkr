#!/bin/bash
set -euo pipefail

# Setup: verify dependencies, create/update config (interactive prompts),
# generate the LaunchAgent plist, and install it to ~/Library/LaunchAgents.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/watermarkr.conf"
CONFIG_bk="$SCRIPT_DIR/watermarkr.conf_bk"
WATERMARK_SH="$SCRIPT_DIR/watermarkr.sh"
# Sanitize $(whoami) for use in a reverse-DNS LaunchAgent label:
# keep ASCII letters/digits only, lowercase, cap at 32 chars, fall back to
# "user" if nothing usable remains. macOS usernames are already constrained,
# but odd locales or modified accounts can produce surprises — be defensive.
USER_RAW="$(whoami)"
USER_SAFE="$(printf '%s' "$USER_RAW" | LC_ALL=C tr -cd 'A-Za-z0-9' | tr '[:upper:]' '[:lower:]' | cut -c1-32)"
USER_SAFE="${USER_SAFE:-user}"
LABEL="com.$USER_SAFE.watermarkr"
PLIST_NAME="$LABEL.plist"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

# --- Dependency check ----------------------------------------------------
missing=()
for bin in fswatch magick; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if (( ${#missing[@]} > 0 )); then
  echo "Missing dependencies: ${missing[*]}" >&2
  echo "Install with: brew install fswatch imagemagick" >&2
  exit 1
fi

FSWATCH_BIN="$(command -v fswatch)"
MAGICK_BIN="$(command -v magick)"

# --- Defaults ------------------------------------------------------------
DEFAULT_WATERMARK_TEXT="© $(id -F 2>/dev/null || whoami)"
# macOS stores the screenshot save location in this preference; fall back to
# Desktop (the system default when no override is set)
DEFAULT_WATCH_DIR="$(defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop")"
DEFAULT_WATCH_DIR="${DEFAULT_WATCH_DIR/#\~/$HOME}"
DEFAULT_LOG="$SCRIPT_DIR/watermarkr.log"

# Prefer the bundled font, otherwise fall back to a system font that always exists
if [[ -f "$SCRIPT_DIR/MonaSans-Regular.ttf" ]]; then
  DEFAULT_FONT="$SCRIPT_DIR/MonaSans-Regular.ttf"
else
  DEFAULT_FONT="/System/Library/Fonts/Helvetica.ttc"
fi

if [[ -f "$CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
  DEFAULT_WATERMARK_TEXT="${WATERMARK_TEXT:-$DEFAULT_WATERMARK_TEXT}"
  DEFAULT_WATCH_DIR="${WATCH_DIR:-$DEFAULT_WATCH_DIR}"
  DEFAULT_LOG="${LOG:-$DEFAULT_LOG}"
  DEFAULT_FONT="${FONT:-$DEFAULT_FONT}"

  cp "$CONFIG" "$CONFIG_bk"
  echo "Backed up existing config → $CONFIG_bk"
fi

ask() {
  local prompt="$1" default="$2" answer
  read -r -p "$prompt [$default]: " answer
  echo "${answer:-$default}"
}

echo "Configure watermark (press Enter to accept the default)"
WATERMARK_TEXT=$(ask "Watermark text"     "$DEFAULT_WATERMARK_TEXT")
WATCH_DIR=$(ask     "Watch directory"     "$DEFAULT_WATCH_DIR")
LOG=$(ask           "Log file path"       "$DEFAULT_LOG")
FONT=$(ask          "Font file path"      "$DEFAULT_FONT")

if [[ ! -f "$FONT" ]]; then
  echo "Warning: font file not found at $FONT — watermarking will fail until this is fixed." >&2
fi

cat > "$CONFIG" <<EOF
# Watermarkr configuration

WATERMARK_TEXT="$WATERMARK_TEXT"
WATCH_DIR="$WATCH_DIR"
LOG="$LOG"
FONT="$FONT"

# Resolved by setup.sh — paths to the binaries the watcher needs
FSWATCH_BIN="$FSWATCH_BIN"
MAGICK_BIN="$MAGICK_BIN"
EOF
echo "Wrote config: $CONFIG"

mkdir -p "$WATCH_DIR"
chmod +x "$WATERMARK_SH"

cat > "$PLIST_SRC" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>$WATERMARK_SH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
  </dict>
</plist>
EOF
echo "Generated plist: $PLIST_SRC"

mkdir -p "$HOME/Library/LaunchAgents"

if launchctl list | grep -q "$LABEL"; then
  launchctl unload "$PLIST_DEST" 2>/dev/null || true
  echo "LaunchAgent unloaded"
fi

cp "$PLIST_SRC" "$PLIST_DEST"
echo "Installed: $PLIST_DEST"

launchctl load "$PLIST_DEST"
echo "Loaded LaunchAgent $LABEL"
