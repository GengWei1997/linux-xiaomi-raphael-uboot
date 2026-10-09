#!/bin/bash
set -e

IMAGE_SIZE="${IMAGE_SIZE:-3G}"
IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
IMAGE_UUID="${IMAGE_UUID:-ee8d3593-59b1-480e-a3b6-4fefb17ee7d8}"
BOOT_SIZE="${BOOT_SIZE:-256M}"
BOOT_LABEL="${BOOT_LABEL:-Boot}"
ROOT_LABEL="${ROOT_LABEL:-Root}"
SECTOR_SIZE="${SECTOR_SIZE:-4096}"
BOOT_PART_START="${BOOT_PART_START:-2048}"
ROOT_PART_TYPE="${ROOT_PART_TYPE:-b921b045-1df0-41c3-af44-4c6f280d3fae}"
ESP_PART_TYPE="${ESP_PART_TYPE:-c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
BOOT_VOLID="${BOOT_VOLID:-1BF4A32B}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📦 创建 GPT 根文件系统镜像 (${IMAGE_SIZE}, boot: ${BOOT_SIZE})"

# 0. 清理残留 loop 与旧镜像 (truncate 不清空, 旧 loop 延迟写回会污染新分区/新文件系统)
losetup -D 2>/dev/null || true
rm -f ${IMAGE_NAME}

# 1. 创建空镜像文件
truncate -s ${IMAGE_SIZE} ${IMAGE_NAME}

# 2. 挂载为 loop 设备（4096 字节逻辑扇区，匹配 UFS 存储），并让内核扫描分区
LOOP_DEV=$(losetup --find --show --sector-size ${SECTOR_SIZE} -P ${IMAGE_NAME})
echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ loop 设备: ${LOOP_DEV} (逻辑扇区 ${SECTOR_SIZE}B)"

# 3. 创建 GPT 分区表（与 postmarketOS / Nura 一致）：
#    p1 = boot (fat32/ESP)，从 ${BOOT_PART_START}s (8MiB) 到 ${BOOT_SIZE}
#    p2 = root (ext4)，占剩余空间
parted -s ${LOOP_DEV} mklabel gpt
parted -s ${LOOP_DEV} mkpart primary fat32 ${BOOT_PART_START}s ${BOOT_SIZE}
parted -s ${LOOP_DEV} mkpart primary ${BOOT_SIZE} 100%
parted -s ${LOOP_DEV} type 2 ${ROOT_PART_TYPE}
parted -s ${LOOP_DEV} set 1 esp on
parted -s ${LOOP_DEV} type 1 ${ESP_PART_TYPE}

# 4. 格式化分区: p1=fat32 (${BOOT_LABEL}), p2=ext4 (${ROOT_LABEL}, 固定 UUID)
mkfs.vfat -F 32 -n ${BOOT_LABEL} -i ${BOOT_VOLID} ${LOOP_DEV}p1
mkfs.ext4 -F -q -L ${ROOT_LABEL} -i 8192 ${LOOP_DEV}p2
tune2fs -U ${IMAGE_UUID} ${LOOP_DEV}p2

# 5. 挂载根分区到构建目录 (boot 分区 p1 由 02-bootstrap.sh 在 bootstrap 完成后挂载,
#    避免 mmdebstrap/debootstrap 因目标目录非空而拒绝)
mkdir -p rootdir
mount ${LOOP_DEV}p2 rootdir

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ GPT 镜像创建完成 (p1=${BOOT_LABEL} fat32 / p2=${ROOT_LABEL} ext4)"
