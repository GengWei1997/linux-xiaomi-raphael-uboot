#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] 📡 更新 apt 源并更新缓存"

export DEBIAN_FRONTEND=noninteractive

cp rootdir/etc/apt/sources.list rootdir/etc/apt/sources.list.bak

if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 配置 Ubuntu $UBUNTU_VERSION 源"
    cat > rootdir/etc/apt/sources.list << EOF
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse
EOF
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 配置 Debian $DEBIAN_VERSION 源"
    cat > rootdir/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian/ $DEBIAN_VERSION main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 执行 apt-get update..."
chroot rootdir apt-get -q update

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] ✅ apt 配置完成"