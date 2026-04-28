#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] 📡 更新 apt 更新缓存"

export DEBIAN_FRONTEND=noninteractive

cp rootdir/etc/apt/sources.list rootdir/etc/apt/sources.list.bak

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05]   └─ 执行 apt update..."
chroot rootdir apt -q update

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] ✅ apt 配置完成"