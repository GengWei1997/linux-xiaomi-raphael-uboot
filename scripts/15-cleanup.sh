#!/bin/sh
set -e

echo "[15] 清理临时文件"

export DEBIAN_FRONTEND=noninteractive

chroot rootdir apt clean

mv rootdir/boot/initrd.img-* rootdir/boot/initramfs 2>/dev/null || true
mv rootdir/boot/vmlinuz-* rootdir/boot/linux.efi 2>/dev/null || true

rm -f rootdir/lib/firmware/reg* 2>/dev/null || true

echo "[15] 完成"