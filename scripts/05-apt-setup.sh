#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/debian/}"
DEBIAN_SECURITY_MIRROR="${DEBIAN_SECURITY_MIRROR:-http://security.debian.org/debian-security}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"
UBUNTU_SECURITY_MIRROR="${UBUNTU_SECURITY_MIRROR:-http://ports.ubuntu.com/ubuntu-ports/}"

echo "[05] 配置 apt 镜像源"

export DEBIAN_FRONTEND=noninteractive

# 基于系统类型选择镜像源
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    if [ -n "$DEBIAN_VERSION" ]; then
        echo "  - 配置 Debian $DEBIAN_VERSION 镜像源"
        cat > rootdir/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian $DEBIAN_VERSION main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
    else
        echo "错误: 未设置 DEBIAN_VERSION"
        exit 1
    fi
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [ -n "$UBUNTU_VERSION" ]; then
        echo "  - 配置 Ubuntu $UBUNTU_VERSION 镜像源"
        cat > rootdir/etc/apt/sources.list << EOF
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    else
        echo "错误: 未设置 UBUNTU_VERSION"
        exit 1
    fi
else
    echo "错误: 未识别的系统类型: $SYSTEM_TYPE"
    exit 1
fi


chroot rootdir apt update

echo "[05] 完成"