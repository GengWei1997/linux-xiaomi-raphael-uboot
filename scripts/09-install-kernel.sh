#!/bin/bash
set -e

KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-.}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] 🧠 安装内核"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 内核包目录: ${KERNEL_DEBS_DIR}"

cp ${KERNEL_DEBS_DIR}/*-xiaomi-raphael.deb rootdir/tmp/

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 linux-image..."
chroot rootdir dpkg -i /tmp/linux-image-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 linux-headers..."
chroot rootdir dpkg -i /tmp/linux-headers-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 安装 firmware..."
chroot rootdir dpkg -i /tmp/firmware-xiaomi-raphael.deb

rm rootdir/tmp/*-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 创建 initramfs firmware hook"
cat > rootdir/etc/initramfs-tools/hooks/raphael << 'EOF'
#!/bin/sh
PREREQS=""
case $1 in
prereqs) echo "$PREREQS"; exit 0;;
esac
. /usr/share/initramfs-tools/hook-functions

for fw in /lib/firmware/qcom/a6*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/a6*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/ad*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/cd*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done

for fw in /lib/firmware/qcom/sm8150/Xiaomi/raphael/ipa*; do
    [ -e "$fw" ] && copy_file firmware "$fw"
done
EOF
chmod +x rootdir/etc/initramfs-tools/hooks/raphael

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09]   └─ 更新 initramfs..."
chroot rootdir update-initramfs -c -k all

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] ✅ 内核安装完成"
