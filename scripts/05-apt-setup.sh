#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian/}"
DEBIAN_SECURITY_MIRROR="${DEBIAN_SECURITY_MIRROR:-http://security.debian.org/debian-security}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports/}"
UBUNTU_SECURITY_MIRROR="${UBUNTU_SECURITY_MIRROR:-http://ports.ubuntu.com/ubuntu-ports/}"

echo "[05] 配置 apt 镜像源"

export DEBIAN_FRONTEND=noninteractive

# 基于系统类型选择镜像源
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    if [ -n "$DEBIAN_VERSION" ]; then
        echo "  - 配置 Debian $DEBIAN_VERSION 镜像源"
        cat > rootdir/etc/apt/sources.list << EOF
deb $DEBIAN_MIRROR $DEBIAN_VERSION main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb $DEBIAN_SECURITY_MIRROR $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
    else
        echo "错误: 未设置 DEBIAN_VERSION"
        exit 1
    fi
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [ -n "$UBUNTU_VERSION" ]; then
        echo "  - 配置 Ubuntu $UBUNTU_VERSION 镜像源"
        
        # 清理已存在的源配置
        if [ -d "rootdir/etc/apt/sources.list.d" ]; then
            echo "  - 清理已存在的源配置"
            rm -f rootdir/etc/apt/sources.list.d/*
        fi
        
        # 创建新的源配置
        cat > rootdir/etc/apt/sources.list << EOF
deb $UBUNTU_MIRROR $UBUNTU_VERSION main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_VERSION-updates main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_VERSION-backports main restricted universe multiverse
deb $UBUNTU_MIRROR $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    else
        echo "错误: 未设置 UBUNTU_VERSION"
        exit 1
    fi
else
    echo "错误: 未识别的系统类型: $SYSTEM_TYPE"
    exit 1
fi

# 执行 apt update
chroot rootdir apt update

echo "[05] 完成"