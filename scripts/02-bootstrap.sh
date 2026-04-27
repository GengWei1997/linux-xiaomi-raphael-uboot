#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
USE_DOCKER="${USE_DOCKER:-false}"

echo "[02] 安装基础系统 🚀"

if [ "$USE_DOCKER" = "true" ]; then
    echo "  - 使用 Docker 加速模式 ⚡"

    # 启用 Docker BuildKit
    export DOCKER_BUILDKIT=1

    if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
        echo "  - 使用 Debian $DEBIAN_VERSION 官方镜像 🐧"
        DOCKER_IMAGE="debian:$DEBIAN_VERSION"
    elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
        echo "  - 使用 Ubuntu $UBUNTU_VERSION 官方镜像 🦁"
        DOCKER_IMAGE="ubuntu:$UBUNTU_VERSION"
    else
        echo "错误: 未识别的系统类型: $SYSTEM_TYPE"
        exit 1
    fi

    echo "  - 拉取 Docker 镜像 📥"
    docker pull "$DOCKER_IMAGE"

    echo "  - 运行临时容器 📦"
    docker run --name tmp_rootfs_builder "$DOCKER_IMAGE" /bin/true

    echo "  - 导出 rootfs 镜像 📤"
    docker export tmp_rootfs_builder | tar -x -C rootdir/

    echo "  - 清理临时容器 🧹"
    docker rm tmp_rootfs_builder

    echo "  - 创建 boot 目录结构 📁"
    mkdir -p rootdir/boot

else
    echo "  - 使用 debootstrap 构建基础系统 🛠️"
    
    if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
        echo "  - 使用 Debian $DEBIAN_VERSION 🐧"
        debootstrap --arch=arm64 $DEBIAN_VERSION rootdir http://deb.debian.org/debian/
    elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
        echo "  - 使用 Ubuntu $UBUNTU_VERSION 🦁"
        debootstrap --arch=arm64 $UBUNTU_VERSION rootdir http://ports.ubuntu.com/ubuntu-ports/
    else
        echo "错误: 未识别的系统类型: $SYSTEM_TYPE"
        exit 1
    fi
fi

if [ -f "${BOOT_IMG}" ]; then
    echo "[02] 挂载 boot 分区 (${BOOT_IMG}) 📁"
    # 尝试挂载，失败则报错退出
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