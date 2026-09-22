import CoreGraphics

/// 只回写被明确选中的垂直滚轮字段；保留事件对象、位置、修饰键及横向数据。
struct ScrollEventAdapter {
    private var transformer = ScrollTransformer()

    mutating func reset() { transformer.reset() }

    func input(from event: CGEvent) -> ScrollInput {
        ScrollInput(
            isContinuous: event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0,
            scrollPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
            momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase)
                | event.getIntegerValueField(.scrollWheelEventMomentumOptionPhase),
            scrollCount: event.getIntegerValueField(.scrollWheelEventScrollCount),
            isSynthetic: event.getIntegerValueField(.eventSourceUnixProcessID) != 0,
            isZoomGesture: event.flags.contains(.maskControl),
            lines: event.getIntegerValueField(.scrollWheelEventDeltaAxis1),
            preciseLines: event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
            pixels: event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
            rawDelta: event.getDoubleValueField(.scrollWheelEventRawDeltaAxis1)
        )
    }

    @discardableResult
    mutating func apply(to event: CGEvent, settings: ScrollSettings) -> ScrollOutput? {
        guard let output = transformer.transform(input(from: event), settings: settings) else {
            return nil
        }
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: output.lines)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: output.preciseLines)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: output.pixels)
        event.setDoubleValueField(.scrollWheelEventAcceleratedDeltaAxis1, value: Double(output.pixels))
        return output
    }
}
