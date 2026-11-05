#!/usr/bin/env bash
# login-video-setup: choose the video for the current user.
#   login-video-setup /path/to/video.mp4   set video and start now
#   login-video-setup --remove              remove this user's settings

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/login-video"
# matches only the running script itself: /usr/bin/login-video or ~/.local/bin/login-video.sh
PATTERN='^(/[^ ]*/)?bash [^ ]*/bin/login-video(\.sh)?$'

usage() {
  echo "Usage: login-video-setup /path/to/video.mp4"
  echo "       login-video-setup --remove"
}

case "$1" in
  ""|-h|--help) usage; exit 0 ;;
  --remove)
    pkill -f "$PATTERN" 2>/dev/null
    rm -rf "$CONF"
    echo "Your login-video settings were removed."
    exit 0 ;;
esac

VIDEO="$(readlink -f "${1/#\~/$HOME}")"
if [ ! -f "$VIDEO" ]; then
  echo "File not found: $VIDEO" >&2
  exit 1
fi

mkdir -p "$CONF"
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

# Stop an older running copy (it holds the lock), then start now
pkill -f "$PATTERN" 2>/dev/null
sleep 1
nohup login-video >/dev/null 2>&1 &

echo "Done. The video will play at login, after wake and after unlock."
echo "Settings: $CONF/config"
