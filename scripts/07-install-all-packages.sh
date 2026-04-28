#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] 📦 安装软件包"

export DEBIAN_FRONTEND=noninteractive

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 更新系统包..."
chroot rootdir apt update
chroot rootdir apt upgrade -y

BASE_PACKAGES="bash-completion netplan sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata iproute2"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    BASE_PACKAGES="$BASE_PACKAGES systemd-boot dnsmasq fonts-wqy-microhei"
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    BASE_PACKAGES="$BASE_PACKAGES systemd-boot dnsmasq language-pack-zh-hans iptables"
fi

DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv"

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    case "$DESKTOP_ENV" in
        "gnome")
            DESKTOP_PACKAGES="gnome gnome-terminal gdm3"
            ;;
        "phosh-core")
            DESKTOP_PACKAGES="phosh phoc squeekboard"
            ;;
        "phosh-full")
            DESKTOP_PACKAGES="phosh phoc squeekboard gnome-settings-daemon gnome-control-center"
            ;;
        "phosh-phone")
            DESKTOP_PACKAGES="phosh phoc squeekboard gnome-settings-daemon gnome-control-center ofono mobian-tweaks"
            ;;
        *)
            DESKTOP_PACKAGES=""
            ;;
    esac
else
    DESKTOP_PACKAGES=""
fi

ALL_PACKAGES="$BASE_PACKAGES $DEVICE_PACKAGES $DESKTOP_PACKAGES"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 基础包: $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 设备包: $(echo "$DEVICE_PACKAGES" | tr ' ' ', ')"
if [ -n "$DESKTOP_PACKAGES" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 桌面包: $(echo "$DESKTOP_PACKAGES" | tr ' ' ', ')"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 开始安装（这可能需要几分钟...）"
chroot rootdir apt install -y --ignore-missing $ALL_PACKAGES || true

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 修复 Debian dpkg 错误"
    chroot rootdir dpkg --remove --force-remove-reinstreq shim-signed 2>/dev/null || true
    chroot rootdir dpkg --purge shim-signed 2>/dev/null || true
    chroot rootdir dpkg --configure -a 2>/dev/null || true
    chroot rootdir apt -f install -y 2>/dev/null || true
fi

sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service 2>/dev/null || true

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    if [ "$DESKTOP_ENV" = "gnome" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 配置 GDM 自动登录"
        cat > rootdir/etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=user
EOF
    fi
fi

if [ -f "alsa-xiaomi-raphael.deb" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06]   └─ 安装 ALSA 配置"
    cp alsa-xiaomi-raphael.deb rootdir/tmp/
    chroot rootdir dpkg -i /tmp/alsa-xiaomi-raphael.deb
    rm rootdir/tmp/alsa-xiaomi-raphael.deb
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] ✅ 软件包安装完成"