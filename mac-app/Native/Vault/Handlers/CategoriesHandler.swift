import Foundation

final class CategoriesHandler: BridgeHandler {
    let namespace = "categories"
    private let service: CategoryService

    init(service: CategoryService) {
        self.service = service
    }

    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        do {
            switch message.method {
            case "list":
                let cats = try service.listCategories()
                let encoded = try encodeToAny(cats)
                completion(.success(id: message.id, data: encoded))

            case "get":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let cat = try service.getCategory(id)
                let encoded = try encodeToAny(cat)
                completion(.success(id: message.id, data: encoded))

            case "create":
                guard let name = message.params["name"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: name")
                }
                let parentId = message.params["parent_id"]?.value as? String
                let cat = try service.createCategory(name: name, parentId: parentId)
                let encoded = try encodeToAny(cat)
                completion(.success(id: message.id, data: encoded))

            case "update":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let name = message.params["name"]?.value as? String
                // parent_id can be nil (not provided) or null (explicitly clearing it)
                let parentId: String?? = message.params["parent_id"].map { $0.value as? String }
                let cat = try service.updateCategory(id, name: name, parentId: parentId)
                let encoded = try encodeToAny(cat)
                completion(.success(id: message.id, data: encoded))

            case "delete":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                try service.deleteCategory(id)
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
