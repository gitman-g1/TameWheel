/// 只让用户决定是否启用；手感固定为已验证的反向、每步 3 行。
struct ScrollSettings: Equatable {
    static let linesPerStep = 3
    var isEnabled = true
}
