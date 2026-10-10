#!/bin/bash
set -e

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
DEBIAN_VERSION="${DEBIAN_VERSION:-trixie}"
UBUNTU_VERSION="${UBUNTU_VERSION:-resolute}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 📦 安装软件包"

export DEBIAN_FRONTEND=noninteractive

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 更新系统包..."
chroot rootdir apt-get update
chroot rootdir apt-get upgrade -y

BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata iproute2 zram-tools"

if [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then 
    BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata fonts-wqy-microhei dnsmasq nftables iproute2 zram-tools"
elif [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
    if [[ "$SYSTEM_TYPE" == *"server"* ]]; then
        BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata dnsmasq nftables iproute2 zram-tools"
    else
        BASE_PACKAGES="bash-completion sudo apt-utils ssh openssh-server nano network-manager initramfs-tools chrony curl wget locales tzdata dnsmasq nftables iproute2 zram-tools"
    fi
fi

DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv qrtr-tools libqmi-utils hexagonrpcd"

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    case "$DESKTOP_ENV" in
        "gnome")
            if [[ "$SYSTEM_TYPE" == *"ubuntu-"* ]]; then
                DESKTOP_PACKAGES="ubuntu-desktop"
            elif [[ "$SYSTEM_TYPE" == *"debian-"* ]]; then
                DESKTOP_PACKAGES="gnome"
            fi
            ;;
        "phosh-core")
            DESKTOP_PACKAGES="phosh-core"
            ;;
        "phosh-full")
            DESKTOP_PACKAGES="phosh-full"
            ;;
        "phosh-phone")
            DESKTOP_PACKAGES="phosh-phone"
            ;;
        *)
            DESKTOP_PACKAGES=""
            ;;
    esac
else
    DESKTOP_PACKAGES=""
fi

ALL_PACKAGES="$BASE_PACKAGES $DEVICE_PACKAGES $DESKTOP_PACKAGES"

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 基础包: $(echo "$BASE_PACKAGES" | tr ' ' ', ')"
echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 设备包: $(echo "$DEVICE_PACKAGES" | tr ' ' ', ')"
if [ -n "$DESKTOP_PACKAGES" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 桌面包: $(echo "$DESKTOP_PACKAGES" | tr ' ' ', ')"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 开始安装（这可能需要几分钟...）"
chroot rootdir apt-get install -y $ALL_PACKAGES parted

echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 systemd-boot (U-Boot 引导链)"
chroot rootdir bash -c 'apt-get install -y systemd-boot-efi 2>/dev/null || apt-get install -y systemd-boot 2>/dev/null || true'

# 修改服务配置
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service 2>/dev/null || true

# UIM 卡槽选择 (pmOS msm-modem-uim-selection), SIM 自动识别
install -m 755 scripts/msm-modem-uim-selection rootdir/usr/libexec/
install -m 644 scripts/msm-modem-uim-selection.service rootdir/lib/systemd/system/
chroot rootdir systemctl enable msm-modem-uim-selection 2>/dev/null || true

# hexagonrpcd (SDSP sensors daemon): 固定 sdsp 设备, attach sensorspd, 崩溃自动重启
mkdir -p rootdir/etc/systemd/system/hexagonrpcd.service.d/
cat > rootdir/etc/systemd/system/hexagonrpcd.service.d/sdsp.conf <<EOF
[Service]
Environment=hexagonrpcd_device=/dev/fastrpc-sdsp
Environment=hexagonrpcd_dsp=sdsp
Environment=hexagonrpcd_extra=-s
Restart=always
RestartSec=3
EOF
chroot rootdir systemctl enable hexagonrpcd 2>/dev/null || true
# 固件已内置在镜像中, 无需 droid-juicer 提取
chroot rootdir systemctl mask droid-juicer 2>/dev/null || true

if [ -f "$KERNEL_DEBS_DIR/alsa-xiaomi-raphael.deb" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 安装 ALSA 配置"
    # alsa-xiaomi-raphael 依赖 alsa-ucm-conf（桌面版由桌面包连带安装，server 版需显式安装）
    chroot rootdir bash -c 'apt-get install -y alsa-ucm-conf 2>/dev/null || true'
    cp "$KERNEL_DEBS_DIR/alsa-xiaomi-raphael.deb" rootdir/tmp/
    chroot rootdir dpkg -i /tmp/alsa-xiaomi-raphael.deb
    rm rootdir/tmp/alsa-xiaomi-raphael.deb
fi

if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    if [[ "$DESKTOP_ENV" == phosh* ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')]   └─ 启用 Phosh 服务"
        chroot rootdir systemctl enable phosh
    fi
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ 软件包安装完成"
