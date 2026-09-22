import Foundation

/// Core 只接受值，不持有 CGEvent。nil 表示原事件必须完全原样返回。
struct ScrollInput {
    var isContinuous = false
    var scrollPhase: Int64 = 0
    var momentumPhase: Int64 = 0
    var scrollCount: Int64 = 0
    var isSynthetic = false
    var isZoomGesture = false
    var lines: Int64 = 0
    var preciseLines: Double = 0
    var pixels: Int64 = 0
    var rawDelta: Double = 0

    var kind: InputKind {
        if isContinuous || scrollPhase != 0 || momentumPhase != 0 || scrollCount != 0 {
            return .continuous
        }
        if isSynthetic || isZoomGesture { return .other }
        return .wheel
    }
}

enum InputKind: Equatable {
    case wheel, continuous, other
}

struct ScrollOutput: Equatable {
    let lines: Int64
    let preciseLines: Double
    let pixels: Int64
    let usedCompatibilityStep: Bool
}

struct ScrollTransformer {
    func transform(_ input: ScrollInput, settings: ScrollSettings) -> ScrollOutput? {
        guard settings.isEnabled, input.kind == .wheel else { return nil }
        guard input.preciseLines.isFinite, input.rawDelta.isFinite else { return nil }
        let reference = input.preciseLines != 0 ? input.preciseLines
            : (input.lines != 0 ? Double(input.lines) : Double(input.pixels))
        guard reference != 0 else { return nil }

        let direction = reference > 0 ? 1.0 : -1.0
        // 新系统提供原始增量时保留合并的多刻度；不把加速后的行数当刻度数。
        // 某些驱动不提供此字段，回退为每个离散滚轮事件固定一步。
        let raw = abs(input.rawDelta)
        let usableRaw = raw >= 1 && raw <= 64 && raw.rounded() == raw
        let steps = usableRaw ? raw : 1
        let lines = -direction * steps * Double(ScrollSettings.linesPerStep)
        return ScrollOutput(
            lines: Int64(lines), preciseLines: lines,
            pixels: Int64(lines * 10), usedCompatibilityStep: !usableRaw
        )
    }
}
