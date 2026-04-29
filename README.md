# 小米 Raphael 设备 Linux 系统镜像构建项目

本项目为**小米 Raphael（Redmi K20 Pro）**专属 Linux 镜像构建项目，提供完整的 Debian / Ubuntu 系统镜像构建脚本与 GitHub Actions 自动化工作流，支持多内核、多桌面、服务器极简版本，开箱即用，适配性完善。

## 📌 项目概述

项目集成全套自动化构建工具链，支持内核编译、系统镜像打包，覆盖桌面端与服务器端系统，所有镜像均预装适配设备的专属驱动、固件及常用工具，无需额外配置即可正常使用。

支持构建系统类型：

- **Debian 系列**：GNOME 桌面版、Phosh 移动桌面版、Server 无图形服务器版

- **Ubuntu 系列**：GNOME 桌面版、Phosh 移动桌面版、Server 无图形服务器版

- **定制内核**：自主编译适配设备的 6\.18 / 7\.0 版本 Linux 内核

## ✅ 设备适配状态

当前设备硬件适配完整，主流功能全部可用：

- 网络：2\.4G/5G 双频 Wi\-Fi、USB NCM 网络

- 外设：蓝牙（文件传输/音频输出）、USB SSH/OTG 功能、触摸屏、手电筒（支持亮度调节）

- 基础硬件：屏幕显示、电池检测、实时时钟、GPU 渲染、FDE 加密

## 📊 版本支持矩阵

### 系统类型对照表

|系统标识|桌面环境|基础发行版|
|---|---|---|
|debian\-server|无（纯命令行）|Debian|
|debian\-gnome|GNOME|Debian|
|debian\-phosh|Phosh 移动端桌面|Debian|
|ubuntu\-server|无（纯命令行）|Ubuntu|
|ubuntu\-gnome|GNOME|Ubuntu|
|ubuntu\-phosh|Phosh 移动端桌面|Ubuntu|

### 系统与内核版本

- **Debian 版本**：trixie（默认最新）

- **Ubuntu 版本**：resolute（默认最新）

- **内核版本**：6\.18、7\.0（双版本可选，均为定制适配版）

### Phosh 桌面变体

- `phosh\-core`：轻量基础环境，仅保留核心桌面组件

- `phosh\-full`：完整桌面环境（默认），内置 GNOME 设置、全套系统工具

- `phosh\-phone`：手机专属优化，适配移动设备通话与触控逻辑

## 🚀 快速上手

### 方式一：下载预构建镜像（推荐）

项目持续自动构建最新镜像，可直接前往 [Releases](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases) 页面下载，无需本地编译。

> **⚠️ 大文件提示**：`ubuntu\-gnome\-6\.18` / `ubuntu\-gnome\-7\.0` 镜像体积超过 2GB，未上传至 Releases，需前往项目 Artifacts 下载。
> 
> 

### 方式二：GitHub Actions 自定义构建

1. Fork 本仓库至个人 GitHub 账号

2. 进入仓库 **Actions** 页面，选择「构建系统镜像」工作流

3. 点击 **Run workflow**，自定义构建参数：
        

    - **构建模式**：`parallel`并行构建全部镜像（默认） / `single` 单独构建指定镜像

    - **系统类型**：支持多类型逗号分隔，默认全量构建

    - **内核版本**：支持 `6\.18,7\.0` 双版本（默认）

    - **构建工具**：`mmdebstrap`（默认） / `debootstrap`

    - **Phosh 变体**：仅 Phosh 桌面镜像生效，默认`phosh\-full`

    - **系统版本**：默认 Debian: trixie、Ubuntu: resolute

4. 等待工作流执行完成，镜像自动打包发布至仓库 Releases

## 📦 镜像通用特性

### 全版本通用

- 默认配置**清华软件源**，国内下载速度更快

- 预装简体中文语言包、中国标准时区，开箱汉化

- 支持 USB NCM 网络共享，电脑直连设备 SSH

- 内置 SSH 服务，支持 root / 普通用户远程登录

- 集成全套设备适配驱动与固件，硬件兼容完善

- 内置**一键内核更新脚本**，可在线升级定制内核

- 默认账号密码：
       

    - 普通用户：`user` / `1234`

    - 超级用户：`root` / `1234`

- 设备默认 IP：`172\.16\.42\.1`，SSH 连接命令：`ssh user@172\.16\.42\.1`

### 桌面版专属特性

- GNOME / Phosh 双桌面环境可选，适配桌面、移动两种使用场景

- 已知问题：**GNOME 桌面电源键无法息屏**，后续版本持续修复

### 服务器版专属特性

- 内置网络管理器，支持有线、Wi\-Fi、USB 多种联网方式

- 开机 15 秒自动熄屏，降低设备功耗

- 自定义快捷命令：`leijun` 关闭屏幕、`jinfan` 点亮屏幕

## ⬆️ 内核更新教程

项目提供一键内核升级脚本，建议**root 权限**执行，快速更新设备定制内核：

官方原始链接：

```Plain Text
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/Update-kernel.sh)"
```

国内加速链接：

```Plain Text
sudo bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/ghproxy-Update-kernel.sh)"
```

脚本执行完成后，重启设备即可生效新内核。

## 🔧 设备安装教程

### 前置准备

1. 设备已完成 **Bootloader 解锁**

2. 电脑安装 `adb`、`fastboot` 刷机工具，并配置环境变量

3. 解压下载的 `\.7z` 镜像压缩包，获取 `rootfs\.img`、`u\-boot\.img` 等刷机文件

### 刷机命令

```Plain Text
# 1. 设备进入 Fastboot 模式
adb reboot bootloader

# 2. 清空设备分区（清除旧数据，避免冲突）
fastboot erase dtbo
fastboot erase boot
fastboot erase cache
fastboot erase userdata

# 3. 刷入底层引导镜像
fastboot flash boot u-boot.img

# 4. 刷入系统主镜像
fastboot flash userdata rootfs.img

# 5. 重启设备，完成刷机
fastboot reboot
```

## ❓ 常见问题 FAQ

- **Windows 无法连接设备 CDC NCM 驱动**：参考解决方案视频[BV1tW4y1A79V](https://www.bilibili.com/video/BV1tW4y1A79V/)

- **Server 版如何联网**：
        

    1. OTG 外接网线，系统自动识别联网

    2. OTG 外接键盘，终端输入 `nmtui` 可视化连接 Wi\-Fi

    3. USB 连接电脑，安装 NCM 驱动后，通过 `nmtui` 配置网络

## 🙏 致谢

本项目基于众多开源项目与开发者成果开发，特此致谢：

- Linux 内核官方开发团队、Debian / Ubuntu 开源社区、Phosh 桌面开发团队

- [@璀璨梦星](https://github.com/ccmx200)：项目优化与创新思路支持

- [@map220v](https://github.com/map220v/ubuntu-xiaomi-nabu)：上游项目参考

- [@Pc1598](https://github.com/Pc1598)：sm8150 设备内核维护

- [Aospa\-raphael\-unofficial/linux](https://github.com/Aospa-raphael-unofficial/linux)、[sm8150\-mainline/linux](https://gitlab.com/sm8150-mainline/linux)：内核源码支持

- 所有开源贡献者与项目使用者

> （注：文档部分内容可能由 AI 生成）
