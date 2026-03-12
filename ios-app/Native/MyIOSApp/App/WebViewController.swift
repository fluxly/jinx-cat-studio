import UIKit
import WebKit

/// WebViewController is the core of the app. It:
/// - Hosts a full-screen WKWebView
/// - Registers the "bridge" script message handler
/// - Loads index.html from the app bundle (Resources/Web/)
/// - Dispatches incoming bridge messages to BridgeRouter
/// - Sends responses back to JS via evaluateJavaScript
class WebViewController: UIViewController {

    // MARK: - Properties

    private var webView: WKWebView!
    private let router = BridgeRouter()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupRouter()
        loadWebContent()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "bridge")
        AppLogger.log(.debug, "WebViewController deinitialized, bridge handler removed")
    }

    // MARK: - Bridge Response

    /// Sends a JSON response string back to the JS bridge client.
    func sendBridgeResponse(_ json: String) {
        let escaped = json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")

        let script = "window.nativeBridge && window.nativeBridge.receiveResponse('\(escaped)');"

        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    AppLogger.log(.error, "evaluateJavaScript error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Private Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // Use a weak proxy to avoid retain cycle between WKUserContentController and self
        contentController.add(WeakScriptMessageHandler(self), name: "bridge")
        config.userContentController = contentController

        // Allow inline media playback if needed in future
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        AppLogger.log(.debug, "WKWebView configured and added to view hierarchy")
    }

    private func setupRouter() {
        router.viewController = self

        router.register(namespace: "meta", handler: MetaHandler())
        router.register(namespace: "mail", handler: MailHandler())
        router.register(namespace: "camera", handler: CameraHandler())
        router.register(namespace: "device", handler: DeviceHandler())
        router.register(namespace: "permissions", handler: PermissionsHandler())

        AppLogger.log(.info, "BridgeRouter configured with all handlers")
    }

    private func loadWebContent() {
        // Xcode flattens folder-reference contents to the bundle root, so index.html
        // and all assets land directly in resourceURL (not in a Web/ subdirectory).
        guard let resourceURL = Bundle.main.resourceURL else {
            AppLogger.log(.error, "Bundle resourceURL is nil — showing error page")
            loadErrorPage()
            return
        }

        let indexURL = resourceURL.appendingPathComponent("index.html")

        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            AppLogger.log(.error, "index.html not found at \(indexURL.path) — showing error page")
            loadErrorPage()
            return
        }

        // Grant read access to the full bundle root so all assets resolve correctly.
        webView.loadFileURL(indexURL, allowingReadAccessTo: resourceURL)
        AppLogger.log(.info, "Loading index.html from bundle: \(indexURL.path)")
    }

    private func loadErrorPage() {
        let resourceURL = Bundle.main.resourceURL
        let resourcePath = resourceURL?.path ?? "nil"
        let webPath = resourceURL?.appendingPathComponent("Web").path ?? "nil"

        // List top-level bundle contents for diagnosis
        let bundleContents: String
        if let rURL = resourceURL,
           let items = try? FileManager.default.contentsOfDirectory(atPath: rURL.path) {
            bundleContents = items.sorted().joined(separator: "<br>")
        } else {
            bundleContents = "(could not list)"
        }

        // List Web/ contents if the directory exists
        let webContents: String
        if let rURL = resourceURL {
            let webDir = rURL.appendingPathComponent("Web")
            if let items = try? FileManager.default.contentsOfDirectory(atPath: webDir.path) {
                webContents = items.sorted().joined(separator: "<br>")
            } else {
                webContents = "(directory not found)"
            }
        } else {
            webContents = "(no resourceURL)"
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: -apple-system, sans-serif; margin: 0; padding: 16px;
                       background: #f2f2f7; font-size: 13px; }
                h2 { color: #c0392b; margin: 0 0 12px; }
                h3 { margin: 16px 0 4px; color: #1c1c1e; font-size: 13px; }
                .path { background: #fff; border-radius: 6px; padding: 8px;
                        word-break: break-all; color: #333; margin-bottom: 4px; }
            </style>
        </head>
        <body>
            <h2>Web Assets Missing</h2>
            <h3>resourceURL</h3>
            <div class="path">\(resourcePath)</div>
            <h3>Looking for Web/ at</h3>
            <div class="path">\(webPath)</div>
            <h3>Bundle root contents</h3>
            <div class="path">\(bundleContents)</div>
            <h3>Web/ contents</h3>
            <div class="path">\(webContents)</div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "bridge" else { return }

        guard let rawJSON = message.body as? String else {
            AppLogger.log(.warning, "Bridge message body is not a String: \(type(of: message.body))")
            return
        }

        AppLogger.log(.debug, "Bridge message received: \(rawJSON.prefix(200))")

        router.route(rawJSON: rawJSON) { [weak self] responseJSON in
            AppLogger.log(.debug, "Bridge response: \(responseJSON.prefix(200))")
            self?.sendBridgeResponse(responseJSON)
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        AppLogger.log(.info, "WebView finished loading")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AppLogger.log(.error, "WebView navigation failed: \(error.localizedDescription)")
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        AppLogger.log(.error, "WebView provisional navigation failed: \(error.localizedDescription)")
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Allow file:// URLs (local bundle) and about:blank; block external navigation
        if let scheme = navigationAction.request.url?.scheme {
            if scheme == "file" || scheme == "about" {
                decisionHandler(.allow)
                return
            }
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - WeakScriptMessageHandler

/// Breaks the retain cycle between WKUserContentController and WebViewController.
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
