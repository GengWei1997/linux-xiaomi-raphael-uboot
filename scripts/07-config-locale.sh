#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] 🌍 配置时区和语言"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 时区: ${TIMEZONE}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 默认语言: ${LANG_DEFAULT}"

# 设置时区和语言
echo "Asia/Shanghai" > rootdir/etc/timezone
chroot rootdir ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 安装中文语言包
if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 安装 Ubuntu 中文语言包"
    chroot rootdir apt-get update
    
    if [[ "$SYSTEM_TYPE" == *"server"* ]]; then
        # Server版本只安装基础中文语言包
        chroot rootdir apt-get install -y language-pack-zh-hans
    else
        # 桌面版本安装完整的中文语言包
        BASE_ZH_PACKAGES="fonts-arphic-uming language-pack-gnome-zh-hans-base language-pack-zh-hans-base language-pack-zh-hans language-pack-gnome-zh-hans fonts-arphic-ukai fonts-noto-cjk fonts-noto-cjk-extra gnome-user-docs-zh-hans language-pack-gnome-zh-hant-base language-pack-zh-hant-base language-pack-zh-hant language-pack-gnome-zh-hant libreoffice-help-common libreoffice-l10n-zh-cn libreoffice-help-zh-cn thunderbird-locale-zh-cn thunderbird-locale-zh-hans"
        
        # 桌面版本特有的中文输入法包
        DESKTOP_ZH_PACKAGES="libopencc-data libmarisa0 libopencc1.1 libpinyin-data libpinyin15 ibus-libpinyin ibus-table ibus-table-wubi libchewing3-data libchewing3 ibus-chewing ibus-table-cangjie3 ibus-table-cangjie5 ibus-table-quick-classic"
        
        # resolute版本不支持libmarisa0包
        if [[ "$UBUNTU_VERSION" == "resolute" ]]; then
            DESKTOP_ZH_PACKAGES="libopencc-data libopencc1.1 libpinyin-data libpinyin15 ibus-libpinyin ibus-table ibus-table-wubi libchewing3-data libchewing3 ibus-chewing ibus-table-cangjie3 ibus-table-cangjie5 ibus-table-quick-classic"
        fi
        
        chroot rootdir apt-get install -y $BASE_ZH_PACKAGES $DESKTOP_ZH_PACKAGES
    fi
elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07]   └─ 安装 Debian 中文语言包"
    chroot rootdir apt-get update
    chroot rootdir apt-get install -y locales locales-all tzdata
fi

# 配置语言环境
cat > rootdir/etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
EOF
chroot rootdir locale-gen zh_CN.UTF-8
chroot rootdir update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh

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
