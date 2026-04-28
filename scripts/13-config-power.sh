#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] 🔋 配置电源管理和熄屏"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 禁用睡眠/挂起目标"
chroot rootdir systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 配置 NetworkManager"
cat > rootdir/etc/netplan/01-network-manager-all.yaml << 'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF





echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] ✅ 电源管理配置完成"