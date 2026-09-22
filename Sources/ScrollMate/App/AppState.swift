import AppKit
import ApplicationServices
import Combine

enum MonitorStatus: Equatable {
    case running, paused, permissionRequired, unavailable, preview

    var title: String {
        switch self {
        case .running: return "正在为鼠标调校"
        case .paused: return "已暂停"
        case .permissionRequired: return "需要辅助功能权限"
        case .unavailable: return "滚动服务未就绪"
        case .preview: return "外观预览"
        }
    }
}

/// 应用的组装点：界面修改设置，由这里交给存储和后续的滚动服务。
@MainActor
final class AppState: ObservableObject {
    @Published var settings: ScrollSettings {
        didSet {
            if !isPreview { store.save(settings) }
            monitor.update(settings: settings)
            refresh()
        }
    }

    @Published private(set) var status: MonitorStatus = .permissionRequired
    @Published private(set) var activity = "滚动鼠标或触控板，查看识别结果"
    @Published private(set) var usesCompatibilityStep = false

    private let store: SettingsStore
    private let monitor = ScrollEventMonitor()
    private var healthTimer: Timer?
    let isPreview: Bool

    init(store: SettingsStore = SettingsStore(), isPreview: Bool = false) {
        self.store = store
        self.isPreview = isPreview
        self.settings = isPreview ? ScrollSettings() : store.load()
        monitor.update(settings: settings)
        if isPreview { status = .preview }
    }

    func start() {
        guard !isPreview, healthTimer == nil else { return }
        refresh()
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        timer.tolerance = 0.5
        RunLoop.main.add(timer, forMode: .common)
        healthTimer = timer
    }

    func refresh() {
        guard !isPreview else { return }
        let nextStatus: MonitorStatus
        if !settings.isEnabled {
            monitor.stop()
            nextStatus = .paused
        } else if !AXIsProcessTrusted() {
            monitor.stop()
            nextStatus = .permissionRequired
        } else {
            nextStatus = monitor.start() ? .running : .unavailable
        }
        if status != nextStatus { status = nextStatus }
        let nextActivity: String
        switch monitor.lastInput {
        case .wheel: nextActivity = "鼠标滚轮 · 已处理 \(monitor.wheelEvents) 次"
        case .continuous: nextActivity = "触控板 / 连续输入 · 原样通过"
        case .other: nextActivity = "缩放或软件输入 · 原样通过"
        case nil: nextActivity = activity
        }
        if activity != nextActivity { activity = nextActivity }
        if usesCompatibilityStep != monitor.usedCompatibilityStep {
            usesCompatibilityStep = monitor.usedCompatibilityStep
        }
    }

    func restart() {
        monitor.stop()
        refresh()
    }

    func stop() {
        healthTimer?.invalidate()
        healthTimer = nil
        monitor.stop()
    }

    func requestAccessibility() {
        guard !isPreview else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        refresh()
    }

    func restoreDefaults() {
        settings = ScrollSettings()
    }
}
