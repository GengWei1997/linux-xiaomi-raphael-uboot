#!/bin/bash
set -e

KERNEL_VERSION="${1:-7.3}"
REPO="${2:-GengWei1997/kernel-deb}"

echo "下载内核包"
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

echo ""
echo "下载完成!"
echo ""
ls -lh xiaomi-raphael-debs_$KERNEL_VERSION/
