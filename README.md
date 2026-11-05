# login-video

Plays a video on Ubuntu after login, after waking from suspend, and after unlocking the screen (Win+L).

## Install
```bash
git clone https://github.com/mkarmannyi-ui/login-video.git
cd login-video
chmod +x *.sh
./install.sh /path/to/your/video.mp4
```

## Install as a .deb package
Build it (needs `dpkg-deb`, included in Ubuntu):
```bash
./build-deb.sh
```
Install it, then choose your video:
```bash
sudo apt install ./login-video_1.0.0_all.deb
login-video-setup /path/to/your/video.mp4
```
Remove it:
```bash
login-video-setup --remove
sudo apt remove login-video
```

## Settings
Edit `~/.config/login-video/config`:
- `VIDEO` path to the video
- `PLAY_ON_LOGIN` / `PLAY_ON_WAKE` / `PLAY_ON_UNLOCK` yes or no
- `LOGIN_DELAY` / `WAKE_DELAY` / `UNLOCK_DELAY` seconds
- `LOCK_PLAYER` yes = the video cannot be paused or closed (no mouse, no keyboard) until it ends
- `SYSTEM_VOLUME` laptop volume in percent set before playing (empty = leave volume alone)
- `MAX_SECONDS` safety limit, the video is stopped after this many seconds (0 = no limit)

With `LOCK_PLAYER=no`, press `q` or `Esc` to close the video.
Emergency exit when locked: press `Ctrl+Alt+F3`, log in, run `pkill mpv`, then `Ctrl+Alt+F2` (or F1) to go back.

## Uninstall
```bash
cd login-video
./uninstall.sh
```

## Notes
- Works on Ubuntu with a desktop session (GNOME). Needs `mpv` (installed automatically).
- It plays after you log in, not on the GDM login screen.
- After wake it plays right away, and again after you unlock (if the first video has finished).
- The player cannot block system shortcuts (Super key, Alt+Tab, Ctrl+Alt+F3, power button).
- Unlock detection uses GNOME (`org.gnome.ScreenSaver`).
- Log file for troubleshooting: `~/.cache/login-video.log` (also shows mpv errors; if mpv rejects an option, the script retries with simpler options)
