#!/usr/bin/env bash
pkill -f '^(/[^ ]*/)?bash [^ ]*/bin/login-video(\.sh)?$' 2>/dev/null
rm -f "$HOME/.local/bin/login-video.sh"
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/autostart/login-video.desktop"
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/login-video"
echo "login-video removed."
