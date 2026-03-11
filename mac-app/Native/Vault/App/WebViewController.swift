import Cocoa
import WebKit

class WebViewController: NSViewController {

    private var webView: WKWebView!
    private var bridgeRouter: BridgeRouter!

    override func loadView() {
        let config = WKWebViewConfiguration()

        // Set up script message handler for the bridge
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "bridge")
        config.userContentController = userContentController

        // Allow local file access
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        #if DEBUG
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize database and bridge
        do {
            let dbManager = try SQLiteManager()
            try MigrationRunner(dbManager: dbManager).runMigrations()

            let documentRepo = DocumentRepository(db: dbManager)
            let assetRepo = AssetRepository(db: dbManager)
            let tagRepo = TagRepository(db: dbManager)
            let categoryRepo = CategoryRepository(db: dbManager)

            let documentService = DocumentService(repo: documentRepo, tagRepo: tagRepo, categoryRepo: categoryRepo)
            let assetService = AssetService(repo: assetRepo, tagRepo: tagRepo, categoryRepo: categoryRepo)
            let tagService = TagService(repo: tagRepo)
            let categoryService = CategoryService(repo: categoryRepo)
            let searchService = SearchService(db: dbManager)

            let tagsHandler = TagsHandler(service: tagService)
            tagsHandler.configure(documentRepo: documentRepo, assetRepo: assetRepo)

            bridgeRouter = BridgeRouter(
                documentsHandler: DocumentsHandler(service: documentService),
                assetsHandler: AssetsHandler(service: assetService, webView: webView),
                tagsHandler: tagsHandler,
                categoriesHandler: CategoriesHandler(service: categoryService),
                searchHandler: SearchHandler(service: searchService)
            )
        } catch {
            NSLog("[WebViewController] Failed to initialize database: \(error)")
            showDatabaseError(error)
            return
        }

        loadWebContent()
    }

    private func loadWebContent() {
        guard let resourcePath = Bundle.main.resourcePath else {
            NSLog("[WebViewController] Could not find resource path")
            return
        }
        let webDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("web")
        let indexURL = webDir.appendingPathComponent("index.html")

        webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
    }

    private func showDatabaseError(_ error: Error) {
        let html = """
        <!DOCTYPE html>
        <html>
        <body style="font-family: -apple-system; padding: 40px; color: red;">
            <h1>Database Error</h1>
            <p>\(error.localizedDescription)</p>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func sendResponse(_ response: BridgeResponse) {
        guard let jsonData = try? JSONEncoder().encode(response),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("[WebViewController] Failed to encode bridge response")
            return
        }
        // Safely pass JSON as a base64-encoded string to avoid escaping issues
        let base64 = jsonData.base64EncodedString()
        let js = "window.__bridgeCallbackB64('\(response.id)', '\(base64)')"
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    NSLog("[WebViewController] evaluateJavaScript error: \(error)")
                    // Fallback: try direct JSON embedding
                    let escaped = jsonString
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "'", with: "\\'")
                        .replacingOccurrences(of: "\n", with: "\\n")
                        .replacingOccurrences(of: "\r", with: "\\r")
                    let fallbackJs = "window.__bridgeCallback('\(response.id)', '\(escaped)')"
                    self.webView.evaluateJavaScript(fallbackJs, completionHandler: nil)
                }
            }
        }
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "bridge" else { return }

        guard let body = message.body as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let bridgeMessage = try? JSONDecoder().decode(BridgeMessage.self, from: jsonData) else {
            NSLog("[WebViewController] Failed to decode bridge message: \(message.body)")
            return
        }

        bridgeRouter.route(message: bridgeMessage) { [weak self] response in
            self?.sendResponse(response)
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("[WebViewController] Web content loaded successfully")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("[WebViewController] Navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("[WebViewController] Provisional navigation failed: \(error)")
    }
}
