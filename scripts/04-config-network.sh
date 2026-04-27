#!/bin/bash
set -e

HOSTNAME="${HOSTNAME:-xiaomi-raphael}"
NAMESERVER="${NAMESERVER:-1.1.1.1}"

echo "[04] 配置网络和主机名"

rm -f rootdir/etc/resolv.conf
touch rootdir/etc/resolv.conf

# 配置网络
echo "nameserver ${NAMESERVER}" > rootdir/etc/resolv.conf
echo "${HOSTNAME}" > rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 ${HOSTNAME}" > rootdir/etc/hosts

echo "[04] 完成"