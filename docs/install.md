# 安装小滚轮

**简体中文** | [English](install.en.md)

适用于 macOS 13 及以上。通用安装包包含 Apple Silicon 和 Intel 两种架构；目前已在 Apple Silicon / macOS 27 上实测，Intel 和旧系统尚待实机验证。

## 下载与安装

1. 打开 [GitHub Release](https://github.com/gitman-g1/TameWheel/releases/tag/v0.3.0)，在 Assets 中下载 **TameWheel-0.3.0-universal.dmg**。
2. 打开 DMG，把 **TameWheel.app** 拖入 **Applications（应用程序）**。
3. 推出磁盘映像，从“应用程序”打开小滚轮。它常驻菜单栏，不显示 Dock 图标。

也可以下载 **TameWheel-0.3.0-universal.zip**，解压后将应用拖入“应用程序”。GitHub 自动提供的 `Source code` 是源码，不是安装包。

## 首次打开

**当前为临时签名的公开测试版，尚未经过 Apple 公证。** 首次打开可能遇到系统的开发者验证提示。

如果系统提示无法验证开发者或无法检查恶意软件，先确认安装包来自上述官方 Release；尝试打开后，到“系统设置 → 隐私与安全性”，在小滚轮对应的提示旁选择“仍要打开”，再确认打开。这是 Apple 提供的单个应用放行流程。[Apple 官方说明](https://support.apple.com/zh-cn/102445)

如果提示文件损坏，请重新下载，并与同一 Release 的 `SHA256SUMS.txt` 核对；仍无法打开时，请通过 [Issues](https://github.com/gitman-g1/TameWheel/issues) 提供系统版本和提示内容。

## 允许调整鼠标滚轮

1. 点击菜单栏的鼠标图标，打开开关。
2. 在“系统设置 → 隐私与安全性 → 辅助功能”中允许小滚轮。需要手动添加时，选择“应用程序”中的 **TameWheel.app**。
3. 回到菜单栏，开关开启后即可使用。

系统保留“自然滚动”开启时，鼠标会采用熟悉的 Windows 滚轮方向，触控板保留原来的手感。关闭开关或退出小滚轮即可恢复系统滚动。

本工具适用于普通鼠标的垂直离散滚轮；Magic Mouse、高精度连续滚轮和被其他驱动转换过的事件可能原样通过。请避免同时用其他工具修改滚轮方向或速度。

## 更新或卸载

更新时先右键菜单栏图标，选择“退出小滚轮”，再用新版本替换“应用程序”中的旧版本。临时签名更新后，若权限已开启但应用仍提示未授权，在辅助功能列表中移除旧条目，再添加当前的 **TameWheel.app**。

卸载时先退出应用，再将它移到废纸篓，并移除辅助功能权限。小滚轮不会改写系统鼠标或触控板的滚动设置。
