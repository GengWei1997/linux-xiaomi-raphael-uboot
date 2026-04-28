#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] 🌍 配置时区和语言"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 时区: ${TIMEZONE}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 默认语言: ${LANG_DEFAULT}"

# 设置时区和语言
echo "Asia/Shanghai" > rootdir/etc/timezone
chroot rootdir ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat > rootdir/etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
EOF
chroot rootdir locale-gen
chroot rootdir env -u LC_ALL update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en

# 配置动态语言切换（SSH使用中文，TTY使用英文）
cat > rootdir/etc/profile.d/99-locale-fix.sh << 'EOF'
# 如果是SSH连接，则使用中文
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
    export LANG=zh_CN.UTF-8
	export LANGUAGE=zh_CN:zh
    export LC_ALL=zh_CN.UTF-8
fi
EOF
chmod +x rootdir/etc/profile.d/99-locale-fix.sh
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] ✅ 时区语言配置完成"
