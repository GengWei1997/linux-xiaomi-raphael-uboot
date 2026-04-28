# 小米 Raphael 设备 Linux 系统镜像构建项目

本项目提供用于小米 Raphael 设备（Redmi K20 Pro）的 Debian/Ubuntu Linux 系统镜像构建脚本和自动化工作流，支持桌面环境和服务器版本。

## 📋 项目概述

本项目包含完整的构建工具链，可用于构建适用于小米 Raphael 设备的 Linux 系统镜像，包括：

- **内核编译工作流** - 自动化编译定制的 Linux 内核
- **Debian gnome** - 带 gnome 桌面环境的 Debian 系统
- **Debian Phosh** - 带 Phosh 桌面环境的 Debian 系统
- **Debian Server** - 无图形界面的 Debian 服务器系统
- **Ubuntu gnome** - 带 gnome 桌面环境的 Ubuntu 系统
- **Ubuntu Phosh** - 带 Phosh 桌面环境的 Ubuntu 系统
- **Ubuntu Server** - 无图形界面的 Ubuntu 服务器系统

## 📋 目前工作

- ✅ Wi-Fi (2.4Ghz，5Ghz)
- ✅ 蓝牙 (文件传输，音频)
- ✅ USB (ssh，OTG)
- ✅ 电池
- ✅ 实时时钟
- ✅ 显示
- ✅ 触摸
- ✅ 手电筒 (LED及强度调节)
- ✅ GPU
- ✅ FDE

## 🚀 快速开始

### 使用 GitHub Actions 自动化构建

1. **Fork 本仓库**到你的 GitHub 账户

2. **构建内核**：
   - 进入仓库的 Actions 页面
   - 选择 "内核编译" 工作流
   - 点击 "Run workflow"
   - 输入内核版本号（如 `6.18`）
   - 等待构建完成，产物将自动发布到 Releases

3. **构建系统镜像**：
   - 选择 "构建系统镜像" 工作流
   - 点击 "Run workflow"
   - 选择系统类型：
       - `debian-gnome`：Debian gnome 版
       - `debian-phosh`：Debian Phosh 版
       - `debian-server`：Debian 服务器版
       - `ubuntu-gnome`：Ubuntu gnome 版
       - `ubuntu-phosh`：Ubuntu Phosh 版
       - `ubuntu-server`：Ubuntu 服务器版
   - 内核版本号：
       - `上一步构建的内核版本号`
   - 选择桌面环境（仅适用于Phosh版本，GNOME版本和server版本无需选择）：
       - `phosh-core`：基础 Phosh 环境
       - `phosh-full`：完整的 Phosh 环境
       - `phosh-phone`：手机优化的 Phosh 环境
   - 等待构建完成，镜像将自动发布到 Releases

## 📦 镜像特性

### 通用特性
- ✅ 清华大学软件源
- ✅ 简体中文语言环境
- ✅ 中国标准时区
- ✅ 支持NCM（usb连接电脑，ssh示例：`ssh user@172.16.42.1`）
- ✅ 预装 SSH 服务器
- ✅ 允许 root SSH 登录
- ✅ 包含必要的设备驱动和固件
- ✅ 默认用户：`user`（密码：`1234`），`root`（密码：`1234`）
- ✅ [一键更新内核脚本](https://github.com/GengWei1997/kernel-deb)

### 桌面版额外特性
- ✅ GNOME 桌面环境(电源键无法息屏）
- ✅ Phosh 移动桌面环境

### 服务器版额外特性
- ✅ 网络管理器
- ✅ 开机15秒后自动熄屏
- ✅ 命令行输入 `leijun` 关闭屏幕，`jinfan` 打开屏幕

## 🔧 安装到设备

### 准备工作
1. **解锁 Bootloader**：确保设备已解锁 Bootloader
2. **安装工具**：安装 `fastboot` 和 `adb`

### 刷机步骤

```bash
# 1. 进入 Fastboot 模式
adb reboot bootloader

# 2. 擦除分区
fastboot erase dtbo
fastboot erase boot
fastboot erase cache
fastboot erase userdata

# 3. 刷入 boot 镜像
fastboot flash cache xiaomi-k20pro-boot.img
fastboot flash boot u-boot.img

# 4. 刷入系统镜像（需要先解压 rootfs.7z）
fastboot flash userdata rootfs.img

# 5. 重启设备
fastboot reboot
```

## ❓ 常见问题解答 (FAQ)

- [解决Windows下无法连接使用CDC NCM驱动](https://www.bilibili.com/video/BV1tW4y1A79V/)

- server版怎么连接网络？？？
	- 1.OTG连接网线系统会自动识别
	- 2.OTG连接键盘输入 `nmtui` 连接wifi
	- 3.usb连接电脑安装好NCM驱动后输入 `nmtui` 连接wifi

## 🙏 致谢

- 感谢所有 Linux 内核开发者的辛勤工作
- 感谢 Debian 和 Ubuntu 社区
- 感谢 Phosh 桌面环境开发团队
- 感谢所有贡献者和用户的支持
- [@璀璨梦星](https://github.com/ccmx200) - 提供帮助以及创新思路
- [@map220v](https://github.com/map220v/ubuntu-xiaomi-nabu) - 原项目
- [@Pc1598](https://github.com/Pc1598) - sm8150-mainline-raphael内核维护
- [Aospa-raphael-unofficial/linux](https://github.com/Aospa-raphael-unofficial/linux) - 内核项目
- [sm8150-mainline/linux](https://gitlab.com/sm8150-mainline/linux) - 内核项目
