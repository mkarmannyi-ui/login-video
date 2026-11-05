#!/usr/bin/env bash
set -e

VIDEO="$1"
if [ -z "$VIDEO" ]; then
  read -r -p "Full path to your video file: " VIDEO
fi
VIDEO="$(readlink -f "${VIDEO/#\~/$HOME}")"
if [ ! -f "$VIDEO" ]; then
  echo "File not found: $VIDEO" >&2
  exit 1
fi

# Dependencies
if ! command -v mpv >/dev/null; then
  echo "Installing mpv (needs sudo)..."
  sudo apt update && sudo apt install -y mpv
fi

BIN="$HOME/.local/bin"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/login-video"
AUTO="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
mkdir -p "$BIN" "$CONF" "$AUTO"

cp "$(dirname "$0")/login-video.sh" "$BIN/login-video.sh"
chmod +x "$BIN/login-video.sh"

cat > "$CONF/config" << CFG
VIDEO="$VIDEO"
LOGIN_DELAY=3
WAKE_DELAY=1
UNLOCK_DELAY=1
PLAY_ON_LOGIN=yes
PLAY_ON_WAKE=yes
PLAY_ON_UNLOCK=yes
LOCK_PLAYER=yes
SYSTEM_VOLUME=80
MAX_SECONDS=600
CFG

cat > "$AUTO/login-video.desktop" << DESK
[Desktop Entry]
Type=Application
Name=Login Video
Exec=$BIN/login-video.sh
X-GNOME-Autostart-enabled=true
DESK

# Stop an older running copy (it holds the lock), then start the new one
pkill -f '^(/[^ ]*/)?bash [^ ]*/bin/login-video(\.sh)?$' 2>/dev/null || true
sleep 1
nohup "$BIN/login-video.sh" >/dev/null 2>&1 &

echo "Done. The video will play at login and after wake."
echo "Config: $CONF/config"
