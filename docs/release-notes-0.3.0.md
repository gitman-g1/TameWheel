# TameWheel · 小滚轮 v0.3.0

首个公开测试版：一个开关，让鼠标滚轮更顺手，触控板保持原来的自然手感。

- 单独反转普通鼠标的垂直滚轮，固定每步 3 行，无需调速。
- 保留触控板的方向、速度和惯性。
- 紧凑的原生菜单栏界面，自动记住开关状态。

## 下载与安装

下载 **TameWheel-0.3.0-universal.dmg**，打开后将 **TameWheel.app** 拖入 **Applications（应用程序）**，再从“应用程序”启动。也提供 ZIP 版本。Assets 中的 `Source code` 是源码，不是安装包。

**这是临时签名、尚未经过 Apple 公证的测试版。** 首次打开如提示无法验证开发者或无法检查恶意软件，请确认下载来源后，在“系统设置 → 隐私与安全性”中选择小滚轮对应的“仍要打开”。随后按提示授予辅助功能权限。

[完整安装说明](https://github.com/gitman-g1/TameWheel/blob/v0.3.0/docs/install.md)

要求 macOS 13 及以上。包内包含 Apple Silicon / Intel 两种架构；目前实机验证环境为 Apple Silicon / macOS 27，Intel 和更早系统仍待实测。适用于普通鼠标垂直离散滚轮；Magic Mouse 和部分驱动转换的连续滚动事件不在调整范围内。

校验文件：`SHA256SUMS.txt`。反馈请附上 macOS 版本和鼠标型号：[Issues](https://github.com/gitman-g1/TameWheel/issues)。

---

First public preview: familiar, consistent mouse-wheel scrolling with your trackpad's natural feel preserved. Just one menu bar switch.

Download **TameWheel-0.3.0-universal.dmg**, drag the app into **Applications**, and launch it from there. A ZIP is also available. GitHub's `Source code` archives are not installable apps.

**This build is ad-hoc signed and has not been notarized by Apple.** If macOS cannot verify the developer or check the app for malicious software, confirm the download source, then use **System Settings → Privacy & Security → Open Anyway** for TameWheel. Grant Accessibility permission when prompted.

[Installation guide](https://github.com/gitman-g1/TameWheel/blob/v0.3.0/docs/install.en.md)

Requires macOS 13 or later. Universal binary for Apple Silicon and Intel; tested on Apple Silicon / macOS 27. Intel and earlier macOS versions still need hardware testing. Handles standard discrete vertical mouse wheels; Magic Mouse and driver-generated continuous scrolling may pass through unchanged. App labels are currently in Chinese.

Checksums: `SHA256SUMS.txt`. Share your macOS version and mouse model in [Issues](https://github.com/gitman-g1/TameWheel/issues).
