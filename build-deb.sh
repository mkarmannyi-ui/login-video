#!/usr/bin/env bash
# Builds login-video_VERSION_all.deb from the files in this folder.
set -e

VERSION="1.0.0"
MAINTAINER="Your Name <352882932+mkarmannyi-ui@users.noreply.github.com>"   # <-- change this
NAME="login-video"

cd "$(dirname "$0")"
PKG="${NAME}_${VERSION}_all"
ROOT="build/$PKG"

rm -rf "$ROOT"
install -D -m 755 login-video.sh       "$ROOT/usr/bin/login-video"
install -D -m 755 login-video-setup.sh "$ROOT/usr/bin/login-video-setup"
install -D -m 644 README.md            "$ROOT/usr/share/doc/$NAME/README.md"

# Starts for every user at login; does nothing until the user runs
# "login-video-setup /path/to/video.mp4"
mkdir -p "$ROOT/etc/xdg/autostart"
cat > "$ROOT/etc/xdg/autostart/login-video.desktop" << DESK
[Desktop Entry]
Type=Application
Name=Login Video
Exec=/usr/bin/login-video
NoDisplay=true
X-GNOME-Autostart-enabled=true
DESK
chmod 644 "$ROOT/etc/xdg/autostart/login-video.desktop"

mkdir -p "$ROOT/DEBIAN"
cat > "$ROOT/DEBIAN/control" << CTRL
Package: $NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: mpv, libglib2.0-bin, procps, util-linux, coreutils
Recommends: wireplumber | pulseaudio-utils, libnotify-bin
Maintainer: $MAINTAINER
Description: Play a video at login, after wake and after unlock
 Plays a fullscreen video without controls when you log in to your
 Ubuntu desktop, when the laptop wakes from suspend, and when you unlock
 the screen. Sets the system volume before playing.
 .
 After installing, each user runs: login-video-setup /path/to/video.mp4
CTRL

dpkg-deb --build --root-owner-group "$ROOT" "$PKG.deb"
echo "Built: $PKG.deb"
