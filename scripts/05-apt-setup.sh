#!/bin/sh
set -e

UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"

echo "[05] 配置 apt 镜像源"

export DEBIAN_FRONTEND=noninteractive

envsubst '${UBUNTU_VERSION}' < config/sources.list.tpl > rootdir/etc/apt/sources.list

chroot rootdir apt update

echo "[05] 完成"