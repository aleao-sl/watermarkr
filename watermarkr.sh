#!/bin/bash
#
# watermarkr — auto-watermark every screenshot on macOS
# Author:  Augusto Leao  <https://github.com/aleao-sl>
# Source:  https://github.com/aleao-sl/watermarkr
# License: MIT (see LICENSE)
#

# Resolve the directory this script lives in so the config sits next to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/watermarkr.conf"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: setup has not been run yet (missing $CONFIG)." >&2
  echo "Please run: $SCRIPT_DIR/setup.sh" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG"

# Directory used for atomic per-file locks (mkdir is atomic, prevents double-processing)
LOCK_DIR="/tmp/watermarkr_locks"
mkdir -p "$LOCK_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

is_image() {
  local lower
  lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff|*.tif|*.webp|*.heic) return 0 ;;
    *) return 1 ;;
  esac
}

add_watermark() {
  local file="$1"

  [[ ! -f "$file" ]] && return
  is_image "$file" || return

  # Atomic per-file lock: only the first event wins, duplicates bail out
  local lock="$LOCK_DIR/$(echo "$file" | md5 -q)"
  mkdir "$lock" 2>/dev/null || return

  # Give the file a moment to finish writing before we read it
  sleep 2

  log "Watermarking: $file"

  "$MAGICK_BIN" "$file" \
    -gravity SouthEast \
    -font "$FONT" \
    -pointsize 27 \
    -stroke "rgba(80,80,80,0.5)" -strokewidth 2 -fill "rgba(255,255,255,0.5)" \
    -annotate +20+20 "$WATERMARK_TEXT" \
    "$file" 2>> "$LOG" && log "Done: $file" || log "FAILED: $file"
}

log "Watcher started on $WATCH_DIR"

# Created + Renamed: macOS screenshots arrive via rename (temp → final).
# The lock above prevents double-processing if both events fire.
"$FSWATCH_BIN" -0 --event Created --event Renamed "$WATCH_DIR" | \
  while IFS= read -r -d $'\0' file; do
    add_watermark "$file"
  done
