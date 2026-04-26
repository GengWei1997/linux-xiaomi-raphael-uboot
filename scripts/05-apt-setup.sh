#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/debian/}"
DEBIAN_SECURITY_MIRROR="${DEBIAN_SECURITY_MIRROR:-http://security.debian.org/debian-security}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"
UBUNTU_SECURITY_MIRROR="${UBUNTU_SECURITY_MIRROR:-http://ports.ubuntu.com/ubuntu-ports/}"

echo "[05] 配置 apt 镜像源"

export DEBIAN_FRONTEND=noninteractive

if [ -n "$DEBIAN_VERSION" ]; then
    echo "  - 配置 Debian $DEBIAN_VERSION 镜像源"
    cat > rootdir/etc/apt/sources.list << EOF
deb $DEBIAN_MIRROR $DEBIAN_VERSION main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb $DEBIAN_SECURITY_MIRROR $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
elif [ -n "$UBUNTU_VERSION" ]; then
    echo "  - 配置 Ubuntu $UBUNTU_VERSION 镜像源"
    cat > rootdir/etc/apt/sources.list << EOF
deb $UBUNTU_MIRROR $UBUNTU_VERSION main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_VERSION-updates main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_VERSION-backports main restricted universe multiverse
deb $UBUNTU_SECURITY_MIRROR $UBUNTU_VERSION-security main restricted universe multiverse
EOF
else
    echo "错误: 未设置 DEBIAN_VERSION 或 UBUNTU_VERSION"
    exit 1
fi

chroot rootdir apt update

echo "[05] 完成"