import CoreGraphics
import Foundation
import Testing
@testable import TameWheel

@Test func trackpadAndMomentumAreNeverTransformed() {
    for continuous in [false, true] {
        for phase: Int64 in [0, 1, 2, 4, 8, 128] {
            for momentum: Int64 in [0, 1, 2, 3] {
                guard continuous || phase != 0 || momentum != 0 else { continue }
                let transformer = ScrollTransformer()
                let input = ScrollInput(isContinuous: continuous, scrollPhase: phase,
                    momentumPhase: momentum, lines: -8, preciseLines: -8.5, pixels: -85)
                #expect(transformer.transform(input, settings: ScrollSettings()) == nil)
            }
        }
    }
}

@Test func syntheticZoomAndAmbiguousCountPassThrough() {
    let transformer = ScrollTransformer()
    for input in [
        ScrollInput(scrollCount: 1, lines: 3),
        ScrollInput(isSynthetic: true, lines: 3),
        ScrollInput(isZoomGesture: true, lines: 3)
    ] {
        #expect(transformer.transform(input, settings: ScrollSettings()) == nil)
    }
}

@Test func fixedStepIgnoresSystemAcceleration() {
    let transformer = ScrollTransformer()
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
    let transformer = ScrollTransformer()
    let output = transformer.transform(
        ScrollInput(lines: -12, preciseLines: -12, pixels: -120, rawDelta: -4),
        settings: ScrollSettings())
    #expect(output?.lines == 12)
}

@Test func legacyDriverHasBoundedCompatibilityStep() {
    let transformer = ScrollTransformer()
    for raw in [0.0, 0.25, 65536] {
        let output = transformer.transform(ScrollInput(lines: 80, rawDelta: raw), settings: ScrollSettings())
        #expect(output?.lines == -3)
        #expect(output?.usedCompatibilityStep == true)
    }
}

@Test func directionIsReversedInBothDirections() {
    let transformer = ScrollTransformer()
    for direction: Int64 in [-1, 1] {
        let output = transformer.transform(
            ScrollInput(lines: direction, rawDelta: Double(direction)), settings: ScrollSettings())
        #expect(output?.lines == -direction * 3)
        #expect(output?.pixels == -direction * 30)
    }
}

@Test func disabledAndZeroInputPassThrough() {
    let transformer = ScrollTransformer()
    #expect(transformer.transform(ScrollInput(), settings: ScrollSettings()) == nil)
    #expect(transformer.transform(ScrollInput(lines: 1), settings: ScrollSettings(isEnabled: false)) == nil)
}

@Test func malformedAndExtremeInputCannotOverflow() {
    let transformer = ScrollTransformer()
    #expect(transformer.transform(ScrollInput(preciseLines: .nan), settings: ScrollSettings()) == nil)
    #expect(transformer.transform(ScrollInput(lines: 1, rawDelta: .infinity), settings: ScrollSettings()) == nil)
    let output = transformer.transform(
        ScrollInput(lines: .min, preciseLines: -1e100, pixels: .min, rawDelta: -64),
        settings: ScrollSettings())
    #expect(output?.lines == 192)
    #expect(output?.preciseLines == 192)
    #expect(output?.pixels == 1920)
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
        let adapter = ScrollEventAdapter()
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
    let adapter = ScrollEventAdapter()
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
    let adapter = ScrollEventAdapter()
    #expect(adapter.apply(to: event, settings: settings) == nil)
    #expect(try #require(event.data) as Data == before)
}

@Test func enabledPreferenceSurvivesReload() throws {
    let suite = "local.tamewheel.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = SettingsStore(defaults: defaults)
    #expect(store.load().isEnabled)
    for enabled in [false, true] {
        store.save(ScrollSettings(isEnabled: enabled))
        #expect(SettingsStore(defaults: defaults).load().isEnabled == enabled)
    }
}

@Test func legacyTuningDoesNotChangeTheFixedFeel() throws {
    let suite = "local.tamewheel.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(false, forKey: "mouse.reverseScrolling")
    defaults.set("system", forKey: "mouse.scrollingMode")
    defaults.set(12, forKey: "mouse.linesPerStep")
    defaults.set(2.5, forKey: "mouse.speedMultiplier")
    let store = SettingsStore(defaults: defaults)
    let transformer = ScrollTransformer()
    let output = transformer.transform(ScrollInput(lines: 20, rawDelta: 1), settings: store.load())
    #expect(output?.lines == -3)
    #expect(output?.pixels == -30)
    defaults.set(false, forKey: "mouse.isEnabled")
    #expect(transformer.transform(ScrollInput(lines: 20), settings: store.load()) == nil)
}
