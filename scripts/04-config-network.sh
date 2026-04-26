#!/bin/bash
set -e

HOSTNAME="${HOSTNAME:-xiaomi-raphael}"
NAMESERVER="${NAMESERVER:-1.1.1.1}"

echo "[04] 配置网络和主机名"

echo "nameserver ${NAMESERVER}" > rootdir/etc/resolv.conf
echo "${HOSTNAME}" > rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 ${HOSTNAME}" > rootdir/etc/hosts

echo "[04] 完成"
