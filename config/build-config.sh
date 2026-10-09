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
      echo "IMAGE_SIZE=8G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "debian-phosh")
      echo "DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}"
      echo "IMAGE_SIZE=8G"
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
      echo "IMAGE_SIZE=8G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "ubuntu-phosh")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-resolute}"
      echo "IMAGE_SIZE=8G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=$2"
      ;;
  esac
}

# ============ GPT 分区方案（Nura / postmarketOS） ============
# 镜像采用 GPT 布局: p1 = boot (fat32, ESP) + p2 = root (ext4)
# 参考: pmbootstrap device-xiaomi-raphael (deviceinfo_rootfs_image_sector_size="4096")
export BOOT_SIZE="${BOOT_SIZE:-256M}"                        # boot 分区大小
export BOOT_LABEL="${BOOT_LABEL:-Boot}"                 # boot 文件系统标签
export ROOT_LABEL="${ROOT_LABEL:-Root}"                 # root 文件系统标签
export SECTOR_SIZE="${SECTOR_SIZE:-4096}"                    # 镜像逻辑扇区大小 (UFS)
export BOOT_PART_START="${BOOT_PART_START:-2048}"            # boot 分区起始扇区 (8MiB 对齐)
export ROOT_PART_TYPE="${ROOT_PART_TYPE:-b921b045-1df0-41c3-af44-4c6f280d3fae}"  # DPS arm64 root
export ESP_PART_TYPE="${ESP_PART_TYPE:-c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"    # ESP
export BOOT_VOLID="${BOOT_VOLID:-1BF4A32B}"                  # boot 分区卷序列号 (UUID: 1BF4-A32B)
