import Foundation

/// 只读写本应用的偏好，不修改 macOS 的鼠标或触控板设置。
final class SettingsStore {
    private enum Key {
        static let isEnabled = "mouse.isEnabled"
        static let reverseMouseScrolling = "mouse.reverseScrolling"
        static let scrollingMode = "mouse.scrollingMode"
        static let linesPerStep = "mouse.linesPerStep"
        static let speedMultiplier = "mouse.speedMultiplier"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let initial = ScrollSettings()
        defaults.register(defaults: [
            Key.isEnabled: initial.isEnabled,
            Key.reverseMouseScrolling: initial.reverseMouseScrolling,
            Key.scrollingMode: initial.scrollingMode.rawValue,
            Key.linesPerStep: initial.linesPerStep,
            Key.speedMultiplier: initial.speedMultiplier
        ])
    }

    func load() -> ScrollSettings {
        var settings = ScrollSettings()
        settings.isEnabled = defaults.bool(forKey: Key.isEnabled)
        settings.reverseMouseScrolling = defaults.bool(forKey: Key.reverseMouseScrolling)
        if let rawMode = defaults.string(forKey: Key.scrollingMode),
           let mode = ScrollSettings.ScrollingMode(rawValue: rawMode) {
            settings.scrollingMode = mode
        }

        let lines = defaults.integer(forKey: Key.linesPerStep)
        if ScrollSettings.allowedLinesPerStep.contains(lines) {
            settings.linesPerStep = lines
        }

        let speed = defaults.double(forKey: Key.speedMultiplier)
        if speed.isFinite && ScrollSettings.allowedSpeed.contains(speed) {
            settings.speedMultiplier = speed
        }

        return settings
    }

    func save(_ settings: ScrollSettings) {
        defaults.set(settings.isEnabled, forKey: Key.isEnabled)
        defaults.set(settings.reverseMouseScrolling, forKey: Key.reverseMouseScrolling)
        defaults.set(settings.scrollingMode.rawValue, forKey: Key.scrollingMode)
        defaults.set(settings.linesPerStep, forKey: Key.linesPerStep)
        defaults.set(settings.speedMultiplier, forKey: Key.speedMultiplier)
    }
}
