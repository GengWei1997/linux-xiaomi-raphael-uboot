#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [10] 📱 配置 USB NCM 网络"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [10]   └─ 创建 dnsmasq 配置"

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

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [10]   └─ 启用 usb-ncm 服务"
chroot rootdir systemctl enable usb-ncm

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [10] ✅ USB NCM 配置完成"
