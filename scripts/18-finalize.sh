#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
IMAGE_UUID="${IMAGE_UUID:-ee8d3593-59b1-480e-a3b6-4fefb17ee7d8}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📦 卸载并完成镜像"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 卸载挂载点..."
umount rootdir/boot 2>/dev/null || true
umount rootdir/sys 2>/dev/null || true
umount rootdir/proc 2>/dev/null || true
umount rootdir/dev/pts 2>/dev/null || true
umount rootdir/dev 2>/dev/null || true
umount rootdir 2>/dev/null || true

rm -d rootdir 2>/dev/null || true

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 检查 root 分区 (p2) 并设置固定 UUID..."
LOOP_DEV=$(losetup -j "$(readlink -f "${IMAGE_NAME}")" -O NAME -n 1 2>/dev/null | tr -d ' ')
if [ -n "${LOOP_DEV}" ] && [ -e "${LOOP_DEV}p2" ]; then
    e2fsck -f -y ${LOOP_DEV}p2
    tune2fs -U ${IMAGE_UUID} ${LOOP_DEV}p2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 卸载 loop 设备 ${LOOP_DEV}"
    losetup -d ${LOOP_DEV}
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  未找到 ${IMAGE_NAME} 对应的 loop 设备, 跳过 UUID 设置"
fi

echo ""
echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ Boot cmdline 参考: root=UUID=${IMAGE_UUID}"

echo ""
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 镜像完成"
