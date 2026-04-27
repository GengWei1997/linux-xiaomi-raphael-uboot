#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"

echo "[06] 安装所有软件包 📦"

export DEBIAN_FRONTEND=noninteractive

# 基础包
BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata dnsmasq iproute2"

# 根据发行版添加特定包
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    BASE_PACKAGES="$BASE_PACKAGES fonts-wqy-microhei"
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    BASE_PACKAGES="$BASE_PACKAGES language-pack-zh-hans iptables"
fi

# 设备特定包
DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv"

# 桌面环境包
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

# 合并所有包
ALL_PACKAGES="$BASE_PACKAGES $DEVICE_PACKAGES $DESKTOP_PACKAGES"

echo "  - 安装基础包 $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
echo "  - 安装设备包 $(echo "$DEVICE_PACKAGES" | tr ' ' ', ')"
if [ -n "$DESKTOP_PACKAGES" ]; then
    echo "  - 安装桌面包 $(echo "$DESKTOP_PACKAGES" | tr ' ' ', ')"
fi

# 执行 apt install
chroot rootdir apt -q install -y $ALL_PACKAGES

# Debian构建时修复可能的dpkg错误（shim-signed:arm64冲突）
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "  - 修复Debian系统dpkg错误"
    chroot rootdir dpkg --remove --force-remove-reinstreq shim-signed 2>/dev/null || true
    chroot rootdir dpkg --purge shim-signed 2>/dev/null || true
    chroot rootdir dpkg --configure -a 2>/dev/null || true
    chroot rootdir apt -f install -y 2>/dev/null || true
fi

# 设备特定配置
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service

# 桌面环境配置
if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    if [ "$DESKTOP_ENV" = "gnome" ]; then
        echo "  - 配置 GDM 自动登录"
        cat > rootdir/etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=user
EOF
    fi
fi

# 安装 ALSA 配置（如果存在）
if [ -f "alsa-xiaomi-raphael.deb" ]; then
    echo "  - 安装 ALSA 配置"
    cp alsa-xiaomi-raphael.deb rootdir/tmp/
    chroot rootdir dpkg -i /tmp/alsa-xiaomi-raphael.deb
    rm rootdir/tmp/alsa-xiaomi-raphael.deb
fi

echo "[06] 完成"