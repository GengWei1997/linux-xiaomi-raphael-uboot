#!/bin/bash
set -e  # 遇到错误立即退�?

# 克隆指定版本的内核源�?
git clone https://github.com/GengWei1997/linux.git --branch raphael-$1 --depth 1 linux

# 应用 builddeb 补丁
patch linux/scripts/package/builddeb < builddeb.patch

cd linux
git add .
git commit -m "builddeb: Add Qcom SM8150 DTBs to boot partition"

# 下载内核配置文件
wget -O arch/arm64/configs/raphael.config https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/uboot-raphael.config

# 生成内核配置
make -j$(nproc) ARCH=arm64 LLVM=-21 defconfig raphael.config

# 编译内核
make -j$(nproc) ARCH=arm64 LLVM=-21 deb-pkg

cd ..

# 重命名生成的 deb �?
IMAGE_DEB=$(ls -1 linux-image-*.deb 2>/dev/null | grep -v '\-dbg_' | head -n1)
HEADERS_DEB=$(ls -1 linux-headers-*.deb 2>/dev/null | head -n1)

if [ -n "$IMAGE_DEB" ]; then
  mv "$IMAGE_DEB" linux-image-xiaomi-raphael.deb
fi
if [ -n "$HEADERS_DEB" ]; then
  mv "$HEADERS_DEB" linux-headers-xiaomi-raphael.deb
fi

# 清理源码目录
rm -rf linux

# 构建 deb �?
dpkg-deb --build --root-owner-group firmware-xiaomi-raphael
dpkg-deb --build --root-owner-group alsa-xiaomi-raphael
