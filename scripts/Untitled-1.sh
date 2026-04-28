#!/bin/sh
set -e  # 遇到错误立即退出

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]
then
  echo "rootfs can only be built as root"
  exit
fi

# 设置 Ubuntu 版本
UBUNTU_VERSION="noble"

# 创建根文件系统镜像
truncate -s 3G rootfs.img
mkfs.ext4 rootfs.img
mkdir rootdir
mount -o loop rootfs.img rootdir

# debootstrap生成镜像
debootstrap --arch=arm64 $UBUNTU_VERSION rootdir https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/

# 挂载boot
mount -o loop xiaomi-k20pro-boot.img rootdir/boot

# 绑定系统目录
mount --bind /dev rootdir/dev
mount --bind /dev/pts rootdir/dev/pts
mount --bind /proc rootdir/proc
mount --bind /sys rootdir/sys

# 配置网络和主机名
echo "nameserver 1.1.1.1" | tee rootdir/etc/resolv.conf
echo "xiaomi-raphael" | tee rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 xiaomi-raphael" | tee rootdir/etc/hosts

# Chroot 安装步骤
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH
export DEBIAN_FRONTEND=noninteractive

# 配置清华镜像源
cat > rootdir/etc/apt/sources.list << 'EOF'
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
EOF

# 更新系统
chroot rootdir apt update
chroot rootdir apt upgrade -y

# 安装基础软件包
chroot rootdir apt install -y bash-completion sudo apt-utils ssh openssh-server nano network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata language-pack-zh-hans dnsmasq iptables iproute2

# 设置时区和语言
echo "Asia/Shanghai" > rootdir/etc/timezone
chroot rootdir ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
chroot rootdir locale-gen en_US.UTF-8 zh_CN.UTF-8
chroot rootdir update-locale LANG=en_US.UTF-8

# 配置动态语言切换（SSH使用中文，TTY使用英文）
cat > rootdir/etc/profile.d/99-locale-fix.sh << 'EOF'
# 如果是SSH连接，则使用中文
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
fi
EOF
chmod +x rootdir/etc/profile.d/99-locale-fix.sh

# 安装设备特定软件包
chroot rootdir apt install -y rmtfs protection-domain-mapper tqftpserv

# 修改服务配置
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service

# 复制并安装内核包（从预下载的目录）
cp xiaomi-raphael-debs_$1/*-xiaomi-raphael.deb rootdir/tmp/
chroot rootdir dpkg -i /tmp/linux-image-xiaomi-raphael.deb
chroot rootdir dpkg -i /tmp/linux-headers-xiaomi-raphael.deb
chroot rootdir dpkg -i /tmp/firmware-xiaomi-raphael.deb
rm rootdir/tmp/*-xiaomi-raphael.deb
chroot rootdir update-initramfs -c -k all

# 配置 NCM
cat > rootdir/etc/dnsmasq.d/usb-ncm.conf << 'EOF'
interface=usb0
bind-dynamic
port=0
dhcp-authoritative
dhcp-range=172.16.42.2,172.16.42.254,255.255.255.0,1h
dhcp-option=3,172.16.42.1
EOF
echo "net.ipv4.ip_forward=1" | tee rootdir/etc/sysctl.d/99-usb-ncm.conf
chroot rootdir systemctl enable dnsmasq
cat > rootdir/usr/local/sbin/setup-usb-ncm.sh << 'EOF'
#!/bin/sh
set -e
modprobe libcomposite
mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config
G=/sys/kernel/config/usb_gadget/g1
mkdir -p $G
echo 0x1d6b > $G/idVendor
echo 0x0104 > $G/idProduct
echo 0x0200 > $G/bcdUSB
mkdir -p $G/strings/0x409
echo xiaomi-raphael > $G/strings/0x409/manufacturer
echo NCM > $G/strings/0x409/product
echo $(cat /etc/machine-id) > $G/strings/0x409/serialnumber
mkdir -p $G/configs/c.1
mkdir -p $G/configs/c.1/strings/0x409
echo NCM > $G/configs/c.1/strings/0x409/configuration
mkdir -p $G/functions/ncm.usb0
ln -sf $G/functions/ncm.usb0 $G/configs/c.1/
UDC=$(ls /sys/class/udc | head -n 1)
echo $UDC > $G/UDC
ip link set usb0 up
ip addr add 172.16.42.1/24 dev usb0 || true
OUT=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -o $OUT -j MASQUERADE || iptables -t nat -A POSTROUTING -o $OUT -j MASQUERADE
iptables -C FORWARD -i $OUT -o usb0 -m state --state RELATED,ESTABLISHED -j ACCEPT || iptables -A FORWARD -i $OUT -o usb0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -C FORWARD -i usb0 -o $OUT -j ACCEPT || iptables -A FORWARD -i usb0 -o $OUT -j ACCEPT
systemctl restart dnsmasq || true
EOF
chmod +x rootdir/usr/local/sbin/setup-usb-ncm.sh
cat > rootdir/etc/systemd/system/usb-ncm.service << 'EOF'
[Unit]
Description=USB CDC-NCM gadget setup
After=network.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/setup-usb-ncm.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
chroot rootdir systemctl enable usb-ncm

# 配置 fstab
echo "PARTLABEL=userdata / ext4 errors=remount-ro,x-systemd.growfs 0 1
PARTLABEL=cache /boot vfat umask=0077 0 1" | tee rootdir/etc/fstab

# 创建默认用户
echo "root:1234" | chroot rootdir chpasswd
chroot rootdir useradd -m -G sudo -s /bin/bash user
echo "user:1234" | chroot rootdir chpasswd

# 允许SSH root登录
echo "PermitRootLogin yes" | tee -a rootdir/etc/ssh/sshd_config
echo "PasswordAuthentication yes" | tee -a rootdir/etc/ssh/sshd_config

# 彻底禁用系统休眠
chroot rootdir systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 配置 Netplan 使用 NetworkManager
cat > rootdir/etc/netplan/01-network-manager-all.yaml << 'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF

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

# 清理 apt 缓存
chroot rootdir apt clean

# 重命名 boot 文件
mv rootdir/boot/initrd.img-* rootdir/boot/initramfs
mv rootdir/boot/vmlinuz-* rootdir/boot/linux.efi

# 删除 wifi 证书
rm -f rootdir/lib/firmware/reg*

# 卸载所有挂载点
umount rootdir/sys
umount rootdir/proc
umount rootdir/dev/pts
umount rootdir/dev
umount rootdir/boot
umount rootdir

rm -d rootdir

# 设置文件系统 UUID
tune2fs -U ee8d3593-59b1-480e-a3b6-4fefb17ee7d8 rootfs.img

echo 'cmdline for legacy boot: "root=PARTLABEL=userdata"'

# 压缩 rootfs 镜像
7z a rootfs.7z rootfs.img