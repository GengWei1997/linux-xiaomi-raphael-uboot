#!/bin/sh
set -e

echo "清理构建产物..."

rm -f rootfs.img rootfs.7z rootfs.img.sha256 rootfs.7z.sha256 sha256sums.txt
rm -f xiaomi-k20pro-boot.img
rm -rf rootdir
rm -rf xiaomi-raphael-debs_*

echo "清理完成"