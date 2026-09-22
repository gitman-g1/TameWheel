import Foundation

/// 只读写本应用的偏好，不修改 macOS 的鼠标或触控板设置。
final class SettingsStore {
    private enum Key {
        static let isEnabled = "mouse.isEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [Key.isEnabled: ScrollSettings().isEnabled])
    }

    func load() -> ScrollSettings {
        // 旧版的方向、模式与速度配置不再读取，升级后统一采用固定手感。
        ScrollSettings(isEnabled: defaults.bool(forKey: Key.isEnabled))
    }

    func save(_ settings: ScrollSettings) {
        defaults.set(settings.isEnabled, forKey: Key.isEnabled)
    }
}
