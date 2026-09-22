import AppKit
import ApplicationServices
import Combine

enum MonitorStatus: Equatable {
    case running, paused, permissionRequired, unavailable, preview
}

/// 应用的组装点：界面修改设置，由这里交给存储和后续的滚动服务。
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var settings: ScrollSettings {
        didSet {
            if !isPreview { store.save(settings) }
            monitor.update(settings: settings)
            refresh()
        }
    }

    @Published private(set) var status: MonitorStatus = .permissionRequired

    private let store: SettingsStore
    private let monitor = ScrollEventMonitor()
    private var healthTimer: Timer?
    let isPreview: Bool

    /// 开关反映实际运行状态，避免缺少权限时仍显示为已启用。
    var isScrollEnabled: Bool {
        settings.isEnabled && (status == .running || status == .preview)
    }

    func setScrollEnabled(_ enabled: Bool) {
        settings.isEnabled = enabled
        if enabled && status == .permissionRequired { requestAccessibility() }
    }

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
}
