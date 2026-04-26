#!/bin/sh
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "rootfs can only be built as root"
    exit 1
fi

KERNEL_VERSION="${1:-6.18}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
export IMAGE_SIZE="${IMAGE_SIZE:-3G}"
export IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
export HOSTNAME="${HOSTNAME:-xiaomi-raphael}"
export BOOT_IMG="${BOOT_IMG:-xiaomi-k20pro-boot.img}"
export KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-xiaomi-raphael-debs_$KERNEL_VERSION}"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "Ubuntu Server ARM64 构建脚本"
echo "=========================================="
echo "内核版本: $KERNEL_VERSION"
echo "Ubuntu 版本: $UBUNTU_VERSION"
echo "镜像大小: $IMAGE_SIZE"
echo "=========================================="

if [ ! -f "$BOOT_IMG" ]; then
    echo "错误: $BOOT_IMG 不存在"
    exit 1
fi

if [ ! -d "$KERNEL_DEBS_DIR" ]; then
    echo "错误: $KERNEL_DEBS_DIR 目录不存在"
    exit 1
fi

chmod +x "$SCRIPT_DIR/scripts"/*.sh

echo ""
echo "[01/15] 创建根文件系统镜像"
"$SCRIPT_DIR/scripts/01-create-image.sh"

echo ""
echo "[02/15] 安装基础系统"
"$SCRIPT_DIR/scripts/02-bootstrap.sh"

echo ""
echo "[03/15] 挂载系统目录"
"$SCRIPT_DIR/scripts/03-mount-dev.sh"

echo ""
echo "[04/15] 配置网络"
"$SCRIPT_DIR/scripts/04-config-network.sh"

echo ""
echo "[05/15] 配置 apt 源"
"$SCRIPT_DIR/scripts/05-apt-setup.sh"

echo ""
echo "[06/15] 安装基础软件包"
"$SCRIPT_DIR/scripts/06-install-packages.sh"

echo ""
echo "[07/15] 配置语言和时区"
"$SCRIPT_DIR/scripts/07-config-locale.sh"

echo ""
echo "[08/15] 安装设备特定包"
"$SCRIPT_DIR/scripts/08-install-device-pkgs.sh"

echo ""
echo "[09/15] 安装内核"
"$SCRIPT_DIR/scripts/09-install-kernel.sh"

echo ""
echo "[10/15] 配置 USB NCM"
"$SCRIPT_DIR/scripts/10-config-ncm.sh"

echo ""
echo "[11/15] 配置 fstab"
"$SCRIPT_DIR/scripts/11-config-fstab.sh"

echo ""
echo "[12/15] 创建用户"
"$SCRIPT_DIR/scripts/12-create-users.sh"

echo ""
echo "[13/15] 配置电源管理"
"$SCRIPT_DIR/scripts/13-config-power.sh"

echo ""
echo "[14/15] 清理"
"$SCRIPT_DIR/scripts/14-cleanup.sh"

echo ""
echo "[15/15] 完成镜像"
"$SCRIPT_DIR/scripts/15-finalize.sh"

echo ""
echo "=========================================="
echo "构建完成!"
echo "=========================================="
echo "产物文件:"
ls -lh rootfs.7z rootfs.img xiaomi-k20pro-boot.img sha256sums.txt 2>/dev/null || true
echo "=========================================="