#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
IMAGE_UUID="${IMAGE_UUID:-ee8d3593-59b1-480e-a3b6-4fefb17ee7d8}"

echo "[15] 卸载并完成镜�?

umount rootdir/sys 2>/dev/null || true
umount rootdir/proc 2>/dev/null || true
umount rootdir/dev/pts 2>/dev/null || true
umount rootdir/dev 2>/dev/null || true
umount rootdir/boot 2>/dev/null || true
umount rootdir 2>/dev/null || true

rm -d rootdir 2>/dev/null || true

tune2fs -U ${IMAGE_UUID} ${IMAGE_NAME}

echo 'cmdline for legacy boot: "root=PARTLABEL=userdata"'

7z a rootfs.7z ${IMAGE_NAME}

sha256sum ${IMAGE_NAME} > ${IMAGE_NAME}.sha256
sha256sum rootfs.7z > rootfs.7z.sha256

echo "[15] 完成"
