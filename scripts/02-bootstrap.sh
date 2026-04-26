#!/bin/sh
set -e

UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"

echo "[02] 使用 debootstrap 生成基础系统 (${UBUNTU_VERSION})"

debootstrap --arch=arm64 ${UBUNTU_VERSION} rootdir https://ports.ubuntu.com/ubuntu-ports/

if [ -f "${BOOT_IMG}" ]; then
    echo "[02] 挂载 boot 分区 (${BOOT_IMG})"
    mount -o loop ${BOOT_IMG} rootdir/boot
else
    echo "[02] 警告: ${BOOT_IMG} 不存在，跳过 boot 挂载"
fi

echo "[02] 完成"