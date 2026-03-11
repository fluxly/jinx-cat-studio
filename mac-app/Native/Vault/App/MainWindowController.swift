import Cocoa

class MainWindowController: NSWindowController {

    private var webViewController: WebViewController?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Vault"
        window.minSize = NSSize(width: 1200, height: 800)
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible

        self.init(window: window)
    }

    func loadContent() {
        let webVC = WebViewController()
        self.webViewController = webVC
        self.contentViewController = webVC
    }
}
