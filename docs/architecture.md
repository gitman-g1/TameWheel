# TameWheel · 小滚轮 — 架构说明

## 结构

单一可执行 target + 一个测试 target，通过目录划分职责。无数据库、网络服务、外部依赖或全局鼠标偏好写入。

| 层 | 职责 |
| --- | --- |
| App | AppKit 生命周期、AppState 状态、授权流程和服务健康检查 |
| Features | SwiftUI 单开关面板，使用 Binding，不直接接触 CGEvent |
| Core | ScrollSettings、ScrollInput、ScrollTransformer，纯值输入输出 |
| Platform | CGEvent 监听/适配、UserDefaults、NSStatusItem 和玻璃面板 |

产品英文名为 TameWheel，中文名为小滚轮。Bundle Identifier 沿用 `local.scrollmate.app`，作为稳定的内部身份保留已有用户偏好，与产品展示名称独立。

入口直接使用 NSApplication，避免仅含 Settings 的 SwiftUI App 启动时出现空白窗口。面板内容仍使用 SwiftUI。

设置流：`View → AppState → SettingsStore / ScrollEventMonitor`。唯一可变配置是 `isEnabled`，旧版方向、模式和速度键不再读取；固定反向、每步 3 行。

输入流：`CGEventTap → ScrollEventAdapter → ScrollTransformer → 原样返回或原位回写`。

## 触控板保护

满足以下任一条件，直接返回原始 CGEvent 对象，不重建事件：

- 连续像素输入。
- 非零滚动相位、惯性相位、可选惯性相位或滚动计数。
- 来自软件进程的合成输入。
- 带 Control 的滚动（保留系统缩放）。
- 功能暂停或没有垂直增量。

这是一套保守的事件特征识别，不是逐设备 HID 身份识别。原生触控板具备上述连续/手势特征；第三方驱动若完全重写这些特征，可能超出当前识别边界。不要宣称所有鼠标、触控板或远程桌面均已适配。

## 速度与方向

- 反向只作用于鼠标的垂直滚动。
- 匀速使用原始整数增量（1–64 范围）乘固定 3 行步长，保留合并刻度；无可信整数增量时回退为每个离散事件一步。
- 原始增量字段的设备覆盖和单位仍需更多实机验证；目前不把加速后的 delta 当作物理刻度数。
- 仅保留固定步长规则，变换无跨事件可变状态。
- line / fixed-point / pixel 和 accelerated vertical 字段一致回写；固定步长用 10 point/行映射，应用的最终显示距离可能不同。
- 保留事件对象、坐标、时间戳、修饰键、水平数据；不重新 post 事件，避免递归。

## 生命周期

事件 tap 注册在 session 层、主 run loop 的 common modes。处理仅涉及配置快照和数值运算，不在回调内读写磁盘或刷新 UI。

AppState 每 2 秒检查授权和服务健康，状态未改变不重复发布 UI 更新。未授权时不创建 tap，用户主动打开开关才请求授权。开关根据实际服务状态显示；缺少授权和连接失败时保持关闭并显示简短提示。授权后自动连接，撤销后停止；超时禁用可重新启用，睡眠唤醒重建连接。暂停和退出会移除 run loop source 并 invalidate tap。

## Liquid Glass

- 原生透明 NSPanel + NSGlassEffectView（macOS 26+），直接采样窗口后的背景。
- 内容由 NSHostingView 承载，只有鼠标符号、13 pt 系统标题与原生开关；无速度控件、状态计数或常驻说明。
- 更早系统回退为 NSVisualEffectView；颜色、字体和控件随系统外观变化。
- 玻璃使用语义化窗口底色轻度着色，保证深色面板在亮背景上仍有清晰的文字对比度。
- 面板常态为 220 × 44 pt，保留 13 pt 系统字号；异常提示出现时高度自适应。点击外部或按 Escape 关闭，右键菜单栏图标可退出。
- 独立预览参数可强制当前进程的浅色/深色，不改变系统外观、不接入事件监听。

## 验证边界

自动化测试使用合成 CGEvent 对象，仅在内存中调用同一适配器，不向系统注入。测试能证明已列特征的事件透传及算法行为，不能替代具体设备的物理刻度和跨应用实测。

本机测试环境为 Apple Silicon / macOS 27 / Swift 6.4。当前用户已确认 HUAWEI 鼠标工作正常、内置触控板未受影响。睡眠唤醒、权限撤销和更多设备组合仍需持续实测；macOS 13–15 的材质回退仅通过编译检查。

## 依据

- [Apple NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [Apple CGEventTap](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsOfInterest:callback:userInfo:))
- [Apple 连续滚动字段](https://developer.apple.com/documentation/coregraphics/cgeventfield/scrollwheeleventiscontinuous)
- [Apple 原始滚动增量](https://developer.apple.com/documentation/coregraphics/cgeventfield/scrollwheeleventrawdeltaaxis1)

实现为本项目编写；未复制第三方项目源码。
