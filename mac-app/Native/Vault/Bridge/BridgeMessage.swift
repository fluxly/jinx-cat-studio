import Foundation

struct BridgeMessage: Decodable {
    let id: String
    let namespace: String
    let method: String
    let params: [String: AnyCodable]

    init(id: String, namespace: String, method: String, params: [String: AnyCodable] = [:]) {
        self.id = id
        self.namespace = namespace
        self.method = method
        self.params = params
    }
}
