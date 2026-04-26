#!/bin/bash
set -e

echo "[05] 更新 apt"

export DEBIAN_FRONTEND=noninteractive

chroot rootdir apt update

echo "[05] 完成"