#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"

echo "[02] 安装基础系统 🚀"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "  - 使用 mmdebstrap 构建 Debian $DEBIAN_VERSION 🐧"
    mmdebstrap $DEBIAN_VERSION rootdir
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "  - 使用 mmdebstrap 构建 Ubuntu $UBUNTU_VERSION 🦁"
    mmdebstrap $UBUNTU_VERSION rootdir
else
    echo "错误: 未识别的系统类型: $SYSTEM_TYPE"
    exit 1
fi

if [ -f "${BOOT_IMG}" ]; then
    echo "[02] 挂载 boot 分区 (${BOOT_IMG}) 📁"
    if mount -o loop ${BOOT_IMG} rootdir/boot 2>&1; then
        echo "[02] Boot 分区挂载成功 ✅"
    else
        echo "[02] 错误: Boot 分区挂载失败 ❌"
        exit 1
    fi
else
    echo "[02] 错误: ${BOOT_IMG} 不存在 ❌"
    exit 1
fi

echo "[02] 完成 ✅"