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
        guard let webDir = Bundle.main.url(
            forResource: "Web",
            withExtension: nil,
            subdirectory: "Resources"
        ),
        let indexURL = Bundle.main.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "Resources/Web"
        ) else {
            AppLogger.log(.error, "Could not locate Resources/Web/index.html in bundle — showing error page")
            loadErrorPage()
            return
        }

        webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
        AppLogger.log(.info, "Loading index.html from bundle: \(indexURL.path)")
    }

    private func loadErrorPage() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: -apple-system, sans-serif; display: flex; align-items: center;
                       justify-content: center; min-height: 100vh; margin: 0; background: #f2f2f7; }
                .card { background: white; border-radius: 12px; padding: 32px; max-width: 320px;
                        text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
                h2 { color: #1c1c1e; margin: 0 0 12px; }
                p { color: #636366; margin: 0; font-size: 14px; line-height: 1.5; }
            </style>
        </head>
        <body>
            <div class="card">
                <h2>Web Assets Missing</h2>
                <p>Run <code>npm run build</code> in the Web/ directory and copy the output
                   to Resources/Web/ before building the app.</p>
            </div>
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
