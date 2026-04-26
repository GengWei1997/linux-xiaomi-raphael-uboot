#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DEBIAN_TSUNING_MIRROR="${DEBIAN_TSUNING_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/debian/}"
UBUNTU_TSUNING_MIRROR="${UBUNTU_TSUNING_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"

echo "[13] 清理临时文件"

export DEBIAN_FRONTEND=noninteractive

chroot rootdir apt -q clean

mv rootdir/boot/initrd.img-* rootdir/boot/initramfs 2>/dev/null || true
mv rootdir/boot/vmlinuz-* rootdir/boot/linux.efi 2>/dev/null || true

rm -f rootdir/lib/firmware/reg* 2>/dev/null || true

# 配置清华源
echo "  - 配置清华源"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    if [ -n "$DEBIAN_VERSION" ]; then
        cat > rootdir/etc/apt/sources.list << EOF
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION main contrib non-free non-free-firmware
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb $DEBIAN_TSUNING_MIRROR $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
    fi
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [ -n "$UBUNTU_VERSION" ]; then
        cat > rootdir/etc/apt/sources.list << EOF
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION main restricted universe multiverse
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION-updates main restricted universe multiverse
deb $UBUNTU_TSUNING_MIRROR $UBUNTU_VERSION-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    fi
fi

# 展示配置文件
echo ""
echo "========================================== 📋 配置文件预览"
echo "========================================== 📋"

echo ""
echo "[/etc/apt/sources.list]"
cat rootdir/etc/apt/sources.list

echo ""
echo "[/etc/netplan/01-network-manager-all.yaml]"
cat rootdir/etc/netplan/01-network-manager-all.yaml 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/systemd/system/usb-gadget-ncm@.service]"
cat rootdir/etc/systemd/system/usb-gadget-ncm@.service 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/dnsmasq.d/usb-ncm]"
cat rootdir/etc/dnsmasq.d/usb-ncm 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/fstab]"
cat rootdir/etc/fstab 2>/dev/null || echo "(文件不存在)"

echo ""
echo "========================================== 📋"
echo "========================================== 📋"

echo "[13] 完成"