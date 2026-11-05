#!/usr/bin/env bash
# login-video: play a video at Ubuntu login, after waking from suspend,
# and after unlocking the screen (Win+L, lock after wake).

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/login-video/config"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/login-video.log"
VIDEO=""
LOGIN_DELAY=3      # seconds to wait after login so the desktop is ready
WAKE_DELAY=1       # seconds to wait after wake
UNLOCK_DELAY=1     # seconds to wait after unlocking
PLAY_ON_LOGIN=yes
PLAY_ON_WAKE=yes
PLAY_ON_UNLOCK=yes
LOCK_PLAYER=yes    # yes = video cannot be paused/closed with mouse or keyboard
SYSTEM_VOLUME=80   # laptop volume in percent before playing (empty = don't touch)
MAX_SECONDS=600    # safety: stop the video after this many seconds (0 = no limit)

# shellcheck disable=SC1090
[ -f "$CONFIG" ] && source "$CONFIG"
[ -n "$1" ] && VIDEO="$1"

CONFIG_DIR="$(dirname "$CONFIG")"
INPUT_CONF="$CONFIG_DIR/mpv-input.conf"

log() { mkdir -p "$(dirname "$LOG")"; echo "$(date '+%F %T') $*" >> "$LOG"; }

if [ -z "$VIDEO" ]; then
  # Not set up yet (for example right after installing the .deb): stay quiet
  log "no video configured. Run: login-video-setup /path/to/video.mp4"
  exit 0
fi

if [ ! -f "$VIDEO" ]; then
  msg="Video not found: '$VIDEO'. Edit $CONFIG"
  echo "$msg" >&2
  log "$msg"
  command -v notify-send >/dev/null && notify-send "login-video" "$msg"
  exit 1
fi

# Only one watcher at a time
LOCK="${XDG_RUNTIME_DIR:-/tmp}/login-video.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

# mpv input file: ignore the window "close" request (Alt+F4, close button)
mkdir -p "$CONFIG_DIR"
printf '%s\n' '# Ignore the window close request' 'CLOSE_WIN ignore' > "$INPUT_CONF"

# Set the laptop volume (PipeWire first, PulseAudio as fallback) and unmute
set_volume() {
  [ -n "$SYSTEM_VOLUME" ] || return
  if command -v wpctl >/dev/null; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${SYSTEM_VOLUME}%" 2>/dev/null
  elif command -v pactl >/dev/null; then
    pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null
    pactl set-sink-volume @DEFAULT_SINK@ "${SYSTEM_VOLUME}%" 2>/dev/null
  fi
}

# Runs mpv. Tries the strictest options first; if mpv fails right away
# (for example an option your mpv version does not know), it logs the error
# and tries a simpler set, so a video always plays.
run_player() {
  local level rc t0 secs
  local -a args
  for level in locked basic minimal; do
    case "$level" in
      locked)
        # Fullscreen, no border, no controls, player volume 100%
        args=(--title=login-video-player --fs --ontop --keep-open=no
              --msg-level=all=error --no-config
              --no-osc --osd-level=0 --no-border
              --volume=100 --volume-max=100)
        if [ "$LOCK_PLAYER" = "yes" ]; then
          # No keyboard, no mouse, no pause, no close, hidden cursor
          args+=(--no-input-default-bindings --input-conf="$INPUT_CONF"
                 --no-input-cursor --input-vo-keyboard=no --no-input-media-keys
                 --no-window-dragging --cursor-autohide=always)
        fi ;;
      basic)
        args=(--title=login-video-player --fs --ontop --keep-open=no
              --msg-level=all=error --no-osc --osd-level=0 --no-border
              --volume=100)
        if [ "$LOCK_PLAYER" = "yes" ]; then
          args+=(--no-input-default-bindings --input-conf="$INPUT_CONF")
        fi ;;
      minimal)
        # exactly the options of the first working version
        args=(--title=login-video-player --fs --ontop --no-terminal
              --really-quiet --keep-open=no) ;;
    esac
    t0=$(date +%s)
    # "timeout" is the safety net so a wrong/very long file cannot trap you
    timeout "$MAX_SECONDS" mpv "${args[@]}" "$VIDEO" </dev/null >/dev/null 2>>"$LOG"
    rc=$?
    secs=$(( $(date +%s) - t0 ))
    log "mpv level=$level exit=$rc after ${secs}s"
    if [ "$rc" -eq 0 ] || [ "$rc" -eq 124 ] || [ "$secs" -ge 3 ]; then
      return
    fi
  done
}

play() {
  # Do not start a second player if one is already running
  pgrep -f -- "--title=login-video-player" >/dev/null && return
  log "playing video"
  set_volume
  run_player &
}

# Ask GNOME whether the lock screen is active. Prints "yes", "no" or "error".
screen_locked() {
  local out
  out=$(gdbus call --session --dest org.gnome.ScreenSaver \
        --object-path /org/gnome/ScreenSaver \
        --method org.gnome.ScreenSaver.GetActive 2>/dev/null) || { echo error; return; }
  case "$out" in
    *true*) echo yes ;;
    *)      echo no ;;
  esac
}

locked=$(screen_locked)
log "started (lock state: $locked)"
[ "$locked" = "error" ] && log "cannot read lock state, unlock detection disabled"

if [ "$PLAY_ON_LOGIN" = "yes" ]; then
  sleep "$LOGIN_DELAY"
  play
fi

# Main loop, every 2 seconds:
#  - wake detection: while the laptop sleeps this loop is frozen but the clock
#    keeps running, so a gap much bigger than 2 s means "just woke up".
#  - unlock detection: lock screen was active and now is not.
last=$(date +%s)
while true; do
  sleep 2
  now=$(date +%s)

  if [ $((now - last)) -gt 6 ]; then
    log "wake detected (gap $((now - last)) s)"
    if [ "$PLAY_ON_WAKE" = "yes" ]; then
      sleep "$WAKE_DELAY"
      play
    fi
    now=$(date +%s)
  fi

  current=$(screen_locked)
  if [ "$locked" = "yes" ] && [ "$current" = "no" ]; then
    log "unlock detected"
    if [ "$PLAY_ON_UNLOCK" = "yes" ]; then
      sleep "$UNLOCK_DELAY"
      play
    fi
    now=$(date +%s)
  fi
  [ "$current" != "error" ] && locked=$current
  last=$now
done
