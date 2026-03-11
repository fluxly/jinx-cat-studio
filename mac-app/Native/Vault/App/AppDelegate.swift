import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[AppDelegate] applicationDidFinishLaunching")
        let wc = MainWindowController()
        mainWindowController = wc
        NSLog("[AppDelegate] window: \(String(describing: wc.window))")
        wc.window?.makeKeyAndOrderFront(nil)
        NSLog("[AppDelegate] isVisible: \(wc.window?.isVisible ?? false), windows: \(NSApp.windows.count)")
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        wc.loadContent()
        NSLog("[AppDelegate] loadContent done")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources before termination
    }
}
