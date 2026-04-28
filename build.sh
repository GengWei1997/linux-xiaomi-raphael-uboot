#!/bin/bash
set -e


# 解析参数
SYSTEM_TYPE="${1:?请指定系统类型}"
KERNEL_VERSION="${2:-6.18}"
DESKTOP_ENV="${3:-phosh-full}"

# 解析发行版版本参数
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    DEBIAN_VERSION="${DEBIAN_VERSION:?请设置 DEBIAN_VERSION 环境变量}"
    export DEBIAN_VERSION
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    UBUNTU_VERSION="${UBUNTU_VERSION:?请设置 UBUNTU_VERSION 环境变量}"
    export UBUNTU_VERSION
fi

# 解析构建模式参数
USE_DOCKER="${5:-false}"
export USE_DOCKER

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载配置文件
. "$SCRIPT_DIR/config/build-config.sh"

# 加载系统配置
TMP_SYSTEM_CONFIG=$(mktemp)
system_config "$SYSTEM_TYPE" "$DESKTOP_ENV" > "$TMP_SYSTEM_CONFIG"
while IFS= read -r line; do
    export "$line"
done < "$TMP_SYSTEM_CONFIG"
rm "$TMP_SYSTEM_CONFIG"

# 加载镜像源配置
TMP_SOURCES_CONFIG=$(mktemp)
sources_config "$SYSTEM_TYPE" > "$TMP_SOURCES_CONFIG"
while IFS= read -r line; do
    export "$line"
done < "$TMP_SOURCES_CONFIG"
rm "$TMP_SOURCES_CONFIG"

# 导出通用变量
export SCRIPT_DIR
export KERNEL_VERSION
export DESKTOP_ENV
export IMAGE_NAME="rootfs.img"
export IMAGE_UUID="ee8d3593-59b1-480e-a3b6-4fefb17ee7d8"
export HOSTNAME="xiaomi-raphael"
export BOOT_IMG="xiaomi-k20pro-boot.img"
export KERNEL_DEBS_DIR="xiaomi-raphael-debs_$KERNEL_VERSION"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export DEBIAN_FRONTEND="noninteractive"
export SYSTEM_TYPE

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ========================================== 🎉"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 系统镜像构建脚本"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ========================================== 🎉"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 系统类型:      $SYSTEM_TYPE 🖥️"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 内核版本:      $KERNEL_VERSION 🧠"
if [ -n "$DEBIAN_VERSION" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Debian 版本:   $DEBIAN_VERSION 🐧"
elif [ -n "$UBUNTU_VERSION" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Ubuntu 版本:   $UBUNTU_VERSION 🦁"
fi
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 镜像大小:      $IMAGE_SIZE 💾"
if [ "$IS_DESKTOP" = "true" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 桌面环境:      $DESKTOP_ENV 🎨"
fi
BOOTSTRAP_TOOL="${BOOTSTRAP_TOOL:-mmdebstrap}"
if [ "$BOOTSTRAP_TOOL" = "debootstrap" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 构建模式:      debootstrap 🛠️"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 构建模式:      mmdebstrap 📦"
fi
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ========================================== 🎉"

if [ ! -f "$BOOT_IMG" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ 错误: $BOOT_IMG 不存在"
    exit 1
fi

if [ ! -d "$KERNEL_DEBS_DIR" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ 错误: $KERNEL_DEBS_DIR 目录不存在"
    exit 1
fi

chmod +x "$SCRIPT_DIR/scripts"/*.sh

echo ""
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ========================================== 🚀 开始构建 =========================================="
"$SCRIPT_DIR/scripts/01-create-image.sh"
"$SCRIPT_DIR/scripts/02-bootstrap.sh"
"$SCRIPT_DIR/scripts/03-mount-dev.sh"
"$SCRIPT_DIR/scripts/04-config-network.sh"
"$SCRIPT_DIR/scripts/05-apt-setup.sh"
"$SCRIPT_DIR/scripts/06-install-all-packages.sh"
"$SCRIPT_DIR/scripts/07-config-locale.sh"
"$SCRIPT_DIR/scripts/08-add-screen-commands.sh"
"$SCRIPT_DIR/scripts/09-install-kernel.sh"
"$SCRIPT_DIR/scripts/10-config-ncm.sh"
"$SCRIPT_DIR/scripts/11-config-fstab.sh"
"$SCRIPT_DIR/scripts/12-create-users.sh"
"$SCRIPT_DIR/scripts/13-config-power.sh"
"$SCRIPT_DIR/scripts/14-cleanup.sh"
"$SCRIPT_DIR/scripts/15-finalize.sh"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ========================================== 🎉 构建完成 🎉 =========================================="

echo ""
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📦 产物文件:"
ls -lh rootfs.img 2>/dev/null || true
ls -lh rootfs.7z 2>/dev/null || true
echo ""
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 构建成功完成!"