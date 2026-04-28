#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13] 🔋 配置电源管理和熄屏"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13]   └─ 禁用睡眠/挂起目标"
chroot rootdir systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 仅在 Ubuntu 构建时配置 NetworkManager
if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then 
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13]   └─ 配置 NetworkManager"
    cat > rootdir/etc/netplan/01-network-manager-all.yaml << 'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
fi


# 配置开机 15 秒后自动熄屏的 Systemd 服务
cat > rootdir/etc/systemd/system/blank_screen.service << 'EOF'
[Unit]
Description=Auto-blank screen after 15s
After=multi-user.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c "/usr/bin/sleep 15"
ExecStart=sh -c 'TERM=linux setterm --blank force </dev/tty1'
User=root
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
chroot rootdir systemctl enable blank_screen.service


echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13] ✅ 电源管理配置完成"
