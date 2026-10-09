#!/bin/bash
# dev-update-kernel.sh - 设备端一键更新内核 (固定名引导, pmOS 式)
# 用法: bash scripts/dev-update-kernel.sh /path/to/debs/
# 说明: 只需 dpkg -i, postinst 钩子自动刷新固定名/dtbs 并卸载旧内核
set -e
DIR="${1:-/tmp/ktest}"
cd "$DIR"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] dpkg -i 安装内核 (钩子自动刷新固定名 + dtbs + 卸载旧内核)"
dpkg -i ./*.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 内核已更新, 重启即进新内核"
