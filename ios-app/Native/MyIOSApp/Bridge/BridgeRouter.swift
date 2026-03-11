import UIKit

// MARK: - BridgeHandler Protocol

/// Any object that handles bridge messages for a specific namespace.
protocol BridgeHandler {
    /// Handle the incoming message and call completion with the response JSON string.
    /// The completion is always called exactly once.
    /// - Parameters:
    ///   - message: The parsed bridge message.
    ///   - completion: Called with the serialized JSON response string.
    func handle(message: BridgeMessage, completion: @escaping (String) -> Void)
}

// MARK: - BridgeRouter

/// Routes incoming bridge messages to the appropriate handler by namespace.
///
/// Usage:
/// ```swift
/// let router = BridgeRouter()
/// router.viewController = self
/// router.register(namespace: "mail", handler: MailHandler())
/// router.route(rawJSON: jsonString) { responseJSON in
///     // send response back to JS
/// }
/// ```
class BridgeRouter {

    /// All registered handlers keyed by namespace string.
    private var handlers: [String: BridgeHandler] = [:]

    /// The view controller used as presentation context for modal native UIs.
    /// Handlers that need to present view controllers (e.g., mail compose, camera) access this.
    weak var viewController: UIViewController?

    // MARK: - Registration

    /// Register a handler for the given namespace.
    /// Replaces any previously registered handler for that namespace.
    func register(namespace: String, handler: BridgeHandler) {
        handlers[namespace] = handler
        AppLogger.log(.debug, "BridgeRouter: registered handler for namespace '\(namespace)'")
    }

    // MARK: - Routing

    /// Parse and route a raw JSON message string.
    /// Always calls completion exactly once with the response JSON string.
    func route(rawJSON: String, completion: @escaping (String) -> Void) {
        // Parse the incoming message
        let parseResult = BridgeMessage.parse(from: rawJSON)

        switch parseResult {
        case .failure(let parseError):
            AppLogger.log(.warning, "BridgeRouter: parse failure — \(parseError.description)")
            // We don't have a valid id, so use a sentinel
            let response = BridgeResponseBuilder.failure(
                id: "unknown",
                code: BridgeErrorCode.invalidRequest,
                message: parseError.description
            )
            completion(response)
            return

        case .success(let message):
            routeMessage(message, completion: completion)
        }
    }

    // MARK: - Private

    private func routeMessage(_ message: BridgeMessage, completion: @escaping (String) -> Void) {
        // Inject presentation context into handlers that need it
        injectViewControllerIfNeeded(into: handlers[message.namespace])

        guard let handler = handlers[message.namespace] else {
            AppLogger.log(.warning, "BridgeRouter: unknown namespace '\(message.namespace)'")
            let response = BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownNamespace,
                message: BridgeError.unknownNamespace(message.namespace).message
            )
            completion(response)
            return
        }

        AppLogger.log(.debug, "BridgeRouter: dispatching \(message.namespace).\(message.method) [id=\(message.id)]")
        handler.handle(message: message, completion: completion)
    }

    /// Injects the viewController into handlers that conform to ViewControllerConsumer.
    private func injectViewControllerIfNeeded(into handler: BridgeHandler?) {
        guard let consumer = handler as? ViewControllerConsumer else { return }
        consumer.viewController = viewController
    }
}

// MARK: - ViewControllerConsumer

/// Protocol adopted by handlers that need a presentation context.
protocol ViewControllerConsumer: AnyObject {
    var viewController: UIViewController? { get set }
}
