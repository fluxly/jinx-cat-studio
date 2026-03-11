import Foundation

final class TagsHandler: BridgeHandler {
    let namespace = "tags"
    private let service: TagService
    private var documentRepo: DocumentRepository?
    private var assetRepo: AssetRepository?

    init(service: TagService) {
        self.service = service
    }

    /// Inject repositories for tag assignment operations
    func configure(documentRepo: DocumentRepository, assetRepo: AssetRepository) {
        self.documentRepo = documentRepo
        self.assetRepo = assetRepo
    }

    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        do {
            switch message.method {
            case "list":
                let tags = try service.listTags()
                let encoded = try encodeToAny(tags)
                completion(.success(id: message.id, data: encoded))

            case "create":
                guard let name = message.params["name"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: name")
                }
                let color = message.params["color"]?.value as? String ?? "#808080"
                let tag = try service.createTag(name: name, color: color)
                let encoded = try encodeToAny(tag)
                completion(.success(id: message.id, data: encoded))

            case "update":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let name = message.params["name"]?.value as? String
                let color = message.params["color"]?.value as? String
                let tag = try service.updateTag(id, name: name, color: color)
                let encoded = try encodeToAny(tag)
                completion(.success(id: message.id, data: encoded))

            case "delete":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                try service.deleteTag(id)
                completion(.success(id: message.id, data: AnyCodable(true)))

            case "assign":
                try handleAssign(message: message)
                completion(.success(id: message.id, data: AnyCodable(true)))

            case "unassign":
                try handleUnassign(message: message)
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

    private func handleAssign(message: BridgeMessage) throws {
        guard let tagId = message.params["tag_id"]?.value as? String else {
            throw BridgeError.invalidParams("Missing required parameter: tag_id")
        }
        if let documentId = message.params["document_id"]?.value as? String {
            guard let repo = documentRepo else { throw BridgeError.internalError("DocumentRepository not configured") }
            try repo.addTag(tagId, toDocument: documentId)
        } else if let assetId = message.params["asset_id"]?.value as? String {
            guard let repo = assetRepo else { throw BridgeError.internalError("AssetRepository not configured") }
            try repo.addTag(tagId, toAsset: assetId)
        } else {
            throw BridgeError.invalidParams("Must provide either document_id or asset_id")
        }
    }

    private func handleUnassign(message: BridgeMessage) throws {
        guard let tagId = message.params["tag_id"]?.value as? String else {
            throw BridgeError.invalidParams("Missing required parameter: tag_id")
        }
        if let documentId = message.params["document_id"]?.value as? String {
            guard let repo = documentRepo else { throw BridgeError.internalError("DocumentRepository not configured") }
            try repo.removeTag(tagId, fromDocument: documentId)
        } else if let assetId = message.params["asset_id"]?.value as? String {
            guard let repo = assetRepo else { throw BridgeError.internalError("AssetRepository not configured") }
            try repo.removeTag(tagId, fromAsset: assetId)
        } else {
            throw BridgeError.invalidParams("Must provide either document_id or asset_id")
        }
    }
}
