#!/usr/bin/env python3
# 自动旋转守护: 监听 iio-sensor-proxy 方向 → 旋转 GNOME 屏幕 (mutter DisplayConfig)
# 方向映射: normal=0°, left-up=270°(cw), right-up=90°(cw), bottom-up=180°(cw)
import subprocess, time, re, os, logging

ORIENT_TRANSFORM = {"normal": 0, "left-up": 3, "right-up": 1, "bottom-up": 2}

LOG = os.path.expanduser("~/.local/share/auto-rotate.log")
os.makedirs(os.path.dirname(LOG), exist_ok=True)
logging.basicConfig(filename=LOG, level=logging.INFO,
                    format="%(asctime)s %(levelname)s %(message)s")


def sh(args, timeout=8):
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return r.stdout
    except Exception as e:
        logging.warning("cmd failed %s: %s", args[0], e)
        return ""


def get_orientation():
    out = sh(["gdbus", "call", "--system", "--dest", "net.hadess.SensorProxy",
              "--object-path", "/net/hadess/SensorProxy",
              "--method", "org.freedesktop.DBus.Properties.Get",
              "net.hadess.SensorProxy", "AccelerometerOrientation"])
    m = re.search(r"<'([^']+)'>", out)
    return m.group(1) if m else None


def get_current_state():
    """Parse GetCurrentState: serial, lm_id, x, scale, transform, primary, connector, mode."""
    out = sh(["gdbus", "call", "--session",
              "--dest", "org.gnome.Mutter.DisplayConfig",
              "--object-path", "/org/gnome/Mutter/DisplayConfig",
              "--method", "org.gnome.Mutter.DisplayConfig.GetCurrentState"])
    if not out:
        return None
    m = re.search(r"\(uint32 (\d+), \[.*?\]", out, re.S)
    if not m:
        return None
    serial = m.group(1)
    # logical monitor: (id, x, scale, uint32 transform, primary, [monitor-spec], @a{sv} {})
    lm = re.search(r"\[\((-?\d+), (-?\d+), ([0-9.]+), uint32 (\d+), (true|false), \[(.*?)\], @a\{sv\} \{\}\)\]", out, re.S)
    if not lm:
        return None
    lm_id, x, scale, transform, primary = lm.group(1), lm.group(2), lm.group(3), lm.group(4), lm.group(5)
    # connector: ('DSI-1', 'unknown', 'unknown', 'unknown')
    c = re.search(r"\('([^']+)',", lm.group(6))
    connector = c.group(1) if c else None
    # current mode: ('1080x2340@60.000', 1080, 2340, ...)
    md = re.search(r"\('([^']+)', \d+, \d+,", out, re.S)
    mode = md.group(1) if md else None
    return serial, lm_id, x, scale, transform, primary, connector, mode


def apply_transform(transform):
    st = get_current_state()
    if not st:
        logging.warning("cannot parse mutter state")
        return
    serial, lm_id, x, scale, primary, connector, mode = st[0], st[1], st[2], st[3], st[5], st[6], st[7]
    if not connector or not mode:
        logging.warning("no connector/mode: %s", st)
        return
    cfg = "[(%s, %s, %s, uint32 %d, %s, [('%s', '%s', @a{sv} {})])]" % (
        lm_id, x, scale, transform, primary, connector, mode)
    out = sh(["gdbus", "call", "--session",
              "--dest", "org.gnome.Mutter.DisplayConfig",
              "--object-path", "/org/gnome/Mutter/DisplayConfig",
              "--method", "org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig",
              serial, "1", cfg, "{}"])
    logging.info("apply transform=%d -> %s", transform, out.strip()[:120])


def main():
    last = None
    logging.info("auto-rotate daemon started")
    while True:
        try:
            # mutter 不可用 (非 GNOME 会话/尚未登录) 时低频率重试
            if get_current_state() is None:
                time.sleep(30)
                continue
            o = get_orientation()
            if o in ORIENT_TRANSFORM and o != last:
                t = ORIENT_TRANSFORM[o]
                logging.info("orientation %s -> transform %d", o, t)
                apply_transform(t)
                last = o
            elif o is None:
                last = None
        except Exception as e:
            logging.error("loop error: %s", e)
        time.sleep(2)


if __name__ == "__main__":
    main()
