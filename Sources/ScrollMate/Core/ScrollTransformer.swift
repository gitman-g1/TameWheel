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
    // 低速倍率的不足一行/像素部分累积到下次，避免吞掉小滚动。
    private var lineRemainder = 0.0
    private var pixelRemainder = 0.0
    private var previousDirection = 0.0

    mutating func reset() {
        lineRemainder = 0
        pixelRemainder = 0
        previousDirection = 0
    }

    mutating func transform(_ input: ScrollInput, settings: ScrollSettings) -> ScrollOutput? {
        guard settings.isEnabled, input.kind == .wheel else {
            reset()
            return nil
        }
        guard input.preciseLines.isFinite, input.rawDelta.isFinite else { return nil }
        let reference = input.preciseLines != 0 ? input.preciseLines
            : (input.lines != 0 ? Double(input.lines) : Double(input.pixels))
        guard reference != 0 else { return nil }

        let direction = reference > 0 ? 1.0 : -1.0
        if previousDirection != direction { reset() }
        previousDirection = direction
        let reversal = settings.reverseMouseScrolling ? -1.0 : 1.0

        if settings.scrollingMode == .fixedStep {
            // 新系统提供原始增量时保留合并的多刻度；不把加速后的行数当刻度数。
            // 某些驱动不提供此字段，回退为每个离散滚轮事件固定一步。
            let raw = abs(input.rawDelta)
            let usableRaw = raw >= 1 && raw <= 64 && raw.rounded() == raw
            let steps = usableRaw ? raw : 1
            let stepSize = min(12, max(1, settings.linesPerStep))
            let lines = direction * reversal * steps * Double(stepSize)
            return ScrollOutput(
                lines: boundedInteger(lines), preciseLines: lines,
                pixels: boundedInteger(lines * 10), usedCompatibilityStep: !usableRaw
            )
        }

        let speed = settings.speedMultiplier.isFinite
            ? min(3, max(0.25, settings.speedMultiplier)) : 1
        // 默认设置下完全放行，保持所有字段和系统的分数累积行为。
        if speed == 1 && !settings.reverseMouseScrolling { return nil }
        let factor = speed * reversal
        let scaledLines = Double(input.lines) * factor + lineRemainder
        let scaledPixels = Double(input.pixels) * factor + pixelRemainder
        let lines = boundedInteger(scaledLines)
        let pixels = boundedInteger(scaledPixels)
        lineRemainder = scaledLines - Double(lines)
        pixelRemainder = scaledPixels - Double(pixels)
        // 上限保护后不把溢出的输入积攒到之后的事件。
        if abs(lineRemainder) >= 1 { lineRemainder = 0 }
        if abs(pixelRemainder) >= 1 { pixelRemainder = 0 }
        return ScrollOutput(
            lines: lines, preciseLines: min(32767, max(-32767, input.preciseLines * factor)),
            pixels: pixels, usedCompatibilityStep: false
        )
    }

    private func boundedInteger(_ value: Double) -> Int64 {
        Int64(min(32767, max(-32767, value)).rounded(.towardZero))
    }
}
