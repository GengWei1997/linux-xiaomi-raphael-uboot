#!/bin/bash
set -e

TIMEZONE="${TIMEZONE:-Asia/Shanghai}"
LANG_DEFAULT="${LANG_DEFAULT:-en_US.UTF-8}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] 🌍 配置时区和语言"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 时区: ${TIMEZONE}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 默认语言: ${LANG_DEFAULT}"

echo "${TIMEZONE}" > rootdir/etc/timezone
chroot rootdir ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
chroot rootdir locale-gen en_US.UTF-8 zh_CN.UTF-8
chroot rootdir update-locale LANG=${LANG_DEFAULT}

cat > rootdir/etc/profile.d/99-locale-fix.sh << 'EOF'
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
fi
EOF
chmod +x rootdir/etc/profile.d/99-locale-fix.sh

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] ✅ 时区语言配置完成"
