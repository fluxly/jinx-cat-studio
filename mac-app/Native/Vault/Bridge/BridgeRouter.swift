import Foundation

typealias BridgeCompletion = (BridgeResponse) -> Void

protocol BridgeHandler {
    var namespace: String { get }
    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion)
}

class BridgeRouter {
    private let handlers: [String: BridgeHandler]
    private let queue = DispatchQueue(label: "com.jinxcatstudio.vault.bridge", qos: .userInitiated)

    init(
        documentsHandler: DocumentsHandler,
        assetsHandler: AssetsHandler,
        tagsHandler: TagsHandler,
        categoriesHandler: CategoriesHandler,
        searchHandler: SearchHandler
    ) {
        var map: [String: BridgeHandler] = [:]
        for handler in [documentsHandler as BridgeHandler, assetsHandler, tagsHandler, categoriesHandler, searchHandler] {
            map[handler.namespace] = handler
        }
        self.handlers = map
    }

    func route(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        queue.async {
            guard let handler = self.handlers[message.namespace] else {
                let error = BridgeErrorPayload(code: BridgeErrorCode.unknownNamespace.rawValue,
                                               message: "Unknown namespace: '\(message.namespace)'")
                completion(BridgeResponse.failure(id: message.id, error: error))
                return
            }
            handler.handle(message: message, completion: completion)
        }
    }
}
