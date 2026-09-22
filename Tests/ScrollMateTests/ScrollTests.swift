import CoreGraphics
import Foundation
import Testing
@testable import ScrollMate

@Test func trackpadAndMomentumAreNeverTransformed() {
    for continuous in [false, true] {
        for phase: Int64 in [0, 1, 2, 4, 8, 128] {
            for momentum: Int64 in [0, 1, 2, 3] {
                guard continuous || phase != 0 || momentum != 0 else { continue }
                var transformer = ScrollTransformer()
                let input = ScrollInput(isContinuous: continuous, scrollPhase: phase,
                    momentumPhase: momentum, lines: -8, preciseLines: -8.5, pixels: -85)
                #expect(transformer.transform(input, settings: ScrollSettings()) == nil)
            }
        }
    }
}

@Test func syntheticZoomAndAmbiguousCountPassThrough() {
    var transformer = ScrollTransformer()
    for input in [
        ScrollInput(scrollCount: 1, lines: 3),
        ScrollInput(isSynthetic: true, lines: 3),
        ScrollInput(isZoomGesture: true, lines: 3)
    ] {
        #expect(transformer.transform(input, settings: ScrollSettings()) == nil)
    }
}

@Test func fixedStepIgnoresSystemAcceleration() {
    var transformer = ScrollTransformer()
    for accelerated: Int64 in [1, 3, 8, 24, 90] {
        let input = ScrollInput(lines: accelerated, preciseLines: Double(accelerated),
                                pixels: accelerated * 10, rawDelta: 1)
        let output = transformer.transform(input, settings: ScrollSettings())
        #expect(output?.lines == -3)
        #expect(output?.pixels == -30)
        #expect(output?.usedCompatibilityStep == false)
    }
}

@Test func coalescedRawStepsArePreserved() {
    var transformer = ScrollTransformer()
    let output = transformer.transform(
        ScrollInput(lines: -12, preciseLines: -12, pixels: -120, rawDelta: -4),
        settings: ScrollSettings())
    #expect(output?.lines == 12)
}

@Test func legacyDriverHasBoundedCompatibilityStep() {
    var transformer = ScrollTransformer()
    for raw in [0.0, 0.25, 65536] {
        let output = transformer.transform(ScrollInput(lines: 80, rawDelta: raw), settings: ScrollSettings())
        #expect(output?.lines == -3)
        #expect(output?.usedCompatibilityStep == true)
    }
}

@Test func directionCanBeKeptOrReversed() {
    for reversed in [false, true] {
        var settings = ScrollSettings()
        settings.reverseMouseScrolling = reversed
        settings.linesPerStep = 5
        var transformer = ScrollTransformer()
        let output = transformer.transform(ScrollInput(lines: -1, rawDelta: 1), settings: settings)
        #expect(output?.lines == (reversed ? 5 : -5))
    }
}

@Test func slowMultiplierAccumulatesFractionalLines() {
    var settings = ScrollSettings()
    settings.scrollingMode = .system
    settings.speedMultiplier = 0.25
    settings.reverseMouseScrolling = false
    var transformer = ScrollTransformer()
    let sample = ScrollInput(lines: 1, preciseLines: 1, pixels: 10)
    let outputs = (0..<4).compactMap { _ in transformer.transform(sample, settings: settings) }
    #expect(outputs.map(\.lines).reduce(0, +) == 1)
    #expect(outputs.map(\.pixels).reduce(0, +) == 10)
    #expect(outputs.allSatisfy { $0.preciseLines == 0.25 })
}

@Test func directionChangeClearsFractionalCarry() {
    var settings = ScrollSettings()
    settings.scrollingMode = .system
    settings.reverseMouseScrolling = false
    settings.speedMultiplier = 0.75
    var transformer = ScrollTransformer()
    _ = transformer.transform(ScrollInput(lines: 1, preciseLines: 1), settings: settings)
    _ = transformer.transform(ScrollInput(lines: -1, preciseLines: -1), settings: settings)
    let next = transformer.transform(ScrollInput(lines: -1, preciseLines: -1), settings: settings)
    #expect(next?.lines == -1)
}

@Test func disabledZeroAndUnchangedSettingsPassThrough() {
    var transformer = ScrollTransformer()
    var settings = ScrollSettings()
    #expect(transformer.transform(ScrollInput(), settings: settings) == nil)
    settings.isEnabled = false
    #expect(transformer.transform(ScrollInput(lines: 1), settings: settings) == nil)
    settings.isEnabled = true
    settings.scrollingMode = .system
    settings.reverseMouseScrolling = false
    #expect(transformer.transform(ScrollInput(lines: 1), settings: settings) == nil)
}

@Test func malformedInputCannotOverflow() {
    var transformer = ScrollTransformer()
    #expect(transformer.transform(ScrollInput(preciseLines: .nan), settings: ScrollSettings()) == nil)
    #expect(transformer.transform(ScrollInput(lines: 1, rawDelta: .infinity), settings: ScrollSettings()) == nil)
    var settings = ScrollSettings()
    settings.scrollingMode = .system
    settings.speedMultiplier = 3
    let output = transformer.transform(ScrollInput(lines: .min, preciseLines: -1e100, pixels: .min), settings: settings)
    #expect(output?.lines == 32767)
    #expect(output?.preciseLines == 32767)
}

private func wheelEvent() throws -> CGEvent {
    let event = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .line,
        wheelCount: 2, wheel1: 3, wheel2: -2, wheel3: 0))
    event.setIntegerValueField(.eventSourceUnixProcessID, value: 0)
    event.setDoubleValueField(.scrollWheelEventRawDeltaAxis1, value: 1)
    event.location = CGPoint(x: 160, y: 240)
    event.timestamp = 123456789
    event.flags = [.maskShift, .maskAlternate]
    return event
}

@Test func trackpadCGEventRemainsByteForByteIdentical() throws {
    for field: CGEventField in [.scrollWheelEventIsContinuous, .scrollWheelEventScrollPhase,
                                .scrollWheelEventMomentumPhase, .scrollWheelEventScrollCount,
                                .scrollWheelEventMomentumOptionPhase] {
        let event = try wheelEvent()
        event.setIntegerValueField(field, value: 1)
        let before = try #require(event.data) as Data
        var adapter = ScrollEventAdapter()
        #expect(adapter.apply(to: event, settings: ScrollSettings()) == nil)
        let after = try #require(event.data) as Data
        #expect(before == after)
    }
}

@Test func mouseCGEventPreservesOtherAxisAndMetadata() throws {
    let event = try wheelEvent()
    let untouched: [CGEventField] = [.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2,
        .scrollWheelEventPointDeltaAxis2, .scrollWheelEventRawDeltaAxis2, .scrollWheelEventDeltaAxis3,
        .scrollWheelEventIsContinuous, .scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase]
    let before = untouched.map { event.getIntegerValueField($0) }
    var adapter = ScrollEventAdapter()
    #expect(adapter.apply(to: event, settings: ScrollSettings()) != nil)
    #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -3)
    #expect(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1) == -3)
    #expect(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == -30)
    #expect(untouched.map { event.getIntegerValueField($0) } == before)
    #expect(event.location == CGPoint(x: 160, y: 240))
    #expect(event.timestamp == 123456789)
    #expect(event.flags == [.maskShift, .maskAlternate])
}

@Test func pausedCGEventIsIdentical() throws {
    let event = try wheelEvent()
    let before = try #require(event.data) as Data
    var settings = ScrollSettings()
    settings.isEnabled = false
    var adapter = ScrollEventAdapter()
    #expect(adapter.apply(to: event, settings: settings) == nil)
    #expect(try #require(event.data) as Data == before)
}

@Test func preferencesRoundTripAndInvalidValuesRecover() throws {
    let suite = "local.scrollmate.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = SettingsStore(defaults: defaults)
    var settings = ScrollSettings()
    settings.isEnabled = false
    settings.reverseMouseScrolling = false
    settings.linesPerStep = 7
    settings.scrollingMode = .system
    settings.speedMultiplier = 1.75
    store.save(settings)
    #expect(store.load() == settings)
    defaults.set(-99, forKey: "mouse.linesPerStep")
    defaults.set(1e50, forKey: "mouse.speedMultiplier")
    defaults.set("invalid", forKey: "mouse.scrollingMode")
    #expect(store.load().linesPerStep == 3)
    #expect(store.load().speedMultiplier == 1)
    #expect(store.load().scrollingMode == .fixedStep)
}
