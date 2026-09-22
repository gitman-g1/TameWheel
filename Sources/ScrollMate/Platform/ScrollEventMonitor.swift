import ApplicationServices

/// 所有操作及回调都在主 run loop 的 common modes 上串行执行。
/// 回调仅做内存中的分类与变换，不保存配置、不更新界面、不重新投递事件。
final class ScrollEventMonitor {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var adapter = ScrollEventAdapter()
    private var settings = ScrollSettings()

    private(set) var wheelEvents = 0
    private(set) var protectedEvents = 0
    private(set) var lastInput: InputKind?
    private(set) var usedCompatibilityStep = false

    var isRunning: Bool {
        guard let tap else { return false }
        return CFMachPortIsValid(tap) && CGEvent.tapIsEnabled(tap: tap)
    }

    func update(settings: ScrollSettings) {
        self.settings = settings
        adapter.reset()
    }

    func start() -> Bool {
        precondition(Thread.isMainThread)
        if isRunning { return true }
        stop()
        guard AXIsProcessTrusted() else { return false }
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<ScrollEventMonitor>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if monitor.settings.isEnabled, let tap = monitor.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            } else if type == .scrollWheel {
                let input = monitor.adapter.input(from: event)
                monitor.lastInput = input.kind
                if input.kind == .continuous { monitor.protectedEvents &+= 1 }
                if let output = monitor.adapter.apply(to: event, settings: monitor.settings) {
                    monitor.wheelEvents &+= 1
                    monitor.usedCompatibilityStep = output.usedCompatibilityStep
                }
            }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
            callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return isRunning
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
        adapter.reset()
    }

    deinit { stop() }
}
