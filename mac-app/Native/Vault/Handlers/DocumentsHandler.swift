import Foundation

final class DocumentsHandler: BridgeHandler {
    let namespace = "documents"
    private let service: DocumentService

    init(service: DocumentService) {
        self.service = service
    }

    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        do {
            switch message.method {
            case "list":
                let docs = try service.listDocuments()
                let encoded = try encodeToAny(docs)
                completion(.success(id: message.id, data: encoded))

            case "get":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let doc = try service.getDocument(id)
                let encoded = try encodeToAny(doc)
                completion(.success(id: message.id, data: encoded))

            case "create":
                let title = message.params["title"]?.value as? String ?? ""
                let body = message.params["body"]?.value as? String ?? ""
                let doc = try service.createDocument(title: title, body: body)
                let encoded = try encodeToAny(doc)
                completion(.success(id: message.id, data: encoded))

            case "update":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let title = message.params["title"]?.value as? String
                let body = message.params["body"]?.value as? String
                let doc = try service.updateDocument(id, title: title, body: body)
                let encoded = try encodeToAny(doc)
                completion(.success(id: message.id, data: encoded))

            case "delete":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                try service.deleteDocument(id)
                completion(.success(id: message.id, data: AnyCodable(true)))

            default:
                throw BridgeError.unknownMethod(message.method, namespace: namespace)
            }
        } catch let error as BridgeError {
            completion(.failure(id: message.id, bridgeError: error))
        } catch {
            completion(.failure(id: message.id, bridgeError: .internalError(error.localizedDescription)))
        }
    }
}
