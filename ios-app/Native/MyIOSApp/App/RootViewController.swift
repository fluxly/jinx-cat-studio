import UIKit

/// RootViewController hosts the WebViewController as a full-screen child.
/// It is the root of the view controller hierarchy and acts as the
/// presentation context for all modal native UIs (mail compose, camera picker).
class RootViewController: UIViewController {

    private let webViewController = WebViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        embedWebViewController()
        AppLogger.log(.info, "RootViewController viewDidLoad — WebViewController embedded")
    }

    // MARK: - Private

    private func embedWebViewController() {
        addChild(webViewController)
        webViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webViewController.view)

        NSLayoutConstraint.activate([
            webViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            webViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        webViewController.didMove(toParent: self)
    }
}
