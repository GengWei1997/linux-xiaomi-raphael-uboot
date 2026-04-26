#!/bin/sh
set -e

DESKTOP_ENV="${DESKTOP_ENV:-gnome}"

echo "[14] 安装桌面环境"

export DEBIAN_FRONTEND=noninteractive

case "$DESKTOP_ENV" in
    "gnome")
        echo "  - 安装 GNOME 桌面环境"
        # 确保已安装基础包
        chroot rootdir apt install -y gnome gnome-terminal gdm3
        
        # 配置 GDM 自动登录
        cat > rootdir/etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=user
EOF
        ;;
    "phosh-core")
        echo "  - 安装 Phosh 核心组件"
        chroot rootdir apt install -y phosh phoc squeekboard
        ;;
    "phosh-full")
        echo "  - 安装 Phosh 完整组件"
        chroot rootdir apt install -y phosh phoc squeekboard gnome-settings-daemon gnome-control-center
        ;;
    "phosh-phone")
        echo "  - 安装 Phosh 电话组件"
        chroot rootdir apt install -y phosh phoc squeekboard gnome-settings-daemon gnome-control-center ofono mobian-tweaks
        ;;
    *)
        echo "  - 未知桌面环境: $DESKTOP_ENV"
        ;;
esac

# 安装 ALSA 配置（如果存在）
if [ -f "alsa-xiaomi-raphael.deb" ]; then
    echo "  - 安装 ALSA 配置"
    cp alsa-xiaomi-raphael.deb rootdir/tmp/
    chroot rootdir dpkg -i /tmp/alsa-xiaomi-raphael.deb
    rm rootdir/tmp/alsa-xiaomi-raphael.deb
fi

echo "[14] 完成"