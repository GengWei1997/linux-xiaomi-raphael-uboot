#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
IS_DESKTOP="${IS_DESKTOP:-false}"
USER_NAME="${USER_NAME:-user}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📐 配置传感器 (libssc + iio-sensor-proxy, SSC 加速计)"

export DEBIAN_FRONTEND=noninteractive

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装编译依赖"
chroot rootdir apt-get install -y git meson ninja-build build-essential pkg-config \
    libglib2.0-dev libgudev-dev libpolkit-gobject-1-dev libqrtr-glib-dev \
    libprotobuf-c-dev protobuf-c-compiler protobuf-compiler libqmi-glib-dev \
    libudev-dev libsystemd-dev python3-dev

# Ubuntu pc 文件名不匹配 (libudev.pc/libsystemd.pc 而非 udev.pc/systemd.pc)
chroot rootdir bash -c '
    set -e
    [ -f /usr/lib/aarch64-linux-gnu/pkgconfig/libudev.pc ] && \
        ln -sf libudev.pc /usr/lib/aarch64-linux-gnu/pkgconfig/udev.pc
    [ -f /usr/lib/aarch64-linux-gnu/pkgconfig/libsystemd.pc ] && \
        ln -sf libsystemd.pc /usr/lib/aarch64-linux-gnu/pkgconfig/systemd.pc
    true
'

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 编译安装 libssc 0.4.4"
chroot rootdir bash -c '
    set -e
    cd /tmp
    rm -rf libssc
    git clone --depth 1 --branch v0.4.4 https://codeberg.org/DylanVanAssche/libssc.git
    cd libssc
    meson setup build --prefix=/usr
    meson compile -C build
    meson install -C build
'

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 编译安装 iio-sensor-proxy 3.9 (SSC 支持 + 启动枚举即 open 补丁)"
cp "$SCRIPT_DIR/iio-sensor-proxy-find-sensors-open.patch" rootdir/tmp/
chroot rootdir bash -c '
    set -e
    cd /tmp
    rm -rf iio-sensor-proxy
    git clone --depth 1 --branch 3.9 https://gitlab.freedesktop.org/hadess/iio-sensor-proxy.git
    cd iio-sensor-proxy
    patch -p1 < /tmp/iio-sensor-proxy-find-sensors-open.patch
    meson setup build --prefix=/usr -Dssc-support=enabled
    meson compile -C build
    meson install -C build
    cp -f /rules.d/80-iio-sensor-proxy.rules /usr/lib/udev/rules.d/ 2>/dev/null || true
    rm -rf /rules.d
'
rm -f rootdir/tmp/iio-sensor-proxy-find-sensors-open.patch

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 udev 规则"
# 只启用 sdsp 上的加速计 (多传感器同时 open 会阻塞 bus 注册, 旋转只需 accel)
cat > rootdir/usr/lib/udev/rules.d/80-iio-sensor-proxy.rules <<'EOF'
# 仅使用 SSC 加速计, 禁用光感/接近/指南针避免多传感器互斥
LABEL="iio_sensor_proxy_end"
EOF
cat > rootdir/usr/lib/udev/rules.d/90-iio-sensor-proxy-proximity-sensor-enable.rules <<'EOF'
ACTION=="remove", GOTO="iio_sensor_proxy_end"
SUBSYSTEM=="misc", KERNEL=="fastrpc-sdsp*", ENV{IIO_SENSOR_PROXY_TYPE}+="ssc-accel"
LABEL="iio_sensor_proxy_end"
EOF
cat > rootdir/usr/lib/udev/rules.d/81-libssc-180-degrees.rules <<'EOF'
# 设备传感器安装方向 180° 翻转
SUBSYSTEM=="misc", KERNEL=="fastrpc-*", ENV{ACCEL_MOUNT_MATRIX}+="-1, 0, 0; 0, -1, 0; 0, 0, -1"
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 iio-sensor-proxy 服务"
cat > rootdir/usr/lib/systemd/system/iio-sensor-proxy.service <<'EOF'
[Unit]
Description=IIO sensors proxy service
After=hexagonrpcd.service
Wants=hexagonrpcd.service

[Service]
Type=dbus
BusName=net.hadess.SensorProxy
ExecStart=/usr/libexec/iio-sensor-proxy
Restart=on-failure
RestartSec=3
RestrictAddressFamilies=AF_UNIX AF_LOCAL AF_NETLINK AF_QIPCRTR

[Install]
WantedBy=multi-user.target
EOF
chroot rootdir systemctl enable iio-sensor-proxy 2>/dev/null || true

if [ "$IS_DESKTOP" = "true" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装自动旋转守护 (GNOME mutter DisplayConfig)"
    install -m 755 "$SCRIPT_DIR/auto-rotate.py" rootdir/usr/local/bin/auto-rotate.py
    install -m 644 "$SCRIPT_DIR/auto-rotate.service" rootdir/usr/lib/systemd/user/
    chroot rootdir bash -c "
        mkdir -p /home/$USER_NAME/.config/systemd/user/default.target.wants
        ln -sf /usr/lib/systemd/user/auto-rotate.service /home/$USER_NAME/.config/systemd/user/default.target.wants/auto-rotate.service
        chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config
    "
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 传感器配置完成"
