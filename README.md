# 小米 Redmi K20 Pro (Raphael) 系统镜像构建框架

## 项目简介

本项目提供了一个统一的构建框架，用于为小米 Redmi K20 Pro (代号 Raphael) 构建各种 Linux 系统镜像。支持以下系统类型：

- **Debian Server** - 无图形界面的服务器版本
- **Debian GNOME** - 带有 GNOME 桌面的版本
- **Debian Phosh** - 带有 Phosh 移动桌面的版本
- **Ubuntu Server** - 无图形界面的服务器版本
- **Ubuntu GNOME** - 带有 GNOME 桌面的版本
- **Ubuntu Phosh** - 带有 Phosh 移动桌面的版本

## 目录结构

```
├── .github/workflows/        # GitHub Actions 工作流
│   ├── build-system.yml      # 统一构建工作流
│   └── 构建rootfs镜像.yaml   # 旧版工作流（保留）
├── config/                   # 配置文件
│   ├── build-config.sh       # 构建配置
│   ├── sources.list.tpl      # 镜像源模板
│   └── netplan.yaml.tpl      # 网络配置模板
├── scripts/                  # 模块化构建脚本
│   ├── 01-create-image.sh    # 创建镜像
│   ├── 02-bootstrap.sh       # 安装基础系统
│   ├── ...                   # 其他构建步骤
│   └── 16-finalize.sh        # 完成镜像
├── build.sh                  # 统一构建入口
├── debian-*.sh               # 兼容性脚本
├── ubuntu-*.sh               # 兼容性脚本
└── README.md                 # 说明文档
```

## 系统要求

- **硬件**：ARM64 架构设备（如树莓派 4、Apple Silicon Mac）或支持 QEMU 模拟的 x86 设备
- **软件**：
  - Ubuntu 22.04+ 或 Debian 11+
  - root 权限
  - debootstrap
  - p7zip-full
  - coreutils
  - curl

## 构建方法

### 1. 下载内核包

```bash
# 下载指定版本的内核包
./scripts/download-deps.sh 6.18
```

### 2. 构建镜像

使用统一构建脚本：

```bash
# 构建 Debian Server 镜像（默认使用 trixie 版本）
sudo ./build.sh debian-server 6.18

# 构建指定 Debian 版本的镜像
sudo ./build.sh debian-server 6.18 "" bookworm

# 构建 Ubuntu Server 镜像（默认使用 resolute 版本）
sudo ./build.sh ubuntu-server 6.18

# 构建指定 Ubuntu 版本的镜像
sudo ./build.sh ubuntu-server 6.18 "" noble

# 构建 Ubuntu GNOME 镜像
sudo ./build.sh ubuntu-gnome 6.18

# 构建指定版本的 Ubuntu GNOME 镜像
sudo ./build.sh ubuntu-gnome 6.18 "" 24.04

# 构建 Debian Phosh 镜像（指定桌面环境）
sudo ./build.sh debian-phosh 6.18 phosh-full

# 构建指定版本的 Debian Phosh 镜像
sudo ./build.sh debian-phosh 6.18 phosh-full trixie
```

或者使用兼容性脚本（保持向后兼容）：

```bash
# 构建 Debian Server 镜像
sudo ./debian-server_build.sh 6.18

# 构建 Ubuntu Server 镜像
sudo ./ubuntu-server_build.sh 6.18
```

### 3. 构建产物

构建完成后，会生成以下文件：

- `rootfs.7z` - 压缩的根文件系统镜像
- `rootfs.img` - 原始根文件系统镜像
- `sha256sums.txt` - SHA256 校验和
- `xiaomi-k20pro-boot.img` - Boot 分区镜像

## GitHub Actions 自动构建

本项目支持通过 GitHub Actions 自动构建：

1. 进入项目的 GitHub 页面
2. 点击 "Actions" 标签
3. 选择 "构建系统镜像" 工作流
4. 点击 "Run workflow" 按钮
5. 选择系统类型、内核版本和桌面环境（仅 Phosh）
6. **可选**：指定 Debian 版本或 Ubuntu 版本
7. 点击 "Run workflow" 开始构建

构建完成后，镜像会自动发布到 GitHub Releases。

## 系统配置

### 默认用户名和密码

- **root** - 密码：1234
- **user** - 密码：1234

### SSH 配置

- 允许 root 登录
- 允许密码认证

### 网络配置

- 使用 NetworkManager 管理网络
- USB NCM 网络已配置（IP: 172.16.42.1）

### 电源管理

- 禁用系统休眠
- 15秒后自动熄屏
- 屏幕管理命令：
  - `leijun` - 关闭屏幕
  - `jinfan` - 开启屏幕

## 桌面环境

### GNOME
- 自动登录用户 `user`
- 包含基本 GNOME 应用

### Phosh
- 提供三种桌面环境选项：
  - `phosh-core` - 核心组件
  - `phosh-full` - 完整组件（推荐）
  - `phosh-phone` - 包含电话功能

## 设备特定配置

- 已安装设备驱动和固件
- 配置了 ALSA 音频
- 支持 USB NCM 网络

## 注意事项

1. 构建过程需要较大的磁盘空间（至少 10GB）
2. 首次构建时间较长（约 30-60 分钟）
3. 请确保有稳定的网络连接
4. 构建完成后，使用 `dd` 命令将镜像写入存储设备

```bash
dd if=rootfs.img of=/dev/sdX bs=1M status=progress
```

## 故障排除

### 常见错误

1. **依赖文件不存在**：请确保已下载内核包和 boot.img
2. **权限错误**：确保以 root 权限运行构建脚本
3. **网络错误**：检查网络连接和镜像源配置
4. **磁盘空间不足**：确保有足够的磁盘空间

### 日志查看

构建过程中的详细日志会显示在终端中，便于排查问题。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 许可证

本项目采用 MIT 许可证。