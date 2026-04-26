#!/bin/sh
set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
. "$SCRIPT_DIR/../config/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"

echo "[06] 安装基础软件包"

export DEBIAN_FRONTEND=noninteractive

BASE_PACKAGES="$(get_packages "$SYSTEM_TYPE" "$DESKTOP_ENV")"

echo "  - 安装基础包: $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
chroot rootdir apt install -y $BASE_PACKAGES

echo "[06] 完成"