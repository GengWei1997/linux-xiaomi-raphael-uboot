#!/bin/sh
set -e

echo "[08] 安装设备特定软件包"

export DEBIAN_FRONTEND=noninteractive

DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv"

chroot rootdir apt install -y ${DEVICE_PACKAGES}

sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service

echo "[08] 完成"