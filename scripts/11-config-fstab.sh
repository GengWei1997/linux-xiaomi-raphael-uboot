#!/bin/bash
set -e

IMAGE_UUID="${IMAGE_UUID:-ee8d3593-59b1-480e-a3b6-4fefb17ee7d8}"
BOOT_VOLID="${BOOT_VOLID:-1BF4A32B}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🗂️ 配置 fstab"

mkdir -p rootdir/etc

echo "UUID=${IMAGE_UUID} / ext4 errors=remount-ro 0 1
UUID=${BOOT_VOLID:0:4}-${BOOT_VOLID:4:4} /boot vfat umask=0077 0 1" > rootdir/etc/fstab

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ fstab 配置完成"
