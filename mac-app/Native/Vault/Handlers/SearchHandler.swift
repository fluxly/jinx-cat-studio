import Foundation

final class SearchHandler: BridgeHandler {
    let namespace = "search"
    private let service: SearchService

    init(service: SearchService) {
        self.service = service
    }

    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        do {
            switch message.method {
            case "query":
                guard let query = message.params["q"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: q")
                }
                let limitRaw = message.params["limit"]?.value
                let limit: Int
                if let l = limitRaw as? Int { limit = l }
                else if let l = limitRaw as? Int64 { limit = Int(l) }
                else { limit = 50 }

                let results = try service.search(query: query, limit: limit)
                let encoded = try encodeToAny(results)
                completion(.success(id: message.id, data: encoded))

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
