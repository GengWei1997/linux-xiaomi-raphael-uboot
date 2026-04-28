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

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 添加熄屏快捷键 (leijun/jinfan)"
cat >> rootdir/etc/bash.bashrc << 'EOF'

leijun() {
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        sudo sh -c 'TERM=linux setterm --blank force </dev/tty1'
    else
        setterm --blank force --term linux </dev/tty1
    fi
    echo "屏幕已关闭"
}

jinfan() {
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        sudo sh -c 'TERM=linux setterm --blank poke </dev/tty1'
    else
        setterm --blank poke --term linux </dev/tty1
    fi
    echo "屏幕已开启"
}
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12]   └─ 创建自动熄屏服务"
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

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] ✅ 电源管理配置完成"