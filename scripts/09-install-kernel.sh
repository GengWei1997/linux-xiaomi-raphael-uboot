#!/bin/bash
set -e

KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-.}"
SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🧠 安装内核"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 内核包目录: ${KERNEL_DEBS_DIR}"

cp ${KERNEL_DEBS_DIR}/*-xiaomi-raphael.deb rootdir/tmp/

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 linux-image..."
chroot rootdir dpkg -i /tmp/linux-image-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 linux-headers..."
chroot rootdir dpkg -i /tmp/linux-headers-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 firmware..."
chroot rootdir dpkg -i /tmp/firmware-xiaomi-raphael.deb

rm rootdir/tmp/*-xiaomi-raphael.deb

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 添加 initramfs hooks..."
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    # ============ Debian 方案 ============
    # Debian trixie 的 busybox 含 losetup/partprobe/blkid applet, zz-busybox 会建共享硬链接(同一 inode),
    # 任何 cp 覆盖其中一个都会写穿整个 inode, 导致 /bin/sh 等全变成该工具二进制, /init 无法启动。
    # 因此这里: 先 rm 解除共享链接, 再独立拷贝 util-linux 版 (losetup/parted/partprobe/resize2fs/e2fsck/blkid)。
    chroot rootdir tee /etc/initramfs-tools/hooks/raphael << 'EOF'
#!/bin/sh
PREREQS=""
case $1 in
prereqs) echo "$PREREQS"; exit 0;;
esac
. /usr/share/initramfs-tools/hook-functions

# util-linux losetup: 支持 --sector-size (initramfs 自带 busybox/klibc 版不支持, 嵌套 GPT 映射必需)
# Debian usrmerge 后 losetup 在 /usr/bin, 逐个路径探测
LOSETUP_SRC=""
for _p in /usr/sbin/losetup /usr/bin/losetup /bin/losetup /sbin/losetup; do
    [ -x "$_p" ] && LOSETUP_SRC="$_p" && break
done
if [ -n "$LOSETUP_SRC" ]; then
    # zz-busybox 会把 busybox 硬链接到全部 applet 路径(共享 inode), 之后任何 cp 覆盖其中一个
    # 都会写穿整个 inode, 导致 /bin/sh、/bin/mount 等全变成 losetup 二进制, /init 无法启动。
    _NL=$(stat -c %h "${DESTDIR:-.}/usr/sbin/losetup" 2>/dev/null || echo 0)
    if [ "${_NL:-0}" -gt 1 ]; then
        rm -f "${DESTDIR:-.}/bin/busybox" 2>/dev/null || true
        copy_exec /bin/busybox /bin/busybox 2>/dev/null || true
        if [ -x "${DESTDIR:-.}/bin/busybox" ]; then
            for _alias in $(/bin/busybox --list-long 2>/dev/null); do
                _alias="${_alias#/}"
                case "$_alias" in
                    usr/*) _alias="${_alias#usr/}" ;;
                    */*) ;;
                    *) _alias="bin/$_alias" ;;
                esac
                rm -f "${DESTDIR:-.}/$_alias" 2>/dev/null || true
                ln "${DESTDIR:-.}/bin/busybox" "${DESTDIR:-.}/$_alias" 2>/dev/null || true
            done
        fi
    fi
    # losetup 独立写入 (rm 后 cp 创建新 inode, 不与 busybox 共享)
    rm -f "${DESTDIR:-.}/usr/sbin/losetup" 2>/dev/null || true
    copy_exec "$LOSETUP_SRC" /usr/sbin/losetup 2>/dev/null || true
    cp -f "$LOSETUP_SRC" "${DESTDIR:-.}/usr/sbin/losetup" 2>/dev/null || true
    # 动态依赖完整拷贝 (initramfs-tools copy_exec 偶尔遗漏 libsmartcols, 导致 losetup/partprobe 段错误)
    for _dep in $(ldd "$LOSETUP_SRC" 2>/dev/null | awk '{print $3}' | grep '^/'); do
        mkdir -p "${DESTDIR:-.}$(dirname $_dep)" 2>/dev/null || true
        rm -f "${DESTDIR:-.}${_dep}" 2>/dev/null || true
        copy_exec "$_dep" "${_dep#/}" 2>/dev/null || true
        cp -f "$_dep" "${DESTDIR:-.}${_dep}" 2>/dev/null || true
    done
fi

# 首启自动扩展 Root 分区 (对齐 pmOS resize_root_partition + resize_root_filesystem):
# parted/partprobe 扩展嵌套 GPT p2 到 100%, e2fsck/resize2fs 扩展 ext4 文件系统。
# 统一先 rm 解除 zz-busybox 共享链接, 再独立拷贝 util-linux 版 (busybox 版
# partprobe/blkid 对 loop+4096 扇区嵌套 GPT 的分区重扫/UUID 查找不可靠)。
for t in parted partprobe resize2fs e2fsck blkid; do
    for p in /usr/sbin/$t /sbin/$t /usr/bin/$t /bin/$t; do
        if [ -x "$p" ]; then
            rm -f "${DESTDIR:-.}$p" 2>/dev/null || true
            if [ "$t" = "blkid" ]; then
                # copy_exec 对 blkid 依赖处理不可靠, 直接 cp -f 独立拷贝
                cp -f "$p" "${DESTDIR:-.}$p" 2>/dev/null || true
                for _dep in $(ldd "$p" 2>/dev/null | awk '{print $3}' | grep '^/'); do
                    mkdir -p "${DESTDIR:-.}$(dirname $_dep)" 2>/dev/null || true
                    cp -f "$_dep" "${DESTDIR:-.}${_dep}" 2>/dev/null || true
                done
            else
                copy_exec "$p" "$p"
                for _dep in $(ldd "$p" 2>/dev/null | awk '{print $3}' | grep '^/'); do
                    mkdir -p "${DESTDIR:-.}$(dirname $_dep)" 2>/dev/null || true
                    rm -f "${DESTDIR:-.}${_dep}" 2>/dev/null || true
                    copy_exec "$_dep" "${_dep#/}" 2>/dev/null || true
                    cp -f "$_dep" "${DESTDIR:-.}${_dep}" 2>/dev/null || true
                done
            fi
            if [ "$t" = "blkid" ] && [ -d "${DESTDIR:-.}/sbin" ]; then
                rm -f "${DESTDIR:-.}/sbin/blkid" 2>/dev/null || true
                ln "${DESTDIR:-.}/usr/sbin/blkid" "${DESTDIR:-.}/sbin/blkid" 2>/dev/null || cp -f "$p" "${DESTDIR:-.}/sbin/blkid" 2>/dev/null || true
            fi
            break
        fi
    done
done

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
else
    # ============ Ubuntu 方案 ============
    # Ubuntu busybox 不含 losetup/partprobe/blkid 等 applet, zz-busybox 不建共享链接,
    # copy_exec 直接可用, 无需 rm/重建。
    chroot rootdir tee /etc/initramfs-tools/hooks/raphael << 'EOF'
#!/bin/sh
PREREQS=""
case $1 in
prereqs) echo "$PREREQS"; exit 0;;
esac
. /usr/share/initramfs-tools/hook-functions

# util-linux losetup: 支持 --sector-size (initramfs 自带 klibc 版不支持, 嵌套 GPT 映射必需)
if [ -x /usr/sbin/losetup ]; then
    copy_exec /usr/sbin/losetup /usr/sbin/losetup
fi

# 首启自动扩展 Root 分区 (对齐 pmOS resize_root_partition + resize_root_filesystem):
# parted/partprobe 扩展嵌套 GPT p2 到 100%, e2fsck/resize2fs 扩展 ext4 文件系统
for t in parted partprobe resize2fs e2fsck; do
    for p in /usr/sbin/$t /sbin/$t /usr/bin/$t /bin/$t; do
        if [ -x "$p" ]; then
            copy_exec "$p" "$p"
            break
        fi
    done
done

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
fi

chroot rootdir chmod +x /etc/initramfs-tools/hooks/raphael

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 添加嵌套 GPT 映射脚本 (与 Nura/pmOS mount_subpartitions 一致)..."
chroot rootdir mkdir -p /etc/initramfs-tools/scripts/local-top
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    # Debian: blkid/partprobe 用绝对路径 (PATH 里 busybox 版不可靠)
    cat > rootdir/etc/initramfs-tools/scripts/local-top/raphael-subpartition << 'EOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
prereqs) prereqs; exit 0;;
esac

. /scripts/functions

# 与 pmOS init_functions.sh 的 mount_subpartitions() 对齐:
# rootfs.img 整体刷入 userdata, 内部为嵌套 GPT (4096B 扇区)。
# 这里用 util-linux losetup 将 userdata 等 Android 分区映射为 loop 设备并扫描分区,
# 暴露 p1=Boot 与 p2=Root, 随后 root=UUID= 才能被 initramfs-tools 找到。

# util-linux losetup 优先 (klibc 版不支持 --sector-size)
LOSETUP="/usr/sbin/losetup"
[ -x "$LOSETUP" ] || LOSETUP="/usr/bin/losetup"
[ -x "$LOSETUP" ] || LOSETUP="losetup"

# util-linux blkid 优先 (busybox 版对 loop 分区 UUID 查找不可靠)
BLKID="/usr/sbin/blkid"
[ -x "$BLKID" ] || BLKID="/sbin/blkid"
[ -x "$BLKID" ] || BLKID="blkid"

modprobe loop 2>/dev/null || true

# 从内核 cmdline 提取 root=UUID=
ROOTUUID=""
for a in $(cat /proc/cmdline); do
    case "$a" in
        root=UUID=*) ROOTUUID="${a#root=UUID=}" ;;
    esac
done

# 1) 优先等待 by-partlabel/userdata 并映射
LOOPDEV=""
i=0
while [ ! -e /dev/disk/by-partlabel/userdata ]; do
    i=$((i+1))
    [ "$i" -gt 50 ] && break
    sleep 0.1
done
if [ -e /dev/disk/by-partlabel/userdata ]; then
    LOOPDEV=$($LOSETUP --find --show -P --sector-size 4096 --direct-io=on /dev/disk/by-partlabel/userdata 2>/dev/null) || true
fi

# 2) 若根 UUID 仍不可见, 遍历所有分区设备逐个尝试 (pmOS 同款兜底)
if [ -n "$ROOTUUID" ] && ! $BLKID --uuid "$ROOTUUID" >/dev/null 2>&1; then
    for b in /sys/class/block/*; do
        [ -d "$b" ] || continue
        b=$(basename "$b")
        case "$b" in
            loop*|ram*|zram*|dm-*) continue ;;
        esac
        # 只处理分区/逻辑设备, 跳过整盘
        [ -e "/sys/class/block/$b/partition" ] || continue
        LOOP_CAND=$($LOSETUP --find --show -P --sector-size 4096 --direct-io=on "/dev/$b" 2>/dev/null) || true
        [ -n "$LOOP_CAND" ] && LOOPDEV="$LOOP_CAND"
        $BLKID --uuid "$ROOTUUID" >/dev/null 2>&1 && break
    done
fi

udevadm settle 2>/dev/null || true

# 3) 首启自动扩展 Root 分区 (对齐 pmOS init_functions_2nd.sh):
#    resize_root_partition: 嵌套 GPT(subpartition) 场景 -> parted resizepart 2 100% + partprobe
#    resize_root_filesystem: e2fsck -p + resize2fs 扩展到整个分区
if [ -n "$LOOPDEV" ] && [ -x /usr/sbin/parted ]; then
    # pmOS has_unallocated_space(): 设备末尾存在 free space 才扩展
    # LC_ALL=C: 强制英文输出, 避免中文 locale 下 parted 输出 "可用空间" 导致 grep "free space" 失配
    if LC_ALL=C parted -s "$LOOPDEV" print free 2>/dev/null | grep -qi "free space"; then
        echo "Raphael: extending root partition to 100% ($LOOPDEV)"
        LC_ALL=C parted -f -s "$LOOPDEV" resizepart 2 100%
        /usr/sbin/partprobe "$LOOPDEV" 2>/dev/null || true
        udevadm settle 2>/dev/null || true
        sleep 1
    fi
fi
if [ -n "$ROOTUUID" ]; then
    ROOTDEV=$($BLKID --uuid "$ROOTUUID" 2>/dev/null)
    if [ -n "$ROOTDEV" ]; then
        R2FS="/usr/sbin/resize2fs"; [ -x "$R2FS" ] || R2FS="/sbin/resize2fs"
        E2FSCK="/usr/sbin/e2fsck"; [ -x "$E2FSCK" ] || E2FSCK="/sbin/e2fsck"
        if [ -x "$R2FS" ]; then
            touch /etc/mtab 2>/dev/null || true  # pmOS: bugs.debian.org/673323
            [ -x "$E2FSCK" ] && "$E2FSCK" -fp "$ROOTDEV" 2>/dev/null || true
            "$R2FS" "$ROOTDEV" 2>/dev/null || true
        fi
    fi
fi
EOF
else
    # Ubuntu: PATH blkid 即 util-linux (busybox 无 blkid applet)
    cat > rootdir/etc/initramfs-tools/scripts/local-top/raphael-subpartition << 'EOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
prereqs) prereqs; exit 0;;
esac

. /scripts/functions

# 与 pmOS init_functions.sh 的 mount_subpartitions() 对齐:
# rootfs.img 整体刷入 userdata, 内部为嵌套 GPT (4096B 扇区)。
# 这里用 util-linux losetup 将 userdata 等 Android 分区映射为 loop 设备并扫描分区,
# 暴露 p1=Boot 与 p2=Root, 随后 root=UUID= 才能被 initramfs-tools 找到。

# util-linux losetup 优先 (klibc 版不支持 --sector-size)
LOSETUP="/usr/sbin/losetup"
[ -x "$LOSETUP" ] || LOSETUP="/usr/bin/losetup"
[ -x "$LOSETUP" ] || LOSETUP="losetup"

modprobe loop 2>/dev/null || true

# 从内核 cmdline 提取 root=UUID=
ROOTUUID=""
for a in $(cat /proc/cmdline); do
    case "$a" in
        root=UUID=*) ROOTUUID="${a#root=UUID=}" ;;
    esac
done

# 1) 优先等待 by-partlabel/userdata 并映射
LOOPDEV=""
i=0
while [ ! -e /dev/disk/by-partlabel/userdata ]; do
    i=$((i+1))
    [ "$i" -gt 50 ] && break
    sleep 0.1
done
if [ -e /dev/disk/by-partlabel/userdata ]; then
    LOOPDEV=$($LOSETUP --find --show -P --sector-size 4096 --direct-io=on /dev/disk/by-partlabel/userdata 2>/dev/null) || true
fi

# 2) 若根 UUID 仍不可见, 遍历所有分区设备逐个尝试 (pmOS 同款兜底)
if [ -n "$ROOTUUID" ] && ! blkid --uuid "$ROOTUUID" >/dev/null 2>&1; then
    for b in /sys/class/block/*; do
        [ -d "$b" ] || continue
        b=$(basename "$b")
        case "$b" in
            loop*|ram*|zram*|dm-*) continue ;;
        esac
        # 只处理分区/逻辑设备, 跳过整盘
        [ -e "/sys/class/block/$b/partition" ] || continue
        LOOP_CAND=$($LOSETUP --find --show -P --sector-size 4096 --direct-io=on "/dev/$b" 2>/dev/null) || true
        [ -n "$LOOP_CAND" ] && LOOPDEV="$LOOP_CAND"
        blkid --uuid "$ROOTUUID" >/dev/null 2>&1 && break
    done
fi

udevadm settle 2>/dev/null || true

# 3) 首启自动扩展 Root 分区 (对齐 pmOS init_functions_2nd.sh):
#    resize_root_partition: 嵌套 GPT(subpartition) 场景 -> parted resizepart 2 100% + partprobe
#    resize_root_filesystem: e2fsck -p + resize2fs 扩展到整个分区
if [ -n "$LOOPDEV" ] && [ -x /usr/sbin/parted ]; then
    # pmOS has_unallocated_space(): 设备末尾存在 free space 才扩展
    # LC_ALL=C: 强制英文输出, 避免中文 locale 下 parted 输出 "可用空间" 导致 grep "free space" 失配
    if LC_ALL=C parted -s "$LOOPDEV" print free 2>/dev/null | grep -qi "free space"; then
        echo "Raphael: extending root partition to 100% ($LOOPDEV)"
        LC_ALL=C parted -f -s "$LOOPDEV" resizepart 2 100%
        partprobe "$LOOPDEV" 2>/dev/null || true
        udevadm settle 2>/dev/null || true
        sleep 1
    fi
fi
if [ -n "$ROOTUUID" ]; then
    ROOTDEV=$(blkid --uuid "$ROOTUUID" 2>/dev/null)
    if [ -n "$ROOTDEV" ]; then
        R2FS="/usr/sbin/resize2fs"; [ -x "$R2FS" ] || R2FS="/sbin/resize2fs"
        E2FSCK="/usr/sbin/e2fsck"; [ -x "$E2FSCK" ] || E2FSCK="/sbin/e2fsck"
        if [ -x "$R2FS" ]; then
            touch /etc/mtab 2>/dev/null || true  # pmOS: bugs.debian.org/673323
            [ -x "$E2FSCK" ] && "$E2FSCK" -fp "$ROOTDEV" 2>/dev/null || true
            "$R2FS" "$ROOTDEV" 2>/dev/null || true
        fi
    fi
fi
EOF
fi
chroot rootdir chmod +x /etc/initramfs-tools/scripts/local-top/raphael-subpartition

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 强制生成 initramfs (mkinitramfs, 直出 /boot/initrd.img-<ver> 标准名)..."
KVER=$(ls rootdir/lib/modules/ | grep -vE '^(build|source)$' | head -1)
echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ 内核版本: ${KVER}"
chroot rootdir mkinitramfs -o "/boot/initrd.img-${KVER}" "${KVER}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 校验 initramfs 内容..."
WORKDIR_SAVE=$PWD
mkdir -p rootdir/tmp/vinit
cd rootdir/tmp/vinit
zstd -dc "../../boot/initrd.img-${KVER}" 2>/dev/null | cpio -idm --quiet 2>/dev/null || true
if [ -x usr/sbin/losetup ] && strings usr/sbin/losetup 2>/dev/null | grep -q 'sector-size'; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: util-linux losetup (--sector-size) 已进入 initramfs"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  losetup 未找到或缺少 --sector-size, 请检查"
fi
if [ -x bin/sh ] && strings bin/sh 2>/dev/null | grep -q 'failed to set up loop'; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  bin/sh 被 losetup 污染 (zz-busybox 共享 inode), /init 无法启动"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: bin/sh 为正常 shell"
fi
if [ -x scripts/local-top/raphael-subpartition ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: raphael-subpartition local-top 已进入 initramfs"
fi
if [ -x usr/sbin/parted ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: parted 已进入 initramfs (首启自动扩展 Root)"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  parted 未进入 initramfs, 请检查 06 是否安装 parted"
fi
if [ -x usr/sbin/resize2fs ] || [ -x sbin/resize2fs ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: resize2fs 已进入 initramfs"
fi
if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
    # Debian 特有校验: busybox 版 partprobe/blkid 不可靠, 必须确认 util-linux 版已进入
    if [ -x usr/sbin/blkid ] && strings usr/sbin/blkid 2>/dev/null | grep -q 'util-linux'; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: blkid util-linux 已进入 initramfs"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  blkid 未进入 initramfs (busybox 版对 loop UUID 查找不可靠)"
    fi
    if [ -x usr/sbin/partprobe ] && strings usr/sbin/partprobe 2>/dev/null | grep -q 'libparted'; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')]     └─ OK: partprobe util-linux (libparted) 已进入 initramfs"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  partprobe 未进入 initramfs"
    fi
fi
cd "$WORKDIR_SAVE"
rm -rf rootdir/tmp/vinit

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 内核安装完成"
