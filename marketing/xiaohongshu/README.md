# 小红书宣传

三张竖版图片，均为 **1080 × 1440 px（3:4）**。浅灰底、系统字体、蓝色点缀，延续小滚轮的简洁风格。

三页均不设页眉、页码；封面不设页脚。第二页用大字号突出英文名 TameWheel 和中文名小滚轮。

第二、三页的内容整体上移，平衡移除页眉后的上下留白。

| 页码 | 文件 | 内容 |
| --- | --- | --- |
| 1 | [01-cover.png](exports/01-cover.png) | 封面：一行标题、一句解释，配鼠标与触控板插画 |
| 2 | [02-github.png](exports/02-github.png) | 中英文产品名与 GitHub 实际页面截图，展示代码目录与中文 README |
| 3 | [03-link.png](exports/03-link.png) | 完整仓库地址、项目名与可识别二维码 |

[三页预览](preview.png) · [笔记文案](copy.md)

## 画面文案

1. **Mac 鼠标，更顺手** / 只调鼠标滚轮，触控板保持原样。
2. **TameWheel · 小滚轮** / 代码和功能介绍都在这里。
3. **在这里，找到小滚轮。** / 喜欢的话，欢迎点个 Star。

仓库地址：<https://github.com/gitman-g1/TameWheel>

## 素材与修改

- `assets/github-page.png`：实际 GitHub 页面截图，拍摄于 2026-09-22。海报仅裁取项目主栏，没有修改页面内容或互动数据。
- 封面硬件和开关为矢量示意插画，不是应用截图。
- `render.swift`：排版源文件；使用 macOS AppKit 绘图、Core Image 生成二维码，并用 Vision 检查二维码目标。
- 在项目根目录运行 `xcrun swift -module-cache-path .build/promo-module-cache marketing/xiaohongshu/render.swift` 可重新导出。

## 下载与发布

公开测试版通过 [GitHub Release](https://github.com/gitman-g1/TameWheel/releases/tag/v0.3.0) 提供 DMG 和 ZIP，安装流程见 [安装说明](../../docs/install.md)。当前安装包尚未经过 Apple 公证，首次打开需要在系统设置中确认。

仓库尚未添加开源许可证，宣传继续使用「源码已公开」。第二页保存的是初始项目页面截图；最新下载入口以仓库首页为准。

这些文件是本地宣传草稿，尚未发布到小红书。
