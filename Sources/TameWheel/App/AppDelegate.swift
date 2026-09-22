import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState?
    private var menuBar: MenuBarController?
    private var wakeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: "退出小滚轮", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        mainMenu.addItem(applicationItem)
        NSApp.mainMenu = mainMenu
        let arguments = ProcessInfo.processInfo.arguments
        let preview = arguments.contains("--preview-light") || arguments.contains("--preview-dark")
        if preview {
            NSApp.appearance = NSAppearance(named: arguments.contains("--preview-dark") ? .darkAqua : .aqua)
        }
        let state = AppState(isPreview: preview)
        self.state = state
        menuBar = MenuBarController(state: state)
        state.start()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak state] _ in
            Task { @MainActor in state?.restart() }
        }
        if preview || arguments.contains("--show-panel") || state.status == .permissionRequired {
            DispatchQueue.main.async { [weak self] in self?.menuBar?.show() }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) { state?.refresh() }

    func applicationDidResignActive(_ notification: Notification) {
        if state?.isPreview == false { menuBar?.hide() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBar?.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        state?.stop()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
