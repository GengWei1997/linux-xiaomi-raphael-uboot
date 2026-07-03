#!/bin/bash
set -e

if [ "$DESKTOP_ENV" != "gnome" ]; then
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] ⏭️  非 GNOME 桌面，跳过电源键配置"
	exit 0
fi

# 默认用户名，构建时由 USER_NAME 环境变量覆盖
POWER_KEY_USER="${USER_NAME:-user}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] 🔘 配置电源键（用户: ${POWER_KEY_USER}，短按息屏/亮屏 / 长按1s关机菜单）"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 禁用 systemd 电源键行为"
install -d rootdir/etc/systemd/logind.conf.d
cat > rootdir/etc/systemd/logind.conf.d/power-key.conf << 'EOF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=ignore
PowerKeyIgnoreInhibited=yes
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 安装电源键守护进程"
install -d rootdir/usr/local/sbin
cat > rootdir/usr/local/sbin/power-key-handler.py << 'PYEOF'
#!/usr/bin/env python3
"""
Power Key Handler for GNOME Desktop
Ported from phosh/src/screen-saver-manager.c behavior:
  - Short press (< 1s): toggle screen blank/wake via ScreenSaver DBus
  - Long press (>= 1s): show power menu (shutdown dialog)
"""
import logging
import os
import select
import struct
import subprocess
import sys
import threading
import time

EV_KEY = 0x01
KEY_POWER = 116
EVENT_FMT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FMT)
LONG_PRESS_SEC = 1.0

logging.basicConfig(
    level=logging.INFO,
    format="power-key: %(message)s",
    stream=sys.stdout,
)
log = logging.getLogger("power-key")


def get_user():
    """Get target username: USER_NAME env var, or fallback to current user."""
    user = os.environ.get("USER_NAME")
    if user:
        return user
    import pwd
    return pwd.getpwuid(os.getuid()).pw_name


def find_power_input():
    """Locate pm8941_pwrkey evdev device."""
    from pathlib import Path
    base = Path("/sys/class/input")
    for name_path in sorted(base.glob("input*/name")):
        name = name_path.read_text().strip()
        if name == "pm8941_pwrkey":
            num = name_path.parent.name.replace("input", "")
            dev = Path(f"/dev/input/event{num}")
            if dev.exists():
                return str(dev)
    return "/dev/input/event0"


def get_env():
    """Build user session environment for gdbus calls."""
    user = get_user()
    import pwd
    uid = pwd.getpwnam(user).pw_uid
    runtime = f"/run/user/{uid}"
    env = os.environ.copy()
    env.update({
        "HOME": f"/home/{user}",
        "USER": user,
        "LOGNAME": user,
        "XDG_RUNTIME_DIR": runtime,
        "DBUS_SESSION_BUS_ADDRESS": f"unix:path={runtime}/bus",
    })
    for disp in ("wayland-0", "wayland-1"):
        if os.path.exists(f"{runtime}/{disp}"):
            env["WAYLAND_DISPLAY"] = disp
            break
    return env


def query_screensaver_active():
    """Query org.gnome.ScreenSaver.GetActive. Returns True if screen is blanked."""
    env = get_env()
    try:
        r = subprocess.run(
            ["gdbus", "call", "--session",
             "--dest", "org.gnome.ScreenSaver",
             "--object-path", "/org/gnome/ScreenSaver",
             "--method", "org.gnome.ScreenSaver.GetActive"],
            env=env, capture_output=True, text=True, timeout=2)
        return "(true" in r.stdout
    except Exception as e:
        log.warning("GetActive failed: %s", e)
        return False


def blank_screen():
    """Blank screen via SetActive(true)."""
    env = get_env()
    log.info("blank screen (SetActive true)")
    subprocess.run(
        ["gdbus", "call", "--session",
         "--dest", "org.gnome.ScreenSaver",
         "--object-path", "/org/gnome/ScreenSaver",
         "--method", "org.gnome.ScreenSaver.SetActive", "true"],
        env=env, timeout=3)


def wake_screen():
    """Wake screen via SetActive(false)."""
    env = get_env()
    log.info("wake screen (SetActive false)")
    subprocess.run(
        ["gdbus", "call", "--session",
         "--dest", "org.gnome.ScreenSaver",
         "--object-path", "/org/gnome/ScreenSaver",
         "--method", "org.gnome.ScreenSaver.SetActive", "false"],
        env=env, timeout=3)


def toggle_screen():
    """Toggle screen: query actual state then blank or wake."""
    active = query_screensaver_active()
    log.info("screensaver active=%s", active)
    if active:
        wake_screen()
    else:
        blank_screen()


def show_power_menu():
    """Show GNOME shutdown dialog."""
    env = get_env()
    log.info("show power menu (long press)")
    r = subprocess.run(
        ["busctl", "--user", "call",
         "org.gnome.SessionManager",
         "/org/gnome/SessionManager",
         "org.gnome.SessionManager",
         "RequestShutdown"],
        env=env, capture_output=True, text=True, timeout=3)
    if r.returncode != 0:
        subprocess.Popen(["gnome-session-quit", "--power-off"], env=env)


def wait_for_session(timeout=120):
    """Wait for user's GNOME session to be ready."""
    user = get_user()
    import pwd
    uid = pwd.getpwnam(user).pw_uid
    bus_path = f"/run/user/{uid}/bus"
    log.info("waiting for %s GNOME session", user)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if os.path.exists(bus_path):
            try:
                subprocess.run(
                    ["pgrep", "-u", user, "-x", "gnome-shell"],
                    check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(3)
                log.info("session ready")
                return True
            except subprocess.CalledProcessError:
                pass
        time.sleep(1)
    log.error("session not ready after %ss", timeout)
    return False


def main():
    if not wait_for_session():
        sys.exit(1)

    dev = find_power_input()
    fd = os.open(dev, os.O_RDONLY | os.O_NONBLOCK)
    log.info("listening on %s", dev)

    press_time = None
    long_fired = False
    long_timer = None
    is_pressed = False

    def cancel_long_timer():
        nonlocal long_timer
        if long_timer is not None:
            long_timer.cancel()
            long_timer = None

    def on_long_press():
        nonlocal long_fired
        if not is_pressed:
            return
        long_fired = True
        show_power_menu()

    while True:
        r, _, _ = select.select([fd], [], [], 1.0)
        if not r:
            continue
        data = os.read(fd, EVENT_SIZE)
        if len(data) < EVENT_SIZE:
            continue
        _sec, _usec, ev_type, code, value = struct.unpack(EVENT_FMT, data)
        if ev_type != EV_KEY or code != KEY_POWER:
            continue

        log.info("KEY_POWER value=%s", value)

        if value == 1:
            if not is_pressed:
                is_pressed = True
                press_time = time.monotonic()
                long_fired = False
                cancel_long_timer()
                long_timer = threading.Timer(LONG_PRESS_SEC, on_long_press)
                long_timer.daemon = True
                long_timer.start()
        elif value == 0 and press_time is not None:
            is_pressed = False
            cancel_long_timer()
            if not long_fired:
                duration = time.monotonic() - press_time
                if duration < LONG_PRESS_SEC:
                    toggle_screen()
            press_time = None


if __name__ == "__main__":
    main()
PYEOF
chmod 755 rootdir/usr/local/sbin/power-key-handler.py

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 创建并启用 systemd 用户服务"
install -d rootdir/etc/systemd/user
cat > rootdir/etc/systemd/user/power-key-handler.service << EOF
[Unit]
Description=Power key handler (short press: toggle screen, long press: power menu)
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
Environment=USER_NAME=${POWER_KEY_USER}
ExecStart=/usr/bin/python3 /usr/local/sbin/power-key-handler.py
Restart=always
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF
install -d rootdir/etc/systemd/user/graphical-session.target.wants
ln -sf /etc/systemd/user/power-key-handler.service rootdir/etc/systemd/user/graphical-session.target.wants/power-key-handler.service
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 启用用户 lingering（确保用户服务开机自启）"
install -d rootdir/var/lib/systemd/linger
touch rootdir/var/lib/systemd/linger/"${POWER_KEY_USER}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 禁用 GNOME 自带电源键处理"
install -d rootdir/etc/dconf/db/local.d rootdir/etc/dconf/profile
cat > rootdir/etc/dconf/db/local.d/01-power-key << 'EOF'
[org/gnome/settings-daemon/plugins/power]
power-button-action='nothing'
EOF
if [ ! -f rootdir/etc/dconf/profile/user ]; then
	cat > rootdir/etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF
fi
chroot rootdir dconf update 2>/dev/null || true

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14]   └─ 添加 udev 规则确保电源键可读"
cat > rootdir/etc/udev/rules.d/99-power-key.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="pm8941_pwrkey", MODE="0666"
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] ✅ 电源键配置完成"
