#!/bin/bash
set -e

DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
BOOTSTRAP_TOOL="${BOOTSTRAP_TOOL:-mmdebstrap}"
BOOTSTRAP_ARCH="${BOOTSTRAP_ARCH:-arm64}"
IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
SECTOR_SIZE="${SECTOR_SIZE:-4096}"
BOOT_LABEL="${BOOT_LABEL:-Boot}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🚀 安装基础系统"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 使用 $BOOTSTRAP_TOOL 构建 Debian $DEBIAN_VERSION ($BOOTSTRAP_ARCH) 🐧"
    OS_VERSION="$DEBIAN_VERSION"
    MIRROR="http://deb.debian.org/debian/"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 使用 $BOOTSTRAP_TOOL 构建 Ubuntu $UBUNTU_VERSION ($BOOTSTRAP_ARCH) 🦁"
    OS_VERSION="$UBUNTU_VERSION"
    MIRROR="http://ports.ubuntu.com/ubuntu-ports/"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 清空挂载点 (bootstrap 目标目录需为空)..."
find rootdir -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

# Ubuntu 新版本 (如 resolute) 可能尚无 debootstrap 定义, 用已存在的 noble 定义兜底
if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]] && [ ! -e "/usr/share/debootstrap/scripts/${UBUNTU_VERSION}" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 兜底: debootstrap 无 ${UBUNTU_VERSION} 定义, 复制 noble 定义"
    cp /usr/share/debootstrap/scripts/noble /usr/share/debootstrap/scripts/${UBUNTU_VERSION}
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 开始 bootstrap (这可能需要几分钟...)"
if [ "$BOOTSTRAP_TOOL" = "mmdebstrap" ]; then
    mmdebstrap --arch="$BOOTSTRAP_ARCH" $OS_VERSION rootdir
elif [ "$BOOTSTRAP_TOOL" = "debootstrap" ]; then
    debootstrap --arch="$BOOTSTRAP_ARCH" $OS_VERSION rootdir $MIRROR
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ 错误: 不支持的构建工具: $BOOTSTRAP_TOOL"
    exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 挂载 boot 分区 (GPT p1, ${BOOT_LABEL} fat32)..."
BOOT_LOOP_DEV=$(losetup --find --show --sector-size ${SECTOR_SIZE} -P ${IMAGE_NAME})
mkdir -p rootdir/boot
mount ${BOOT_LOOP_DEV}p1 rootdir/boot

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 基础系统安装完成"
