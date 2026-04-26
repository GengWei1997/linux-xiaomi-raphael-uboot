# 系统类型配置
SYSTEM_TYPES="
  debian-server
  debian-gnome
  debian-phosh
  ubuntu-server
  ubuntu-gnome
  ubuntu-phosh
"

# 系统类型到基础设置的映射
system_config() {
  case "$1" in
    "debian-server")
      echo "DEBIAN_VERSION=trixie"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "debian-gnome")
      echo "DEBIAN_VERSION=trixie"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "debian-phosh")
      echo "DEBIAN_VERSION=trixie"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
    "ubuntu-server")
      echo "UBUNTU_VERSION=resolute"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "ubuntu-gnome")
      echo "UBUNTU_VERSION=resolute"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "ubuntu-phosh")
      echo "UBUNTU_VERSION=resolute"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
  esac
}

# 镜像源配置
sources_config() {
  case "$1" in
    debian-*)
      echo "DEBIAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/debian/"
      echo "DEBIAN_SECURITY_MIRROR=http://security.debian.org/debian-security"
      ;;
    ubuntu-*)
      echo "UBUNTU_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"
      echo "UBUNTU_SECURITY_MIRROR=http://ports.ubuntu.com/ubuntu-ports/"
      ;;
  esac
}

# 软件包配置
get_packages() {
  local system_type="$1"
  local desktop_env="$2"
  
  base_packages="bash-completion sudo apt-utils ssh openssh-server nano network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata dnsmasq iptables iproute2"
  
  case "$system_type" in
    debian-*)
      base_packages="$base_packages fonts-wqy-microhei"
      ;;
    ubuntu-*)
      base_packages="$base_packages language-pack-zh-hans"
      ;;
  esac
  
  if [[ "$system_type" == *"server"* ]]; then
    echo "$base_packages"
  else
    case "$desktop_env" in
      "gnome")
        echo "$base_packages gnome gnome-terminal gdm3"
        ;;
      "phosh-core")
        echo "$base_packages phosh phoc squeekboard"
        ;;
      "phosh-full")
        echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center"
        ;;
      "phosh-phone")
        echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center ofono mobian-tweaks"
        ;;
    esac
  fi
}