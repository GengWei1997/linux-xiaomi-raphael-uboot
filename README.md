<div align="center">

# <img src="https://img.shields.io/badge/Device-Xiaomi_Raphael-FF6900?style=for-the-badge&logo=android&logoColor=white" alt="Device"/> <img src="https://img.shields.io/badge/Linux-Ubuntu|Debian-E95420?style=for-the-badge&logo=linux&logoColor=white" alt="Linux"/>

# 📱 小米 Raphael Linux 镜像构建项目

### Redmi K20 Pro · 一键构建 Debian / Ubuntu 系统镜像

[![Build](https://img.shields.io/github/actions/workflow/status/GengWei1997/linux-xiaomi-raphael-uboot/build-system.yml?style=flat-square&label=Build&logo=github-actions&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/actions)
[![Release](https://img.shields.io/github/v/release/GengWei1997/linux-xiaomi-raphael-uboot?style=flat-square&label=Release&logo=github&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases)
[![Stars](https://img.shields.io/github/stars/GengWei1997/linux-xiaomi-raphael-uboot?style=flat-square&logo=github&logoColor=white)](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/stargazers)

---

</div>

## ✨ 项目简介

本项目为 **小米 Raphael（Redmi K20 Pro）** 专属 Linux 镜像构建方案，提供完整的 Debian / Ubuntu 系统镜像构建脚本与 GitHub Actions 自动化工作流。支持多内核版本、多桌面环境，开箱即用。

## 📋 支持系统类型

| 系统标识 | 桌面环境 | 发行版 | 镜像大小 |
|:---:|:---:|:---:|:---:|
| `debian-server` | 无（纯命令行） | Debian trixie | 3G |
| `debian-gnome` | GNOME | Debian trixie | 6G |
| `debian-phosh` | Phosh 移动端桌面 | Debian trixie | 6G |
| `ubuntu-server` | 无（纯命令行） | Ubuntu resolute | 3G |
| `ubuntu-gnome` | GNOME | Ubuntu resolute | 6G |
| `ubuntu-phosh` | Phosh 移动端桌面 | Ubuntu resolute | 6G |

## 🖥️ 设备硬件适配

| 分类 | 支持项目 | 状态 |
|:---:|:---|:---:|
| 🌐 **网络** | 2.4G / 5G 双频 Wi-Fi | ✅ |
| 📡 **蓝牙** | 文件传输 · 音频输出 | ✅ |
| 📶 **蜂窝** | 网络支持 | ✅ |
| 🔌 **USB** | NCM 网络共享 · OTG 功能 | ✅ |
| 🖥️ **显示** | 屏幕输出 · GPU 渲染 | ✅ |
| 🔊 **音频** | 扬声器 · 耳机输出 | ✅ |
| 👆 **输入** | 触摸屏 · 闪光灯（手电筒） | ✅ |
| 🔋 **系统** | 电池检测 · 实时时钟 · FDE 加密 | ✅ |

## 🚀 快速上手

### 方式一：下载预构建镜像

前往 [Releases](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases) 页面下载最新镜像，无需本地编译。

> ⚠️ `ubuntu-gnome` 镜像体积超过 2GB，请前往项目 [Actions → Artifacts](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/actions) 下载。

### 方式二：GitHub Actions 自定义构建（推荐）

1. **Fork** 本仓库至个人 GitHub 账号
2. 进入 **Actions** 页面 → 选择「构建系统镜像」工作流 → 点击 **Run workflow**，按需选择系统类型 / 内核版本 / 构建工具
3. 等待构建完成，镜像自动发布至 Releases

> 参数说明详见 [Wiki: 自定义构建](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/wiki/Custom-Build)

## 📦 镜像特性

### 🌐 全版本通用

- 默认配置 **清华软件源**
- 预装简体中文语言包 + 中国标准时区，开箱汉化
- 支持 USB NCM 网络共享，电脑直连设备 SSH
- 内置 SSH 服务，支持 root / 普通用户远程登录
- 支持 `dpkg -i` 直接更新内核（固定名引导自动刷新，自动卸载旧内核）

| 账户 | 用户名 | 密码 |
|:---:|:---:|:---:|
| 普通用户 | `user` | `1234` |
| 超级用户 | `root` | `1234` |

> 📌 USB NCM 连接时，设备 IP：`172.16.42.1`，SSH 连接：`ssh user@172.16.42.1`

### 🎨 桌面版专属

- GNOME / Phosh 双桌面环境可选，适配桌面、移动两种使用场景

### 🖥️ 服务器版专属

- 内置网络管理器，支持有线、Wi-Fi、USB 多种联网方式
- 开机 15 秒自动熄屏，降低设备功耗
- 自定义快捷命令：`leijun` 关闭屏幕 · `jinfan` 点亮屏幕

## 🔧 安装教程

完整刷机教程见 [Wiki: 安装教程](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/wiki/Installation)，或直接下载 [一键安装](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/releases/tag/%E4%B8%80%E9%94%AE%E5%AE%89%E8%A3%85) 整合包

## 🔄 内核更新

镜像已集成 **固定名引导**（与 [Nura](https://wiki.nura.eco) / postmarketOS 一致）：`dpkg -i ./*.deb` 即可自动更新内核，钩子自动刷新 `/boot/vmlinuz` + `/boot/initrd.img` 与 dtbs，详见 [Wiki: 内核更新](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/wiki/Kernel-Updates)

## 💽 分区方案（GPT）

镜像采用 **GPT 分区表**（与 [Nura](https://wiki.nura.eco) / postmarketOS 一致），整体通过 `fastboot flash userdata rootfs.img` 刷入设备，内核与根文件系统都位于镜像内部，无需改动设备的 Android 分区布局。

| 分区 | 编号 | 文件系统 | 标签 | 大小 | 类型 |
|:---:|:---:|:---|:---:|:---:|:---|
| Boot | p1 | FAT32 | `Boot` | 256M | ESP (`c12a7328-f81f-11d2-ba4b-00a0c93ec93b`) |
| Root | p2 | ext4 | `Root` | 剩余空间 | DPS arm64 root (`b921b045-1df0-41c3-af44-4c6f280d3fae`) |

- 逻辑扇区大小: **4096 字节**（匹配 UFS 存储，对应 `deviceinfo_rootfs_image_sector_size`）
- Boot 分区起始: `2048s`（8MiB 对齐）
- 根分区固定 UUID: `ee8d3593-59b1-480e-a3b6-4fefb17ee7d8`
- Boot 分区 UUID: `1BF4-A32B`
- 启动 cmdline 参考: `root=UUID=ee8d3593-59b1-480e-a3b6-4fefb17ee7d8`
- 启动链: u-boot → systemd-boot（`EFI/BOOT/BOOTAA64.EFI`）→ 固定引导条目（`/boot/vmlinuz` + `/boot/initrd.img`，与 Nura/pmOS 一致）→ 内核
- initramfs 启动时自动将 `userdata` 分区以 4096B 扇区映射为 loop 设备，暴露镜像内嵌套 GPT 分区（与 Nura/postmarketOS 的 mount_subpartitions 机制一致，由 `scripts/09-install-kernel.sh` 生成的 local-top 脚本实现）
## ❓ 常见问题

常见问题与解决方案见 [Wiki: 常见问题](https://github.com/GengWei1997/linux-xiaomi-raphael-uboot/wiki/FAQ)

---

## 🙏 致谢

感谢以下开源项目与开发者的支持（排名不分先后）：

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/degdag">
        <img src="https://github.com/degdag.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>degdag</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/dabao1955">
        <img src="https://github.com/dabao1955.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>dabao1955</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/qaz6750">
        <img src="https://github.com/qaz6750.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>qaz6750</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/GavinLiuOnline">
        <img src="https://github.com/GavinLiuOnline.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>GavinLiuOnline</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/umeiko">
        <img src="https://github.com/umeiko.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>umeiko</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/yuweiyuan8">
        <img src="https://github.com/yuweiyuan8.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>yuweiyuan8</b></sub>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/ccmx200">
        <img src="https://github.com/ccmx200.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>璀璨梦星</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/map220v">
        <img src="https://github.com/map220v.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>map220v</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Pc1598">
        <img src="https://github.com/Pc1598.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>Pc1598</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Aospa-raphael-unofficial/linux">
        <img src="https://github.com/Aospa-raphael-unofficial.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>Aospa-raphael</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux">
        <img src="https://gitlab.postmarketos.org/uploads/-/system/project/avatar/4623/sm8150.png" width="60" height="60" style="border-radius:50%"><br>
        <sub><b>sm8150-mainline</b></sub>
      </a>
    </td>
  </tr>
</table>

<p align="center">
  <i>Linux 内核官方开发团队 · Debian / Ubuntu 开源社区 · Phosh 桌面开发团队 · 以及所有开源贡献者</i>
</p>

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐ Star 支持一下！**

</div>
