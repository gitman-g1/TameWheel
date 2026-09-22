import AppKit
import Combine
import SwiftUI

/// AppKit 管理菜单栏与透明浮层，内容仍为 SwiftUI。
/// 原生 NSGlassEffectView 让 Liquid Glass 采样真实桌面背景。
@MainActor
final class MenuBarController: NSObject, NSWindowDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel: SettingsPanel
    private let state: AppState
    private let hosting: NSHostingView<MenuBarView>
    private var resizeSubscription: AnyCancellable?
    private var outsideClick: Any?
    private var localClick: Any?

    init(state: AppState) {
        self.state = state
        hosting = NSHostingView(rootView: MenuBarView(state: state))
        let size = NSSize(width: 220, height: 44)
        panel = SettingsPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        super.init()
        panel.title = "小滚轮"
        panel.setAccessibilityLabel("小滚轮 · TameWheel")
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self

        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: hosting.frame)
            glass.style = .regular
            // 减少底色叠加；深色仍保留足够底色，保证亮背景上的文字对比度。
            glass.tintColor = NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return .windowBackgroundColor.withAlphaComponent(isDark ? 0.55 : 0.15)
            }
            glass.cornerRadius = 14
            glass.contentView = hosting
            panel.contentView = glass
        } else {
            let material = NSVisualEffectView(frame: hosting.frame)
            material.material = .popover
            material.blendingMode = .behindWindow
            material.state = .active
            material.wantsLayer = true
            material.layer?.cornerRadius = 14
            material.layer?.masksToBounds = true
            material.addSubview(hosting)
            panel.contentView = material
        }
        panel.onDismiss = { [weak self] in self?.hide() }
        resizeSubscription = state.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.panel.isVisible else { return }
                self.positionPanel()
            }
        }
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "小滚轮 · TameWheel")
            button.image?.isTemplate = true
            button.toolTip = "小滚轮 · TameWheel"
            button.target = self
            button.action = #selector(toggle)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func toggle() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            hide()
            let menu = NSMenu()
            menu.addItem(withTitle: "退出小滚轮", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            if let button = statusItem.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY - 6), in: button)
            }
        } else {
            panel.isVisible ? hide() : show()
        }
    }

    func show() {
        state.refresh()
        positionPanel()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        statusItem.button?.highlight(true)
        if outsideClick == nil && !state.isPreview {
            outsideClick = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
                [weak self] _ in self?.hide()
            }
            localClick = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
                [weak self] event in
                if let self, event.window !== self.panel,
                   event.window !== self.statusItem.button?.window { self.hide() }
                return event
            }
        }
    }

    private func positionPanel() {
        hosting.layoutSubtreeIfNeeded()
        panel.setContentSize(hosting.fittingSize)
        if state.isPreview {
            panel.center()
            return
        }
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame ?? anchor
        // 登录/启动时菜单栏图标可能尚未完成布局，位置为零或在可见屏幕外。
        let validAnchor = anchor.width > 0 && anchor.height > 0
            && visible.insetBy(dx: -40, dy: -40).intersects(anchor)
        let anchorX = validAnchor ? anchor.midX : visible.maxX - panel.frame.width / 2 - 10
        let anchorY = validAnchor ? anchor.minY : visible.maxY
        let x = min(max(anchorX - panel.frame.width / 2, visible.minX + 10),
                    visible.maxX - panel.frame.width - 10)
        let y = max(visible.minY + 8, min(anchorY - panel.frame.height - 8,
                                        visible.maxY - panel.frame.height - 8))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func hide() {
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        if let outsideClick { NSEvent.removeMonitor(outsideClick) }
        if let localClick { NSEvent.removeMonitor(localClick) }
        outsideClick = nil
        localClick = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        if !NSApp.isActive && !state.isPreview { hide() }
    }
}

private final class SettingsPanel: NSPanel {
    var onDismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onDismiss?() }
}
