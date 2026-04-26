#!/bin/bash
set -e

echo "[03] 绑定挂载系统目录"

mount --bind /dev rootdir/dev
mount --bind /dev/pts rootdir/dev/pts
mount --bind /proc rootdir/proc
mount --bind /sys rootdir/sys

echo "[03] 完成"
