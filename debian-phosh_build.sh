#!/bin/sh
# 兼容性脚本 - 调用新的统一构建框架

SYSTEM_TYPE="debian-phosh"
DESKTOP_ENV="${1:-phosh-full}"
KERNEL_VERSION="${2:-6.18}"

echo "使用新的统一构建框架..."
./build.sh "$SYSTEM_TYPE" "$KERNEL_VERSION" "$DESKTOP_ENV"