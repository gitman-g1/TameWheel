/// 与界面和 macOS 事件 API 无关的滚轮配置。
struct ScrollSettings: Equatable {
    enum ScrollingMode: String, CaseIterable {
        case system
        case fixedStep
    }

    static let allowedLinesPerStep = 1...12

    var isEnabled = true
    var reverseMouseScrolling = true
    var scrollingMode: ScrollingMode = .fixedStep
    var linesPerStep = 3
    var speedMultiplier = 1.0

    static let allowedSpeed = 0.25...3.0
}
