import Foundation

// MARK: - Success Response

/// A typed success response envelope.
struct BridgeSuccessResponse<T: Encodable>: Encodable {
    let id: String
    let ok: Bool = true
    let result: T

    enum CodingKeys: String, CodingKey {
        case id, ok, result
    }
}

// MARK: - Error Response

/// An error response envelope.
struct BridgeErrorResponse: Encodable {
    let id: String
    let ok: Bool = false
    let error: BridgeErrorPayload

    enum CodingKeys: String, CodingKey {
        case id, ok, error
    }
}

/// The payload inside a BridgeErrorResponse.
struct BridgeErrorPayload: Encodable {
    let code: String
    let message: String
}

// MARK: - Builder

/// Static factory for building serialized bridge response JSON strings.
enum BridgeResponseBuilder {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = []
        return e
    }()

    /// Builds a success response JSON string.
    /// - Parameters:
    ///   - id: The request ID to echo back.
    ///   - result: An Encodable result payload.
    /// - Returns: A compact JSON string, or a fallback error JSON if encoding fails.
    static func success<T: Encodable>(id: String, result: T) -> String {
        let response = BridgeSuccessResponse(id: id, result: result)
        do {
            let data = try encoder.encode(response)
            return String(data: data, encoding: .utf8) ?? fallbackError(id: id, code: "encoding_failed", message: "Failed to encode success response")
        } catch {
            AppLogger.log(.error, "BridgeResponseBuilder.success encoding error: \(error)")
            return fallbackError(id: id, code: "encoding_failed", message: error.localizedDescription)
        }
    }

    /// Builds an error response JSON string.
    /// - Parameters:
    ///   - id: The request ID to echo back.
    ///   - code: Machine-readable error code.
    ///   - message: Human-readable error description.
    /// - Returns: A compact JSON string.
    static func failure(id: String, code: String, message: String) -> String {
        let response = BridgeErrorResponse(id: id, error: BridgeErrorPayload(code: code, message: message))
        do {
            let data = try encoder.encode(response)
            return String(data: data, encoding: .utf8) ?? fallbackError(id: id, code: code, message: message)
        } catch {
            AppLogger.log(.error, "BridgeResponseBuilder.failure encoding error: \(error)")
            return fallbackError(id: id, code: code, message: message)
        }
    }

    /// Produces a hardcoded minimal error JSON without using the encoder (last resort).
    private static func fallbackError(id: String, code: String, message: String) -> String {
        let safeId = id.replacingOccurrences(of: "\"", with: "'")
        let safeCode = code.replacingOccurrences(of: "\"", with: "'")
        let safeMsg = message.replacingOccurrences(of: "\"", with: "'")
        return "{\"id\":\"\(safeId)\",\"ok\":false,\"error\":{\"code\":\"\(safeCode)\",\"message\":\"\(safeMsg)\"}}"
    }
}
