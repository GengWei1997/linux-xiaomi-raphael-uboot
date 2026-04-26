#!/bin/sh
set -e

echo "[06] 安装基础软件包"

export DEBIAN_FRONTEND=noninteractive

BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata language-pack-zh-hans dnsmasq iptables iproute2"

chroot rootdir apt install -y ${BASE_PACKAGES}

echo "[06] 完成"