import Foundation

struct BridgeResponse: Encodable {
    let id: String
    let success: Bool
    let data: AnyCodable?
    let error: BridgeErrorPayload?

    init(id: String, data: AnyCodable) {
        self.id = id
        self.success = true
        self.data = data
        self.error = nil
    }

    init(id: String, error: BridgeErrorPayload) {
        self.id = id
        self.success = false
        self.data = nil
        self.error = error
    }

    static func success(id: String, data: Any) -> BridgeResponse {
        return BridgeResponse(id: id, data: AnyCodable(data))
    }

    static func failure(id: String, error: BridgeErrorPayload) -> BridgeResponse {
        return BridgeResponse(id: id, error: error)
    }

    static func failure(id: String, bridgeError: BridgeError) -> BridgeResponse {
        return BridgeResponse(id: id, error: BridgeErrorPayload(code: bridgeError.code.rawValue, message: bridgeError.message))
    }
}
