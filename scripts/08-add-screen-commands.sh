#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [08] 🖥️ 添加屏幕管理命令"

# 添加屏幕管理命令到全局bash配置
cat >> rootdir/etc/bash.bashrc << 'EOF'
# 屏幕管理命令
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

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [08]   └─ 屏幕管理命令已添加"

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

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [08]   └─ 自动熄屏服务已启用"
