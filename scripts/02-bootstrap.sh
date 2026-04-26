#!/bin/sh
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/debian/}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"

echo "[02] 安装基础系统"

if [ -n "$DEBIAN_VERSION" ]; then
    echo "  - 使用 Debian $DEBIAN_VERSION"
    debootstrap --arch=arm64 $DEBIAN_VERSION rootdir $DEBIAN_MIRROR
elif [ -n "$UBUNTU_VERSION" ]; then
    echo "  - 使用 Ubuntu $UBUNTU_VERSION"
    debootstrap --arch=arm64 $UBUNTU_VERSION rootdir $UBUNTU_MIRROR
else
    echo "错误: 未设置 DEBIAN_VERSION 或 UBUNTU_VERSION"
    exit 1
fi

if [ -f "${BOOT_IMG}" ]; then
    echo "[02] 挂载 boot 分区 (${BOOT_IMG})"
    mount -o loop ${BOOT_IMG} rootdir/boot
else
    echo "[02] 警告: ${BOOT_IMG} 不存在，跳过 boot 挂载"
fi

echo "[02] 完成"