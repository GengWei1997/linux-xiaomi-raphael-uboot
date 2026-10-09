#!/bin/bash
set -e

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
IMAGE_UUID="${IMAGE_UUID:-ee8d3593-59b1-480e-a3b6-4fefb17ee7d8}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🧹 清理临时文件"

export DEBIAN_FRONTEND=noninteractive

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 清理 apt-get 缓存"
chroot rootdir apt-get -q clean

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 内核文件保持标准名 (vmlinuz-<ver> / initrd.img-<ver>, 09 已生成)"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 配置 systemd-boot 引导 (与 Nura/pmOS 一致)"
SDBOOT_PATH=""
for p in rootdir/usr/lib/systemd/boot/efi/systemd-bootaa64.efi rootdir/lib/systemd/boot/efi/systemd-bootaa64.efi; do
    if [ -f "$p" ]; then
        SDBOOT_PATH="$p"
        break
    fi
done
if [ -n "$SDBOOT_PATH" ]; then
    mkdir -p rootdir/boot/EFI/BOOT
    cp "$SDBOOT_PATH" rootdir/boot/EFI/BOOT/BOOTAA64.EFI
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ EFI/BOOT/BOOTAA64.EFI 已生成"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  未找到 systemd-bootaa64.efi, 请确认已安装 systemd-boot-efi"
fi
mkdir -p rootdir/boot/loader/entries
# 单内核固定名引导: 无需 loader.conf, systemd-boot 直接启动默认条目, 不显示菜单
# 固定名引导 (与 Nura/pmOS 一致): /boot/vmlinuz + /boot/initrd.img, 条目固定, 不随版本变化
echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 固定名引导: /boot/vmlinuz + /boot/initrd.img (设备更新后内核 dpkg 钩子自动刷新)"
KVER=$(ls rootdir/lib/modules/ | grep -vE '^(build|source)$' | head -1)
echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ KVER=$KVER"
cp -f "rootdir/boot/vmlinuz-${KVER}" rootdir/boot/vmlinuz
cp -f "rootdir/boot/initrd.img-${KVER}" rootdir/boot/initrd.img
# pmOS 式: 首刷后 /boot 只保留固定名, 否则 dpkg 重装同版本时会尝试备份版本化文件 (FAT32 不支持符号链接备份)
rm -f "rootdir/boot/vmlinuz-${KVER}" "rootdir/boot/initrd.img-${KVER}" "rootdir/boot/System.map-${KVER}" "rootdir/boot/config-${KVER}"
# dtbs: 从版本化路径拷贝到 /boot/dtbs/qcom
if [ -d "rootdir/usr/lib/linux-image-${KVER}/qcom" ]; then
    mkdir -p rootdir/boot/dtbs/qcom
    cp -rf "rootdir/usr/lib/linux-image-${KVER}/qcom/." rootdir/boot/dtbs/qcom/
fi
# 固定引导条目 (与设备更新后一致, 无需重建)
TITLE=$(chroot rootdir sh -c '. /etc/os-release; echo "$PRETTY_NAME"' 2>/dev/null || echo "xiaomi-raphael")
cat > rootdir/boot/loader/entries/linux.conf << EOF
title ${TITLE}
linux /vmlinuz
initrd /initrd.img
options root=UUID=${IMAGE_UUID} rw quiet loglevel=3 splash console=tty0
EOF
cat rootdir/boot/loader/entries/linux.conf
# 内核更新钩子: dpkg -i 新内核后自动刷新固定名 + dtbs
mkdir -p rootdir/etc/kernel/postinst.d rootdir/etc/kernel/postrm.d
cat > rootdir/etc/kernel/postinst.d/zz-kernel-install << 'EOF'
#!/bin/sh
KVER="$1"
KIMAGE="$2"
[ -f "/boot/vmlinuz-$KVER" ] && cp -f "/boot/vmlinuz-$KVER" /boot/vmlinuz
[ -f "/boot/initrd.img-$KVER" ] && cp -f "/boot/initrd.img-$KVER" /boot/initrd.img
if [ -d "/usr/lib/linux-image-$KVER/qcom" ]; then
  mkdir -p /boot/dtbs/qcom
  cp -rf "/usr/lib/linux-image-$KVER/qcom/." /boot/dtbs/qcom/ 2>/dev/null || true
fi
# pmOS 式: /boot 只保留固定名, 删除版本化副本
rm -f "/boot/vmlinuz-$KVER" "/boot/initrd.img-$KVER" "/boot/System.map-$KVER" "/boot/config-$KVER"
# 自动卸载旧内核: dpkg -i 新内核后无需手动 purge
# dpkg 事务内不能嵌套 dpkg, 延迟到事务结束后后台清理
( sleep 15
  for p in $(dpkg-query -W -f='${Package}\n' 'linux-image-*' 'linux-headers-*' 2>/dev/null \
        | grep -vE "linux-(image|headers)-$KVER$"); do
    dpkg --purge "$p" >>/var/log/kernel-purge.log 2>&1 || true
  done ) >/dev/null 2>&1 &
exit 0
EOF
chmod +x rootdir/etc/kernel/postinst.d/zz-kernel-install
# postrm: purge 旧内核后固定名回退到剩余最新内核
cat > rootdir/etc/kernel/postrm.d/zz-kernel-install << 'EOF'
#!/bin/sh
KVER="$1"
LATEST=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
[ -n "$LATEST" ] && cp -f "$LATEST" /boot/vmlinuz
LATEST_I=$(ls /boot/initrd.img-* 2>/dev/null | sort -V | tail -1)
[ -n "$LATEST_I" ] && cp -f "$LATEST_I" /boot/initrd.img
exit 0
EOF
chmod +x rootdir/etc/kernel/postrm.d/zz-kernel-install

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 清理固件文件"
rm -f rootdir/lib/firmware/reg* 2>/dev/null || true

echo ""
echo "========================================== 📋 配置文件预览 =========================================="

echo ""
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    echo "[/etc/apt/sources.list.d/debian.sources]"
    cat rootdir/etc/apt/sources.list.d/debian.sources 2>/dev/null || echo "(文件不存在)"
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    echo "[/etc/apt/sources.list.d/ubuntu.sources]"
    cat rootdir/etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || echo "(文件不存在)"
fi

echo ""
echo "[/etc/fstab]"
cat rootdir/etc/fstab 2>/dev/null || echo "(文件不存在)"

echo ""
echo "[/etc/default/zramswap]"
cat rootdir/etc/default/zramswap 2>/dev/null || echo "(文件不存在)"

echo ""
echo "========================================== 📋 配置文件预览结束 =========================================="

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 清理完成"
