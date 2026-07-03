#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13] 🔋 配置电源管理和熄屏"

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13]   └─ 禁用睡眠/挂起目标"
    chroot rootdir systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
fi

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

# 禁用 WiFi 省电模式，解决连接 WiFi 跳 ping 问题
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13]   └─ 禁用 WiFi 省电模式"
mkdir -p rootdir/etc/NetworkManager/conf.d
cat > rootdir/etc/NetworkManager/conf.d/wifi-powersave.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13]   └─ 配置 ath10k 无线参数"
mkdir -p rootdir/etc/modprobe.d
cat > rootdir/etc/modprobe.d/ath10k.conf << 'EOF'
options ath10k_core skip_otp=y
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13] ✅ 电源管理配置完成"
