#!/bin/sh
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "rootfs can only be built as root"
    exit 1
fi

# 解析参数
SYSTEM_TYPE="${1:?请指定系统类型}"
KERNEL_VERSION="${2:-6.18}"
DESKTOP_ENV="${3:-phosh-full}"

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
export HOSTNAME="xiaomi-raphael"
export BOOT_IMG="xiaomi-k20pro-boot.img"
export KERNEL_DEBS_DIR="xiaomi-raphael-debs_$KERNEL_VERSION"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export DEBIAN_FRONTEND="noninteractive"

# 显示构建信息
echo "=========================================="
echo "系统镜像构建脚本"
echo "=========================================="
echo "系统类型: $SYSTEM_TYPE"
echo "内核版本: $KERNEL_VERSION"
echo "镜像大小: $IMAGE_SIZE"
if [ "$IS_DESKTOP" = "true" ]; then
    echo "桌面环境: $DESKTOP_ENV"
fi
echo "=========================================="

# 检查必要文件
if [ ! -f "$BOOT_IMG" ]; then
    echo "错误: $BOOT_IMG 不存在"
    exit 1
fi

if [ ! -d "$KERNEL_DEBS_DIR" ]; then
    echo "错误: $KERNEL_DEBS_DIR 目录不存在"
    exit 1
fi

# 确保脚本可执行
chmod +x "$SCRIPT_DIR/scripts"/*.sh

# 执行构建步骤
echo ""
echo "[01/16] 创建根文件系统镜像"
"$SCRIPT_DIR/scripts/01-create-image.sh"

echo ""
echo "[02/16] 安装基础系统"
"$SCRIPT_DIR/scripts/02-bootstrap.sh"

echo ""
echo "[03/16] 挂载系统目录"
"$SCRIPT_DIR/scripts/03-mount-dev.sh"

echo ""
echo "[04/16] 配置网络"
"$SCRIPT_DIR/scripts/04-config-network.sh"

echo ""
echo "[05/16] 配置 apt 源"
"$SCRIPT_DIR/scripts/05-apt-setup.sh"

echo ""
echo "[06/16] 安装基础软件包"
"$SCRIPT_DIR/scripts/06-install-packages.sh"

echo ""
echo "[07/16] 配置语言和时区"
"$SCRIPT_DIR/scripts/07-config-locale.sh"

echo ""
echo "[08/16] 安装设备特定包"
"$SCRIPT_DIR/scripts/08-install-device-pkgs.sh"

echo ""
echo "[09/16] 安装内核"
"$SCRIPT_DIR/scripts/09-install-kernel.sh"

echo ""
echo "[10/16] 配置 USB NCM"
"$SCRIPT_DIR/scripts/10-config-ncm.sh"

echo ""
echo "[11/16] 配置 fstab"
"$SCRIPT_DIR/scripts/11-config-fstab.sh"

echo ""
echo "[12/16] 创建用户"
"$SCRIPT_DIR/scripts/12-create-users.sh"

echo ""
echo "[13/16] 配置电源管理"
"$SCRIPT_DIR/scripts/13-config-power.sh"

if [ "$IS_DESKTOP" = "true" ]; then
    echo ""
    echo "[14/16] 安装桌面环境"
    "$SCRIPT_DIR/scripts/14-install-desktop.sh"
else
    echo ""
    echo "[14/16] 跳过桌面环境安装"
fi

echo ""
echo "[15/16] 清理"
"$SCRIPT_DIR/scripts/15-cleanup.sh"

echo ""
echo "[16/16] 完成镜像"
"$SCRIPT_DIR/scripts/16-finalize.sh"

echo ""
echo "=========================================="
echo "构建完成!"
echo "=========================================="
echo "产物文件:"
ls -lh rootfs.7z rootfs.img xiaomi-k20pro-boot.img sha256sums.txt 2>/dev/null || true
echo "=========================================="