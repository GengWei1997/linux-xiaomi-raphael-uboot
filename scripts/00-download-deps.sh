#!/bin/bash
set -e

KERNEL_VERSION="${1:-6.18}"
REPO="${2:-${{ github.repository }}}"

echo "下载内核包和 boot.img"
echo "内核版本: $KERNEL_VERSION"
echo "仓库: $REPO"

mkdir -p xiaomi-raphael-debs_$KERNEL_VERSION

echo "正在下载内核包..."
curl -sL -o xiaomi-raphael-debs_$KERNEL_VERSION/linux-image-xiaomi-raphael.deb \
    "https://github.com/$REPO/releases/download/kernel-v$KERNEL_VERSION/linux-image-xiaomi-raphael.deb"

curl -sL -o xiaomi-raphael-debs_$KERNEL_VERSION/linux-headers-xiaomi-raphael.deb \
    "https://github.com/$REPO/releases/download/kernel-v$KERNEL_VERSION/linux-headers-xiaomi-raphael.deb"

curl -sL -o xiaomi-raphael-debs_$KERNEL_VERSION/firmware-xiaomi-raphael.deb \
    "https://github.com/$REPO/releases/download/kernel-v$KERNEL_VERSION/firmware-xiaomi-raphael.deb"

echo "正在下载 boot.img..."
curl -sL -o xiaomi-k20pro-boot.img \
    "https://github.com/GengWei1997/kernel-deb/releases/download/v1.0.0/xiaomi-k20pro-boot.img"

echo ""
echo "下载完成!"
echo ""
ls -lh xiaomi-raphael-debs_$KERNEL_VERSION/
ls -lh xiaomi-k20pro-boot.img
