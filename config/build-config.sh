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
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "debian-gnome")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "debian-phosh")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
    "ubuntu-server")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "ubuntu-gnome")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "ubuntu-phosh")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
  esac
}

# 镜像源配置
sources_config() {
  if [[ "$1" == *"debian-"* ]]; then
    local version="${DEBIAN_VERSION:-trixie}"
    echo "DEBIAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/debian/"
    echo "DEBIAN_SECURITY_MIRROR=http://security.debian.org/debian-security"
  elif [[ "$1" == *"ubuntu-"* ]]; then
    local version="${UBUNTU_VERSION:-resolute}"
    echo "UBUNTU_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"
    echo "UBUNTU_SECURITY_MIRROR=http://ports.ubuntu.com/ubuntu-ports/"
  fi
}

# 软件包配置
get_packages() {
  local system_type="$1"
  local desktop_env="$2"
  
  base_packages="bash-completion sudo apt-utils ssh openssh-server nano network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata dnsmasq iptables iproute2"
  
  if [[ "$system_type" == *"debian-"* ]]; then
    base_packages="$base_packages fonts-wqy-microhei"
  elif [[ "$system_type" == *"ubuntu-"* ]]; then
    base_packages="$base_packages language-pack-zh-hans"
  fi
  
  if [[ "$system_type" == *"server"* ]]; then
    echo "$base_packages"
  else
    case "$desktop_env" in
      "gnome")
        echo "$base_packages gnome gnome-terminal gdm3"
        ;;
      "phosh-core")
        if [[ "$system_type" == *"ubuntu-"* ]]; then
          echo "$base_packages phosh phoc onboard"
        elif [[ "$system_type" == *"debian-"* ]]; then
          echo "$base_packages phosh phoc squeekboard"
        fi
        ;;
      "phosh-full")
        if [[ "$system_type" == *"ubuntu-"* ]]; then
          echo "$base_packages phosh phoc onboard gnome-settings-daemon gnome-control-center"
        elif [[ "$system_type" == *"debian-"* ]]; then
          echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center"
        fi
        ;;
      "phosh-phone")
        echo "$base_packages phosh phoc squeekboard gnome-settings-daemon gnome-control-center ofono mobian-tweaks"
        ;;
      *)
        # 默认返回基础包
        echo "$base_packages"
        ;;
    esac
  fi
}